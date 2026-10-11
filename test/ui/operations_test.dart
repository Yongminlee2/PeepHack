import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/engine/shop.dart';
import 'package:hack_quest/sfx.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/mission_screen.dart';
import 'package:hack_quest/ui/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

Mission mk({int trace = 0}) => Mission.fromJson({
      'id': 'm9_01', 'chapter': 1, 'title': '@t', 'brief': ['@b'], 'done': ['@d'],
      'commands': ['scan', 'connect', 'open'],
      'trace': trace,
      'hosts': {
        'home': {'name': 'my-laptop', 'fs': {'a.txt': 'A'}},
        'pub': {'name': 'pub-box', 'fs': {'p.txt': 'P'}},
        'srv': {'name': 'srv', 'lock': {'type': 'password', 'answer': 'zz'}, 'fs': {'flag.txt': 'FLAG'}},
      },
      'puzzles': [],
      'goal': {'read': 'srv:/flag.txt'},
      'hints': ['@h1', '@h2', '@h3'],
      'solution': ['connect srv', 'zz', 'open flag.txt'],
    });

void main() {
  late Progress p;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
    p = await Progress.load();
    Sfx().progress = p;
  });

  Future<void> open(WidgetTester t, Mission m) async {
    await t.pumpWidget(MaterialApp(home: MissionScreen(mission: m, progress: p, catalog: Catalog.fromTexts({}))));
    await settle(t);
  }

  String appBarTitle(WidgetTester t) =>
      (t.widget<Text>(find.descendant(of: find.byType(AppBar), matching: find.textContaining(':/')).first)).data!;

  testWidgets('지도: 열린 서버를 누르면 접속한다', (t) async {
    await open(t, mk());
    expect(find.byKey(const Key('node_srv')), findsOneWidget);
    await t.tap(find.byKey(const Key('node_pub')));
    await settle(t);
    expect(appBarTitle(t), 'pub-box:/');
  });

  testWidgets('지도: 잠긴 서버는 포트 크랙으로 뚫고 들어간다', (t) async {
    final m = mk();
    await open(t, m);
    await t.tap(find.byKey(const Key('node_srv')));
    await settle(t);
    await t.tap(find.text(S.tn('map_crack', {'n': 1})));
    await settle(t);
    expect(find.text(S.t('crack_rule_breach')), findsOneWidget); // 처음 보는 판의 규칙 한 줄
    expect(find.byKey(const Key('input_field')), findsNothing); // 퍼즐 창에선 명령줄을 숨겨 판을 넓게
    final puzzle = crackPuzzle(missionId: m.id, host: 'srv', port: 0, attempt: 0, chapter: 1, owned: const {});
    for (final (r, c) in puzzle.solution) {
      if (find.byKey(Key('cell_${r}_$c')).evaluate().isEmpty) break;
      await t.tap(find.byKey(Key('cell_${r}_$c')));
      await t.pump();
    }
    await settle(t);
    expect(appBarTitle(t), 'srv:/');
    expect(find.text(S.tn('shell_cracked', {'host': 'srv'})), findsOneWidget);
  });

  testWidgets('추적: 시작 서버 밖에 오래 있으면 들킨다', (t) async {
    await open(t, mk(trace: 5));
    await t.pump(const Duration(seconds: 8)); // 집에서는 안 오른다
    expect(find.text(S.t('trace_caught')), findsNothing);
    await t.tap(find.byKey(const Key('node_pub')));
    await t.pump();
    await t.pump(const Duration(seconds: 6));
    await t.pump();
    expect(find.text(S.t('trace_caught')), findsWidgets);
  });

  testWidgets('임무를 처음 별 3으로 깨면 크레딧 250', (t) async {
    await open(t, mk());
    for (final line in ['connect srv', 'zz', 'open flag.txt']) {
      final tf = find.byKey(const Key('input_field'));
      if (line == 'zz') {
        await t.enterText(tf, line);
      } else {
        for (final tok in line.split(' ')) {
          await t.tap(find.byKey(Key('chip_$tok')));
          await t.pump();
        }
      }
      await t.tap(find.byKey(const Key('run_btn')));
      await settle(t);
    }
    await t.tap(find.byKey(const Key('file_finish')));
    await settle(t);
    expect(p.credits, 250);
    expect(find.text(S.tn('result_credits', {'n': 250})), findsOneWidget);
  });

  testWidgets('상점: 크레딧으로 장비를 사고, 모자라면 못 산다', (t) async {
    await p.addCredits(350);
    await t.pumpWidget(MaterialApp(home: ShopScreen(progress: p)));
    await settle(t);
    expect(find.text(S.tn('shop_credits', {'n': 350})), findsOneWidget);
    await t.tap(find.byKey(const Key('buy_buffer')));
    await settle(t);
    expect(p.owned, {'buffer'});
    expect(find.text(S.tn('shop_credits', {'n': 50})), findsOneWidget);
    await t.tap(find.byKey(const Key('buy_jammer')));
    await settle(t);
    expect(p.owned, {'buffer'});
    expect(find.text(S.t('shop_no_money')), findsOneWidget);
  });
  testWidgets('2장부터 두 번째 포트는 단어 추리로 뚫는다', (t) async {
    final m = Mission.fromJson({
      'id': 'm9_02', 'chapter': 2, 'title': '@t', 'brief': ['@b'], 'done': ['@d'],
      'commands': ['scan', 'connect', 'ls', 'cat'], 'trace': 0,
      'hosts': {
        'home': {'name': 'my-laptop', 'fs': {}},
        'srv': {'name': 'srv', 'ports': 2, 'lock': {'type': 'password', 'answer': 'zz'}, 'fs': {'flag.txt': 'F'}},
      },
      'puzzles': [], 'goal': {'read': 'srv:/flag.txt'}, 'hints': ['@h1', '@h2', '@h3'], 'solution': [],
    });
    await open(t, m);
    await t.tap(find.byKey(const Key('node_srv')));
    await settle(t);
    await t.tap(find.text(S.tn('map_crack', {'n': 2})));
    await settle(t);
    final b = crackPuzzle(missionId: m.id, host: 'srv', port: 0, attempt: 0, chapter: 2, owned: const {});
    for (final (r, c) in b.solution) {
      if (find.byKey(Key('cell_${r}_$c')).evaluate().isEmpty) break;
      await t.tap(find.byKey(Key('cell_${r}_$c')));
      await t.pump();
    }
    await settle(t);
    expect(find.text(S.t('crack_rule_word')), findsOneWidget);
    final w = wordCrackPuzzle(missionId: m.id, host: 'srv', port: 1, attempt: 0, chapter: 2, owned: const {});
    await t.ensureVisible(find.byKey(Key('word_${w.answer}')));
    await t.tap(find.byKey(Key('word_${w.answer}')));
    await settle(t);
    expect(appBarTitle(t), 'srv:/');
  });
  testWidgets('추적 70% 를 넘으면 경보음과 붉은 가장자리', (t) async {
    Sfx().log.clear();
    await open(t, mk(trace: 10));
    await t.tap(find.byKey(const Key('node_pub')));
    await t.pump();
    await t.pump(const Duration(seconds: 6));
    expect(find.byKey(const Key('trace_alarm')), findsNothing);
    expect(Sfx().log, isNot(contains('alarm')));
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('trace_alarm')), findsOneWidget);
    expect(Sfx().log.where((s) => s == 'alarm').length, 1); // 한 번만
    await t.pump(const Duration(seconds: 1));
    expect(Sfx().log.where((s) => s == 'alarm').length, 1);
  });
  testWidgets('목표 파일을 읽는 동안에는 추적이 멈춘다', (t) async {
    await open(t, mk(trace: 8));
    for (final line in ['connect srv', 'zz', 'open flag.txt']) {
      final tf = find.byKey(const Key('input_field'));
      if (line == 'zz') {
        await t.enterText(tf, line);
      } else {
        for (final tok in line.split(' ')) {
          await t.tap(find.byKey(Key('chip_$tok')));
          await t.pump();
        }
      }
      await t.tap(find.byKey(const Key('run_btn')));
      await t.pump();
    }
    await t.pump(const Duration(seconds: 12)); // 천천히 읽는다
    await t.pump();
    expect(find.text(S.t('trace_caught')), findsNothing);
    await t.tap(find.byKey(const Key('file_finish')));
    await settle(t);
    expect(p.isDone('m9_01'), isTrue);
  });
}
