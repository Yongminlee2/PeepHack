import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../../strings.dart';
import '../theme.dart';
import 'codefix_puzzle.dart';
import 'match_puzzle.dart';
import 'order_puzzle.dart';
import 'password_puzzle.dart';

/// 퍼즐 창. 제목·닫기 + 종류별 위젯.
class PuzzleView extends StatelessWidget {
  final Puzzle puzzle;
  final bool Function(Object answer) onSubmit;
  final VoidCallback onClose;
  const PuzzleView({super.key, required this.puzzle, required this.onSubmit, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final body = switch (puzzle.type) {
      'match' => MatchPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      'password' => PasswordPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      'order' => OrderPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      'codefix' => CodefixPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      _ => Center(child: Text(puzzle.type)),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        color: hqPanel,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Expanded(child: Text(S.t('puzzle_${puzzle.type}_title'), style: const TextStyle(color: hqOrange))),
          TextButton(onPressed: onClose, child: Text(S.t('btn_close'))),
        ]),
      ),
      Expanded(child: _Shake(child: body)),
    ]);
  }
}

/// 틀렸을 때 공통 반응: 퍼즐 판이 좌우로 흔들리고 안내가 뜬다.
void showWrong(BuildContext context) {
  context.findAncestorStateOfType<_ShakeState>()?.shake();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('puzzle_wrong')), duration: const Duration(seconds: 1)));
}

class _Shake extends StatefulWidget {
  final Widget child;
  const _Shake({required this.child});
  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  void shake() => _c.forward(from: 0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final v = _c.value;
          final dx = v == 0 || v == 1 ? 0.0 : math.sin(v * math.pi * 6) * 12 * (1 - v);
          return Transform(key: const Key('shake'), transform: Matrix4.translationValues(dx, 0, 0), child: child);
        },
      );
}

Widget submitButton(VoidCallback? onPressed) => Padding(
      padding: const EdgeInsets.all(12),
      child: FilledButton(key: const Key('puzzle_submit'), onPressed: onPressed, child: Text(S.t('btn_check'))),
    );
