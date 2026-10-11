import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/main.dart';
import 'package:hack_quest/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('화면 아래 시스템 내비게이션 바 밑으로 앱이 깔리지 않는다', (t) async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('en');
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.625;
    t.view.padding = const FakeViewPadding(bottom: 126); // 갤럭시 A16 3버튼 바 = 48dp
    addTearDown(t.view.reset);
    final progress = await Progress.load();
    final catalog = Catalog.fromTexts({});
    await t.pumpWidget(HackQuestApp(progress: progress, catalog: catalog));
    await t.pumpAndSettle();
    final screenH = 2340 / 2.625;
    final bottom = t.getBottomLeft(find.byType(Scaffold).first).dy;
    expect(bottom, lessThanOrEqualTo(screenH - 48 + 0.5));
  });
}
