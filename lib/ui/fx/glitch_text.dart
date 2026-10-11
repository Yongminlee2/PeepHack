import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'fx.dart';

/// 빨강·청록이 어긋나게 겹친 글자(글리치). 글자 자체는 하나만 읽힌다(접근성).
/// [animate] 면 2.5초마다 0.15초 동안 층이 흔들린다(로고용).
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double shift;
  final bool animate;
  const GlitchText(this.text, {super.key, required this.style, this.shift = 2.5, this.animate = false});

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  Timer? _timer;
  final _rnd = Random();
  double _jx = 0, _jy = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate && Fx.animate) {
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
        for (var i = 0; i < 3; i++) {
          if (!mounted) return;
          setState(() {
            _jx = (_rnd.nextDouble() - 0.5) * 10;
            _jy = (_rnd.nextDouble() - 0.5) * 4;
          });
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        if (mounted) setState(() => _jx = _jy = 0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shift;
    return Stack(children: [
      Transform.translate(
        offset: Offset(-s - _jx, -_jy),
        child: ExcludeSemantics(child: Text(widget.text, style: widget.style.copyWith(color: const Color(0xB3FF2E63)))),
      ),
      Transform.translate(
        offset: Offset(s + _jx, _jy),
        child: ExcludeSemantics(child: Text(widget.text, style: widget.style.copyWith(color: const Color(0xB300F0FF)))),
      ),
      Transform.translate(offset: Offset(_jx * 0.3, 0), child: Text(widget.text, style: widget.style)),
    ]);
  }
}
