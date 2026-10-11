// lib/ui/puzzles/puzzle_view.dart (임시, Task 11 에서 교체)
import 'package:flutter/material.dart';
import '../../engine/mission.dart';
class PuzzleView extends StatelessWidget {
  final Puzzle puzzle; final bool Function(Object answer) onSubmit; final VoidCallback onClose;
  const PuzzleView({super.key, required this.puzzle, required this.onSubmit, required this.onClose});
  @override Widget build(BuildContext context) => Center(child: Text(puzzle.id));
}
