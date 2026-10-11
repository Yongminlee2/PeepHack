import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/main.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/fx/ghost_avatar.dart';
import 'package:hack_quest/ui/inbox_screen.dart';
import 'package:hack_quest/ui/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱은 타이틀 화면으로 시작하고 「접속 시작」 → 모드 선택 → 작전으로 메시지함에 간다', (t) async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
    final p = await Progress.load();
    await t.pumpWidget(HackQuestApp(progress: p, catalog: Catalog.fromTexts({})));
    await t.pumpAndSettle();
    expect(find.text('HACKQUEST'), findsWidgets);
    expect(find.byType(GhostAvatar), findsOneWidget);
    expect(find.text(S.t('title_tagline')), findsOneWidget);
    await t.tap(find.textContaining(S.t('btn_start')));
    await t.pumpAndSettle();
    await t.tap(find.text(S.t('mode_campaign')));
    await t.pumpAndSettle();
    expect(find.byType(InboxScreen), findsOneWidget);
  });
  testWidgets('완료 화면의 「메시지함으로」는 타이틀이 아니라 메시지함으로 간다', (t) async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
    final p = await Progress.load();
    const m1 = '{"id":"m1_01","chapter":1,"title":"@t","brief":["@b"],"done":["@d"],"commands":["scan"],'
        '"hosts":{"home":{"name":"h","fs":{}}},"goal":{"connect":"home"},"hints":[],"solution":[]}';
    final c = Catalog.fromTexts({'m1_01': m1});
    await t.pumpWidget(HackQuestApp(progress: p, catalog: c));
    await t.pumpAndSettle();
    await t.tap(find.textContaining(S.t('btn_start')));
    await t.pumpAndSettle();
    await t.tap(find.text(S.t('mode_campaign')));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => ResultScreen(
        mission: c.byId('m1_01')!, progress: p, catalog: c, hintsUsed: 0, elapsed: Duration.zero)));
    await t.pumpAndSettle();
    await t.tap(find.text(S.t('btn_back_inbox')));
    await t.pumpAndSettle();
    expect(find.byType(InboxScreen), findsOneWidget);
  });
}
