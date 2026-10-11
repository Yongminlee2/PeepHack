import 'package:flutter/material.dart';

/// 빨강·청록이 어긋나게 겹친 글자(글리치). 글자 자체는 하나만 읽힌다(접근성).
class GlitchText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double shift;
  const GlitchText(this.text, {super.key, required this.style, this.shift = 2.5});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Transform.translate(
          offset: Offset(-shift, 0),
          child: ExcludeSemantics(child: Text(text, style: style.copyWith(color: const Color(0xB3FF2E63)))),
        ),
        Transform.translate(
          offset: Offset(shift, 0),
          child: ExcludeSemantics(child: Text(text, style: style.copyWith(color: const Color(0xB300F0FF)))),
        ),
        Text(text, style: style),
      ]);
}
