import 'package:flutter/material.dart';

/// 옛 모니터 느낌: 가로 스캔라인 + 가장자리 어둡게. 터치는 통과시킨다.
class CrtOverlay extends StatelessWidget {
  const CrtOverlay({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(child: CustomPaint(painter: _CrtPainter(), size: Size.infinite));
}

class _CrtPainter extends CustomPainter {
  const _CrtPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = const Color(0x14000000);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.9,
          colors: [Color(0x00000000), Color(0x00000000), Color(0x99000000)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CrtPainter old) => false;
}
