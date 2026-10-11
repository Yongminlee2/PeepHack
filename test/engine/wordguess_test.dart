import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/wordguess.dart';

WordPuzzle small() => const WordPuzzle(
      words: ['CACHE', 'CATCH', 'PROXY', 'TOKEN'],
      answer: 'CATCH',
      attempts: 4,
      lines: [],
    );

void main() {
  test('일치 수 = 같은 자리 같은 글자', () {
    expect(likeness('CACHE', 'CATCH'), 2);
    expect(likeness('CATCH', 'CATCH'), 5);
    expect(likeness('PROXY', 'CATCH'), 0);
  });

  test('틀리면 기회가 줄고 일치 수가 기록된다, 맞히면 끝', () {
    final g = WordGame(small());
    expect(g.guess('CACHE'), 2);
    expect(g.left, 3);
    expect(g.log.single, ('CACHE', 2));
    expect(g.guess('CACHE'), isNull); // 같은 단어 두 번은 무시
    expect(g.left, 3);
    expect(g.guess('NOPE!'), isNull); // 후보가 아니면 무시
    expect(g.guess('CATCH'), 5);
    expect(g.solved, isTrue);
    expect(g.finished, isTrue);
    expect(g.guess('TOKEN'), isNull);
  });

  test('기회를 다 쓰면 실패', () {
    final g = WordGame(const WordPuzzle(words: ['AAAAA', 'BBBBB', 'CCCCC', 'DDDDD', 'EEEEE'], answer: 'EEEEE', attempts: 4, lines: []));
    for (final w in ['AAAAA', 'BBBBB', 'CCCCC', 'DDDDD']) {
      g.guess(w);
    }
    expect(g.failed, isTrue);
    expect(g.finished, isTrue);
  });

  test('괄호 보너스: 틀린 후보를 지우고, 더 지울 게 없으면 기회를 채운다, 한 괄호는 한 번만', () {
    final g = WordGame(small());
    g.guess('PROXY');
    final removed = g.useBracket(0);
    expect(removed, isNot('CATCH'));
    expect(g.removed, contains(removed));
    expect(g.useBracket(0), isNull); // 이미 씀
    expect(g.guess(removed!), isNull); // 지운 후보는 못 고른다
    // 남은 틀린 후보: CACHE·TOKEN 중 지워지지 않은 것 하나 — 그것도 지우면 다음엔 기회 리필
    g.useBracket(1);
    expect(g.useBracket(2), 'RESET');
    expect(g.left, 4);
  });

  group('생성기', () {
    test('같은 길이 후보, 정답 포함, 중복 없음, 덤프에 각 단어가 정확히 한 번', () {
      for (final len in [5, 6, 7]) {
        for (var seed = 0; seed < 40; seed++) {
          final p = generateWordPuzzle(length: len, count: 9, seed: seed);
          expect(p.words.length, 9);
          expect(p.words.toSet().length, 9);
          expect(p.words.every((w) => w.length == len && w == w.toUpperCase()), isTrue);
          expect(p.words, contains(p.answer));
          final tokens = [for (final l in p.lines) ...l];
          for (final w in p.words) {
            expect(tokens.where((t) => t.word == w).length, 1, reason: '$w 가 덤프에 한 번');
          }
          expect(tokens.where((t) => t.bracket != null).length, greaterThanOrEqualTo(3));
          final widths = p.lines.map((l) => l.map((t) => t.text).join().length).toSet();
          expect(widths.length, 1, reason: '줄 너비가 같다');
          final near = p.words.where((w) => w != p.answer && likeness(w, p.answer) > 0).length;
          expect(near, greaterThanOrEqualTo(4), reason: '추리할 거리(일치 1 이상 후보)가 있다');
        }
      }
    });
    test('같은 씨앗은 같은 퍼즐', () {
      final a = generateWordPuzzle(length: 6, count: 8, seed: 42);
      final b = generateWordPuzzle(length: 6, count: 8, seed: 42);
      expect(a.words, b.words);
      expect(a.answer, b.answer);
    });
  });
}
