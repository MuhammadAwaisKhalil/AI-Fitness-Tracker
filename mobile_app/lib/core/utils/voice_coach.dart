import 'package:flutter/services.dart';

/// Audio, Voice & Haptic Coach for real-time workout feedback.
/// Uses Flutter's native SystemSound and HapticFeedback channels
/// for zero-latency cues when users are exercising.
class VoiceCoach {
  static final VoiceCoach instance = VoiceCoach._internal();
  VoiceCoach._internal();

  bool isMuted = false;

  /// Triggered on every successful full-depth rep.
  void onGoodRep(int repCount) {
    if (isMuted) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Triggered when a partial rep is detected.
  void onPartialRep() {
    if (isMuted) return;
    HapticFeedback.lightImpact();
  }

  /// Triggered when a form error / deviation occurs (e.g., sagging hips).
  void onFormWarning(String message) {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
  }

  /// Triggered when completing a hold milestone (e.g., every 5s on plank).
  void onHoldMilestone(int seconds) {
    if (isMuted) return;
    if (seconds % 5 == 0) {
      HapticFeedback.selectionClick();
    }
  }

  void toggleMute() {
    isMuted = !isMuted;
  }
}
