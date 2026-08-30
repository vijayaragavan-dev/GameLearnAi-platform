import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/providers.dart';

/// Centralized game sound controller wrapping AudioManager.
/// No audio logic scattered in widgets. Provides semantic methods.
class GameSoundController {
  GameSoundController(this._audio);

  final AudioManager _audio;

  bool get enabled => _audio.sfxEnabled;

  Future<void> buttonTap() => _audio.play(Sfx.buttonTap);
  Future<void> correct() => _audio.play(Sfx.correct);
  Future<void> incorrect() => _audio.play(Sfx.incorrect);
  Future<void> combo() => _audio.play(Sfx.xpGain);
  Future<void> levelUp() => _audio.play(Sfx.levelUp);
  Future<void> achievement() => _audio.play(Sfx.achievementUnlock);
  Future<void> missionComplete() => _audio.play(Sfx.missionComplete);
  Future<void> cardFlip() => _audio.play(Sfx.buttonTap);
  Future<void> match() => _audio.play(Sfx.correct);
  Future<void> mismatch() => _audio.play(Sfx.incorrect);
  Future<void> streak() => _audio.play(Sfx.streakContinue);
  Future<void> countdownTick() => _audio.play(Sfx.notification);

  Future<void> setEnabled(bool v) => _audio.setSfxEnabled(v);
}

final gameSoundControllerProvider = Provider<GameSoundController>((ref) {
  final audio = ref.watch(audioManagerProvider);
  return GameSoundController(audio);
});
