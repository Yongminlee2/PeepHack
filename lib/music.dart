import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'engine/progress.dart';
import 'ui/fx/fx.dart';

/// 배경음악(tool/gen_music.py 로 합성한 반복곡). 앱이 뒤로 가면 멈추고, 돌아오면 이어서.
/// 다른 앱의 음악을 끊지 않게 오디오 포커스는 잡지 않는다.
class Music {
  static final Music _i = Music._();
  factory Music() => _i;
  Music._();

  static const asset = 'music/ambient.wav';
  static const volume = 0.35;

  AudioPlayer? _player;
  Progress? progress;
  bool _started = false;

  /// 위젯 테스트에서는 [Fx.animate] 가 꺼져 있어 아무것도 안 한다(오디오 플러그인이 없다).
  bool get _can => Fx.animate && (progress?.musicOn ?? false);

  Future<void> start(Progress p) async {
    progress = p;
    if (!_can || _started) return;
    try {
      final pl = _player ??= AudioPlayer();
      await pl.setAudioContext(AudioContext(android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none)));
      await pl.setReleaseMode(ReleaseMode.loop);
      await pl.setVolume(volume);
      await pl.play(AssetSource(asset));
      _started = true;
    } catch (e) {
      debugPrint('music: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (!_can) return;
    if (!_started) return start(progress!);
    try {
      await _player?.resume();
    } catch (_) {}
  }

  Future<void> setEnabled(bool on) async {
    await progress?.setMusic(on);
    if (on) {
      await resume();
    } else {
      await pause();
    }
  }
}
