// 앱 아이콘 원본을 그림 코드(GhostAvatar)에서 PNG 로 뽑는다.
//   flutter test tool/render_icon_test.dart   → store/icon/flat.png, fg.png (1024)
// 그 다음 python tool/apply_icon.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/fx/ghost_avatar.dart';

Future<void> _render(WidgetTester t, Widget child, String path) async {
  final key = GlobalKey();
  await t.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: RepaintBoundary(key: key, child: SizedBox(width: 1024, height: 1024, child: child))),
  ));
  await t.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('아이콘 원본 뽑기', (t) async {
    t.view.physicalSize = const Size(1200, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // 통짜(구형 런처·스토어): 어두운 바탕 + 가는 격자 + 고스트
    await _render(
      t,
      Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xFF060A07)),
        CustomPaint(painter: _Grid()),
        const Center(child: GhostAvatar(size: 820)),
      ]),
      'store/icon/flat.png',
    );
    // 적응형 앞층: 투명 바탕, 가운데 66% 안전 영역 안에 고스트
    await _render(t, const Center(child: GhostAvatar(size: 640)), 'store/icon/fg.png');
  });
}

class _Grid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x1A00FF46)..strokeWidth = 2;
    for (var x = 0.0; x <= size.width; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y <= size.height; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_Grid old) => false;
}
