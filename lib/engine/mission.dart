import 'dart:convert';

import 'trace.dart';

/// 임무 JSON 모델. Flutter 의존 없음. 형식은 설계 문서 3절.
class Mission {
  final String id;
  final int chapter;
  final String title;
  final List<String> brief;
  final List<String> done;
  final String input; // 'chips' | 'keyboard'
  final List<String> commands;
  final List<String> words;
  final Map<String, Host> hosts;
  final String start;
  final List<Puzzle> puzzles;
  final Goal goal;
  final List<String> hints;
  final List<Object> solution; // String | PuzzleStep
  final int? _trace;

  Mission({
    required this.id, required this.chapter, required this.title,
    required this.brief, required this.done, required this.input,
    required this.commands, required this.words, required this.hosts,
    required this.start, required this.puzzles, required this.goal,
    required this.hints, required this.solution, int? trace,
  }) : _trace = trace;

  /// 추적 한도(초). 0 이면 추적 없음. JSON 에 없으면 챕터 기본값.
  int get trace => _trace ?? defaultTrace(chapter);

  /// 이 서버를 크랙할 때 뚫어야 하는 포트 수.
  int portsFor(Host h) => h.ports ?? defaultPorts(chapter);

  static Mission parse(String jsonText) =>
      Mission.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'] as String,
        chapter: j['chapter'] as int,
        title: j['title'] as String? ?? '',
        brief: _strs(j['brief']),
        done: _strs(j['done']),
        input: j['input'] as String? ?? 'chips',
        commands: _strs(j['commands']),
        words: _strs(j['words']),
        hosts: (j['hosts'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, Host.fromJson(k, v as Map<String, dynamic>))),
        start: j['start'] as String? ?? 'home',
        puzzles: [
          for (final p in (j['puzzles'] as List?) ?? const [])
            Puzzle.fromJson(p as Map<String, dynamic>)
        ],
        goal: Goal.fromJson(j['goal'] as Map<String, dynamic>),
        hints: _strs(j['hints']),
        trace: j['trace'] as int?,
        solution: [
          for (final s in j['solution'] as List)
            s is String ? s : PuzzleStep((s as Map)['puzzle'] as String)
        ],
      );

  Host? hostByName(String name) {
    for (final h in hosts.values) {
      if (h.key == name || h.name == name) return h;
    }
    return null;
  }

  Puzzle? puzzleById(String id) {
    for (final p in puzzles) {
      if (p.id == id) return p;
    }
    return null;
  }

  Puzzle? puzzleForFile(String hostKey, String absPath) {
    final want = '$hostKey:$absPath';
    for (final p in puzzles) {
      if (p.file == want) return p;
    }
    return null;
  }
}

/// 빈 `{}` 처럼 형이 덜 정해진 맵도 받는다(손으로 만든 데이터·테스트).
Map<String, dynamic> _map(Object? v) => v == null ? const {} : Map<String, dynamic>.from(v as Map);

List<String> _strs(Object? v) => v == null ? const [] : List<String>.from(v as List);

class PuzzleStep {
  final String puzzle;
  const PuzzleStep(this.puzzle);
}

class Host {
  final String key;
  final String name;
  final Lock? lock;
  final FsDir fs;
  final String? user;
  final List<Commit> git;
  final Map<String, String> env;
  final List<String> cron;
  final int? ports;

  /// 잠금이 있거나 계정(ssh)이 필요한 서버 — 지도에서 크랙할 수 있다.
  bool get isProtected => lock != null || user != null;

  Host({
    required this.key, required this.name, this.lock, required this.fs,
    this.user, this.git = const [], this.env = const {}, this.cron = const [], this.ports,
  });

  factory Host.fromJson(String key, Map<String, dynamic> j) => Host(
        key: key,
        name: j['name'] as String? ?? key,
        lock: j['lock'] == null ? null : Lock.fromJson(j['lock'] as Map<String, dynamic>),
        fs: FsDir.fromJson(_map(j['fs'])),
        user: j['user'] as String?,
        git: [
          for (final c in (j['git'] as List?) ?? const [])
            Commit(
              hash: (c as Map)['hash'] as String,
              message: c['message'] as String,
              diff: c['diff'] as String? ?? '',
            )
        ],
        env: Map<String, String>.from((j['env'] as Map?) ?? const {}),
        cron: _strs(j['cron']),
        ports: j['ports'] as int?,
      );
}

