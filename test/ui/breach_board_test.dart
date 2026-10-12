import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/breach.dart';
import 'package:hack_quest/strings.dart';
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
  testWidgets('버퍼 8칸도 좁은 폰(360dp)에서 한 줄에 들어간다', (t) async {
    t.view.physicalSize = const Size(360 * 3, 800 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    const p = BreachPuzzle(grid: [['1C', '55'], ['BD', 'E9']], buffer: 8, daemons: [['FF']]);
    await t.pumpWidget(wrap(p, (_) {}));
    final y0 = t.getTopLeft(find.byKey(const Key('buf_0'))).dy;
    expect(t.getTopLeft(find.byKey(const Key('buf_7'))).dy, y0);
  });
  testWidgets('목표에 이름이 있고, 누르면 목표가 나아가는 칸이 빛난다', (t) async {
    await t.pumpWidget(wrap(puzzle, (_) {}));
    expect(find.text(S.t('breach_d_alarm')), findsOneWidget);
    expect(find.text(S.t('breach_d_door')), findsOneWidget);
    // 맨 윗줄 중 55(첫 목표의 첫 코드)만 빛난다. 1C·BD 는 어느 목표도 앞으로 안 간다
    expect(find.byKey(const Key('hint_0_1')), findsOneWidget);
    expect(find.byKey(const Key('hint_0_0')), findsNothing);
    expect(find.byKey(const Key('hint_0_2')), findsNothing);
    await t.tap(find.byKey(const Key('cell_0_1')));
    await t.pump();
    expect(find.byKey(const Key('hint_2_1')), findsOneWidget); // 그 세로줄의 E9
  });

  testWidgets('목표를 끝내면 「완료」, 겹쳐 이어 끝내면 「연쇄」가 뜬다', (t) async {
    await t.pumpWidget(wrap(puzzle, (_) {}));
    await t.tap(find.byKey(const Key('cell_0_1'))); // 55
    await t.pump();
    await t.tap(find.byKey(const Key('cell_2_1'))); // E9 → 경보 끄기
    await t.pump();
    expect(find.text(S.tn('breach_done', {'name': S.t('breach_d_alarm')})), findsOneWidget);
    await t.tap(find.byKey(const Key('cell_2_0'))); // BD → 문 열기, E9 를 같이 썼다
    await t.pump();
    expect(find.text(S.t('breach_chain')), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    expect(find.text(S.t('breach_chain')), findsNothing); // 잠깐 떴다 사라진다
  });

  testWidgets('연습판: 단계마다 무엇을 할지 알려 주고 정답 칸을 가리킨다', (t) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(body: BreachBoard(
        puzzle: const BreachPuzzle(grid: [['E9', '55', 'BD'], ['E9', '1C', '55'], ['BD', 'E9', '1C']], buffer: 4,
            daemons: [['55', 'E9'], ['E9', 'BD']], solution: [(0, 1), (2, 1), (2, 0)]),
        guide: true,
        onFinish: (_) {}))));
    expect(find.text(S.t('breach_tut_top')), findsOneWidget);
    expect(find.byKey(const Key('guide_0_1')), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('hint_')),
        findsNothing); // 연습판에선 손가락 칸만 빛난다(여럿 빛나면 어느 걸 누를지 헷갈렸다)
    await t.tap(find.byKey(const Key('cell_0_1')));
    await t.pump();
    expect(find.text(S.t('breach_tut_col')), findsOneWidget);
    expect(find.byKey(const Key('guide_2_1')), findsOneWidget);
    await t.tap(find.byKey(const Key('cell_2_1')));
    await t.pump();
    expect(find.text(S.t('breach_tut_row')), findsOneWidget);
    expect(find.byKey(const Key('guide_2_0')), findsOneWidget);
  });
  testWidgets('안내를 끄면(11단계부터·2장부터 크랙) 빛나는 칸이 없다, 목표 넷째 이름', (t) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(body: BreachBoard(
        puzzle: const BreachPuzzle(grid: [['1C', '55', 'BD'], ['E9', '1C', '55'], ['BD', 'E9', '1C']], buffer: 6,
            daemons: [['55', 'E9'], ['E9', 'BD'], ['1C', '55'], ['BD', '1C']]),
        hints: false,
        onFinish: (_) {}))));
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('hint_')),
        findsNothing);
    expect(find.text(S.t('breach_d_data')), findsOneWidget);
  });
}
