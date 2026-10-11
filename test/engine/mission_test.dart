import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';

const sample = '''
{
  "id": "m9_01", "chapter": 9, "title": "@m9_01_title",
  "brief": ["@m9_01_brief_1"], "done": ["@m9_01_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open"],
  "words": ["admin"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {"note.txt": "hello", "work/": {"a.txt": {"text": "x", "encode": "reverse"}}}},
    "shop": {"name": "shop-server", "user": "root", "lock": {"type": "password", "answer": "pw1"},
             "fs": {"flag.txt": {"text": "FLAG", "lock": {"type": "password", "answer": "pw2"}}},
             "git": [{"hash": "a1b2", "message": "fix", "diff": "-1\\n+2"}],
             "env": {"MODE": "prod"}, "cron": ["* * * * * /x.sh"]}
  },
  "start": "home",
  "puzzles": [{"id": "p1", "type": "password", "file": "shop:/flag.txt",
               "data": {"clues": ["@c1"], "fragments": ["pw", "2"]}, "answer": "pw2"}],
  "goal": {"all": [{"read": "shop:/flag.txt"}, {"puzzle": "p1"}, {"connect": "shop"}, {"run": "shop:/a.py"}]},
  "hints": ["@h1", "@h2", "@h3"],
  "solution": ["scan", "connect shop-server", "pw1", {"puzzle": "p1"}]
}
''';

void main() {
  final m = Mission.parse(sample);
  test('기본 필드', () {
    expect(m.id, 'm9_01');
    expect(m.chapter, 9);
    expect(m.commands, ['scan', 'connect', 'open']);
    expect(m.start, 'home');
    expect(m.solution.length, 4);
    expect(m.solution[3], isA<PuzzleStep>());
    expect((m.solution[3] as PuzzleStep).puzzle, 'p1');
  });
  test('파일시스템 파싱', () {
    final home = m.hosts['home']!;
    expect(lookup(home.fs, '/note.txt'), isA<FsFile>());
    expect((lookup(home.fs, '/note.txt') as FsFile).text, 'hello');
    expect(lookup(home.fs, '/work'), isA<FsDir>());
    expect((lookup(home.fs, '/work/a.txt') as FsFile).encode, 'reverse');
    expect(lookup(home.fs, '/nope'), isNull);
    expect(lookup(home.fs, '/'), same(home.fs));
  });
  test('호스트 부가 정보', () {
    final shop = m.hosts['shop']!;
    expect(shop.lock!.type, 'password');
    expect(shop.lock!.answer, 'pw1');
    expect(shop.user, 'root');
    expect(shop.git.single.hash, 'a1b2');
    expect(shop.env['MODE'], 'prod');
    expect(shop.cron.single, '* * * * * /x.sh');
    expect((lookup(shop.fs, '/flag.txt') as FsFile).lock!.answer, 'pw2');
    expect(m.hostByName('shop-server')!.key, 'shop');
    expect(m.hostByName('shop')!.key, 'shop');
    expect(m.hostByName('zzz'), isNull);
  });
  test('퍼즐 찾기', () {
    expect(m.puzzleById('p1')!.type, 'password');
    expect(m.puzzleForFile('shop', '/flag.txt')!.id, 'p1');
    expect(m.puzzleForFile('home', '/note.txt'), isNull);
  });
  test('목표 판정', () {
    final none = GoalState();
    expect(m.goal.check(none), isFalse);
    final all = GoalState(
      read: {'shop:/flag.txt'}, solved: {'p1'}, connected: {'home', 'shop'}, ran: {'shop:/a.py'});
    expect(m.goal.check(all), isTrue);
    final partial = GoalState(read: {'shop:/flag.txt'}, solved: {'p1'}, connected: {'shop'});
    expect(m.goal.check(partial), isFalse);
    final any = Goal.fromJson({'any': [{'puzzle': 'zz'}, {'connect': 'home'}]});
    expect(any.check(all), isTrue);
  });
}
