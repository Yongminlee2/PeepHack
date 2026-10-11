import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../theme.dart';
import 'puzzle_view.dart';

class OrderPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const OrderPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<OrderPuzzle> createState() => _OrderState();
}

class _OrderState extends State<OrderPuzzle> {
  late List<int> order = List.generate((widget.puzzle.data['items'] as List).length, (i) => i);
  List<String> get items => List<String>.from(widget.puzzle.data['items'] as List);

  void _submit() {
    if (!widget.onSubmit(List<int>.from(order))) {
      showWrong(context);
      setState(() => order = List.generate(items.length, (i) => i));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.all(12),
            // onReorderItem 은 빠진 칸만큼 to 를 이미 보정해 준다.
            onReorderItem: (from, to) => setState(() => order.insert(to, order.removeAt(from))),
            children: [
              for (final i in order)
                ListTile(key: ValueKey(i), tileColor: hqPanel, leading: const Icon(Icons.drag_handle), title: Text(tr(items[i]))),
            ],
          ),
        ),
        submitButton(_submit),
      ]);
}
