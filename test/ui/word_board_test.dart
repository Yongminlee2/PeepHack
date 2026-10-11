import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/wordguess.dart';
import 'package:hack_quest/strings.dart';
import 'package:hack_quest/ui/wordguess/word_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrap(WordPuzzle p, void Function(bool) onFinish) =>
    MaterialApp(home: Scaffold(body: WordBoard(puzzle: p, onFinish: onFinish)));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLang().set('ko');
  });

  testWidgets('틀리면 일치 수가 뜨고, 정답을 누르면 성공으로 끝난다', (t) async {
    final p = generateWordPuzzle(length: 5, count: 8, seed: 3);
    bool? result;
    await t.pumpWidget(wrap(p, (ok) => result = ok));
    final wrong = p.words.firstWhere((w) => w != p.answer);
    await t.ensureVisible(find.byKey(Key('word_$wrong')));
    await t.tap(find.byKey(Key('word_$wrong')));
    await t.pump();
    expect(find.textContaining(S.tn('wg_likeness', {'n': likeness(wrong, p.answer)})), findsOneWidget);
    expect(result, isNull);
    await t.ensureVisible(find.byKey(Key('word_${p.answer}')));
    await t.tap(find.byKey(Key('word_${p.answer}')));
    await t.pump();
    expect(result, isTrue);
  });

  testWidgets('기회를 다 쓰면 실패로 끝난다', (t) async {
    final p = generateWordPuzzle(length: 6, count: 9, seed: 5);
    bool? result;
    await t.pumpWidget(wrap(p, (ok) => result = ok));
    for (final w in p.words.where((w) => w != p.answer).take(4)) {
      await t.ensureVisible(find.byKey(Key('word_$w')));
      await t.tap(find.byKey(Key('word_$w')));
      await t.pump();
    }
    expect(result, isFalse);
  });

  testWidgets('괄호를 누르면 틀린 후보 하나가 지워져 누를 수 없게 된다', (t) async {
    final p = generateWordPuzzle(length: 5, count: 8, seed: 9);
    await t.pumpWidget(wrap(p, (_) {}));
    await t.ensureVisible(find.byKey(const Key('bracket_0')));
    await t.tap(find.byKey(const Key('bracket_0')));
    await t.pump();
    final gone = p.words.where((w) => find.byKey(Key('word_$w')).evaluate().isEmpty).toList();
    expect(gone.length, 1);
    expect(gone.single, isNot(p.answer));
  });
  testWidgets('세로 폰: 덤프가 화면 폭을 채우고, 기록은 덤프 바로 아래에 뜬다', (t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final p = generateWordPuzzle(length: 5, count: 8, seed: 3);
    await t.pumpWidget(wrap(p, (_) {}));
    final line = t.getRect(find.byKey(const Key('dump_0')));
    expect(line.width, greaterThan(412 * 0.85));
    final wrong = p.words.firstWhere((w) => w != p.answer);
    await t.ensureVisible(find.byKey(Key('word_$wrong')));
    await t.tap(find.byKey(Key('word_$wrong')));
    await t.pump();
    final last = t.getRect(find.byKey(Key('dump_${p.lines.length - 1}')));
    final note = t.getRect(find.text('> $wrong'));
    expect(note.top, greaterThanOrEqualTo(last.bottom));
    expect(note.top - last.bottom, lessThan(80));
  });
}
