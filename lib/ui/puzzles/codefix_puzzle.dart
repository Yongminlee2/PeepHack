import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../../strings.dart';
import '../theme.dart';
import 'puzzle_view.dart';

/// 줄을 누르면 그 줄의 선택지가 아래 뜬다. 고르면 줄 끝에 표시.
// ponytail: 버그 아닌 줄을 누르면 "문제없어 보임" 이 떠서 찍어 보기로 버그 줄을 찾을 수 있다.
// 그래도 어느 조각이 답인지는 모른다. 모든 줄에 가짜 선택지를 주는 건 v1.1 에서.
class CodefixPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const CodefixPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<CodefixPuzzle> createState() => _CodefixState();
}

class _CodefixState extends State<CodefixPuzzle> {
  int? selected;
  final Map<int, String> picks = {};

  List<String> get lines => List<String>.from(widget.puzzle.data['lines'] as List);
  List<Map> get bugs => List<Map>.from(widget.puzzle.data['bugs'] as List);
  Map? _bugAt(int i) {
    for (final b in bugs) {
      if (b['line'] == i) return b;
    }
    return null;
  }

  void _tapLine(int i) {
    if (_bugAt(i) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('puzzle_codefix_line_ok')), duration: const Duration(seconds: 1)));
      setState(() => selected = null);
      return;
    }
    setState(() => selected = i);
  }

  void _submit() {
    if (!widget.onSubmit(Map<int, String>.from(picks))) {
      showWrong(context);
      setState(() { picks.clear(); selected = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ls = lines;
    final bug = selected == null ? null : _bugAt(selected!);
    final situation = widget.puzzle.data['situation'] as String?;
    return Column(children: [
      // 개발을 몰라도 무엇이 문제인지 알 수 있게 상황을 쉬운 말로
      if (situation != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: Color(0xFF1E1A10), border: Border(left: BorderSide(color: hqOrange, width: 3))),
          child: Text(tr(situation), style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      Expanded(child: ListView(padding: const EdgeInsets.all(8), children: [
        for (var i = 0; i < ls.length; i++)
          InkWell(
            key: Key('line_$i'),
            onTap: () => _tapLine(i),
            child: Container(
              color: selected == i ? hqPanel : null,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(children: [
                SizedBox(width: 28, child: Text('${i + 1}', style: const TextStyle(color: hqDim))),
                Expanded(child: Text(ls[i], style: const TextStyle(fontSize: 13, fontFamily: kMono))),
                if (picks.containsKey(i)) Text('→ ${picks[i]}', style: const TextStyle(color: hqOrange)),
              ]),
            ),
          ),
      ])),
      if (bug != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            for (final (k, c) in List<String>.from(bug['choices'] as List).indexed)
              ChoiceChip(
                key: Key('choice_$c'),
                // 선택지마다 쉬운 뜻(있으면): `>=  같거나 크면`
                label: Builder(builder: (_) {
                  final text = bug['labels'] == null ? c : '$c  ${tr((bug['labels'] as List)[k] as String)}';
                  return Text(text, style: TextStyle(fontFamily: monoFor(text)));
                }),
                selected: picks[selected] == c,
                onSelected: (_) => setState(() => picks[selected!] = c),
              ),
          ]),
        ),
      submitButton(picks.length == bugs.length ? _submit : null),
    ]);
  }
}
