import 'mission.dart';
import 'paths.dart';
import 'puzzles.dart';

/// 명령 → 처음 등장하는 챕터. 설계 문서 4절 표.
const Map<String, int> kCommandChapter = {
  'scan': 1, 'connect': 1, 'open': 1, 'decode': 1, 'back': 1,
  'ls': 2, 'cd': 2, 'pwd': 2, 'cat': 2, 'grep': 2,
  'find': 3, 'ssh': 3, 'head': 3, 'tail': 3, '|': 3, 'history': 3,
  'git': 4, 'env': 4, 'crontab': 4, 'fix': 4, 'run': 4,
};

class ShellResult {
  final String text; // 원문 출력 (번역 안 함)
  final String? key; // 번역 열쇠 (오류는 shell_err_ 로 시작)
  final Map<String, Object> args;
  final String? openFile; // 파일 창에 띄울 절대 경로
  final String? fileText; // 그 파일의 (풀린) 내용
  final String? openPuzzle; // 퍼즐 창에 띄울 퍼즐 id
  const ShellResult({
    this.text = '', this.key, this.args = const {},
    this.openFile, this.fileText, this.openPuzzle,
  });
  bool get isError => key?.startsWith('shell_err_') ?? false;
}

class Suggestions {
  final List<String> commands;
  final List<String> args;
  Suggestions(this.commands, this.args);
}

class Shell {
  final Mission mission;
  late String hostKey;
  String cwd = '/';
  final Set<String> _unlockedHosts = {};
  final Set<String> _unlockedFiles = {}; // "host:/path"
  final Set<String> _read = {};
  final Set<String> _solved = {};
  final Set<String> _connected = {};
  final Set<String> _ran = {};
  final Set<String> _revealed = {}; // ls -a 한 폴더 "host:/dir"
  final List<String> history = [];
  String? _pendingHost; // 비밀번호 대기 중인 호스트 key
  String? _pendingFile; // 비밀번호 대기 중인 파일 절대 경로
  String? _puzzleHost; // 퍼즐 창이 뜬 원인이 호스트 잠금이면 그 key
  int _solutionIdx = 0;

  Shell(this.mission) {
    hostKey = mission.start;
    _connected.add(hostKey);
  }

  Host get host => mission.hosts[hostKey]!;
  bool get awaitingPassword => _pendingHost != null || _pendingFile != null;
  GoalState get state => GoalState(read: _read, solved: _solved, connected: _connected, ran: _ran);
  bool get goalDone => mission.goal.check(state);

  /// 정답 경로에서 아직 안 한 첫 줄. 힌트 3 용.
  String? nextSolutionLine() {
    if (_solutionIdx >= mission.solution.length) return null;
    final s = mission.solution[_solutionIdx];
    return s is String ? s : 'puzzle ${(s as PuzzleStep).puzzle}';
  }

  // ponytail: 정답 경로 추적은 "다음 줄과 똑같으면 전진" 뿐이다. 다른 순서로 풀면
  // 힌트 3 이 이미 한 일을 가리킬 수 있다. 문제 되면 goal 상태로 건너뛰기 추가.
  void _advance(Object step) {
    if (_solutionIdx >= mission.solution.length) return;
    final want = mission.solution[_solutionIdx];
    final same = (want is String && step is String && want == step) ||
        (want is PuzzleStep && step is PuzzleStep && want.puzzle == step.puzzle);
    if (same) _solutionIdx++;
  }

  ShellResult run(String rawLine) {
    final line = rawLine.trim();
    final r = _run(line);
    if (!r.isError) _advance(line);
    return r;
  }

  ShellResult _run(String line) {
    if (_pendingHost != null || _pendingFile != null) return _password(line);
    if (line.isEmpty) return const ShellResult();
    history.add(line);
    final pipe = line.indexOf('|');
    if (pipe >= 0) return _piped(line.substring(0, pipe).trim(), line.substring(pipe + 1).trim());
    final parts = line.split(RegExp(r'\s+'));
    final cmd = parts.first;
    final a = parts.sublist(1);
    if (!kCommandChapter.containsKey(cmd)) return _err('shell_err_unknown', {'cmd': cmd});
    if (!mission.commands.contains(cmd)) return _err('shell_err_locked_cmd', {'cmd': cmd});
    switch (cmd) {
      case 'scan': return _scan();
      case 'connect': return a.isEmpty ? _usage('connect <host>') : _connect(a[0]);
      case 'back': return _switchHost(mission.start);
      case 'open':
      case 'cat': return a.isEmpty ? _usage('$cmd <file>') : _open(a[0]);
      case 'decode': return a.isEmpty ? _usage('decode <file>') : _open(a[0], decode: true);
      case 'ls': return _ls(a);
      case 'cd': return _cd(a.isEmpty ? '/' : a[0]);
      case 'pwd': return ShellResult(text: cwd);
      case 'grep': return a.length < 2 ? _usage('grep <word> <file>') : _grep(a[0], a[1]);
      default: return _notYet(cmd, a);
    }
  }

  // Task 6 에서 채운다.
  ShellResult _notYet(String cmd, List<String> a) => _err('shell_err_unknown', {'cmd': cmd});
  ShellResult _piped(String left, String right) => _err('shell_err_unknown', {'cmd': '|'});

  ShellResult _err(String key, [Map<String, Object> args = const {}]) => ShellResult(key: key, args: args);
  ShellResult _usage(String usage) => _err('shell_err_usage', {'usage': usage});

