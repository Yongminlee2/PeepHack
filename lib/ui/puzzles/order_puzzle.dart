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
            // 항목 전체는 길게 눌러 끌고, 왼쪽 손잡이는 바로 끈다(실기기에서 길게 누르기가 자주 빗나갔다).
            buildDefaultDragHandles: false,
            children: [
              for (var k = 0; k < order.length; k++)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(order[k]),
                  index: k,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: hqPanel,
                      shape: Border.all(color: hqDim),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: k,
                          child: Padding(
                            key: Key('handle_${order[k]}'),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.drag_indicator, color: hqGreen),
                          ),
                        ),
                        title: Text(tr(items[order[k]]), style: TextStyle(fontFamily: monoFor(tr(items[order[k]])))),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        submitButton(_submit),
      ]);
}
