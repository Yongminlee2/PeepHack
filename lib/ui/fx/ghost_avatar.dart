import 'package:flutter/material.dart';

/// 의뢰인 「고스트」: 후드 + 하얀 가면 + 초록 눈. 이 앱 고유 디자인이다.
/// (가이 포크스 가면은 영화사 권리가 걸려 있어 쓰지 않는다.)
class GhostAvatar extends StatelessWidget {
  final double size;
  final bool glow;
  const GhostAvatar({super.key, this.size = 160, this.glow = true});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Ghost',
        child: CustomPaint(size: Size.square(size), painter: _GhostPainter(glow)),
      );
}

class _GhostPainter extends CustomPainter {
  final bool glow;
  const _GhostPainter(this.glow);

  @override
  void paint(Canvas canvas, Size sz) {
    final s = sz.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    const green = Color(0xFF00FF46);

    if (glow) {
      final r = Rect.fromCircle(center: p(0.5, 0.5), radius: s * 0.5);
      canvas.drawCircle(
        p(0.5, 0.5),
        s * 0.5,
        Paint()..shader = const RadialGradient(colors: [Color(0x4000FF46), Color(0x0000FF46)]).createShader(r),
      );
    }

    // 후드
    final hood = Path()
      ..moveTo(p(0.5, 0.05).dx, p(0.5, 0.05).dy)
      ..cubicTo(p(0.80, 0.05).dx, p(0.80, 0.05).dy, p(0.90, 0.30).dx, p(0.90, 0.30).dy, p(0.88, 0.55).dx, p(0.88, 0.55).dy)
      ..cubicTo(p(0.87, 0.72).dx, p(0.87, 0.72).dy, p(0.97, 0.85).dx, p(0.97, 0.85).dy, p(1.0, 1.0).dx, p(1.0, 1.0).dy)
      ..lineTo(0, s)
      ..cubicTo(p(0.03, 0.85).dx, p(0.03, 0.85).dy, p(0.13, 0.72).dx, p(0.13, 0.72).dy, p(0.12, 0.55).dx, p(0.12, 0.55).dy)
      ..cubicTo(p(0.10, 0.30).dx, p(0.10, 0.30).dy, p(0.20, 0.05).dx, p(0.20, 0.05).dy, p(0.5, 0.05).dx, p(0.5, 0.05).dy)
      ..close();
    canvas.drawPath(
      hood,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E2A21), Color(0xFF070A08)])
            .createShader(Offset.zero & sz),
    );
    canvas.drawPath(hood, Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.012..color = green.withValues(alpha: 0.55));

    // 얼굴 그늘
    canvas.drawOval(Rect.fromCenter(center: p(0.5, 0.50), width: s * 0.50, height: s * 0.60), Paint()..color = Colors.black);

    // 가면
    final maskRect = Rect.fromCenter(center: p(0.5, 0.50), width: s * 0.36, height: s * 0.47);
    canvas.drawOval(
      maskRect,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F6EF), Color(0xFFB8C2B6)]).createShader(maskRect),
    );

    // 금
    final crack = Path()
      ..moveTo(p(0.54, 0.27).dx, p(0.54, 0.27).dy)
      ..lineTo(p(0.51, 0.33).dx, p(0.51, 0.33).dy)
      ..lineTo(p(0.545, 0.37).dx, p(0.545, 0.37).dy)
      ..lineTo(p(0.52, 0.41).dx, p(0.52, 0.41).dy);
    canvas.drawPath(crack, Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.008..color = const Color(0xFF39433A));

    // 눈: 기울어진 틈 + 초록 빛
    void eye(double cx, double tilt) {
      final a = p(cx - 0.042, 0.46 - tilt);
      final b = p(cx + 0.042, 0.46 + tilt);
      canvas.drawLine(a, b, Paint()..strokeWidth = s * 0.05..strokeCap = StrokeCap.round..color = Colors.black);
      canvas.drawLine(a, b, Paint()
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round
        ..color = green
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02));
      canvas.drawLine(a, b, Paint()..strokeWidth = s * 0.012..strokeCap = StrokeCap.round..color = const Color(0xFFD8FFE0));
    }

    eye(0.415, -0.012);
    eye(0.585, 0.012);

    // 입
    canvas.drawLine(p(0.47, 0.63), p(0.53, 0.63), Paint()..strokeWidth = s * 0.008..strokeCap = StrokeCap.round..color = const Color(0xFF4A544B));
    // 눈 아래 초록 줄(코드 눈물)
    canvas.drawLine(p(0.60, 0.50), p(0.60, 0.58), Paint()..strokeWidth = s * 0.006..color = green.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(_GhostPainter old) => old.glow != glow;
}
