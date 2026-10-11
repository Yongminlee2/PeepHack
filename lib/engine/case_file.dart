import 'dart:convert';

import 'hash.dart';
import 'wordguess.dart';

/// 사건 파일: 의뢰 + 자료(일부는 단어 추리로 잠김) + 결론 질문. Flutter 의존 없음.
const kCaseCount = 6;

class CaseDoc {
  final String name;
  final String text; // '@열쇠' 면 번역, 아니면 원문(로그)
  final int? lockLength; // 잠겼으면 단어 추리 길이
  const CaseDoc(this.name, this.text, this.lockLength);
}

class CaseQuestion {
  final String q;
  final List<String> options;
  final int answer;
  const CaseQuestion(this.q, this.options, this.answer);
}

class CaseFile {
  final String id, title;
  final List<String> brief, done;
  final List<CaseDoc> docs;
  final List<CaseQuestion> questions;
  const CaseFile(this.id, this.title, this.brief, this.done, this.docs, this.questions);

  static CaseFile parse(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    List<String> strs(Object? v) => List<String>.from((v as List?) ?? const []);
    return CaseFile(
      j['id'] as String,
      j['title'] as String,
      strs(j['brief']),
      strs(j['done']),
      [
        for (final d in j['docs'] as List)
          CaseDoc(d['name'] as String, d['text'] as String, (d['lock'] as Map?)?['length'] as int?),
      ],
      [
        for (final q in j['questions'] as List)
          CaseQuestion(q['q'] as String, strs(q['options']), q['answer'] as int),
      ],
    );
  }
}

class CaseGame {
  final CaseFile file;
  int index = 0;
  int wrong = 0;
  CaseGame(this.file);

  CaseQuestion? get current => index < file.questions.length ? file.questions[index] : null;
  bool get finished => current == null;

  /// 맞으면 다음 질문으로. 틀리면 오답 +1, 같은 질문 그대로.
  bool answer(int option) {
    final q = current;
    if (q == null) return false;
    if (option == q.answer) {
      index++;
      return true;
    }
    wrong++;
    return false;
  }

  int starsFor(int wrong) => wrong == 0 ? 3 : (wrong == 1 ? 2 : 1);
  int get stars => starsFor(wrong);
}

/// 잠긴 자료를 여는 단어 추리. 같은 사건·자료면 같은 퍼즐.
WordPuzzle caseLockPuzzle(String caseId, String docName, int length) =>
    generateWordPuzzle(length: length, count: 8, seed: stableHash('case/$caseId/$docName'));
