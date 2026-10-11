import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/music.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/mode_screen.dart';
import 'package:hack_quest/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Progress p;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
    p = await Progress.load();
    Music().progress = p;
  });

  test('끄면 설정에 저장되고, 다시 켜면 켜진다', () async {
    expect(p.musicOn, isTrue);
    await Music().setEnabled(false);
    expect(p.musicOn, isFalse);
    await Music().setEnabled(true);
    expect(p.musicOn, isTrue);
  });

  testWidgets('설정 화면 배경음악 스위치', (t) async {
    await t.pumpWidget(MaterialApp(home: SettingsScreen(progress: p)));
    await t.tap(find.byKey(const Key('set_music')));
    await t.pumpAndSettle();
    expect(p.musicOn, isFalse);
  });

  testWidgets('모드 선택 화면 위 단추로 바로 끄고 켠다', (t) async {
    await t.pumpWidget(MaterialApp(home: ModeScreen(progress: p, catalog: Catalog.fromTexts({}))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('music_toggle')));
    await t.pumpAndSettle();
    expect(p.musicOn, isFalse);
    expect(find.byIcon(Icons.music_off), findsOneWidget);
    await t.tap(find.byKey(const Key('music_toggle')));
    await t.pumpAndSettle();
    expect(p.musicOn, isTrue);
  });
}
