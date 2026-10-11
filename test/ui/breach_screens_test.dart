import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/breach_gen.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/main.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/breach/breach_list_screen.dart';
import 'package:hack_quest/ui/breach/breach_play_screen.dart';
import 'package:hack_quest/ui/cases/case_list_screen.dart';
import 'package:hack_quest/ui/inbox_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

void main() {
  late Progress p;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
    p = await Progress.load();
  });

  testWidgets('타이틀 → 모드 선택: 작전·브리치·사건 파일이 다 열린다', (t) async {
    await t.pumpWidget(HackQuestApp(progress: p, catalog: Catalog.fromTexts({})));
    await settle(t);
    await t.tap(find.textContaining(S.t('btn_start')));
    await settle(t);
    expect(find.text(S.t('mode_campaign')), findsOneWidget);
    await t.tap(find.text(S.t('mode_cases')));
    await settle(t);
    expect(find.byType(CaseListScreen), findsOneWidget);
    await t.pageBack();
    await settle(t);
    await t.tap(find.text(S.t('mode_campaign')));
    await settle(t);
    expect(find.byType(InboxScreen), findsOneWidget);
    await t.pageBack();
    await settle(t);
    await t.tap(find.text(S.t('mode_breach')));
    await settle(t);
    expect(find.byType(BreachListScreen), findsOneWidget);
  });

  testWidgets('목록: 1번만 열려 있고, 잠긴 칸은 눌러도 안 열린다', (t) async {
    await t.pumpWidget(MaterialApp(home: BreachListScreen(progress: p)));
    await settle(t);
    await t.tap(find.byKey(const Key('stage_2')));
    await settle(t);
    expect(find.byType(BreachPlayScreen), findsNothing);
    await t.tap(find.byKey(const Key('stage_1')));
    await settle(t);
    expect(find.byType(BreachPlayScreen), findsOneWidget);
  });

  testWidgets('정답대로 풀면 별 3 저장, 결과에서 다음 퍼즐로', (t) async {
    await t.pumpWidget(MaterialApp(home: BreachPlayScreen.stage(progress: p, n: 1)));
    await settle(t);
    for (final (r, c) in generateStage(1).solution) {
      if (find.text(S.t('breach_success')).evaluate().isNotEmpty) break;
      await t.tap(find.byKey(Key('cell_${r}_$c')));
      await t.pump();
    }
    await settle(t);
    expect(find.text(S.t('breach_success')), findsWidgets); // 글리치로 세 겹
    expect(p.breachStars(1), 3);
    await t.tap(find.text(S.t('btn_next_stage')));
    await settle(t);
    expect(find.text(S.tn('breach_stage_n', {'n': 2})), findsOneWidget);
  });

  testWidgets('다시: 같은 퍼즐을 처음부터', (t) async {
    await t.pumpWidget(MaterialApp(home: BreachPlayScreen.stage(progress: p, n: 1)));
    await settle(t);
    final (r, c) = generateStage(1).solution.first;
    await t.tap(find.byKey(Key('cell_${r}_$c')));
    await t.pump();
    expect(find.text('[ ]'), findsOneWidget);
    await t.tap(find.byTooltip(S.t('btn_retry')));
    await settle(t);
    expect(find.text('[ ]'), findsNothing);
  });

  testWidgets('오늘의 퍼즐은 목록 맨 위에서 바로 열린다', (t) async {
    await t.pumpWidget(MaterialApp(home: BreachListScreen(progress: p)));
    await settle(t);
    await t.tap(find.byKey(const Key('daily')));
    await settle(t);
    expect(find.byType(BreachPlayScreen), findsOneWidget);
  });
}
