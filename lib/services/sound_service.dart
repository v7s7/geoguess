import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Wraps audioplayers + HapticFeedback.
/// Sound files must be placed in assets/sounds/:
///   correct.mp3, wrong.mp3, tick.mp3, success.mp3, countdown.mp3
/// The app works silently if files are missing.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool soundEnabled = true;
  bool hapticEnabled = true;

  Future<void> playCorrect() async {
    if (hapticEnabled) HapticFeedback.lightImpact();
    await _play('sounds/correct.mp3');
  }

  Future<void> playWrong() async {
    if (hapticEnabled) HapticFeedback.mediumImpact();
    await _play('sounds/wrong.mp3');
  }

  Future<void> playSuccess() async {
    if (hapticEnabled) HapticFeedback.lightImpact();
    await _play('sounds/success.mp3');
  }

  Future<void> playTick() async {
    await _play('sounds/tick.mp3');
  }

  Future<void> playTap() async {
    if (hapticEnabled) HapticFeedback.selectionClick();
  }

  Future<void> _play(String assetPath) async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Silently fail if asset not found
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
  }
}
