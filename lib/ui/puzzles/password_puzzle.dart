import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../theme.dart';
import 'puzzle_view.dart';

class PasswordPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const PasswordPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<PasswordPuzzle> createState() => _PasswordState();
}

class _PasswordState extends State<PasswordPuzzle> {
  final List<int> picked = []; // 조각 인덱스 순서

  List<String> get frags => List<String>.from(widget.puzzle.data['fragments'] as List);
  List<String> get clues => List<String>.from((widget.puzzle.data['clues'] as List?) ?? const []);
  String get assembled => picked.map((i) => frags[i]).join();

  void _submit() {
    if (!widget.onSubmit(assembled)) {
      showWrong(context);
      setState(picked.clear);
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
          for (final c in clues)
            Card(color: hqPanel, child: Padding(padding: const EdgeInsets.all(12), child: Text(tr(c)))),
          const SizedBox(height: 12),
          Container(
            key: const Key('assembled'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: hqDim)),
            child: Row(children: [
              Expanded(child: Text(assembled, style: const TextStyle(fontSize: 20, color: hqOrange))),
              IconButton(icon: const Icon(Icons.backspace_outlined), onPressed: picked.isEmpty ? null : () => setState(picked.removeLast)),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < frags.length; i++)
              ActionChip(key: Key('frag_$i'), label: Text(frags[i]), onPressed: picked.contains(i) ? null : () => setState(() => picked.add(i))),
          ]),
        ])),
        submitButton(picked.isEmpty ? null : _submit),
      ]);
}
