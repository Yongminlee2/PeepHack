import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../theme.dart';
import 'puzzle_view.dart';

/// 왼쪽을 누르고 오른쪽을 누르면 짝. 같은 오른쪽을 다시 고르면 앞 짝은 풀린다.
class MatchPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const MatchPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<MatchPuzzle> createState() => _MatchState();
}

class _MatchState extends State<MatchPuzzle> {
  int? selectedLeft;
  final Map<int, int> pairs = {}; // left → right

  List<String> get left => List<String>.from(widget.puzzle.data['left'] as List);
  List<String> get right => List<String>.from(widget.puzzle.data['right'] as List);

  void _pickRight(int r) {
    final l = selectedLeft;
    if (l == null) return;
    setState(() {
      pairs.removeWhere((_, v) => v == r);
      pairs[l] = r;
      selectedLeft = null;
    });
  }

  void _submit() {
    final ok = widget.onSubmit([for (final e in pairs.entries) [e.key, e.value]]);
    if (!ok) {
      showWrong(context);
      setState(pairs.clear);
    }
  }

  static const _rowH = 64.0;
  static const _gap = 12.0;
  // 케이블 색. 짝마다 다르게 해서 어느 선이 어디로 가는지 보이게.
  static const _wire = [Color(0xFF00FF46), Color(0xFFFFB454), Color(0xFF00F0FF), Color(0xFFFF2E63), Color(0xFFB98CFF), Color(0xFFFFF35C)];

  Widget _port(Key key, String label, {required bool lit, required Color edge, required VoidCallback onTap}) => SizedBox(
        height: _rowH,
        child: Material(
          key: key,
          color: lit ? const Color(0xFF1A2A1E) : hqPanel,
          shape: Border.all(color: edge, width: lit ? 2 : 1),
          child: InkWell(
            onTap: onTap,
            child: Center(child: Text(tr(label), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontFamily: monoFor(tr(label))))),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = left, r = right;
    final rows = l.length > r.length ? l.length : r.length;
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (_, box) {
            final colW = box.maxWidth * 0.36;
            return SizedBox(
              height: rows * (_rowH + _gap),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _WirePainter(pairs, colW, box.maxWidth, _rowH, _gap, _wire))),
                Positioned(left: 0, top: 0, width: colW, child: Column(children: [
                  for (var i = 0; i < l.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _gap),
                      child: _port(Key('left_$i'), l[i],
                          lit: selectedLeft == i || pairs.containsKey(i),
                          edge: pairs.containsKey(i) ? _wire[i % _wire.length] : (selectedLeft == i ? hqOrange : hqDim),
                          onTap: () => setState(() => selectedLeft = i)),
                    ),
                ])),
                Positioned(right: 0, top: 0, width: colW, child: Column(children: [
                  for (var j = 0; j < r.length; j++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _gap),
                      child: _port(Key('right_$j'), r[j],
                          lit: pairs.containsValue(j),
                          edge: _rightColor(j) ?? hqDim,
                          onTap: () => _pickRight(j)),
                    ),
                ])),
              ]),
            );
          }),
        ),
      ),
      submitButton(pairs.length == l.length ? _submit : null),
    ]);
  }

  Color? _rightColor(int j) {
    for (final e in pairs.entries) {
      if (e.value == j) return _wire[e.key % _wire.length];
    }
    return null;
  }
}

/// 왼쪽 포트 오른쪽 끝 → 오른쪽 포트 왼쪽 끝으로 휘어진 케이블.
class _WirePainter extends CustomPainter {
  final Map<int, int> pairs;
  final double colW, width, rowH, gap;
  final List<Color> colors;
  _WirePainter(this.pairs, this.colW, this.width, this.rowH, this.gap, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    double cy(int i) => i * (rowH + gap) + rowH / 2;
    for (final e in pairs.entries) {
      final a = Offset(colW, cy(e.key));
      final b = Offset(width - colW, cy(e.value));
      final mid = (a.dx + b.dx) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
      final c = colors[e.key % colors.length];
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 7..color = c.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = c);
      canvas.drawCircle(a, 5, Paint()..color = c);
      canvas.drawCircle(b, 5, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_WirePainter old) => true;
}
