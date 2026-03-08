import 'package:just_audio/just_audio.dart';

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Mishari Al-Afasy, 128kbps, whole-surah audio from AlQuran CDN.
  // https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/{surah}.mp3
  static const String _baseUrl =
      'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/';

  Future<void> playSurah(int surahNumber) async {
    final url = '$_baseUrl$surahNumber.mp3';
    try {
      final currentUrl = _player.audioSource is ProgressiveAudioSource
          ? (_player.audioSource as ProgressiveAudioSource).uri.toString()
          : null;

      if (currentUrl != url) {
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (_) {
      // optionally log
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();

  AudioPlayer get player => _player;
}
