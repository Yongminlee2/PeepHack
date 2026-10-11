import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/shell.dart';
import 'package:hack_quest/strings.dart';
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
    expect(f.obscureText, isFalse); // 게임 속 비밀번호라 보이게(한글 자판·오타를 눈으로 잡는다)
    expect(f.keyboardType, TextInputType.visiblePassword);
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
  testWidgets('인자 칩이 많아도 옆으로 숨지 않고 줄을 바꿔 전부 보인다', (t) async {
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['scan', 'connect', 'open', 'decode', 'back'],
          ['note.txt', 'hint.txt', '..', 'my-laptop', 'mail-box', 'safe-box']),
      editable: false, password: false, onRun: (_) {},
    )));
    final w = t.getSize(find.byType(InputBar)).width;
    for (final k in ['chip_safe-box', 'chip_back']) {
      final r = t.getRect(find.byKey(Key(k)));
      expect(r.right, lessThanOrEqualTo(w), reason: '$k 가 화면 밖');
    }
  });
  testWidgets('키보드 임무에서 엔터로 실행해도 키보드가 닫히지 않는다', (t) async {
    final ran = <String>[];
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['scan'], []), editable: true, password: false, onRun: ran.add)));
    await t.enterText(find.byKey(const Key('input_field')), 'scan');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(ran, ['scan']);
    expect(t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });
  testWidgets('비밀번호를 물으면 입력칸이 바로 선택된다(키보드가 뜬다)', (t) async {
    Widget bar(bool pw) => wrap(InputBar(
      suggestions: Suggestions(['scan'], []), editable: false, password: pw, onRun: (_) {}));
    await t.pumpWidget(bar(false));
    await t.pumpWidget(bar(true));
    await t.pump();
    expect(t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });
  testWidgets('명령 칩을 누르면 쉬운 말 설명이 뜨고, 도움말에는 쓸 수 있는 명령이 다 있다', (t) async {
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['ls', 'grep', '|'], ['a.txt']), editable: false, password: false, onRun: (_) {})));
    await t.tap(find.byKey(const Key('chip_grep')));
    await t.pump();
    expect(find.text(S.t('cmd_grep')), findsOneWidget);
    await t.tap(find.byKey(const Key('cmd_help')));
    await t.pumpAndSettle();
    for (final k in ['cmd_ls', 'cmd_grep', 'cmd_pipe']) {
      expect(find.text(S.t(k)), findsWidgets, reason: k);
    }
  });
}
