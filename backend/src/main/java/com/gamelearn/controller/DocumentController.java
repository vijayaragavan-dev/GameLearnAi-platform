package com.gamelearn.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.DocumentAskRequest;
import com.gamelearn.dto.DocumentAskResponse;
import com.gamelearn.dto.DocumentMetadataResponse;
import com.gamelearn.dto.DocumentUploadResponse;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.service.DocumentQaService;
import com.gamelearn.service.DocumentUploadService;
import com.gamelearn.service.UserDocumentService;

import jakarta.validation.Valid;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * USER-DOC RAG Phase C — secure PDF upload.
 *
 * <p>Identity always comes from the SecurityContext; the endpoint accepts
 * NO client-controlled userId/ownerId, and ownership of the created
 * document is the authenticated principal, server-derived. Thin by
 * convention — all validation, storage and extraction live in the
 * service layer. The response is metadata only.</p>
 */
@RestController
@Tag(name = "Documents", description = "User-owned PDF documents (metadata foundation)")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1")
public class DocumentController {

    private final DocumentUploadService documentUploadService;
    private final DocumentQaService documentQaService;
    private final UserDocumentService userDocumentService;

    public DocumentController(DocumentUploadService documentUploadService,
                              DocumentQaService documentQaService,
                              UserDocumentService userDocumentService) {
        this.documentUploadService = documentUploadService;
        this.documentQaService = documentQaService;
        this.userDocumentService = userDocumentService;
    }

    @Operation(summary = "Upload a PDF document",
            description = "Validates, stores and extracts one user-owned PDF: "
                    + "magic-signature and size checks, server-UUID storage, "
                    + "page-aware extraction with security screening. "
                    + "Succeeds as CHUNKED metadata (never INDEXED in this "
                    + "phase); failures surface as safe 4xx/5xx envelopes "
                    + "with the metadata row marked FAILED.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Document accepted and extracted (CHUNKED metadata)"),
            @ApiResponse(responseCode = "400", description = "Missing/unsupported/malformed PDF or failed screening"),
            @ApiResponse(responseCode = "401", description = "Missing/invalid/expired token"),
            @ApiResponse(responseCode = "413", description = "PDF exceeds the maximum allowed size"),
            @ApiResponse(responseCode = "429", description = "Upload rate limit exhausted"),
            @ApiResponse(responseCode = "500", description = "Storage or processing failure")
    })
    @PostMapping(value = "/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public DocumentUploadResponse upload(@AuthenticationPrincipal AuthenticatedUser principal,
                                         @RequestParam("file") MultipartFile file) {
        return documentUploadService.upload(principal.id(), file);
    }

    @Operation(summary = "Ask a question over owned documents",
            description = "USER-DOC RAG Phase I (feature flagged, disabled by default): "
                    + "answers one question SOLELY from Phase-H-validated evidence "
                    + "retrieved from the caller's own indexed documents. Ownership "
                    + "is the authenticated principal; the request carries no "
                    + "owner identity, filters, citations or vectors. Empty "
                    + "evidence never reaches Gemini (explicit insufficient "
                    + "response); fabricated citations degrade safely; provider "
                    + "faults are 503 with no outside-knowledge fallback.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Grounded answer or explicit insufficient response"),
            @ApiResponse(responseCode = "400", description = "Structural/validation failure"),
            @ApiResponse(responseCode = "401", description = "Missing/invalid/expired token"),
            @ApiResponse(responseCode = "404", description = "Document scope not owned by caller"),
            @ApiResponse(responseCode = "429", description = "Document Q&A rate limit exhausted"),
            @ApiResponse(responseCode = "503", description = "Feature disabled or Gemini unavailable")
    })
    @PostMapping(value = "/documents/ask", consumes = MediaType.APPLICATION_JSON_VALUE)
    public DocumentAskResponse ask(@AuthenticationPrincipal AuthenticatedUser principal,
                                   @Valid @RequestBody DocumentAskRequest request) {
        return documentQaService.ask(principal.id(), request);
    }

    @Operation(summary = "List owned documents",
            description = "Returns the authenticated learner's active "
                    + "documents newest-first (metadata only). Ownership "
                    + "is the authenticated principal; the response never "
                    + "carries paths, bytes, text, or secrets.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Owned document metadata list (possibly empty)"),
            @ApiResponse(responseCode = "401", description = "Missing/invalid/expired token")
    })
    @GetMapping(value = "/documents", produces = MediaType.APPLICATION_JSON_VALUE)
    public java.util.List<DocumentMetadataResponse> list(
            @AuthenticationPrincipal AuthenticatedUser principal) {
        return userDocumentService.listOwned(principal.id()).stream()
                .map(DocumentController::toMetadata)
                .toList();
    }

    private static DocumentMetadataResponse toMetadata(UserDocument doc) {
        return new DocumentMetadataResponse(
                doc.getId(),
                doc.getFilename(),
                doc.getContentType(),
                doc.getByteSize(),
                doc.getPageCount(),
                doc.getStatus().name(),
                doc.getDocVersion(),
                doc.getCreatedAt());
    }
}
