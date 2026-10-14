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

  Future<void>? _starting; // 시작하는 중(켜자마자 앱을 오가면 resume 이 또 start 를 부른다)

  /// 이미 시작 중이면 같은 작업을 돌려줘서 두 번 틀지 않는다.
  Future<void> start(Progress p) {
    progress = p;
    if (!_can || _started) return Future.value();
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    try {
      final pl = _player ??= AudioPlayer();
      // 아이폰은 ambient: 듣던 음악과 섞이고, 무음 스위치를 켜면 조용해진다(기본값 playback 은 둘 다 안 한다).
      await pl.setAudioContext(AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
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
    if (_starting != null) return _starting; // 아직 켜는 중 — 다시 틀지 않는다
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
