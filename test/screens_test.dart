import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/result_screen.dart';
import 'package:hack_quest/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

String m(String id) => '{"id":"$id","chapter":1,"title":"@t_$id","brief":["@b"],"done":["@d"],"commands":["scan"],'
    '"hosts":{"home":{"name":"h","fs":{}}},"goal":{"connect":"home"},"hints":[],"solution":[]}';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('en');
  });

  testWidgets('완료 화면: 별과 다음 임무 버튼, 마지막 임무엔 다음 없음', (t) async {
    final p = await Progress.load();
    await p.complete('m1_01', 1);
    final c = Catalog.fromTexts({'m1_01': m('m1_01'), 'm1_02': m('m1_02')});
    await t.pumpWidget(MaterialApp(home: ResultScreen(
      mission: c.byId('m1_01')!, progress: p, catalog: c, hintsUsed: 1, elapsed: const Duration(seconds: 75))));
    expect(find.text('★★☆'), findsOneWidget);
    expect(find.text(S.tn('result_time', {'m': 1, 's': 15})), findsOneWidget);
    expect(find.text(S.t('btn_next')), findsOneWidget);
    await t.tap(find.text(S.t('btn_next')));
    await t.pumpAndSettle();
    expect(find.text('t_m1_02'), findsOneWidget); // 다음 임무 상세(번역 없는 열쇠는 열쇠 그대로)

    await t.pumpWidget(MaterialApp(home: ResultScreen(
      mission: c.byId('m1_02')!, progress: p, catalog: c, hintsUsed: 0, elapsed: Duration.zero)));
    await t.pumpAndSettle();
    expect(find.text(S.t('btn_next')), findsNothing);
  });

  testWidgets('설정: 언어를 고르면 바로 바뀌고 저장된다, 소리 끄기', (t) async {
    final p = await Progress.load();
    await t.pumpWidget(MaterialApp(home: SettingsScreen(progress: p)));
    expect(find.text('Settings'), findsOneWidget);
    await t.tap(find.text('한국어'));
    await t.pumpAndSettle();
    expect(AppLang().value, 'ko');
    expect(find.text('설정'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('app_language'), 'ko');
    await t.tap(find.byKey(const Key('set_sound')));
    await t.pumpAndSettle();
    expect(p.soundOn, isFalse);
    await t.tap(find.byKey(const Key('set_vibration')));
    await t.pumpAndSettle();
    expect(p.vibrationOn, isFalse);
  });

  testWidgets('설정: 초기화는 확인을 받고 진행만 지운다', (t) async {
    final p = await Progress.load();
    await p.complete('m1_01', 0);
    await t.pumpWidget(MaterialApp(home: SettingsScreen(progress: p)));
    await t.scrollUntilVisible(find.text(S.t('btn_reset')), 200);
    await t.tap(find.text(S.t('btn_reset')));
    await t.pumpAndSettle();
    await t.tap(find.text(S.t('btn_check')));
    await t.pumpAndSettle();
    expect(p.isDone('m1_01'), isFalse);
  });
}
