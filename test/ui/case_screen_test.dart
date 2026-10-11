import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/case_file.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/cases/case_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 폰처럼 저장이 느린 저장소(쓰기가 끝나기 전에 화면이 다시 그려진다).
class _SlowStore extends InMemorySharedPreferencesStore {
  _SlowStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return super.setValue(valueType, key, value);
  }
}

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
  testWidgets('저장이 느려도 마지막 정답 뒤 바로 결과가 나온다(빈 화면·오류 없음)', (t) async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _SlowStore();
    final slow = await Progress.load();
    final c = CaseFile.parse(File('assets/cases/c01.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: CaseScreen(file: c, progress: slow)));
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('case_conclude')));
    await settle(t);
    await t.tap(find.byKey(const Key('case_conclude')));
    await settle(t);
    await t.tap(find.byKey(const Key('opt_1')));
    await settle(t);
    await t.tap(find.byKey(const Key('opt_0')));
    await t.pump(); // 저장이 아직 안 끝난 첫 프레임
    expect(t.takeException(), isNull);
    expect(find.text(S.t('case_solved')), findsWidgets);
    await t.pump(const Duration(seconds: 1));
    expect(slow.caseStars('c01'), 3);
  });
}
