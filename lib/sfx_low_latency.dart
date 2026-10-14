// 출처: 스토어에 출시된 Flutter 게임의 효과음 (실기기 프레임 기록으로 확인)
//
// 짧은 효과음(걸음·버튼)용. audioplayers 기본(MediaPlayer) 모드와 AudioPool 을
// 효과음에 쓰지 않는다 — 이유는 아래 주석과 ../README.md 「소리」.
//
// 쓰는 법:
//   final step = await LowLatencySfx.fromAsset('audio/move.wav');  // 시작할 때 한 번
//   step.start();                                                  // 낼 때마다
library;

import 'package:audioplayers/audioplayers.dart';

/// 저지연 모드(안드로이드 SoundPool) 플레이어 몇 개를 돌려 가며 쓴다.
///
/// 예전엔 [AudioPool](MediaPlayer)을 썼다. MediaPlayer는 재생할 때마다 속도
/// 설정을 미디어 서버에 묻는데, 이게 **가끔 0.12초씩 폰의 메인 스레드를
/// 붙잡았다.** Flutter는 화면을 그릴 신호(vsync)를 메인 스레드에서 받으므로
/// 그동안 화면이 멈춘다 — 움직이는 캐릭터가 가끔 "끊겼다 한 번에" 가던
/// 진짜 원인이었다(실기기 프레임 기록으로 확인).
/// SoundPool은 짧은 효과음용이라 재생 호출이 가볍다.
///
/// 오디오 포커스는 요청하지 않는다. 걸음마다 포커스를 잡으면 그것도 시스템
/// 호출이고, 듣던 음악이 걸음마다 끊긴다.
class LowLatencySfx {
  final List<AudioPlayer> _players;
  var _next = 0;
  LowLatencySfx(this._players);

  static final _ctx = AudioContext(
    android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    // 아이폰도 듣던 음악을 끊지 않고, 무음 스위치를 따른다(music.dart 와 같은 세션).
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// 같은 소리가 겹쳐 날 수 있는 수. 소리가 재생 간격보다 길어도 앞 소리를
  /// 끊지 않게 셋을 돌린다. 연타가 더 빠르거나 소리가 길면 늘린다.
  static const _voices = 3;

  static Future<LowLatencySfx> fromAsset(String asset) async {
    final players = <AudioPlayer>[];
    for (var i = 0; i < _voices; i++) {
      final p = AudioPlayer();
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setAudioContext(_ctx);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource(asset));
      players.add(p);
    }
    return LowLatencySfx(players);
  }

  Future<void> start() async {
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    // 저지연 모드는 "재생 끝" 신호가 없어서, 한 번 울린 플레이어는 멈춰
    // 두지 않으면 다음 resume이 끝난 소리를 이어 틀려다 조용히 넘어간다.
    await p.stop();
    await p.resume();
  }

  Future<void> dispose() => Future.wait(_players.map((p) => p.dispose()));
}
