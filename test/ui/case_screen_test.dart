import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/case_file.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/cases/case_screen.dart';
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

  testWidgets('자료를 읽고, 잠긴 자료는 단어 추리로 열고, 결론(오답 1개) → 별 2', (t) async {
    final c = CaseFile.parse(File('assets/cases/c01.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: CaseScreen(file: c, progress: p)));
    await settle(t);

    await t.tap(find.byKey(const Key('doc_admin_access.log')));
    await settle(t);
    expect(find.textContaining('export coupon_list.csv'), findsOneWidget);
    await t.pageBack();
    await settle(t);

    await t.tap(find.byKey(const Key('doc_minho_dm.txt')));
    await settle(t);
    final w = caseLockPuzzle('c01', 'minho_dm.txt', 5);
    await t.ensureVisible(find.byKey(Key('word_${w.answer}')));
    await t.tap(find.byKey(Key('word_${w.answer}')));
    await t.pump(const Duration(seconds: 1)); // 「접속 허가」를 잠깐 보여 준 뒤 닫힌다
    await settle(t);
    expect(find.text(S.t('c01_d_dm')), findsOneWidget); // 열리면 바로 내용
    await t.pageBack();
    await settle(t);

    await t.ensureVisible(find.byKey(const Key('case_conclude')));
    await settle(t);
    await t.tap(find.byKey(const Key('case_conclude')));
    await settle(t);
    await t.tap(find.byKey(const Key('opt_0'))); // 오답
    await settle(t);
    await t.tap(find.byKey(const Key('opt_1')));
    await settle(t);
    await t.tap(find.byKey(const Key('opt_0')));
    await settle(t);
    expect(find.text(S.t('case_solved')), findsWidgets);
    expect(p.caseStars('c01'), 2);
    expect(p.credits, 60);
  });
}
