import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/shell.dart';
import 'package:hack_quest/ui/input_bar.dart';

Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('칩만으로 한 줄을 만들고 실행하면 비워진다', (t) async {
    String? ran;
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['scan', 'open'], ['a.txt']),
      editable: false, password: false, onRun: (s) => ran = s,
    )));
    await t.tap(find.byKey(const Key('chip_open')));
    await t.pump();
    await t.tap(find.byKey(const Key('chip_a.txt')));
    await t.pump();
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).controller!.text, 'open a.txt ');
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).readOnly, isTrue);
    await t.tap(find.byKey(const Key('run_btn')));
    await t.pump();
    expect(ran, 'open a.txt');
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).controller!.text, '');
  });
  testWidgets('비밀번호 대기 중에는 칩이 없고 입력칸이 열린다', (t) async {
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['scan'], ['a.txt']),
      editable: false, password: true, onRun: (_) {},
    )));
    expect(find.byKey(const Key('chip_scan')), findsNothing);
    final f = t.widget<TextField>(find.byKey(const Key('input_field')));
    expect(f.readOnly, isFalse);
    expect(f.obscureText, isTrue);
  });
  testWidgets('키보드 임무는 입력칸이 열려 있고 칩도 있다', (t) async {
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['find'], ['x']),
      editable: true, password: false, onRun: (_) {},
    )));
    expect(find.byKey(const Key('chip_find')), findsOneWidget);
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).readOnly, isFalse);
  });
  testWidgets('칩 임무에서 비밀번호를 끝내면 입력칸 포커스(키보드)를 놓는다', (t) async {
    Widget bar(bool pw) => wrap(InputBar(
      suggestions: Suggestions(['scan'], []), editable: false, password: pw, onRun: (_) {}));
    await t.pumpWidget(bar(true));
    await t.tap(find.byKey(const Key('input_field')));
    await t.pump();
    bool focused() => t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;
    expect(focused(), isTrue);
    await t.pumpWidget(bar(false));
    await t.pump();
    expect(focused(), isFalse);
  });
}
