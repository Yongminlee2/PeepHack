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

  testWidgets('자료를 읽고, 잠긴 이름표는 단어 추리로 열고, 결론(오답 1개) → 별 2', (t) async {
    final c = CaseFile.parse(File('assets/cases/c01.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: CaseScreen(file: c, progress: p)));
    await settle(t);

    await t.tap(find.byKey(const Key('doc_admin_access.log')));
    await settle(t);
    expect(find.textContaining('export  coupon_list.csv'), findsOneWidget);
    await t.pageBack();
    await settle(t);

    await t.tap(find.byKey(const Key('doc_accounts.csv')));
    await settle(t);
    final w = caseLockPuzzle('c01', 'accounts.csv', 5);
    await t.ensureVisible(find.byKey(Key('word_${w.answer}')));
    await t.tap(find.byKey(Key('word_${w.answer}')));
    await t.pump(const Duration(seconds: 1)); // 「접속 허가」를 잠깐 보여 준 뒤 닫힌다
    await settle(t);
    expect(find.textContaining('A-105,minho'), findsOneWidget); // 열리면 바로 내용
    await t.pageBack();
    await settle(t);

    await t.scrollUntilVisible(find.byKey(const Key('case_conclude')), 200, scrollable: find.byType(Scrollable).last);
    await settle(t);
    await t.tap(find.byKey(const Key('case_conclude')));
    await settle(t);
    for (final o in [0, 1, 2, 1]) { // 첫 번째는 오답
      await t.ensureVisible(find.byKey(Key('opt_$o')));
      await t.tap(find.byKey(Key('opt_$o')));
      await settle(t);
    }
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
    await t.scrollUntilVisible(find.byKey(const Key('case_conclude')), 200, scrollable: find.byType(Scrollable).last);
    await settle(t);
    await t.tap(find.byKey(const Key('case_conclude')));
    await settle(t);
    for (final o in [1, 2]) {
      await t.tap(find.byKey(Key('opt_$o')));
      await settle(t);
    }
    await t.tap(find.byKey(const Key('opt_1')));
    await t.pump(); // 저장이 아직 안 끝난 첫 프레임
    expect(t.takeException(), isNull);
    expect(find.text(S.t('case_solved')), findsWidgets);
    await t.pump(const Duration(seconds: 1));
    expect(slow.caseStars('c01'), 3);
  });
  testWidgets('잠긴 자료를 맞힌 직후 뒤로가기를 눌러도 사건 화면에 남는다', (t) async {
    final c = CaseFile.parse(File('assets/cases/c01.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: Builder(
      builder: (ctx) => TextButton(
        onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => CaseScreen(file: c, progress: p))),
        child: const Text('list'),
      ),
    )));
    await t.tap(find.text('list'));
    await settle(t);
    await t.tap(find.byKey(const Key('doc_accounts.csv')));
    await settle(t);
    final w = caseLockPuzzle('c01', 'accounts.csv', 5);
    await t.ensureVisible(find.byKey(Key('word_${w.answer}')));
    await t.tap(find.byKey(Key('word_${w.answer}')));
    await t.pump(const Duration(milliseconds: 200));
    await t.pageBack(); // 자동으로 닫히기 전에 직접 뒤로
    await t.pump(const Duration(seconds: 1));
    await settle(t);
    expect(find.byType(CaseScreen), findsOneWidget);
  });
  testWidgets('세 번 틀리면 사건 실패, 다시 하면 자료부터 처음부터', (t) async {
    final c = CaseFile.parse(File('assets/cases/c01.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: CaseScreen(file: c, progress: p)));
    await settle(t);
    await t.scrollUntilVisible(find.byKey(const Key('case_conclude')), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.byKey(const Key('case_conclude')));
    await settle(t);
    final q = c.questions.first;
    final wrongs = [for (var i = 0; i < q.options.length; i++) if (i != q.answer) i];
    for (final w in wrongs.take(3)) {
      await t.ensureVisible(find.byKey(Key('opt_$w')));
      await t.tap(find.byKey(Key('opt_$w')));
      await settle(t);
    }
    expect(find.text(S.t('case_failed')), findsWidgets);
    expect(p.caseStars('c01'), 0);
    await t.tap(find.byKey(const Key('case_retry')));
    await settle(t);
    expect(find.byKey(const Key('doc_admin_access.log')), findsOneWidget); // 자료 보기로 돌아왔다
    await t.scrollUntilVisible(find.byKey(const Key('case_conclude')), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.byKey(const Key('case_conclude')));
    await settle(t);
    expect(find.text(S.tn('case_question_n', {'i': 1, 'n': c.questions.length})), findsOneWidget); // 첫 질문부터
  });
  testWidgets('영문 기록은 줄이 꺾이지 않게: 가장 긴 줄에 맞춰 글자를 줄이고 옆으로 밀 수 있다', (t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = CaseFile.parse(File('assets/cases/c01.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: CaseScreen(file: c, progress: p)));
    await settle(t);
    await t.tap(find.byKey(const Key('doc_admin_access.log')));
    await settle(t);
    final txt = t.widget<SelectableText>(find.byType(SelectableText));
    expect(txt.style!.fontSize, lessThan(14));
    expect(txt.style!.fontSize, greaterThanOrEqualTo(10));
    expect(find.ancestor(of: find.byType(SelectableText), matching: find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal)), findsOneWidget);
  });
  testWidgets('번역되는 자료(메모·채팅)는 영어여도 문장이라 줄을 꺾는다 — 옆으로 밀려 잘리지 않게', (t) async {
    await AppLang().set('en');
    t.view.physicalSize = const Size(375, 667); // 아이폰 SE
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = CaseFile.parse(File('assets/cases/c12.json').readAsStringSync());
    await t.pumpWidget(MaterialApp(home: CaseScreen(file: c, progress: p)));
    await settle(t);
    await t.tap(find.byKey(const Key('doc_last_message.txt')));
    await settle(t);
    final txt = t.widget<SelectableText>(find.byType(SelectableText));
    expect(txt.data, contains('Find me.'));
    expect(find.ancestor(of: find.byType(SelectableText), matching: find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal)), findsNothing);
  });
}
