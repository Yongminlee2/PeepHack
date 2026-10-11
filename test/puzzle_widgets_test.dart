import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/ui/puzzles/puzzle_view.dart';

Widget wrap(Puzzle p, bool Function(Object) onSubmit) =>
    MaterialApp(home: Scaffold(body: PuzzleView(puzzle: p, onSubmit: onSubmit, onClose: () {})));

void main() {
  testWidgets('match: 왼쪽→오른쪽 탭으로 짝을 짓고 확인', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'match', data: {'left': ['A', 'B'], 'right': ['1', '2']}, answer: [[0, 1], [1, 0]]),
      (a) { got = a; return true; },
    ));
    await t.tap(find.byKey(const Key('left_0'))); await t.pump();
    await t.tap(find.byKey(const Key('right_1'))); await t.pump();
    await t.tap(find.byKey(const Key('left_1'))); await t.pump();
    await t.tap(find.byKey(const Key('right_0'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, [[0, 1], [1, 0]]);
  });
  testWidgets('password: 조각을 눌러 조립, 틀리면 비워진다', (t) async {
    final calls = <Object>[];
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'password', data: {'clues': ['c'], 'fragments': ['ab', 'cd']}, answer: 'abcd'),
      (a) { calls.add(a); return a == 'abcd'; },
    ));
    await t.tap(find.byKey(const Key('frag_1'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(calls, ['cd']);
    expect(find.text('cd'), findsNWidgets(1)); // 조립칸은 비워졌고 칩만 남음
    await t.tap(find.byKey(const Key('frag_0'))); await t.pump();
    await t.tap(find.byKey(const Key('frag_1'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(calls.last, 'abcd');
  });
  testWidgets('order: 현재 순서를 그대로 낸다', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'order', data: {'items': ['x', 'y', 'z']}, answer: [0, 1, 2]),
      (a) { got = a; return true; },
    ));
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, [0, 1, 2]);
  });
  testWidgets('codefix: 줄을 누르고 조각을 고른다', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'codefix', data: {
        'lang': 'python', 'lines': ['a = 1', 'if a <= 1:'],
        'bugs': [{'line': 1, 'choices': ['<', '<='], 'answer': '<'}],
      }, answer: 'bugs'),
      (a) { got = a; return true; },
    ));
    await t.tap(find.byKey(const Key('line_1'))); await t.pump();
    await t.tap(find.byKey(const Key('choice_<'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, {1: '<'});
  });
  testWidgets('order: 첫 항목을 맨 아래로 끌면 순서가 바뀐다', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'order', data: {'items': ['x', 'y', 'z']}, answer: [1, 2, 0]),
      (a) { got = a; return true; },
    ));
    final g = await t.startGesture(t.getCenter(find.text('x')));
    await t.pump(const Duration(seconds: 1)); // 길게 누르기
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, 30));
      await t.pump(const Duration(milliseconds: 50));
    }
    await g.up();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, [1, 2, 0]);
  });
  testWidgets('order: 손잡이는 길게 누르지 않아도 바로 끌린다', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'order', data: {'items': ['x', 'y', 'z']}, answer: [1, 0, 2]),
      (a) { got = a; return true; },
    ));
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('handle_1'))));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, -8));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, [1, 0, 2]);
  });
  testWidgets('match: 틀리면 선 연결과 왼쪽 선택이 모두 풀리고 화면이 흔들린다', (t) async {
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'match', data: {'left': ['A', 'B'], 'right': ['1', '2']}, answer: [[0, 1], [1, 0]]),
      (a) => false,
    ));
    await t.tap(find.byKey(const Key('left_0'))); await t.pump();
    await t.tap(find.byKey(const Key('right_0'))); await t.pump();
    await t.tap(find.byKey(const Key('left_1'))); await t.pump();
    await t.tap(find.byKey(const Key('right_1'))); await t.pump();
    await t.tap(find.byKey(const Key('left_0'))); await t.pump(); // 선택만 해 둔 상태로
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump(); // 버튼은 짝이 다 있어야 켜진다
    await t.pump(const Duration(milliseconds: 60));
    final dx = t.widget<Transform>(find.byKey(const Key('shake'))).transform.getTranslation().x;
    expect(dx, isNot(0)); // 흔들리는 중
    await t.pumpAndSettle();
    final m = t.widget<Material>(find.byKey(const Key('left_0')));
    expect((m.shape as Border).top.width, 1); // 선택 표시(두꺼운 테두리)가 풀림
  });
}
