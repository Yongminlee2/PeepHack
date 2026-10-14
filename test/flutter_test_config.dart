import 'dart:async';

import 'package:hack_quest/ui/fx/fx.dart';
import 'package:hack_quest/ui/how_to.dart';

/// 모든 테스트 전에 한 번. 움직이는 배경을 멈춘다 — 안 그러면 pumpAndSettle 이 안 끝난다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Fx.animate = false;
  HowTo.autoShow = false; // 하는 법 카드가 화면을 가리지 않게(카드 시험에서만 켠다)
  await testMain();
}
