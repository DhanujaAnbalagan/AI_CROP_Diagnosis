import 'package:audioplayers/audioplayers.dart';
import '../models/alert_models.dart';

/// Manages playing different alert tones based on urgency.
class AlertToneManager {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isMuted = false;

  /// Mute/unmute alert tones
  static void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// Play alert tone based on urgency level
  static Future<void> playAlertTone(UrgencyLevel urgency) async {
    if (_isMuted) return;

    try {
      String soundPath;
      switch (urgency) {
        case UrgencyLevel.high:
          soundPath = 'assets/sounds/urgent_alert.mp3';
          break;
        case UrgencyLevel.medium:
          soundPath = 'assets/sounds/normal_alert.mp3';
          break;
        case UrgencyLevel.low:
          soundPath = 'assets/sounds/soft_alert.mp3';
          break;
      }

      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Handle audio playback errors gracefully
      print('Failed to play alert tone: $e');
    }
  }

  /// Stop any currently playing alert
  static Future<void> stopAlert() async {
    await _audioPlayer.stop();
  }

  /// Dispose the audio player
  static void dispose() {
    _audioPlayer.dispose();
  }
}
