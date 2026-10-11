import 'dart:math';

/// 단어 추리(폴아웃 단말기 해킹과 같은 규칙). Flutter 의존 없음.
///
/// 메모리 덤프 속 같은 길이의 후보 중 비밀번호를 고른다. 틀리면 「일치 n」(같은 자리 같은 글자 수).
/// 짝 맞는 괄호를 누르면 틀린 후보 하나가 지워지고, 지울 게 없으면 기회가 다시 찬다.
int likeness(String a, String b) {
  var n = 0;
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] == b[i]) n++;
  }
  return n;
}

/// 덤프 한 조각: 단어 / 괄호 보너스 / 그냥 기호.
class DumpToken {
  final String text;
  final String? word;
  final int? bracket;
  const DumpToken(this.text, {this.word, this.bracket});
}

class WordPuzzle {
  final List<String> words;
  final String answer;
  final int attempts;
  final List<List<DumpToken>> lines;
  const WordPuzzle({required this.words, required this.answer, required this.attempts, required this.lines});
}

class WordGame {
  final WordPuzzle puzzle;
  late int left = puzzle.attempts;
  final List<(String, int)> log = [];
  final Set<String> removed = {};
  final Set<int> _usedBrackets = {};
  bool solved = false;

  WordGame(this.puzzle);

  bool get failed => !solved && left <= 0;
  bool get finished => solved || failed;

  /// 일치 수를 돌려준다. 끝났거나·후보가 아니거나·지웠거나·이미 고른 단어면 null.
  int? guess(String w) {
    if (finished || !puzzle.words.contains(w) || removed.contains(w) || log.any((e) => e.$1 == w)) return null;
    final n = likeness(w, puzzle.answer);
    log.add((w, n));
    if (w == puzzle.answer) {
      solved = true;
    } else {
      left--;
    }
    return n;
  }

  /// 괄호 보너스. 지운 단어, 기회를 채웠으면 'RESET', 이미 썼거나 끝났으면 null.
  String? useBracket(int id) {
    if (finished || _usedBrackets.contains(id)) return null;
    _usedBrackets.add(id);
    for (final w in puzzle.words) {
      if (w != puzzle.answer && !removed.contains(w) && !log.any((e) => e.$1 == w)) {
        removed.add(w);
        return w;
      }
    }
    left = puzzle.attempts;
    return 'RESET';
  }

  bool bracketUsed(int id) => _usedBrackets.contains(id);
}

