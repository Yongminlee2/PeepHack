import 'mission.dart';

/// 퍼즐 정답 판정. 화면은 이 함수만 부른다.
bool checkAnswer(Puzzle p, Object answer) {
  switch (p.type) {
    case 'match':
      final want = _pairSet(p.answer);
      final got = _pairSet(answer);
      return want.length == got.length && want.containsAll(got);
    case 'password':
      return (answer as String).trim() == (p.answer as String);
    case 'order':
      final want = List<int>.from(p.answer as List);
      final got = List<int>.from(answer as List);
      if (want.length != got.length) return false;
      for (var i = 0; i < want.length; i++) {
        if (want[i] != got[i]) return false;
      }
      return true;
    case 'codefix':
      final got = answer as Map;
      for (final b in _bugs(p)) {
        if (got[b['line']] != b['answer']) return false;
      }
      return true;
  }
  return false;
}

Set<String> _pairSet(Object v) =>
    {for (final pair in v as List) '${(pair as List)[0]}-${pair[1]}'};

List<Map> _bugs(Puzzle p) => List<Map>.from(p.data['bugs'] as List);

/// 정답을 data 만으로 만들 수 있는가. `missions_test` 가 쓴다.
bool answerBuildable(Puzzle p) {
  switch (p.type) {
    case 'match':
      final l = (p.data['left'] as List).length;
      final r = (p.data['right'] as List).length;
      final usedL = <int>{};
      for (final pair in p.answer as List) {
        final a = (pair as List)[0] as int;
        final b = pair[1] as int;
        if (a < 0 || a >= l || b < 0 || b >= r || !usedL.add(a)) return false;
      }
      return usedL.length == l;
    case 'password':
      return _buildable(p.answer as String, List<String>.from(p.data['fragments'] as List));
    case 'order':
      final n = (p.data['items'] as List).length;
      final got = List<int>.from(p.answer as List);
      return got.length == n && got.toSet().length == n && got.every((i) => i >= 0 && i < n);
    case 'codefix':
      final n = (p.data['lines'] as List).length;
      return _bugs(p).every((b) =>
          (b['line'] as int) < n && List<String>.from(b['choices'] as List).contains(b['answer']));
  }
  return false;
}

/// 조각을 각각 한 번씩만 써서 answer 를 이어 만들 수 있는가.
bool _buildable(String rest, List<String> frags) {
  if (rest.isEmpty) return true;
  for (var i = 0; i < frags.length; i++) {
    if (rest.startsWith(frags[i])) {
      final left = [...frags]..removeAt(i);
      if (_buildable(rest.substring(frags[i].length), left)) return true;
    }
  }
  return false;
}

/// `decode` 명령. 모르는 방식이면 원문 그대로.
String decodeText(String text, String encode) {
  if (encode == 'reverse') return text.split('').reversed.join();
  if (encode.startsWith('caesar:')) {
    final k = int.parse(encode.substring(7));
    return String.fromCharCodes(text.runes.map((c) {
      if (c >= 97 && c <= 122) return 97 + (c - 97 - k + 26) % 26;
      if (c >= 65 && c <= 90) return 65 + (c - 65 - k + 26) % 26;
      return c;
    }));
  }
  return text;
}
