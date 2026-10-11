import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/breach.dart';
import 'package:hack_quest/ui/breach/breach_board.dart';

const puzzle = BreachPuzzle(
  grid: [
    ['1C', '55', 'BD'],
    ['E9', '1C', '55'],
    ['BD', 'E9', '1C'],
  ],
  buffer: 4,
  daemons: [['55', 'E9'], ['E9', 'BD']],
);

Widget wrap(BreachPuzzle p, void Function(BreachGame) onFinish) =>
    MaterialApp(home: Scaffold(body: BreachBoard(puzzle: p, onFinish: onFinish)));

void main() {
  testWidgets('정답 경로를 누르면 끝나고 별 3, 버퍼에 코드가 쌓인다', (t) async {
    BreachGame? done;
    await t.pumpWidget(wrap(puzzle, (g) => done = g));
    await t.tap(find.byKey(const Key('cell_1_1'))); // 첫 선택은 맨 윗줄만 → 무시
    await t.pump();
    expect(find.byKey(const Key('buf_0')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('buf_0')), matching: find.text('E9')), findsNothing);
    await t.tap(find.byKey(const Key('cell_0_1'))); // 55
    await t.pump();
    expect(find.descendant(of: find.byKey(const Key('buf_0')), matching: find.text('55')), findsOneWidget);
    await t.tap(find.byKey(const Key('cell_2_1'))); // E9
    await t.pump();
    expect(done, isNull);
    await t.tap(find.byKey(const Key('cell_2_0'))); // BD
    await t.pump();
    expect(done, isNotNull);
    expect(done!.stars, 3);
  });

  testWidgets('제한 시간은 첫 선택부터 흐르고, 끝나면 그 자리에서 끝난다', (t) async {
    BreachGame? done;
    const timed = BreachPuzzle(grid: [['1C', '55'], ['BD', 'E9']], buffer: 4, daemons: [['FF']], timeLimit: 5);
    await t.pumpWidget(wrap(timed, (g) => done = g));
    await t.pump(const Duration(seconds: 10)); // 아직 아무것도 안 골랐다 → 시간 안 흐름
    expect(done, isNull);
    await t.tap(find.byKey(const Key('cell_0_0')));
    await t.pump(const Duration(seconds: 3));
    expect(done, isNull);
    expect(find.text('0:02'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    expect(done, isNotNull);
    expect(done!.timedOut, isTrue);
  });
}
