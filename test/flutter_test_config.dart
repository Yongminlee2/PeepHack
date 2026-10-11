import 'dart:async';

import 'package:hack_quest/ui/fx/fx.dart';

/// 모든 테스트 전에 한 번. 움직이는 배경을 멈춘다 — 안 그러면 pumpAndSettle 이 안 끝난다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Fx.animate = false;
  await testMain();
}
