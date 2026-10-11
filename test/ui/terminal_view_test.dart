import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/fx/fx.dart';
import 'package:hack_quest/ui/terminal_view.dart';

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
}
