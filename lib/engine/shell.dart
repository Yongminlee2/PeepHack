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
  int _solutionIdx = 0;

  Shell(this.mission) {
    hostKey = mission.start;
    _connected.add(hostKey);
  }

  Host get host => mission.hosts[hostKey]!;
  /// 잠금을 풀었거나(비밀번호·퍼즐·크랙) ssh 로 들어간 적 있는 서버.
  bool isUnlocked(String key) => _unlockedHosts.contains(key);

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
      case 'find': return a.isEmpty ? _usage('find <name>') : _find(a[0]);
      case 'ssh': return _ssh(a);
      case 'head':
      case 'tail': return _headTail(cmd, a);
      case 'history': return _history();
      case 'git': return _git(a);
      case 'env': return _env();
      case 'crontab': return a.contains('-l') ? _cron() : _usage('crontab -l');
      case 'fix': return a.isEmpty ? _usage('fix <file>') : _fix(a[0]);
      case 'run': return a.isEmpty ? _usage('run <file>') : _runFile(a[0]);
      default: return _err('shell_err_unknown', {'cmd': cmd});
    }
  }

  /// `왼쪽 | grep 낱말` 만 지원한다. 왼쪽은 파일 창을 열지 않고 글만 쓴다.
  ShellResult _piped(String left, String right) {
    if (!mission.commands.contains('|')) return _err('shell_err_locked_cmd', {'cmd': '|'});
    final r = right.split(RegExp(r'\s+'));
    if (r.length != 2 || r[0] != 'grep') return _usage('... | grep <word>');
    final l = _run(left);
    if (l.isError || l.key == 'shell_password_prompt' || l.openPuzzle != null) return l;
    final src = l.fileText ?? l.text;
    final lines = src.split('\n').where((x) => x.contains(r[1])).toList();
    return lines.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: lines.join('\n'));
  }

  ShellResult _find(String name) {
    final out = <String>[];
    void walk(FsDir d, String prefix) {
      d.children.forEach((n, node) {
        final p = prefix == '/' ? '/$n' : '$prefix/$n';
        if (n.contains(name)) out.add(p);
        if (node is FsDir) walk(node, p);
      });
    }
    walk(host.fs, '/');
    out.sort();
    return out.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: out.join('\n'));
  }

  ShellResult _ssh(List<String> a) {
    if (a.isEmpty || !a[0].contains('@')) return _usage('ssh <user>@<host>');
    final at = a[0].indexOf('@');
    final user = a[0].substring(0, at);
    final name = a[0].substring(at + 1);
    final h = mission.hostByName(name);
    if (h == null) return _err('shell_err_no_host', {'host': name});
    if (h.user != null && h.user != user) return _err('shell_err_ssh_denied', {'user': user});
    final r = _connect(name, viaSsh: true);
    if (r.key == 'shell_connected') _unlockedHosts.add(h.key);
    return r;
  }

  ShellResult _headTail(String cmd, List<String> a) {
    var n = 10;
    final rest = <String>[];
    for (var i = 0; i < a.length; i++) {
      if (a[i] == '-n' && i + 1 < a.length) {
        n = int.tryParse(a[++i]) ?? 10;
      } else {
        rest.add(a[i]);
      }
    }
    if (rest.isEmpty) return _usage('$cmd -n <k> <file>');
    final r = _open(rest[0]);
    if (r.fileText == null) return r;
    final lines = r.fileText!.split('\n');
    final pick = cmd == 'head' ? lines.take(n) : lines.skip(lines.length > n ? lines.length - n : 0);
    return ShellResult(text: pick.join('\n'));
  }

  ShellResult _history() {
    final f = lookup(host.fs, '/.bash_history');
    if (f is! FsFile) return const ShellResult(key: 'shell_empty');
    return ShellResult(text: f.text);
  }

  ShellResult _git(List<String> a) {
    if (a.isEmpty) return _usage('git log | git diff <hash>');
    if (a[0] == 'log') {
      if (host.git.isEmpty) return const ShellResult(key: 'shell_empty');
      return ShellResult(text: host.git.map((c) => '${c.hash}  ${c.message}').join('\n'));
    }
    if (a[0] == 'diff' && a.length >= 2) {
      for (final c in host.git) {
        if (c.hash == a[1]) return ShellResult(text: c.diff);
      }
      return _err('shell_err_no_commit', {'hash': a[1]});
    }
    return _usage('git log | git diff <hash>');
  }

  ShellResult _env() => host.env.isEmpty
      ? const ShellResult(key: 'shell_empty')
      : ShellResult(text: host.env.entries.map((e) => '${e.key}=${e.value}').join('\n'));

  ShellResult _cron() =>
      host.cron.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: host.cron.join('\n'));

  Puzzle? _codefixFor(String arg) {
    final p = mission.puzzleForFile(hostKey, normalizePath(cwd, arg));
    return p?.type == 'codefix' ? p : null;
  }

  ShellResult _fix(String arg) {
    final p = _codefixFor(arg);
    if (p == null) return _err('shell_err_nothing_to_fix', {'path': arg});
    return ShellResult(openPuzzle: p.id);
  }

  ShellResult _runFile(String arg) {
    final p = _codefixFor(arg);
    if (p == null) return _err('shell_err_nothing_to_run', {'path': arg});
    if (!_solved.contains(p.id)) return ShellResult(text: p.data['failOutput'] as String? ?? 'error');
    _ran.add(joinHostPath(hostKey, normalizePath(cwd, arg)));
    return ShellResult(text: p.data['okOutput'] as String? ?? 'OK', key: 'shell_run_ok');
  }

  ShellResult _err(String key, [Map<String, Object> args = const {}]) => ShellResult(key: key, args: args);
  ShellResult _usage(String usage) => _err('shell_err_usage', {'usage': usage});

  ShellResult _scan() {
    final lines = mission.hosts.values.map((h) {
      final locked = h.lock != null && !_unlockedHosts.contains(h.key);
      return '${h.name}  ${locked ? 'LOCKED' : 'OK'}';
    });
    return ShellResult(text: lines.join('\n'));
  }

  ShellResult _connect(String name, {bool viaSsh = false}) {
    final h = mission.hostByName(name);
    if (h == null) return _err('shell_err_no_host', {'host': name});
    // 계정이 필요한 서버는 ssh 로만(크랙으로 연 뒤엔 그냥 들어간다)
    if (h.user != null && !viaSsh && !_unlockedHosts.contains(h.key)) return _err('shell_err_need_ssh', {'host': h.name});
    if (h.lock != null && !_unlockedHosts.contains(h.key)) {
      if (h.lock!.type == 'password') {
        _pendingHost = h.key;
        return const ShellResult(key: 'shell_password_prompt');
      }
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
    // 틀리면 대기를 푼다. 안 그러면 다음 명령까지 비밀번호로 먹혀서 빠져나갈 길이 없다.
    // 횟수 제한은 없다 — 다시 connect/cat 하면 또 묻는다.
    if (_pendingHost != null) {
      final h = mission.hosts[_pendingHost]!;
      if (line != h.lock!.answer) {
        _pendingHost = null;
        return _err('shell_err_wrong_password');
      }
      _unlockedHosts.add(h.key);
      _pendingHost = null;
      return _switchHost(h.key);
    }
    final path = _pendingFile!;
    final f = lookup(host.fs, path) as FsFile;
    if (line != f.lock!.answer) {
      _pendingFile = null;
      return _err('shell_err_wrong_password');
    }
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

  /// 포트 크랙 성공: 잠금을 풀고 그 서버로 들어간다. 잠금이 퍼즐이었으면 그 퍼즐도 푼 것으로 친다.
  ShellResult crack(String hostKey) {
    final h = mission.hosts[hostKey]!;
    _unlockedHosts.add(h.key);
    if (h.lock?.type == 'puzzle') _solved.add(h.lock!.puzzle!);
    _pendingHost = null;
    _switchHost(h.key);
    return ShellResult(key: 'shell_cracked', args: {'host': h.name});
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
    // 호스트 잠금 퍼즐이면 그 호스트로 들어간다. (창을 닫았다 다시 연 경우도 같은 길)
    if (p.file == null) {
      for (final h in mission.hosts.values) {
        if (h.lock?.puzzle == id) return _switchHost(h.key);
      }
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
      if (mission.commands.contains('ssh'))
        ...mission.hosts.values.where((h) => h.user != null).map((h) => '${h.user}@${h.name}'),
      if (mission.commands.contains('git')) ...['log', 'diff', ...host.git.map((c) => c.hash)],
      if (mission.commands.contains('crontab')) '-l',
      if (mission.commands.contains('head') || mission.commands.contains('tail')) '-n',
    ];
    return Suggestions(List.of(mission.commands), args);
  }
}
