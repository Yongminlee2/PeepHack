import 'package:flutter/foundation.dart';

import 'engine/progress.dart';
import 'sfx_low_latency.dart'; // common/flutter/sfx_low_latency.dart 복사

/// 효과음 다섯 개: key tap run ok fail. 설정에서 끄면 전부 조용.
class Sfx {
  static final Sfx _i = Sfx._();
  factory Sfx() => _i;
  Sfx._();

  static const names = ['key', 'tap', 'run', 'ok', 'fail'];
  final Map<String, LowLatencySfx> _s = {};
  Progress? progress;

  /// 테스트용: 울린 소리 이름(소리가 켜져 있을 때만 쌓인다).
  @visibleForTesting
  final List<String> log = [];

  /// 실패해도 앱은 뜬다(소리 없이). 위젯 테스트에는 오디오 플러그인이 없다.
  Future<void> load(Progress p) async {
    progress = p;
    for (final n in names) {
      try {
        _s[n] = await LowLatencySfx.fromAsset('sfx/$n.wav');
      } catch (e) {
        debugPrint('sfx $n: $e');
      }
    }
  }

  void play(String name) {
    if (progress?.soundOn == false) return;
    if (kDebugMode) log.add(name);
    _s[name]?.start();
  }
}
