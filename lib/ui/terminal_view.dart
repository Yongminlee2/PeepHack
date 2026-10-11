import 'dart:math';

import 'package:flutter/material.dart';

import 'fx/fx.dart';
import 'theme.dart';

class TermLine {
  final String text;
  final bool isCmd;
  final bool isError;
  const TermLine(this.text, {this.isCmd = false, this.isError = false});
}

/// 출력 줄 목록. 새 줄이 오면 맨 아래로. 새 출력은 한 글자씩 찍힌다([Fx.animate] 일 때).
class TerminalView extends StatefulWidget {
  final List<TermLine> lines;
  const TerminalView({super.key, required this.lines});
  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final _ctl = ScrollController();
  final Set<int> _typed = {}; // 다 찍힌 줄(다시 그려도 또 찍지 않게)

  @override
  void didUpdateWidget(TerminalView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ctl.hasClients) _ctl.jumpTo(_ctl.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: _ctl,
        padding: const EdgeInsets.all(12),
        itemCount: widget.lines.length,
        itemBuilder: (_, i) {
          final l = widget.lines[i];
          final text = l.isCmd ? '\$ ${l.text}' : l.text;
          final style = TextStyle(color: l.isError ? hqRed : (l.isCmd ? hqOrange : hqGreen), fontSize: 14, fontFamily: monoFor(l.text));
          return _Typing(
            key: ValueKey(i),
            text: text,
            style: style,
            // 친 명령은 바로, 출력만 찍는다
            animate: Fx.animate && !l.isCmd && !_typed.contains(i),
            onDone: () => _typed.add(i),
          );
        },
      );
}

class _Typing extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;
  final VoidCallback onDone;
  const _Typing({super.key, required this.text, required this.style, required this.animate, required this.onDone});

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: min(400, 12 * widget.text.length + 40)),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.forward().whenComplete(widget.onDone);
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final n = (widget.text.length * _c.value).ceil();
          return Text(n >= widget.text.length ? widget.text : '${widget.text.substring(0, n)}▌', style: widget.style);
        },
      );
}
