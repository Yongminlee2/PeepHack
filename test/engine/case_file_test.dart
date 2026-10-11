import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/case_file.dart';
import 'package:hack_quest/engine/wordguess.dart';

const sample = '''
{"id":"c99","title":"@t","brief":["@b"],"done":["@d"],
 "docs":[{"name":"a.log","text":"raw"},{"name":"secret.txt","text":"@s","lock":{"length":6}}],
 "questions":[{"q":"@q1","options":["x","y","z"],"answer":1},{"q":"@q2","options":["p","q"],"answer":0}]}
''';

void main() {
  test('사건 파일 읽기', () {
    final c = CaseFile.parse(sample);
    expect(c.id, 'c99');
    expect(c.docs.length, 2);
    expect(c.docs[1].lockLength, 6);
    expect(c.docs[0].lockLength, isNull);
    expect(c.questions[0].answer, 1);
  });

  test('질문은 하나씩, 틀리면 오답이 쌓이고 다시 고른다, 별은 오답 0=3·1=2·2+=1', () {
    final g = CaseGame(CaseFile.parse(sample));
    expect(g.current!.q, '@q1');
    expect(g.answer(0), isFalse);
    expect(g.wrong, 1);
    expect(g.current!.q, '@q1'); // 그대로
    expect(g.answer(1), isTrue);
    expect(g.current!.q, '@q2');
    expect(g.answer(0), isTrue);
    expect(g.finished, isTrue);
    expect(g.current, isNull);
    expect(g.stars, 2);
    expect(CaseGame(CaseFile.parse(sample)).starsFor(0), 3);
    expect(CaseGame(CaseFile.parse(sample)).starsFor(5), 1);
  });

  test('잠긴 자료의 단어 퍼즐: 길이대로, 같은 사건·자료는 같은 퍼즐', () {
    final a = caseLockPuzzle('c99', 'secret.txt', 6);
    expect(a.words.first.length, 6);
    expect(a.words, caseLockPuzzle('c99', 'secret.txt', 6).words);
    expect(a, isA<WordPuzzle>());
  });

  test('실제 사건 6개: 읽히고, 정답이 선택지 안, 잠금 길이 5~7, 열쇠가 ko·en 에 다 있다', () {
    final ko = jsonDecode(File('i18n/ko.json').readAsStringSync()) as Map<String, dynamic>;
    final en = jsonDecode(File('i18n/en.json').readAsStringSync()) as Map<String, dynamic>;
    for (var i = 1; i <= kCaseCount; i++) {
      final id = 'c0$i';
      final raw = File('assets/cases/$id.json').readAsStringSync();
      final c = CaseFile.parse(raw);
      expect(c.id, id);
      expect(c.docs.length, greaterThanOrEqualTo(3), reason: '$id 자료');
      expect(c.questions.length, greaterThanOrEqualTo(2), reason: '$id 질문');
      for (final q in c.questions) {
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: '$id ${q.q}');
        expect(q.options.length, greaterThanOrEqualTo(2));
      }
      for (final d in c.docs) {
        if (d.lockLength != null) expect(d.lockLength, inInclusiveRange(5, 7));
      }
      final keys = RegExp(r'"@([a-z0-9_]+)"').allMatches(raw).map((m) => m.group(1)!);
      for (final k in keys) {
        expect(ko.containsKey(k), isTrue, reason: 'ko 에 없는 열쇠 $k');
        expect(en.containsKey(k), isTrue, reason: 'en 에 없는 열쇠 $k');
        expect(k.startsWith('${id}_'), isTrue, reason: '열쇠 접두어 $k');
      }
    }
  });
}
