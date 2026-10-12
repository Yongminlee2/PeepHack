import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'engine/progress.dart';
import 'sfx_low_latency.dart'; // common/flutter/sfx_low_latency.dart 복사

/// 효과음: 입력(key tap run)·결과(ok fail alarm)·연출(daemon chain star stamp). 설정에서 끄면 전부 조용.
class Sfx {
  static final Sfx _i = Sfx._();
  factory Sfx() => _i;
  Sfx._();

  static const names = ['key', 'tap', 'run', 'ok', 'fail', 'alarm', 'daemon', 'chain', 'star', 'stamp'];
  final Map<String, LowLatencySfx> _s = {};
  Progress? progress;

  /// 테스트용: 울린 소리 이름(소리가 켜져 있을 때만 쌓인다).
  @visibleForTesting
  final List<String> log = [];

  /// 테스트용: 울린 진동 세기(light / medium / heavy).
  @visibleForTesting
  final List<String> haptics = [];

  // 소리마다 진동 세기. 키 입력·실행은 진동 없이(너무 잦다).
  static const _haptic = {
    'tap': 'light', 'ok': 'medium', 'fail': 'heavy', 'alarm': 'heavy',
    'daemon': 'medium', 'chain': 'heavy', 'star': 'light', 'stamp': 'heavy',
  };

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
    _vibrate(_haptic[name]);
    if (progress?.soundOn == false) return;
    if (kDebugMode) log.add(name);
    _s[name]?.start();
  }

  void _vibrate(String? kind) {
    if (kind == null || progress?.vibrationOn == false) return;
    if (kDebugMode) haptics.add(kind);
    final Future<void> f = switch (kind) {
      'light' => HapticFeedback.selectionClick(),
      'medium' => HapticFeedback.mediumImpact(),
      _ => HapticFeedback.heavyImpact(),
    };
    unawaited(f.catchError((_) {})); // 진동이 없는 기기·테스트에서도 조용히
  }
}
