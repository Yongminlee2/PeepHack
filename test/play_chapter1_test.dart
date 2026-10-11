import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/mission_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 챕터 1 을 실제 화면으로 끝까지 누른다. 칩·비밀번호 입력·퍼즐 위젯·완료 전환까지.
/// 엔진 검사(missions_test)가 못 보는 "화면 배선" 을 본다.
// 멈추면 10분 기다리지 말고 10초에 실패한다.
Future<void> settle(WidgetTester t) =>
    t.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

void main() {
  setUp(() async {
    // 앞 테스트의 가짜 시간 영역에서 만든 자산 캐시를 기다리면 영원히 안 끝난다.
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('en');
  });

  Future<void> tapKey(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    expect(f, findsOneWidget, reason: '없음: $key');
    await t.ensureVisible(f);
    await settle(t);
    await t.tap(f);
    await settle(t);
  }

  bool passwordMode(WidgetTester t) =>
      t.widget<TextField>(find.byKey(const Key('input_field'))).obscureText;

  Future<void> typeLine(WidgetTester t, String line) async {
    if (passwordMode(t)) {
      await t.enterText(find.byKey(const Key('input_field')), line);
    } else {
      for (final tok in line.split(' ')) {
        await tapKey(t, 'chip_$tok');
      }
    }
    await tapKey(t, 'run_btn');
  }

  Future<void> dragTo(WidgetTester t, String text, int from, int to) async {
    final h = t.getSize(find.ancestor(of: find.text(text), matching: find.byType(ListTile)).first).height;
    final g = await t.startGesture(t.getCenter(find.text(text)));
    await t.pump(const Duration(seconds: 1));
    final steps = 10;
    final dy = (to - from) * h + (to > from ? h * 0.1 : -h * 0.1); // 칸 중심까지, 반 칸 넘기면 한 칸 더 간다
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(0, dy / steps));
      await t.pump(const Duration(milliseconds: 50));
    }
    await g.up();
    await settle(t);
  }

  Future<void> solvePuzzle(WidgetTester t, Puzzle p) async {
    switch (p.type) {
      case 'match':
        for (final pair in p.answer as List) {
          await tapKey(t, 'left_${(pair as List)[0]}');
          await tapKey(t, 'right_${pair[1]}');
        }
      case 'password':
        var rest = p.answer as String;
        final frags = List<String>.from(p.data['fragments'] as List);
        final used = <int>{};
        while (rest.isNotEmpty) {
          final i = List.generate(frags.length, (i) => i)
              .firstWhere((i) => !used.contains(i) && rest.startsWith(frags[i]));
          used.add(i);
          rest = rest.substring(frags[i].length);
          await tapKey(t, 'frag_$i');
        }
      case 'order':
        final items = List<String>.from(p.data['items'] as List);
        final want = List<int>.from(p.answer as List);
        var cur = List.generate(items.length, (i) => i);
        for (var k = 0; k < want.length; k++) {
          final from = cur.indexOf(want[k]);
          if (from == k) continue;
          await dragTo(t, items[want[k]], from, k);
          cur.insert(k, cur.removeAt(from));
        }
    }
    await tapKey(t, 'puzzle_submit');
  }

  for (var n = 1; n <= 6; n++) {
    final id = 'm1_0$n';
    testWidgets('$id 를 화면으로 끝까지', (t) async {
      final catalog = await Catalog.load();
      final progress = await Progress.load();
      final m = catalog.byId(id)!;
      await t.pumpWidget(MaterialApp(home: MissionScreen(mission: m, progress: progress, catalog: catalog)));
      await settle(t);
      for (final step in m.solution) {
        if (step is PuzzleStep) {
          expect(find.byKey(const Key('puzzle_submit')), findsOneWidget, reason: '퍼즐 창이 안 떴다: ${step.puzzle}');
          await solvePuzzle(t, m.puzzleById(step.puzzle)!);
        } else {
          await typeLine(t, step as String);
        }
      }
      await settle(t);
      // 목표 파일을 열었으면 내용을 먼저 보여 주고, 닫을 때 완료로 넘어간다.
      final last = m.solution.last;
      if (last is String && last.startsWith('open ')) {
        expect(find.byKey(const Key('file_view')), findsOneWidget, reason: '목표 파일 내용이 안 보인다');
      }
      if (find.byKey(const Key('file_view')).evaluate().isNotEmpty) {
        expect(find.byType(MissionScreen), findsOneWidget, reason: '파일을 보기도 전에 완료로 넘어갔다');
        await tapKey(t, 'file_finish'); // 아래쪽 큰 「임무 완료」 버튼
      }
      expect(find.text(S.t('result_title')), findsOneWidget, reason: '완료 화면으로 안 넘어갔다');
      expect(progress.stars(id), 3);
    });
  }
  testWidgets('파일 창이 열린 채로 친 명령의 결과가 보인다', (t) async {
    final catalog = await Catalog.load();
    final progress = await Progress.load();
    final m = catalog.byId('m1_02')!;
    await t.pumpWidget(MaterialApp(home: MissionScreen(mission: m, progress: progress, catalog: catalog)));
    await settle(t);
    await typeLine(t, 'open note.txt');
    expect(find.byKey(const Key('file_view')), findsOneWidget);
    expect(find.byKey(const Key('file_finish')), findsNothing); // 목표 전엔 완료 버튼 없음
    expect(find.text(S.t('m1_02_f_note')), findsOneWidget); // 열쇠가 아니라 번역된 글
    expect(find.textContaining('@m1_02'), findsNothing);
    await typeLine(t, 'scan');
    expect(find.byKey(const Key('file_view')), findsNothing);
    expect(find.textContaining('vault-box  LOCKED'), findsOneWidget);
    // 앞서 연 파일 내용도 터미널 기록에 남는다(창을 닫아도 다시 볼 수 있게)
    expect(find.textContaining(S.t('m1_02_f_note')), findsOneWidget);
  });
}
