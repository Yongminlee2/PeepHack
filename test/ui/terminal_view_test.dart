import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/fx/fx.dart';
import 'package:hack_quest/ui/readable_text.dart';
import 'package:hack_quest/ui/terminal_view.dart';
import 'package:hack_quest/ui/theme.dart';

void main() {
  testWidgets('새 줄은 한 글자씩 찍히고(연출 켬), 이미 찍힌 줄은 그대로', (t) async {
    Fx.animate = true;
    addTearDown(() => Fx.animate = false);
    final lines = [const TermLine('OLD LINE')];
    Widget view() => MaterialApp(home: Scaffold(body: TerminalView(lines: List.of(lines))));
    await t.pumpWidget(view());
    await t.pump(const Duration(seconds: 1));
    expect(find.text('OLD LINE'), findsOneWidget);
    lines.add(const TermLine('HELLO WORLD FROM GHOST'));
    await t.pumpWidget(view());
    await t.pump(const Duration(milliseconds: 30));
    expect(find.text('HELLO WORLD FROM GHOST'), findsNothing); // 아직 찍는 중
    expect(find.text('OLD LINE'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    expect(find.text('HELLO WORLD FROM GHOST'), findsOneWidget);
  });

  testWidgets('연출을 끄면(테스트 기본) 바로 다 보인다', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: TerminalView(lines: [TermLine('AT ONCE')]))));
    expect(find.text('AT ONCE'), findsOneWidget);
  });
  testWidgets('읽기 쉽게: 안내는 밝은 글씨·넓은 줄 간격, 출력은 왼쪽 선으로 묶고, 오류는 ✗', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: TerminalView(lines: [
      TermLine('ls', isCmd: true),
      TermLine('notes.txt\nlogs/', isData: true),
      TermLine('cafe-pc 에 접속했습니다'),
      TermLine('파일이 없습니다', isError: true),
    ]))));
    final msg = t.widget<Text>(find.text('cafe-pc 에 접속했습니다'));
    expect(msg.style!.color, hqText);
    expect(msg.style!.fontSize, greaterThanOrEqualTo(15));
    expect(msg.style!.height, greaterThanOrEqualTo(1.4));
    expect(find.byKey(const Key('term_data')), findsOneWidget); // 출력 묶음
    expect(find.text('✗ 파일이 없습니다'), findsOneWidget);
  });

  testWidgets('읽기 블록: 한글 글은 밝은 글씨로 줄을 바꾸고, 영문 기록은 꺾지 않고 크기를 맞춘다', (t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: ReadableText('안녕, 신입. 나는 고스트.'))));
    expect(t.widget<SelectableText>(find.byType(SelectableText)).style!.color, hqText);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: ReadableText(
        '10-12 21:49 export  coupon_list.csv  acct=A-105 ip=172.16.4.9\n10-12 21:58 view coupon_list'))));
    final log = t.widget<SelectableText>(find.byType(SelectableText));
    expect(log.style!.fontFamily, kMono);
    expect(log.style!.fontSize, lessThan(15));
    expect(find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal), findsOneWidget);
  });
}
