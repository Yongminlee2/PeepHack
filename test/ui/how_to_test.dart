import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/breach/breach_list_screen.dart';
import 'package:hack_quest/ui/cases/case_list_screen.dart';
import 'package:hack_quest/ui/how_to.dart';
import 'package:hack_quest/ui/inbox_screen.dart';
import 'package:hack_quest/ui/mission_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

void main() {
  late Progress p;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
    p = await Progress.load();
    HowTo.autoShow = true;
  });
  tearDown(() => HowTo.autoShow = false);

  test('하는 법은 모드마다 한 번 본 걸 기억하고, 진행 초기화하면 다시 뜬다', () async {
    expect(p.seenHowTo('breach'), isFalse);
    await p.markHowTo('breach');
    expect(p.seenHowTo('breach'), isTrue);
    expect(p.seenHowTo('cases'), isFalse);
    await p.reset();
    expect(p.seenHowTo('breach'), isFalse);
  });

  Future<void> pageThrough(WidgetTester t, String mode) async {
    final n = HowTo.pages[mode]!;
    for (var i = 1; i < n; i++) {
      await t.tap(find.byKey(const Key('howto_next')));
      await settle(t);
    }
    expect(find.text(S.t('howto_${mode}_${n}_t')), findsOneWidget);
    await t.tap(find.byKey(const Key('howto_next'))); // 마지막 장: 시작하기
    await settle(t);
  }

  for (final (mode, screen) in [
    ('breach', (Progress p) => BreachListScreen(progress: p)),
    ('cases', (Progress p) => CaseListScreen(progress: p)),
    ('ops', (Progress p) => InboxScreen(progress: p, catalog: Catalog.fromTexts({}))),
  ]) {
    testWidgets('$mode: 처음 들어가면 하는 법 카드, 다 넘기면 닫히고 다음엔 안 뜬다, ? 로 다시 본다', (t) async {
      await t.pumpWidget(MaterialApp(home: screen(p)));
      await settle(t);
      expect(find.text(S.t('howto_${mode}_1_t')), findsOneWidget);
      await pageThrough(t, mode);
      expect(find.text(S.t('howto_${mode}_1_t')), findsNothing);
      expect(p.seenHowTo(mode), isTrue);

      await t.pumpWidget(MaterialApp(home: KeyedSubtree(key: UniqueKey(), child: screen(p))));
      await settle(t);
      expect(find.text(S.t('howto_${mode}_1_t')), findsNothing);
      await t.tap(find.byKey(const Key('howto_btn')));
      await settle(t);
      expect(find.text(S.t('howto_${mode}_1_t')), findsOneWidget);
    });
  }

  testWidgets('작전 첫 임무(tutorial): 다음에 누를 칩이 빛나고, 명령이 다 되면 실행 단추가 빛난다', (t) async {
    final m = Mission.fromJson({
      'id': 'm9_01', 'chapter': 1, 'title': '@t', 'brief': ['@b'], 'done': ['@d'], 'tutorial': true,
      'commands': ['scan', 'connect', 'open'], 'trace': 0,
      'hosts': {'home': {'name': 'my-laptop', 'fs': {'a.txt': 'A'}}, 'pub': {'name': 'pub-box', 'fs': {'p.txt': 'P'}}},
      'puzzles': [], 'goal': {'read': 'pub:/p.txt'}, 'hints': ['@h1', '@h2', '@h3'],
      'solution': ['scan', 'connect pub-box', 'open p.txt'],
    });
    expect(m.tutorial, isTrue);
    await t.pumpWidget(MaterialApp(home: MissionScreen(mission: m, progress: p, catalog: Catalog.fromTexts({}))));
    await settle(t);
    expect(find.byKey(const Key('guide_chip_scan')), findsOneWidget);
    expect(find.byKey(const Key('guide_chip_connect')), findsNothing);
    expect(find.text(S.tn('tut_ops_next', {'line': 'scan'})), findsOneWidget);
    await t.tap(find.byKey(const Key('chip_scan')));
    await t.pump();
    expect(find.byKey(const Key('guide_run')), findsOneWidget);
    await t.tap(find.byKey(const Key('run_btn')));
    await settle(t);
    expect(find.byKey(const Key('guide_chip_connect')), findsOneWidget);
    await t.tap(find.byKey(const Key('chip_connect')));
    await t.pump();
    expect(find.byKey(const Key('guide_chip_pub-box')), findsOneWidget);
  });
}
