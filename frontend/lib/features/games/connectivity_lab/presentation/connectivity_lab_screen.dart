import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/game_visual_identity.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_surfaces.dart';
import '../../../game_engine/engine/game_combo.dart';
import '../../../game_engine/engine/game_scoring.dart';
import '../../../game_engine/engine/game_timer.dart';
import '../../../game_engine/models/game_models.dart';
import '../../../game_engine/utils/difficulty_utils.dart';
import '../../../game_engine/widgets/game_hud.dart';
import '../../../game_engine/widgets/game_result_screen.dart';
import '../data/connectivity_missions.dart';
import '../models/connectivity_lab.dart';

class ConnectivityLabScreen extends ConsumerStatefulWidget {
  const ConnectivityLabScreen({super.key, required this.topicId, this.topicName, this.subjectId, this.subjectName});
  final String topicId;
  final String? topicName;
  final String? subjectId;
  final String? subjectName;
  @override
  ConsumerState<ConnectivityLabScreen> createState() => _ConnectivityLabScreenState();
}

class _ConnectivityLabScreenState extends ConsumerState<ConnectivityLabScreen> {
  late List<ConnectivityMission> _missions;
  int _index = 0;
  int _score = 0;
  int _lives = 3;
  int _correctCount = 0;
  late GameCombo _combo;
  late GameTimer _timer;
  GameDifficulty _difficulty = GameDifficulty.medium;
  int _timeLimit = 150;
  DateTime? _start;
  bool _paused = false;
  bool _hintVisible = false;
  bool _showResult = false;
  bool _wasCorrect = false;
  String? _feedback;
  Timer? _feedbackTimer;

  // Per-mission state
  Set<NetworkConnection> _userConns = {};
  List<String> _routeSelected = [];
  String? _selectedDiagnosis;
  List<String> _layerSelected = [];
  String? _firstDevice; // for connect

  ConnectivityMission get _current => _missions[_index];

  @override
  void initState() {
    super.initState();
    _combo = GameCombo();
    _difficulty = GameDifficulty.medium;
    _timeLimit = DifficultyUtils.timeLimitFor(_difficulty, GameType.connectivityLab);
    _missions = ConnectivityMissions.session(count: 4);
    _initMission();
    _timer = GameTimer(totalSeconds: _timeLimit);
    _timer.onTickValue = (_) { if (mounted) setState(() {}); };
    _timer.onComplete = _onTimeUp;
    _timer.start();
    _start = DateTime.now();
  }

  void _initMission() {
    final m = _current;
    _hintVisible = false;
    _showResult = false;
    _wasCorrect = false;
    _feedback = null;
    _firstDevice = null;
    _routeSelected = [];
    _selectedDiagnosis = null;
    _layerSelected = [];
    // Initialize connections: for repair keep broken as is, for connect/build start with initial non-broken
    if (m.missionType == MissionType.repair) {
      _userConns = m.initialConnections.toSet();
    } else if (m.missionType == MissionType.connect || m.missionType == MissionType.build) {
      _userConns = {};
    } else if (m.missionType == MissionType.route || m.missionType == MissionType.trace) {
      _userConns = m.initialConnections.toSet();
      _routeSelected = [];
    } else {
      _userConns = m.initialConnections.toSet();
    }
  }

  void _onTimeUp() => _finishGame(timedOut: true);

  // Connect helpers
  void _onDeviceTapForConnect(String deviceId) {
    if (_showResult) return;
    if (_firstDevice == null) {
      setState(() => _firstDevice = deviceId);
    } else {
      if (_firstDevice == deviceId) {
        setState(() => _firstDevice = null);
        return;
      }
      final link = NetworkConnection(id: '${_firstDevice}_$deviceId', sourceId: _firstDevice!, targetId: deviceId);
      final reverse = NetworkConnection(id: '${deviceId}_${_firstDevice}', sourceId: deviceId, targetId: _firstDevice!);
      setState(() {
        if (_userConns.contains(link) || _userConns.contains(reverse)) {
          _userConns.remove(link);
          _userConns.remove(reverse);
        } else {
          _userConns = {..._userConns, link};
        }
        _firstDevice = null;
        _feedback = null;
      });
    }
  }