  ShellResult _scan() {
    final lines = mission.hosts.values.map((h) {
      final locked = h.lock != null && !_unlockedHosts.contains(h.key);
      return '${h.name}  ${locked ? 'LOCKED' : 'open'}';
    });
    return ShellResult(text: lines.join('\n'));
  }

  ShellResult _connect(String name) {
    final h = mission.hostByName(name);
    if (h == null) return _err('shell_err_no_host', {'host': name});
    if (h.lock != null && !_unlockedHosts.contains(h.key)) {
      if (h.lock!.type == 'password') {
        _pendingHost = h.key;
        return const ShellResult(key: 'shell_password_prompt');
      }
      _puzzleHost = h.key;
      return ShellResult(openPuzzle: h.lock!.puzzle);
    }
    return _switchHost(h.key);
  }

  ShellResult _switchHost(String key) {
    hostKey = key;
    cwd = '/';
    _connected.add(key);
    return ShellResult(key: 'shell_connected', args: {'host': host.name});
  }

  ShellResult _password(String line) {
    if (_pendingHost != null) {
      final h = mission.hosts[_pendingHost]!;
      if (line != h.lock!.answer) return _err('shell_err_wrong_password');
      _unlockedHosts.add(h.key);
      _pendingHost = null;
      return _switchHost(h.key);
    }
    final path = _pendingFile!;
    final f = lookup(host.fs, path) as FsFile;
    if (line != f.lock!.answer) return _err('shell_err_wrong_password');
    _unlockedFiles.add(joinHostPath(hostKey, path));
    _pendingFile = null;
    return _open(path);
  }

  /// 파일을 연다. 잠금·퍼즐이 있으면 그쪽으로 보내고, 아니면 내용을 돌려준다.
  ShellResult _open(String arg, {bool decode = false}) {
    final path = normalizePath(cwd, arg);
    final node = lookup(host.fs, path);
    if (node == null) return _err('shell_err_no_file', {'path': arg});
    if (node is FsDir) return _err('shell_err_is_dir', {'path': arg});
    final f = node as FsFile;
    final hp = joinHostPath(hostKey, path);
    if (f.lock != null && !_unlockedFiles.contains(hp)) {
      _pendingFile = path;
      return const ShellResult(key: 'shell_password_prompt');
    }
    final pz = mission.puzzleForFile(hostKey, path);
    if (pz != null && pz.type != 'codefix' && !_solved.contains(pz.id)) {
      return ShellResult(openPuzzle: pz.id);
    }
    if (decode && f.encode == null) return _err('shell_err_not_encoded');
    final text = decode ? decodeText(f.text, f.encode!) : f.text;
    _read.add(hp);
    return ShellResult(text: text, openFile: path, fileText: text);
  }

  ShellResult _ls(List<String> a) {
    final all = a.contains('-a');
    final target = a.where((x) => !x.startsWith('-')).toList();
    final path = target.isEmpty ? cwd : normalizePath(cwd, target[0]);
    final node = lookup(host.fs, path);
    if (node is! FsDir) return _err('shell_err_no_dir', {'path': target.isEmpty ? cwd : target[0]});
    if (all) _revealed.add(joinHostPath(hostKey, path));
    final names = node.children.keys.where((n) => all || !n.startsWith('.')).toList()..sort();
    final lines = names.map((n) => node.children[n] is FsDir ? '$n/' : n);
    return lines.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: lines.join('\n'));
  }

  ShellResult _cd(String arg) {
    final path = normalizePath(cwd, arg);
    if (lookup(host.fs, path) is! FsDir) return _err('shell_err_no_dir', {'path': arg});
    cwd = path;
    return const ShellResult();
  }

  ShellResult _grep(String word, String file) {
    final r = _open(file);
    if (r.fileText == null) return r; // 오류·잠금·퍼즐 그대로
    final lines = r.fileText!.split('\n').where((l) => l.contains(word)).toList();
    return lines.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: lines.join('\n'));
  }

  /// 퍼즐 창에서 「확인」. 맞으면 잠금 해제 → 호스트 접속 또는 파일 열기.
  ShellResult submitPuzzle(String id, Object answer) {
    final p = mission.puzzleById(id)!;
    if (!checkAnswer(p, answer)) return const ShellResult(key: 'puzzle_wrong');
    _solved.add(id);
    _advance(PuzzleStep(id));
    for (final h in mission.hosts.values) {
      if (h.lock?.puzzle == id) _unlockedHosts.add(h.key);
    }
    if (_puzzleHost != null) {
      final k = _puzzleHost!;
      _puzzleHost = null;
      return _switchHost(k);
    }
    if (p.file != null && p.type != 'codefix') {
      final i = p.file!.indexOf(':');
      final hk = p.file!.substring(0, i);
      final path = p.file!.substring(i + 1);
      if (hk == hostKey) return _open(path);
    }
    return const ShellResult(key: 'puzzle_solved');
  }

  Suggestions suggestions() {
    final dir = lookup(host.fs, cwd) as FsDir;
    final showHidden = _revealed.contains(joinHostPath(hostKey, cwd));
    final args = <String>[
      ...dir.children.keys.where((n) => showHidden || !n.startsWith('.')),
      '..',
      ...mission.hosts.values.map((h) => h.name),
      ...mission.words,
      if (mission.commands.contains('ls')) '-a',
    ];
    return Suggestions(List.of(mission.commands), args);
  }
}
