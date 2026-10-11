import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/engine/shell.dart';
import 'package:hack_quest/sfx.dart';
import 'package:hack_quest/ui/input_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Sfx().log.clear();
    Sfx().progress = await Progress.load();
  });

  testWidgets('칩을 누르면 tap, 실행하면 run 이 울린다', (t) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(body: InputBar(
      suggestions: Suggestions(['scan'], []), editable: false, password: false, onRun: (_) {}))));
    await t.tap(find.byKey(const Key('chip_scan')));
    await t.pump();
    await t.tap(find.byKey(const Key('run_btn')));
    await t.pump();
    expect(Sfx().log, ['tap', 'run']);
  });

  test('효과음을 끄면 아무것도 안 울린다', () async {
    await Sfx().progress!.setSound(false);
    Sfx().play('ok');
    expect(Sfx().log, isEmpty);
  });
  test('진동: 성공·실패·누르기마다 세기가 다르고, 설정에서 끄면 진동만 멈춘다', () async {
    Sfx().haptics.clear();
    Sfx().play('tap');
    Sfx().play('ok');
    Sfx().play('fail');
    expect(Sfx().haptics, ['light', 'medium', 'heavy']);
    await Sfx().progress!.setVibration(false);
    Sfx().haptics.clear();
    Sfx().play('fail');
    expect(Sfx().haptics, isEmpty);
    expect(Sfx().log.last, 'fail'); // 소리는 그대로
  });
}
