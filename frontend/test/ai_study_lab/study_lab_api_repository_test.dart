// ApiStudyLabRepository: real document-API mapping against mocked HTTP.
// No backend invention: every shape mirrors the MlRag document contract
// (metadata-only upload response, ask answer/citations/grounded flags).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/ai_study_lab/data/api_study_lab_repository.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_document.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_practice.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_tutor.dart';
import 'package:gamelearn_app/features/ai_study_lab/domain/study_upload.dart';

Map<String, dynamic> _meta(String status) => {
  'id': 'doc-1',
  'filename': 'algebra.pdf',
  'contentType': 'application/pdf',
  'byteSize': 1024,
  'pageCount': 12,
  'status': status,
  'docVersion': 1,
  'createdAt': '2026-09-28T10:00:00Z',
};

ApiStudyLabRepository _repo(
  Future<http.Response> Function(http.BaseRequest) handler,
) =>
    ApiStudyLabRepository(ApiClient(client: MockClient(handler)));

void main() {
  group('documents list mapping', () {
    test('maps statuses honestly', () async {
      final repo = _repo((_) async => http.Response(
        jsonEncode([
          _meta('INDEXED'),
          _meta('UPLOADED'),
          _meta('EXTRACTING'),
          _meta('CHUNKED'),
          _meta('FAILED'),
          _meta('SOMETHING_ELSE'),
        ]),
        200,
      ));
      final docs = await repo.documents();
      expect(
        docs.map((d) => d.status).toList(),
        [
          DocumentStatus.ready,
          DocumentStatus.processing,
          DocumentStatus.processing,
          DocumentStatus.processing,
          DocumentStatus.failed,
          DocumentStatus.unavailable,
        ],
      );
      expect(docs.first.title, 'algebra.pdf');
      expect(docs.first.fileType, DocumentFileType.pdf);
    });

    test('documentById resolves by id only', () async {
      final repo = _repo((_) async => http.Response(
        jsonEncode([
          {..._meta('INDEXED'), 'id': 'a', 'filename': 'a.pdf'},
          {..._meta('INDEXED'), 'id': 'b', 'filename': 'b.pdf'},
        ]),
        200,
      ));
      expect((await repo.documentById('b'))?.title, 'b.pdf');
      expect(await repo.documentById('nope'), isNull);
    });
  });

  group('upload', () {
    test('multipart fields and success mapping', () async {
      http.BaseRequest? seen;
      final repo = ApiStudyLabRepository(
        ApiClient(
          client: MockClient.streaming((request, bodyStream) async {
            seen = request;
            await bodyStream.toBytes();
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(jsonEncode(_meta('CHUNKED'))),
              ),
              201,
            );
          }),
        ),
      );
      final result = await repo.uploadDocument(
        const PickedStudyFile(name: 'n.pdf', sizeBytes: 3, bytes: [1, 2, 3]),
      );
      expect(seen, isA<http.MultipartRequest>());
      final mp = seen! as http.MultipartRequest;
      expect(mp.url.path, '/api/v1/documents');
      expect(mp.files.single.field, 'file');
      expect(mp.files.single.filename, 'n.pdf');
      expect(result, isA<UploadSuccess>());
      final doc = (result as UploadSuccess).document;
      expect(doc.status, DocumentStatus.processing);
    });

    test('missing bytes never uploads', () async {
      var called = false;
      final repo = _repo((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final result = await repo.uploadDocument(
        const PickedStudyFile(name: 'n.pdf', sizeBytes: null),
      );
      expect(result, isA<UploadFailure>());
      expect(called, isFalse);
    });

    test('400/413 become failures, 401 rethrows', () async {
      Future<UploadResult> run(int code) => _repo(
        (_) async => http.Response(
          jsonEncode({'errorCode': 'X', 'message': 'Denied'}),
          code,
        ),
      ).uploadDocument(
        const PickedStudyFile(name: 'n.pdf', sizeBytes: 1, bytes: [1]),
      );
      expect(await run(400), isA<UploadFailure>());
      expect(await run(413), isA<UploadFailure>());
      await expectLater(
        run(401),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('ask', () {
    test('grounded answer with parsed page citations', () async {
      Map<String, dynamic>? seenBody;
      final repo = _repo((request) async {
        expect(request.url.path, '/api/v1/documents/ask');
        seenBody = jsonDecode(
          (request as http.Request).body,
        ) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'answer': 'Trees are hierarchical.',
            'citations': ['doc:doc-1:v1#p4c2', 'not-a-citation'],
            'grounded': true,
            'insufficientEvidence': false,
          }),
          200,
        );
      });
      final result = await repo.askDocumentQuestion(
        documentId: 'doc-1',
        question: 'What?',
      );
      expect(seenBody!['question'], 'What?');
      expect(seenBody!['documentId'], 'doc-1');
      expect(result, isA<TutorAnswer>());
      final answer = result as TutorAnswer;
      expect(answer.grounded, isTrue);
      expect(answer.sources, hasLength(2));
      expect(answer.sources.first.page, 4);
      expect(answer.sources.first.documentId, 'doc-1');
      expect(answer.sources.last.section, 'not-a-citation');
    });

    test('insufficient evidence maps to no-answer', () async {
      final repo = _repo((_) async => http.Response(
        jsonEncode({
          'answer': '',
          'citations': [],
          'grounded': false,
          'insufficientEvidence': true,
        }),
        200,
      ));
      final result = await repo.askDocumentQuestion(
        documentId: 'doc-1',
        question: 'What?',
      );
      expect(result, isA<TutorNoAnswer>());
    });

    test('404/503/401 surface honestly', () async {
      Future<TutorAskResult> run(int code) => _repo(
        (_) async => http.Response(
          jsonEncode({'errorCode': 'X', 'message': 'Nope'}),
          code,
        ),
      ).askDocumentQuestion(documentId: 'doc-1', question: 'What?');
      expect(await run(404), isA<TutorFailure>());
      expect(await run(503), isA<TutorUnavailable>());
      await expectLater(
        run(401),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('practice seam stays unavailable', () {
    test('generation and evaluation have no backend', () async {
      final repo = _repo((_) async => http.Response('{}', 200));
      expect(
        await repo.generateDocumentPractice(
          documentId: 'd',
          setup: const PracticeSetup(),
        ),
        isA<PracticeUnavailable>(),
      );
      expect(
        await repo.evaluatePracticeAnswer(
          documentId: 'd',
          questionId: 'q',
          selectedAnswer: 'a',
        ),
        isA<PracticeEvaluationUnavailable>(),
      );
    });
  });
}
