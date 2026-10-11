import 'package:flutter/material.dart';

import 'theme.dart';

class TermLine {
  final String text;
  final bool isCmd;
  final bool isError;
  const TermLine(this.text, {this.isCmd = false, this.isError = false});
}

/// 출력 줄 목록. 새 줄이 오면 맨 아래로.
class TerminalView extends StatefulWidget {
  final List<TermLine> lines;
  const TerminalView({super.key, required this.lines});
  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final _ctl = ScrollController();

  @override
  void didUpdateWidget(TerminalView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ctl.hasClients) _ctl.jumpTo(_ctl.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: _ctl,
        padding: const EdgeInsets.all(12),
        itemCount: widget.lines.length,
        itemBuilder: (_, i) {
          final l = widget.lines[i];
          return Text(
            l.isCmd ? '\$ ${l.text}' : l.text,
            style: TextStyle(color: l.isError ? hqRed : (l.isCmd ? hqOrange : hqGreen), fontSize: 14),
          );
        },
      );
}