const _words = {
  5: ['ADMIN', 'ALERT', 'ARRAY', 'BLOCK', 'BYTES', 'CACHE', 'CATCH', 'CHAIN', 'CLASS', 'CLICK', 'CLOCK', 'CLOUD', 'CRASH',
    'DEBUG', 'ERROR', 'EVENT', 'FETCH', 'FIELD', 'FLASH', 'FRAME', 'GHOST', 'GRANT', 'GUARD', 'INDEX', 'INPUT', 'LAYER',
    'LINUX', 'LOGIN', 'MACRO', 'MERGE', 'MODEM', 'MOUSE', 'NODES', 'PANEL', 'PATCH', 'PIXEL', 'PORTS', 'PROXY', 'QUERY',
    'QUEUE', 'RESET', 'ROUTE', 'SCALE', 'SCOPE', 'SHELL', 'SLICE', 'SPOOF', 'STACK', 'STATE', 'TABLE', 'TOKEN', 'TRACE',
    'VIRUS', 'WATCH'],
  6: ['ACCESS', 'BINARY', 'BUFFER', 'BYPASS', 'CIPHER', 'CLIENT', 'CODING', 'COOKIE', 'CURSOR', 'DAEMON', 'DECODE', 'DELETE',
    'DOMAIN', 'ENCODE', 'EXPORT', 'FILTER', 'FOLDER', 'GLITCH', 'HACKER', 'HANDLE', 'HEADER', 'IMPORT', 'KERNEL', 'LAPTOP',
    'LEGACY', 'LOGOUT', 'MEMORY', 'MODULE', 'OBJECT', 'OUTPUT', 'PACKET', 'PARSER', 'PLUGIN', 'PORTAL', 'RANDOM', 'RECORD',
    'REMOTE', 'ROUTER', 'SCRIPT', 'SECRET', 'SERVER', 'SIGNAL', 'SOCKET', 'SOURCE', 'STATUS', 'SWITCH', 'SYNTAX', 'SYSTEM',
    'TARGET', 'THREAD', 'TUNNEL', 'UPDATE', 'UPLOAD', 'VECTOR', 'WIDGET'],
  7: ['ACCOUNT', 'ADDRESS', 'BACKUPS', 'BOOTING', 'BROWSER', 'CAPTURE', 'CHANNEL', 'CHECKER', 'COMMAND', 'COMPILE', 'CONSOLE',
    'CONTENT', 'CONTROL', 'CRACKER', 'DECRYPT', 'DEFAULT', 'DESKTOP', 'DEVICES', 'DISPLAY', 'ENCRYPT', 'GATEWAY', 'HACKING',
    'INSTALL', 'KEYWORD', 'LIBRARY', 'MALWARE', 'MONITOR', 'NETWORK', 'OVERRUN', 'PAYLOAD', 'PHANTOM', 'PROCESS', 'PROGRAM',
    'PROTECT', 'RECOVER', 'REFRESH', 'REQUEST', 'RESTORE', 'ROUTING', 'RUNTIME', 'SANDBOX', 'SCANNER', 'SESSION', 'SPYWARE',
    'STORAGE', 'SUPPORT', 'SYSTEMS', 'TRACING', 'TROJANS', 'UPGRADE', 'VERSION', 'WARNING'],
};

const _junk = r'!@#$%^&*-_=+;:,.?/|\~';
const _pairs = [('(', ')'), ('[', ']'), ('{', '}'), ('<', '>')];

/// 씨앗이 같으면 같은 퍼즐. 후보의 반 이상은 정답과 일치 1 이상.
WordPuzzle generateWordPuzzle({required int length, required int count, required int seed, int attempts = 4, int brackets = 3}) {
  final rnd = Random(seed);
  final pool = _words[length]!;
  while (true) {
    final answer = pool[rnd.nextInt(pool.length)];
    final others = [...pool]..remove(answer)..shuffle(rnd);
    final near = others.where((w) => likeness(w, answer) > 0).toList();
    final far = others.where((w) => likeness(w, answer) == 0).toList();
    final wantNear = (count - 1) * 2 ~/ 3;
    if (near.length < wantNear) continue;
    final words = [answer, ...near.take(wantNear), ...[...near.skip(wantNear), ...far].take(count - 1 - wantNear)]..shuffle(rnd);
    if (words.length != count) continue;
    return WordPuzzle(words: words, answer: answer, attempts: attempts, lines: _dump(rnd, words, brackets));
  }
}

List<List<DumpToken>> _dump(Random rnd, List<String> words, int brackets) {
  const width = 16;
  final n = max(14, words.length + brackets + 2);
  final rows = List.generate(n, (i) => i)..shuffle(rnd);
  String junk(int k) => String.fromCharCodes(List.generate(k, (_) => _junk.codeUnitAt(rnd.nextInt(_junk.length))));
  final lines = List<List<DumpToken>>.generate(n, (_) => [DumpToken(junk(width))]);
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final at = rnd.nextInt(width - w.length + 1);
    lines[rows[i]] = [DumpToken(junk(at)), DumpToken(w, word: w), DumpToken(junk(width - at - w.length))];
  }
  for (var b = 0; b < brackets; b++) {
    final (o, c) = _pairs[rnd.nextInt(_pairs.length)];
    final inner = junk(rnd.nextInt(3));
    final text = '$o$inner$c';
    final at = rnd.nextInt(width - text.length + 1);
    lines[rows[words.length + b]] = [DumpToken(junk(at)), DumpToken(text, bracket: b), DumpToken(junk(width - at - text.length))];
  }
  return lines;
}