class Lock {
  final String type; // 'password' | 'puzzle'
  final String? answer;
  final String? puzzle;
  Lock({required this.type, this.answer, this.puzzle});
  factory Lock.fromJson(Map<String, dynamic> j) => Lock(
        type: j['type'] as String,
        answer: j['answer'] as String?,
        puzzle: j['puzzle'] as String?,
      );
}

class Commit {
  final String hash;
  final String message;
  final String diff;
  Commit({required this.hash, required this.message, required this.diff});
}

abstract class FsNode {}

class FsDir extends FsNode {
  final Map<String, FsNode> children;
  FsDir(this.children);

  /// 열쇠가 `/` 로 끝나면 폴더, 값이 문자열이면 파일, 객체면 옵션 있는 파일.
  factory FsDir.fromJson(Map<String, dynamic> j) {
    final out = <String, FsNode>{};
    j.forEach((name, v) {
      if (name.endsWith('/')) {
        out[name.substring(0, name.length - 1)] =
            FsDir.fromJson(_map(v));
      } else if (v is String) {
        out[name] = FsFile(text: v);
      } else {
        final m = v as Map<String, dynamic>;
        out[name] = FsFile(
          text: m['text'] as String? ?? '',
          encode: m['encode'] as String?,
          lock: m['lock'] == null ? null : Lock.fromJson(m['lock'] as Map<String, dynamic>),
        );
      }
    });
    return FsDir(out);
  }
}

class FsFile extends FsNode {
  final String text;
  final String? encode; // 'caesar:3' | 'reverse'
  final Lock? lock; // password 만
  FsFile({required this.text, this.encode, this.lock});
}

/// 절대 경로로 노드를 찾는다. 없으면 null. '/' 는 root.
FsNode? lookup(FsDir root, String absPath) {
  FsNode cur = root;
  for (final seg in absPath.split('/')) {
    if (seg.isEmpty) continue;
    if (cur is! FsDir) return null;
    final next = cur.children[seg];
    if (next == null) return null;
    cur = next;
  }
  return cur;
}

class Puzzle {
  final String id;
  final String type; // match | password | order | codefix
  final String? file; // "host:/abs/path"
  final Map<String, dynamic> data;
  final Object answer;
  Puzzle({required this.id, required this.type, this.file, required this.data, required this.answer});
  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
        id: j['id'] as String,
        type: j['type'] as String,
        file: j['file'] as String?,
        data: Map<String, dynamic>.from((j['data'] as Map?) ?? const {}),
        answer: j['answer'] as Object,
      );
}

/// 목표 판정에 필요한 셸 상태 스냅샷.
class GoalState {
  final Set<String> read; // "host:/path"
  final Set<String> solved; // puzzle id
  final Set<String> connected; // host key
  final Set<String> ran; // "host:/path"
  GoalState({
    this.read = const {}, this.solved = const {},
    this.connected = const {}, this.ran = const {},
  });
}

abstract class Goal {
  bool check(GoalState s);

  factory Goal.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('all')) return _Combo(_list(j['all']), all: true);
    if (j.containsKey('any')) return _Combo(_list(j['any']), all: false);
    if (j.containsKey('read')) return _Leaf('read', j['read'] as String);
    if (j.containsKey('puzzle')) return _Leaf('puzzle', j['puzzle'] as String);
    if (j.containsKey('connect')) return _Leaf('connect', j['connect'] as String);
    if (j.containsKey('run')) return _Leaf('run', j['run'] as String);
    throw FormatException('알 수 없는 goal: $j');
  }

  static List<Goal> _list(Object? v) =>
      [for (final g in v as List) Goal.fromJson(g as Map<String, dynamic>)];
}

class _Leaf implements Goal {
  final String kind;
  final String target;
  _Leaf(this.kind, this.target);
  @override
  bool check(GoalState s) => switch (kind) {
        'read' => s.read.contains(target),
        'puzzle' => s.solved.contains(target),
        'connect' => s.connected.contains(target),
        'run' => s.ran.contains(target),
        _ => false,
      };
}

class _Combo implements Goal {
  final List<Goal> parts;
  final bool all;
  _Combo(this.parts, {required this.all});
  @override
  bool check(GoalState s) => all ? parts.every((g) => g.check(s)) : parts.any((g) => g.check(s));
}
