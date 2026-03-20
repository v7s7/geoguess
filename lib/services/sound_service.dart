import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/services.dart';

/// Wraps audioplayers + HapticFeedback.
///
/// Asset layout expected in assets/sounds/:
///   correct.mp3 / correct.ogg
///   wrong.mp3   / wrong.ogg
///   tick.mp3    / tick.ogg
///   success.mp3 / success.ogg
///
/// Web browsers have inconsistent MP3 support inside Flutter's asset system
/// and frequently throw MEDIA_ELEMENT_ERROR: Format error (Code 4).
/// OGG/Vorbis is universally supported in Chrome, Firefox, and Edge, so we
/// serve .ogg on Web and keep .mp3 for iOS/Android.
///
/// The app works silently if a file is missing.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool soundEnabled = true;
  bool hapticEnabled = true;

  // Web → OGG (broad codec support), mobile → MP3.
  static String get _ext => kIsWeb ? 'ogg' : 'mp3';

  Future<void> playCorrect() async {
    if (hapticEnabled) HapticFeedback.lightImpact();
    await _play('correct');
  }

  Future<void> playWrong() async {
    if (hapticEnabled) HapticFeedback.mediumImpact();
    await _play('wrong');
  }

  Future<void> playSuccess() async {
    if (hapticEnabled) HapticFeedback.lightImpact();
    await _play('success');
  }

  Future<void> playTick() async {
    await _play('tick');
  }

  Future<void> playTap() async {
    if (hapticEnabled) HapticFeedback.selectionClick();
  }

  Future<void> _play(String name) async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/$name.$_ext'));
    } catch (_) {
      // Silently fail — missing file or unsupported codec.
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
  }
}
