/// 앱스토어 스크린샷을 찍는다 (iOS 시뮬레이터용).
///
///     flutter drive -d (시뮬레이터 ID) \
///       --driver=test_driver/integration_test.dart \
///       --target=integration_test/store_shots_test.dart \
///       --dart-define=SHOT_LANGS=ko,en
///
/// 결과: `build/store_shots/(언어)/01_title.png` … — `tool/ios_store_shots.sh` 가 돌리고 JPEG 로 옮긴다.
/// 화면 순서는 안드로이드 스토어 스크린샷(store/screenshots/ko)과 같다.
/// 이 맥의 시뮬레이터는 바깥에서 넣은 탭을 앱이 받지 못해서, 앱 안에서 위젯을 직접 눌러 가며 찍는다.
///
/// **진행 기록을 지운다.** 시뮬레이터에서만 돌릴 것.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/breach_gen.dart';
import 'package:hack_quest/engine/case_file.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/main.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/breach/breach_play_screen.dart';
import 'package:hack_quest/ui/cases/case_screen.dart';
import 'package:hack_quest/ui/how_to.dart';
import 'package:hack_quest/ui/mission_screen.dart';
import 'package:hack_quest/ui/result_screen.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _langsArg = String.fromEnvironment('SHOT_LANGS', defaultValue: 'ko,en');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false; // 디버그 빌드의 「DEBUG」 띠를 스토어 사진에서 뺀다

  testWidgets('스토어 스크린샷', (t) async {
    final catalog = await Catalog.load();

    // 실제 폰처럼 기다리는 동안 계속 그린다. 두 번만 그리면 화면 전환이 덜 끝난 채 찍혀 왼쪽 끝에 앞 화면이 비친다.
    Future<void> wait(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      await t.pump();
      while (DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await t.pump();
      }
    }

    Future<void> shot(String lang, String name) async {
      await wait(900);
      await binding.takeScreenshot('$lang/$name');
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f.first);
      await wait(150);
      await t.tap(f.first);
      await wait(350);
    }

    NavigatorState nav() => t.state<NavigatorState>(find.byType(Navigator).first);
    Future<void> push(Widget w) async {
      nav().push(MaterialPageRoute(builder: (_) => w));
      await wait(800);
    }

    Future<void> home() async {
      nav().popUntil((r) => r.isFirst);
      await wait(600);
    }

    // 칩이 있으면 칩으로, 없으면(키보드 임무) 입력칸에 친다.
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
      await wait(600);
    }

    for (final lang in _langsArg.split(',')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await AppLang().set(lang);
      final p = await Progress.load();
      await p.setMusic(false); // 찍는 동안 조용히
      // 몇 판 해 본 사람의 화면(모드 화면의 진행 숫자·크레딧이 0 이 아니게)
      for (final id in ['m1_01', 'm1_02', 'm1_03', 'm1_04', 'm1_05', 'm1_06', 'm2_01']) {
        await p.complete(id, 0);
      }
      await p.addCredits(1250);
      for (final mode in HowTo.pages.keys) {
        await p.markHowTo(mode); // 하는 법 카드가 화면을 가리지 않게
      }

      await t.pumpWidget(HackQuestApp(key: UniqueKey(), progress: p, catalog: catalog));
      await wait(2500);
      await shot(lang, '01_title');

      await tap(find.textContaining(S.t('btn_start')));
      await shot(lang, '02_modes');

      // 작전: 2장 두 번째 의뢰를 몇 줄 진행한 모습
      await push(MissionScreen(mission: catalog.byId('m2_02')!, progress: p, catalog: catalog));
      for (final line in ['scan', 'connect shop-server', 'ls', 'cd home']) {
        await typeLine(line);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await shot(lang, '03_operation');
      await home();

      // 브리치: 8단계를 반쯤 푼 모습
      await push(BreachPlayScreen.stage(progress: p, n: 8));
      final path = generateStage(8).solution;
      for (final (r, c) in path.take(path.length ~/ 2)) {
        await tap(find.byKey(Key('cell_${r}_$c')));
      }
      await wait(2500); // 목표 완료 파편·알림이 가라앉게
      await shot(lang, '04_breach');
      await home();

      // 사건 파일: 첫 사건 → 잠긴 자료(단어 추리) → 결론 질문
      final c01 = CaseFile.parse(await rootBundle.loadString('assets/cases/c01.json'));
      await push(CaseScreen(file: c01, progress: p));
      await shot(lang, '05_case');
      await tap(find.byKey(const Key('doc_accounts.csv')));
      await shot(lang, '06_case_lock');
      nav().pop();
      await wait(600);
      await t.scrollUntilVisible(find.byKey(const Key('case_conclude')), 200, scrollable: find.byType(Scrollable).last);
      await tap(find.byKey(const Key('case_conclude')));
      await shot(lang, '07_case_question');
      await home();

      await push(ResultScreen(
          mission: catalog.byId('m2_01')!, progress: p, catalog: catalog,
          hintsUsed: 0, elapsed: const Duration(minutes: 2, seconds: 17), earned: 250));
      await wait(2500); // 별·크레딧 연출이 끝나게
      await shot(lang, '08_result');
      await home();
    }
  });
}