  void _onRemoveConn(NetworkConnection c) {
    if (_showResult) return;
    setState(() => _userConns = _userConns.where((e) => e != c).toSet());
  }

  // Route helpers
  void _onRouteDeviceTap(String deviceId) {
    if (_showResult) return;
    setState(() {
      if (_routeSelected.contains(deviceId)) {
        _routeSelected.remove(deviceId);
      } else {
        _routeSelected = [..._routeSelected, deviceId];
      }
      _feedback = null;
    });
  }

  void _onRepairTap(String connId) {
    if (_showResult) return;
    setState(() {
      _userConns = _userConns.map((c) {
        if (c.id == connId && c.isBroken) return c.copyWith(isBroken: false, enabled: true);
        return c;
      }).toSet();
      _feedback = null;
    });
  }

  void _onLayerTap(String layer) {
    if (_showResult) return;
    setState(() {
      if (_layerSelected.contains(layer)) {
        _layerSelected.remove(layer);
      } else {
        _layerSelected = [..._layerSelected, layer];
      }
      _feedback = null;
    });
  }

  void _onLayerReorder(int oldIdx, int newIdx) {
    if (_showResult) return;
    if (newIdx > oldIdx) newIdx--;
    setState(() {
      final item = _layerSelected.removeAt(oldIdx);
      _layerSelected.insert(newIdx, item);
    });
  }

