import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'fx.dart';

/// 매트릭스 비. 이미지 파일 없이 코드로 그린다(저작권·용량 걱정 없음).
///
/// 위젯 테스트에서는 [MatrixRain.animate] 를 끈다(test/flutter_test_config.dart).
/// 계속 움직이는 화면은 pumpAndSettle 이 영원히 안 끝난다.
class MatrixRain extends StatefulWidget {
  /// 예전 이름. [Fx.animate] 와 같다.
  static bool get animate => Fx.animate;
  static set animate(bool v) => Fx.animate = v;

  final double opacity;
  final double cell; // 글자 칸 크기(논리 픽셀)
  const MatrixRain({super.key, this.opacity = 1, this.cell = 16});

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<MatrixRain> with SingleTickerProviderStateMixin {
  RainField? _field;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  final _repaint = ValueNotifier<int>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = !MatrixRain.animate || MediaQuery.of(context).disableAnimations;
    if (still) {
      _ticker?.dispose();
      _ticker = null;
    } else {
      _ticker ??= createTicker(_tick)..start();
    }
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = now;
    _field?.step(dt);
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(builder: (_, box) {
          final cols = (box.maxWidth / widget.cell).ceil();
          final rows = (box.maxHeight / widget.cell).ceil();
          if (_field == null || _field!.columns != cols || _field!.rows != rows) {
            _field = RainField(seed: DateTime.now().microsecond, columns: cols, rows: rows); // 화면마다 다른 무늬
          }
          return Opacity(
            opacity: widget.opacity,
            child: CustomPaint(
              size: Size(box.maxWidth, box.maxHeight),
              painter: _RainPainter(_field!, widget.cell, _repaint),
            ),
          );
        }),
      );
}

/// 빗줄기 상태. 그리기와 분리해서 테스트한다.
class RainField {
  static const glyphs = 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789:.=*+-<>|';
  static const trail = 18; // 꼬리 길이(칸)

  final int columns;
  final int rows;
  final Random _rnd;
  late final List<double> heads; // 각 줄 머리의 행 위치
  late final List<double> _speed; // 초당 행
  late final List<int> _grid; // columns*rows 글자 인덱스

  RainField({required int seed, required this.columns, required this.rows}) : _rnd = Random(seed) {
    heads = List.generate(columns, (_) => _rnd.nextDouble() * (rows + trail) - trail);
    _speed = List.generate(columns, (_) => 6 + _rnd.nextDouble() * 14);
    _grid = List.generate(columns * rows, (_) => _rnd.nextInt(glyphs.length));
  }

  void step(double dt) {
    for (var c = 0; c < columns; c++) {
      heads[c] += _speed[c] * dt;
      if (heads[c] - trail > rows) {
        heads[c] = -_rnd.nextDouble() * rows * 0.5;
        _speed[c] = 6 + _rnd.nextDouble() * 14;
      }
    }
    // 글자 몇 개를 바꿔 반짝이게
    final flips = max(1, (columns * rows * dt * 0.8).round());
    for (var i = 0; i < flips; i++) {
      _grid[_rnd.nextInt(_grid.length)] = _rnd.nextInt(glyphs.length);
    }
  }

  String glyphAt(int c, int r) => glyphs[_grid[r * columns + c]];
}

class _RainPainter extends CustomPainter {
  final RainField f;
  final double cell;
  _RainPainter(this.f, this.cell, Listenable repaint) : super(repaint: repaint);

  static const _levels = 8;
  static final Map<String, TextPainter> _cache = {};

  TextPainter _tp(String g, int level, bool head) {
    final key = '$g$level$head';
    return _cache.putIfAbsent(key, () {
      final a = (level + 1) / _levels;
      final color = head ? const Color(0xFFE8FFE8) : Color.fromRGBO(0, 255, 70, a);
      return TextPainter(
        text: TextSpan(text: g, style: TextStyle(color: color, fontSize: cell * 0.85, height: 1, fontFamily: 'monospace')),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var c = 0; c < f.columns; c++) {
      final head = f.heads[c].floor();
      for (var k = 0; k < RainField.trail; k++) {
        final r = head - k;
        if (r < 0 || r >= f.rows) continue;
        final level = ((1 - k / RainField.trail) * (_levels - 1)).round();
        _tp(f.glyphAt(c, r), level, k == 0).paint(canvas, Offset(c * cell, r * cell));
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => false; // repaint 리스너로만 다시 그린다
}
