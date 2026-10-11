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

  @override
  Widget build(BuildContext context) {
    final l = left, r = right;
    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: ListView(children: [
            for (var i = 0; i < l.length; i++)
              ListTile(
                key: Key('left_$i'),
                selected: selectedLeft == i,
                selectedTileColor: hqPanel,
                title: Text(tr(l[i])),
                trailing: pairs.containsKey(i) ? Text(tr(r[pairs[i]!]), style: const TextStyle(color: hqOrange)) : null,
                onTap: () => setState(() => selectedLeft = i),
              ),
          ])),
          Expanded(child: ListView(children: [
            for (var j = 0; j < r.length; j++)
              ListTile(
                key: Key('right_$j'),
                title: Text(tr(r[j])),
                tileColor: pairs.containsValue(j) ? hqPanel : null,
                onTap: () => _pickRight(j),
              ),
          ])),
        ]),
      ),
      submitButton(pairs.length == l.length ? _submit : null),
    ]);
  }
}
