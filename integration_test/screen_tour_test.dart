/// 작은 아이폰(SE 3세대 375×667)·큰 아이폰에서 모든 화면을 돌며 넘침·오류를 잡고 화면을 찍는다.
///
///     flutter drive -d (시뮬레이터 ID) --driver=test_driver/integration_test.dart \
///       --target=integration_test/screen_tour_test.dart --dart-define=SHOT_LANGS=ko,en
///
/// 결과: `build/store_shots/tour/(언어)/…png` — `tool/ios_screen_tour.sh` 가 돌린다.
/// 글자가 넘치면(RenderFlex overflow 등) 그 자리에서 시험이 실패한다. 실제 글꼴로 그리므로 위젯 시험(Ahem 글꼴)보다 정확하다.
/// **진행 기록을 지운다.** 시뮬레이터에서만 돌릴 것.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/breach_gen.dart';
import 'package:hack_quest/engine/case_file.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/main.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/breach/breach_list_screen.dart';
import 'package:hack_quest/ui/breach/breach_play_screen.dart';
import 'package:hack_quest/ui/brief_screen.dart';
import 'package:hack_quest/ui/cases/case_list_screen.dart';
import 'package:hack_quest/ui/cases/case_screen.dart';
import 'package:hack_quest/ui/how_to.dart';
import 'package:hack_quest/ui/inbox_screen.dart';
import 'package:hack_quest/ui/mission_screen.dart';
import 'package:hack_quest/ui/result_screen.dart';
import 'package:hack_quest/ui/settings_screen.dart';
import 'package:hack_quest/ui/shop_screen.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _langsArg = String.fromEnvironment('SHOT_LANGS', defaultValue: 'ko,en');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false;

  testWidgets('화면 둘러보기', (t) async {
    final catalog = await Catalog.load();
    var lang = 'ko';
    var n = 0;

    // 실제 폰처럼 기다리는 동안 계속 그린다. 두 번만 그리면 화면 전환이 덜 끝난 채 찍혀 왼쪽 끝에 앞 화면이 비친다.
    Future<void> wait(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      await t.pump();
      while (DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await t.pump();
      }
    }

    Future<void> shot(String name) async {
      await wait(700);
      await binding.takeScreenshot('tour/$lang/${(++n).toString().padLeft(2, '0')}_$name');
    }

    Future<void> tap(Finder f) async {
      // 작은 화면에선 목록 아래쪽 항목이 아직 안 그려졌다 — 굴려서 찾는다
      if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);
      await t.ensureVisible(f.first);
      await wait(150);
      await t.tap(f.first);
      await wait(400);
    }

    NavigatorState nav() => t.state<NavigatorState>(find.byType(Navigator).first);
    Future<void> push(Widget w) async {
      nav().push(MaterialPageRoute(builder: (_) => w));
      await wait(800);
    }

    Future<void> home() async {
      nav().popUntil((r) => r.isFirst);
      await wait(500);
    }

    Future<void> typeLine(String line) async {
      final toks = line.split(' ');
      if (toks.every((tok) => find.byKey(Key('chip_$tok')).evaluate().isNotEmpty)) {
        for (final tok in toks) {
          await tap(find.byKey(Key('chip_$tok')));
        }
      } else {
        await t.enterText(find.byKey(const Key('input_field')), line);
      }
      await tap(find.byKey(const Key('run_btn')));
      await wait(500);
    }

    // 임무를 열고 해답대로 치다가 [stopAt] 번째 퍼즐 앞에서 멈춘다(퍼즐 창이 열린 채).
    Future<Mission> playUntilPuzzle(String id, {int puzzles = 1}) async {
      final m = catalog.byId(id)!;
      final p = await Progress.load();
      await push(MissionScreen(mission: m, progress: p, catalog: catalog));
      var seen = 0;
      for (final step in m.solution) {
        if (step is PuzzleStep) {
          if (++seen == puzzles) break;
          continue;
        }
        await typeLine(step as String);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await wait(600);
      return m;
    }

    // 모드에 처음 들어가면 뜨는 「하는 법」 카드를 장마다 찍고 닫는다.
    Future<void> howTo(String mode) async {
      for (var i = 1; i <= HowTo.pages[mode]!; i++) {
        expect(find.byKey(const Key('howto_next')), findsOneWidget, reason: '하는 법 카드($mode)');
        await shot('howto_${mode}_$i');
        await tap(find.byKey(const Key('howto_next')));
        await wait(300);
      }
    }

    for (final l in _langsArg.split(',')) {
      lang = l;
      n = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await AppLang().set(lang);
      final p = await Progress.load();
      await p.setMusic(false);
      for (final id in ['m1_01', 'm1_02', 'm1_03', 'm1_04', 'm1_05', 'm1_06', 'm2_01']) {
        await p.complete(id, 0);
      }
      await p.addCredits(1250);

      await t.pumpWidget(HackQuestApp(key: UniqueKey(), progress: p, catalog: catalog));
      await wait(2000);
      await shot('title');
      await tap(find.textContaining(S.t('btn_start')));
      await shot('modes');

      await push(InboxScreen(progress: p, catalog: catalog));
      await howTo('ops');
      await shot('inbox');
      await push(BriefScreen(mission: catalog.byId('m3_01')!, progress: p, catalog: catalog));
      await shot('brief');
      await home();

      // 작전: 칩 임무 / 퍼즐 4종 / 코드 고치기 / 키보드 임무
      await playUntilPuzzle('m1_03');
      await shot('puzzle_match');
      await home();
      await playUntilPuzzle('m1_04');
      await shot('puzzle_password');
      await home();
      await playUntilPuzzle('m1_05');
      await shot('puzzle_order');
      await home();
      await playUntilPuzzle('m4_01');
      await shot('puzzle_codefix');
      await home();

      // 키보드 임무: 몇 줄 친 뒤 키보드가 열린 모습(아이폰 SE 키보드 높이 ≈ 260pt)
      await push(MissionScreen(mission: catalog.byId('m3_01')!, progress: p, catalog: catalog));
      await typeLine('scan');
      await typeLine('connect corp-fs');
      FocusManager.instance.primaryFocus?.unfocus();
      await wait(300);
      await shot('keyboard_mission');
      t.view.viewInsets = FakeViewPadding(bottom: 260 * t.view.devicePixelRatio);
      await wait(600);
      await shot('keyboard_open');
      t.view.resetViewInsets();
      await wait(400);
      await home();

      // 포트 크랙(브리치·단어 추리): 잠긴 서버를 지도에서 눌러 크랙
      await push(MissionScreen(mission: catalog.byId('m1_03')!, progress: p, catalog: catalog));
      await typeLine('scan');
      await tap(find.byKey(const Key('node_router')));
      await wait(400);
      await shot('host_sheet');
      await tap(find.textContaining(S.t('map_crack').split('(').first.trim()));
      await wait(800);
      await shot('crack');
      await home();
      await push(MissionScreen(mission: catalog.byId('m5_01')!, progress: p, catalog: catalog));
      await typeLine('scan');
      await tap(find.byKey(const Key('node_gate')));
      await tap(find.textContaining(S.t('map_crack').split('(').first.trim()));
      await wait(800);
      await shot('crack_late');
      await home();

      await push(ResultScreen(mission: catalog.byId('m2_01')!, progress: p, catalog: catalog,
          hintsUsed: 1, elapsed: const Duration(minutes: 12, seconds: 5), earned: 250));
      await wait(2500);
      await shot('result');
      await home();

      // 브리치
      await push(BreachListScreen(progress: p));
      await howTo('breach');
      await shot('breach_list');
      await push(BreachPlayScreen.stage(progress: p, n: 1));
      await shot('breach_tutorial');
      await home();
      await push(BreachPlayScreen.stage(progress: p, n: 60));
      await shot('breach_60');
      await home();
      await push(BreachPlayScreen.daily(progress: p, day: DateTime.now()));
      await shot('breach_daily');
      final path = generateStage(2).solution;
      await home();
      await push(BreachPlayScreen.stage(progress: p, n: 2));
      for (final (r, c) in path) {
        if (find.byKey(Key('cell_${r}_$c')).evaluate().isEmpty) break;
        await tap(find.byKey(Key('cell_${r}_$c')));
      }
      await wait(2500);
      await shot('breach_result');
      await home();

      // 사건 파일: 목록, 마지막 사건(자료 많음), 잠금, 질문(보기 많음)
      await push(CaseListScreen(progress: p));
      await howTo('cases');
      await shot('case_list');
      final c12 = CaseFile.parse(await rootBundle.loadString('assets/cases/c12.json'));
      await push(CaseScreen(file: c12, progress: p));
      await shot('case_12');
      final locked = c12.docs.firstWhere((d) => d.lockLength != null);
      await tap(find.byKey(Key('doc_${locked.name}')));
      await wait(600);
      await shot('case_12_lock');
      nav().pop();
      await wait(500);
      final open = c12.docs.firstWhere((d) => d.lockLength == null);
      await tap(find.byKey(Key('doc_${open.name}')));
      await shot('case_12_doc');
      nav().pop();
      await wait(500);
      await t.scrollUntilVisible(find.byKey(const Key('case_conclude')), 200, scrollable: find.byType(Scrollable).last);
      await tap(find.byKey(const Key('case_conclude')));
      await shot('case_12_question');
      await home();

      await push(ShopScreen(progress: p));
      await shot('shop');
      await home();
      await push(SettingsScreen(progress: p));
      await shot('settings');
      await t.scrollUntilVisible(find.text(S.t('btn_reset')), 200);
      await wait(300);
      await shot('settings_bottom');
      await home();
    }
  });
}