  void _onCheck() {
    if (_showResult) return;
    final m = _current;
    bool correct = false;
    switch (m.missionType) {
      case MissionType.connect:
      case MissionType.build:
        if (_userConns.isEmpty) {
          setState(() => _feedback = 'Build the network first!');
          return;
        }
        correct = m.isConnectionCorrect(_userConns);
        break;
      case MissionType.route:
      case MissionType.trace:
        if (_routeSelected.length < 2) {
          setState(() => _feedback = 'Select the route nodes in order!');
          return;
        }
        correct = m.isRouteCorrect(_routeSelected);
        break;
      case MissionType.repair:
        correct = m.isRepairCorrect(_userConns);
        if (!correct && _userConns.any((c) => c.isBroken)) {
          // still broken
        }
        break;
      case MissionType.diagnose:
        if (_selectedDiagnosis == null) {
          setState(() => _feedback = 'Select a diagnosis!');
          return;
        }
        correct = m.isDiagnosisCorrect(_selectedDiagnosis!);
        break;
      case MissionType.layer:
        if (_layerSelected.length != m.layerBlocks!.length) {
          setState(() => _feedback = 'Arrange all layers to check!');
          return;
        }
        correct = m.isLayerCorrect(_layerSelected);
        break;
    }

    setState(() {
      _showResult = true;
      _wasCorrect = correct;
      _feedback = null;
    });

    if (correct) {
      _correctCount++;
      _combo.registerHit();
      final elapsed = _start == null ? 3 : DateTime.now().difference(_start!).inSeconds % 10;
      _score += GameScoring.scoreForHit(difficulty: m.difficulty, combo: _combo.current, responseTimeSeconds: elapsed.clamp(2, 10));
      ref.read(hapticsProvider).success();
    } else {
      _combo.registerMiss();
      _lives--;
      ref.read(hapticsProvider).error();
      if (_lives <= 0) {
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) _finishGame(outOfLives: true);
        });
        return;
      }
    }

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(Duration(milliseconds: correct ? 1600 : 1800), () {
      if (!mounted) return;
      if (correct) {
        if (_index < _missions.length - 1) {
          setState(() {
            _index++;
            _initMission();
          });
        } else {
          _finishGame();
        }
      } else {
        // allow retry
        setState(() {
          _showResult = false;
          _wasCorrect = false;
          if (m.missionType == MissionType.route || m.missionType == MissionType.trace) {
            _routeSelected = [];
          } else if (m.missionType == MissionType.diagnose) {
            _selectedDiagnosis = null;
          } else if (m.missionType == MissionType.layer) {
            _layerSelected = [];
          }
          // for connect/build keep current connections for retry
          // for repair keep repaired state (if wrong still broken, user can try again)
        });
      }
    });
  }

  void _finishGame({bool timedOut = false, bool outOfLives = false}) {
    _timer.stop();
    final elapsed = _start == null ? 0 : DateTime.now().difference(_start!).inSeconds;
    final total = _missions.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total * 100;
    final xpPreview = GameScoring.totalXpPreview(accuracy: accuracy, difficulty: _difficulty, comboMax: _combo.max);
    final result = GameResult(
      config: GameConfig(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId, subjectName: widget.subjectName, difficulty: _difficulty, type: GameType.connectivityLab, timeLimitSeconds: _timeLimit),
      score: _score,
      accuracy: accuracy,
      correctCount: _correctCount,
      totalQuestions: total,
      timeElapsedSeconds: elapsed,
      comboMax: _combo.max,
      xpEarned: xpPreview,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameResultScreen(
              result: result,
              onReplay: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ConnectivityLabScreen(topicId: widget.topicId, topicName: widget.topicName, subjectId: widget.subjectId))),
            )));
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  Color _timerColor() {
    final r = _timer.remaining;
    if (r <= 10) return AppColors.error;
    if (r <= 30) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  void dispose() {
    try { _timer.dispose(); } catch (_) {}
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_missions.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('CONNECTIVITY LAB')), body: const EmptyState(icon: Icons.wifi_off_rounded, title: 'No missions', message: 'No missions available.'));
    }
    final m = _current;
    final progress = (_index + (_showResult && _wasCorrect ? 1 : 0)) / _missions.length;
    final identity = GameVisualRegistry.of(GameType.connectivityLab);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                GameHud(
                  score: _score,
                  progress: progress,
                  progressLabel: 'MISSION ${_index + 1} / ${_missions.length}',
                  timeRemaining: _fmt(_timer.remaining),
                  combo: _combo,
                  difficultyLabel: _difficulty.displayName,
                  accent: identity.accent,
                  gameIcon: identity.icon,
                  gameTitle: GameType.connectivityLab.displayName,
                  onPause: () => setState(() { _paused = true; _timer.pause(); }),
                ),
                // Preserve lives indicator outside HUD so tests and UX still see hearts
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      _LivesIndicator(lives: _lives),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mission header
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF10B981).withValues(alpha: 0.14), AppColors.surfaceElevated]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.30))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF047857), Color(0xFF10B981)])), child: const Icon(Icons.hub_rounded, size: 18, color: Colors.white)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(m.title, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 15, fontWeight: FontWeight.w700))),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)), child: Text(m.missionType.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
                              ]),
                              const SizedBox(height: 8),
                              Text(m.objective, style: const TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(m.learningObjective, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(m.story, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Network Map — premium challenge surface with identity accent
                        GameChallengeSurface(
                          accent: identity.accent,
                          title: 'NETWORK MAP',
                          icon: identity.icon,
                          subtitle: m.topic.toUpperCase(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNetworkMap(m),
                              const SizedBox(height: 12),
                              // Connections display
                              if (_userConns.isNotEmpty || (m.missionType == MissionType.connect || m.missionType == MissionType.build || m.missionType == MissionType.repair))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('CONNECTIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                                      const SizedBox(height: 6),
                                      if (_userConns.isEmpty)
                                        const Text('No connections yet — tap devices to connect', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
                                      else
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: _userConns.map((c) {
                                            final isBroken = c.isBroken;
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(color: isBroken ? AppColors.error.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: isBroken ? AppColors.error : AppColors.success)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(isBroken ? Icons.link_off_rounded : Icons.link_rounded, size: 12, color: isBroken ? AppColors.error : AppColors.success),
                                                  const SizedBox(width: 4),
                                                  Text('${_deviceLabel(c.sourceId)} → ${_deviceLabel(c.targetId)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isBroken ? AppColors.error : AppColors.success)),
                                                  if (isBroken) ...[
                                                    const SizedBox(width: 4),
                                                    const Text('(BROKEN)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.error)),
                                                  ],
                                                  if ((m.missionType == MissionType.connect || m.missionType == MissionType.build) && !_showResult)
                                                    GestureDetector(
                                                      onTap: () => _onRemoveConn(c),
                                                      child: const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.close_rounded, size: 12, color: AppColors.textTertiary)),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              // Route display
                              if (m.missionType == MissionType.route || m.missionType == MissionType.trace)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('CURRENT ROUTE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                                      const SizedBox(height: 6),
                                      if (_routeSelected.isEmpty)
                                        const Text('Tap devices in order to build route', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
                                      else
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: _routeSelected.asMap().entries.map((e) {
                                            final idx = e.key;
                                            final node = e.value;
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: const Color(0xFF10B981))),
                                                  child: Text('${idx + 1}. ${_deviceLabel(node)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                                                ),
                                                if (idx < _routeSelected.length - 1) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textTertiary)),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      if (_routeSelected.isNotEmpty && !_showResult)
                                        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _routeSelected = []), icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR'))),
                                    ],
                                  ),
                                ),
                              // Repair hint
                              if (m.missionType == MissionType.repair && _userConns.any((c) => c.isBroken))
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                                    child: Row(children: [
                                      const Icon(Icons.build_rounded, size: 14, color: AppColors.error),
                                      const SizedBox(width: 6),
                                      const Expanded(child: Text('Tap the broken link to repair', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600))),
                                      TextButton(onPressed: () => _onRepairTap(m.brokenConnectionId!), child: const Text('REPAIR')),
                                    ]),
                                  ),
                                ),
                              if (_hintVisible) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(m.hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))]),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('SHOW HINT'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero))),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Type-specific controls
                        _buildMissionControls(m),
                        const SizedBox(height: 12),
                        if (_feedback != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                            child: Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(_feedback!, style: const TextStyle(fontSize: 12, color: AppColors.warning)))]),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_showResult) ...[
                          GameFeedbackSurface(
                            isCorrect: _wasCorrect,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_wasCorrect ? 'MISSION COMPLETE!' : 'NETWORK STILL OFFLINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.success : AppColors.error)),
                                const SizedBox(height: 6),
                                Text(m.explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(children: [Icon(Icons.school_outlined, size: 12, color: AppColors.success), SizedBox(width: 6), Text('CONCEPT', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.success))]),
                                      const SizedBox(height: 4),
                                      Text(m.concept, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (_wasCorrect) ...[
                                  const SizedBox(height: 6),
                                  Text('+${GameScoring.scoreForHit(difficulty: m.difficulty, combo: _combo.current, responseTimeSeconds: 3)} · ${_combo.label.isEmpty ? "x1" : _combo.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ] else ...[
                                  const SizedBox(height: 6),
                                  Text(_lives > 0 ? 'Lives remaining: $_lives — diagnose again!' : 'No lives left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _lives > 0 ? AppColors.textSecondary : AppColors.error)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _hintVisible = true), icon: const Icon(Icons.lightbulb_outline_rounded, size: 16), label: const Text('HINT'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _showResult ? null : _onCheck,
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: const Color(0xFF10B981), disabledBackgroundColor: AppColors.surfaceHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(_showResult ? (_wasCorrect ? 'NEXT MISSION' : (_lives <= 0 ? 'GAME OVER' : 'RETRYING...')) : 'CHECK', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w700, color: _showResult ? AppColors.textTertiary : Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.pop(), child: const Text('EXIT LAB')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_paused)
            Positioned.fill(
              child: Container(
                color: AppColors.scrim,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_rounded, size: 48, color: Color(0xFF10B981)),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => setState(() { _paused = false; _timer.resume(); }), icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'))),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT LAB'))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _deviceLabel(String id) {
    try {
      return _current.devices.firstWhere((d) => d.id == id).name;
    } catch (_) {
      return id;
    }
  }

  Widget _buildNetworkMap(ConnectivityMission m) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: m.devices.map((d) {
        final isSelected = _firstDevice == d.id || _routeSelected.contains(d.id);
        final isInRoute = _routeSelected.contains(d.id);
        Color border = AppColors.border;
        Color fill = AppColors.surfaceElevated;
        IconData iconData = Icons.device_hub_rounded;
        switch (d.type) {
          case DeviceType.client:
          case DeviceType.pc:
            iconData = Icons.computer_rounded;
            break;
          case DeviceType.server:
            iconData = Icons.dns_rounded;
            break;
          case DeviceType.router:
            iconData = Icons.router_rounded;
            break;
          case DeviceType.switch_:
            iconData = Icons.hub_rounded;
            break;
          case DeviceType.accessPoint:
            iconData = Icons.wifi_rounded;
            break;
          case DeviceType.firewall:
            iconData = Icons.security_rounded;
            break;
          case DeviceType.dns:
            iconData = Icons.language_rounded;
            break;
          case DeviceType.dhcp:
            iconData = Icons.settings_ethernet_rounded;
            break;
        }
        if (isSelected) {
          border = const Color(0xFF10B981);
          fill = const Color(0xFF10B981).withValues(alpha: 0.12);
        } else if (isInRoute) {
          border = const Color(0xFF10B981);
          fill = const Color(0xFF10B981).withValues(alpha: 0.08);
        }
        // For route missions, tapping builds route; for connect, tapping builds connection
        VoidCallback? onTap;
        if (m.missionType == MissionType.connect || m.missionType == MissionType.build) {
          onTap = () => _onDeviceTapForConnect(d.id);
        } else if (m.missionType == MissionType.route || m.missionType == MissionType.trace) {
          onTap = () => _onRouteDeviceTap(d.id);
        } else if (m.missionType == MissionType.repair) {
          // devices not directly tappable for repair, but we allow route tap for repair? Just show
          onTap = null;
        } else {
          onTap = null;
        }

        return Semantics(
          button: true,
          label: 'Device ${d.name}',
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: border, width: isSelected ? 1.6 : 1.0), boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 10)] : null),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceHigh, border: Border.all(color: border)),
                    child: Icon(iconData, size: 18, color: isSelected ? const Color(0xFF10B981) : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(d.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (d.label != null) Text(d.label!, style: const TextStyle(fontSize: 9, color: AppColors.textTertiary), textAlign: TextAlign.center),
                  if (isInRoute) ...[
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4))), child: Text('${_routeSelected.indexOf(d.id) + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)))),
                  ],
                  if (_firstDevice == d.id) const Padding(padding: EdgeInsets.only(top: 4), child: Text('SELECTED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF10B981)))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMissionControls(ConnectivityMission m) {
    switch (m.missionType) {
      case MissionType.diagnose:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CHOOSE DIAGNOSIS', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            for (var i = 0; i < m.diagnosisOptions!.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosisCard(
                  index: i,
                  option: m.diagnosisOptions![i],
                  selected: _selectedDiagnosis == m.diagnosisOptions![i].id,
                  showResult: _showResult,
                  isCorrect: m.correctDiagnosisId == m.diagnosisOptions![i].id,
                  wasSelected: _selectedDiagnosis == m.diagnosisOptions![i].id,
                  enabled: !_showResult,
                  onTap: () => setState(() => _selectedDiagnosis = m.diagnosisOptions![i].id),
                ),
              ),
          ],
        );
      case MissionType.layer:
        final blocks = m.layerBlocks!;
        final available = blocks.where((b) => !_layerSelected.contains(b)).toList();
        final selected = _layerSelected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ARRANGE LAYERS (${_layerSelected.length}/${blocks.length})', style: const TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: _showResult ? (_wasCorrect ? AppColors.success : AppColors.error) : AppColors.border, width: _showResult ? 1.6 : 1.0)),
              child: _layerSelected.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Tap layers below to build stack →', style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.9)))))
                  : Column(
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: selected.length,
                          onReorder: _onLayerReorder,
                          itemBuilder: (context, idx) {
                            final layer = selected[idx];
                            final correctPos = _showResult ? m.correctLayerOrder![idx] == layer : null;
                            return Padding(
                              key: ValueKey('layer_$layer'),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _LayerCard(layer: layer, index: idx, showResult: _showResult, isCorrectPos: correctPos, onRemove: () => setState(() => _layerSelected.removeAt(idx))),
                            );
                          },
                        ),
                        if (!_showResult) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _layerSelected = []), icon: const Icon(Icons.clear_rounded, size: 14), label: const Text('CLEAR'))),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            const Text('AVAILABLE LAYERS', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: available.map((l) => _AvailableLayerChip(layer: l, onTap: () => _onLayerTap(l), enabled: !_showResult)).toList(),
            ),
          ],
        );
      case MissionType.connect:
      case MissionType.build:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TAP TWO DEVICES TO CONNECT', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            const Text('Tap source then destination. Tap existing connection chip to remove.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            if (_firstDevice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF10B981)), const SizedBox(width: 6), Text('Selected ${_deviceLabel(_firstDevice!)} — now tap destination', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))]),
              ),
            ],
          ],
        );
      case MissionType.route:
      case MissionType.trace:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TAP DEVICES IN ORDER TO BUILD ROUTE', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            const Text('Tap devices sequentially. Tap again to remove from route.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        );
      case MissionType.repair:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REPAIR THE BROKEN LINK', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
            SizedBox(height: 4),
            Text('The red broken connection blocks delivery. Tap REPAIR to restore.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        );
    }
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.index, required this.option, required this.selected, required this.showResult, required this.isCorrect, required this.wasSelected, required this.enabled, required this.onTap});
  final int index;
  final DiagnosisOption option;
  final bool selected;
  final bool showResult;
  final bool isCorrect;
  final bool wasSelected;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Color border;
    Color fill;
    Color glyph;
    if (showResult) {
      if (isCorrect) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.14);
        glyph = AppColors.success;
      } else if (wasSelected && !isCorrect) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.12);
        glyph = AppColors.error;
      } else {
        border = AppColors.border;
        fill = AppColors.surface;
        glyph = AppColors.textTertiary;
      }
    } else {
      if (selected) {
        border = const Color(0xFF10B981);
        fill = const Color(0xFF10B981).withValues(alpha: 0.16);
        glyph = const Color(0xFF10B981);
      } else {
        border = AppColors.border;
        fill = AppColors.surface;
        glyph = AppColors.textTertiary;
      }
    }
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Option ${String.fromCharCode(65 + index)}: ${option.label}',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: border, width: selected || (showResult && isCorrect) ? 1.8 : 1.2), boxShadow: selected && !showResult ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.30), blurRadius: 16)] : null),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: glyph.withValues(alpha: 0.14), border: Border.all(color: glyph.withValues(alpha: 0.5))), child: showResult && isCorrect ? const Icon(Icons.check_rounded, size: 15, color: AppColors.success) : showResult && wasSelected && !isCorrect ? const Icon(Icons.close_rounded, size: 15, color: AppColors.error) : Text(String.fromCharCode(65 + index), style: TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 13, fontWeight: FontWeight.w700, color: glyph))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(option.label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, height: 1.4)), const SizedBox(height: 4), Text(option.description, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))])),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({required this.layer, required this.index, required this.showResult, required this.isCorrectPos, required this.onRemove});
  final String layer;
  final int index;
  final bool showResult;
  final bool? isCorrectPos;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    Color border = const Color(0xFF10B981);
    Color fill = const Color(0xFF10B981).withValues(alpha: 0.08);
    IconData icon = Icons.drag_handle_rounded;
    Color iconColor = const Color(0xFF10B981);
    if (showResult) {
      if (isCorrectPos == true) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.12);
        icon = Icons.check_rounded;
        iconColor = AppColors.success;
      } else if (isCorrectPos == false) {
        border = AppColors.error;
        fill = AppColors.error.withValues(alpha: 0.1);
        icon = Icons.close_rounded;
        iconColor = AppColors.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: border, width: 1.4)),
      child: Row(
        children: [
          Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: border)), child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: border))),
          const SizedBox(width: 10),
          Expanded(child: Text(layer, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (!showResult) ...[
            ReorderableDragStartListener(index: index, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.textTertiary))),
            const SizedBox(width: 8),
            GestureDetector(onTap: onRemove, child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.1), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))), child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error))),
          ] else
            Icon(icon, size: 16, color: iconColor),
        ],
      ),
    );
  }
}

class _AvailableLayerChip extends StatelessWidget {
  const _AvailableLayerChip({required this.layer, required this.onTap, required this.enabled});
  final String layer;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Layer $layer',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: enabled ? AppColors.surface : AppColors.surfaceHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: enabled ? const Color(0xFF10B981).withValues(alpha: 0.45) : AppColors.border, width: 1.2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withValues(alpha: 0.15), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4))), child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF10B981))),
                  const SizedBox(width: 8),
                  Flexible(child: Text(layer, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: enabled ? AppColors.textPrimary : AppColors.textTertiary))),
                ],
              ),
            ),
          ),
        ),
      );
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.lives});
  final int lives;
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) => Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 4), child: Icon(i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: i < lives ? AppColors.error : AppColors.textTertiary))));
}
