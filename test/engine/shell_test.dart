import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/shell.dart';

Mission mk({String input = 'chips', List<String>? commands}) => Mission.fromJson({
  'id': 'm9_01', 'chapter': 9, 'input': input,
  'commands': commands ?? ['scan', 'connect', 'open', 'decode', 'back', 'ls', 'cd', 'pwd', 'cat', 'grep'],
  'words': ['ERROR'],
  'hosts': {
    'home': {'name': 'my-laptop', 'fs': {
      'note.txt': 'go to shop', 'secret.txt': {'text': 'sz1', 'encode': 'caesar:1'},
      '.hidden': 'h', 'work/': {'log.txt': 'ok\nERROR bad\nok'}}},
    'shop': {'name': 'shop-server', 'lock': {'type': 'password', 'answer': 'ry1'},
      'fs': {'flag.txt': 'FLAG', 'safe.txt': {'text': 'S', 'lock': {'type': 'password', 'answer': 'zz'}},
             'box.txt': 'B'}},
    'vault': {'name': 'vault', 'lock': {'type': 'puzzle', 'puzzle': 'p1'}, 'fs': {'v.txt': 'V'}},
  },
  'puzzles': [
    {'id': 'p1', 'type': 'order', 'data': {'items': ['a', 'b']}, 'answer': [1, 0]},
    {'id': 'p2', 'type': 'password', 'file': 'shop:/box.txt', 'data': {'fragments': ['B', 'x']}, 'answer': 'Bx'},
  ],
  'goal': {'all': [{'read': 'shop:/flag.txt'}, {'puzzle': 'p1'}]},
  'solution': ['scan', 'connect shop-server', 'ry1', 'open flag.txt', 'connect vault', {'puzzle': 'p1'}],
});

void main() {
  test('scan·connect·비밀번호·open·goal', () {
    final sh = Shell(mk());
    expect(sh.run('scan').text, contains('shop-server'));
    expect(sh.run('scan').text, contains('LOCKED'));
    var r = sh.run('connect shop-server');
    expect(r.key, 'shell_password_prompt');
    expect(sh.awaitingPassword, isTrue);
    r = sh.run('wrong');
    expect(r.key, 'shell_err_wrong_password');
    expect(sh.awaitingPassword, isTrue);
    r = sh.run('ry1');
    expect(r.key, 'shell_connected');
    expect(sh.hostKey, 'shop');
    expect(sh.goalDone, isFalse);
    r = sh.run('open flag.txt');
    expect(r.openFile, '/flag.txt');
    expect(r.fileText, 'FLAG');
    expect(sh.state.read, contains('shop:/flag.txt'));
    r = sh.run('connect vault');
    expect(r.openPuzzle, 'p1');
    expect(sh.submitPuzzle('p1', [0, 1]).key, 'puzzle_wrong');
    r = sh.submitPuzzle('p1', [1, 0]);
    expect(r.key, 'shell_connected');
    expect(sh.hostKey, 'vault');
    expect(sh.goalDone, isTrue);
  });
  test('잠금 푼 호스트는 다시 묻지 않는다', () {
    final sh = Shell(mk());
    sh.run('connect shop-server'); sh.run('ry1'); sh.run('back');
    expect(sh.hostKey, 'home');
    expect(sh.run('connect shop-server').key, 'shell_connected');
  });
  test('오류 열쇠', () {
    final sh = Shell(mk());
    expect(sh.run('nope').key, 'shell_err_unknown');
    expect(sh.run('find x').key, 'shell_err_locked_cmd');
    expect(sh.run('connect zzz').key, 'shell_err_no_host');
    expect(sh.run('open zzz').key, 'shell_err_no_file');
    expect(sh.run('open work').key, 'shell_err_is_dir');
    expect(sh.run('cd nope').key, 'shell_err_no_dir');
    expect(sh.run('decode note.txt').key, 'shell_err_not_encoded');
    expect(sh.run('open').key, 'shell_err_usage');
    expect(sh.run('').key, isNull);
  });
  test('decode 는 풀어서 보여 주고 읽은 것으로 친다', () {
    final sh = Shell(mk());
    final r = sh.run('decode secret.txt');
    expect(r.fileText, 'ry1');
    expect(sh.state.read, contains('home:/secret.txt'));
  });
  test('ls·cd·pwd·cat·grep·숨김', () {
    final sh = Shell(mk());
    expect(sh.run('ls').text, 'note.txt\nsecret.txt\nwork/');
    expect(sh.run('ls -a').text, '.hidden\nnote.txt\nsecret.txt\nwork/');
    expect(sh.run('cd work').key, isNull);
    expect(sh.run('pwd').text, '/work');
    expect(sh.run('cat log.txt').fileText, 'ok\nERROR bad\nok');
    expect(sh.run('grep ERROR log.txt').text, 'ERROR bad');
    expect(sh.run('grep zzz log.txt').key, 'shell_empty');
    expect(sh.run('cd ..').key, isNull);
    expect(sh.cwd, '/');
    expect(sh.run('cat /work/log.txt').openFile, '/work/log.txt');
    expect(sh.run('cd').key, isNull);
  });
  test('파일 비밀번호 잠금과 파일 퍼즐', () {
    final sh = Shell(mk());
    sh.run('connect shop-server'); sh.run('ry1');
    expect(sh.run('cat safe.txt').key, 'shell_password_prompt');
    expect(sh.run('zz').fileText, 'S');
    expect(sh.run('cat safe.txt').fileText, 'S');
    expect(sh.run('cat box.txt').openPuzzle, 'p2');
    final r = sh.submitPuzzle('p2', 'Bx');
    expect(r.fileText, 'B');
    expect(sh.state.read, contains('shop:/box.txt'));
    expect(sh.run('cat box.txt').openPuzzle, isNull);
  });
  test('칩 제안', () {
    final sh = Shell(mk());
    final s = sh.suggestions();
    expect(s.commands, contains('ls'));
    expect(s.args, containsAll(['note.txt', 'work', 'shop-server', 'ERROR', '..', '-a']));
    expect(s.args, isNot(contains('.hidden')));
    sh.run('ls -a');
    expect(sh.suggestions().args, contains('.hidden'));
  });
  test('힌트 3: 다음 정답 줄', () {
    final sh = Shell(mk());
    expect(sh.nextSolutionLine(), 'scan');
    sh.run('scan');
    expect(sh.nextSolutionLine(), 'connect shop-server');
    sh.run('ls');
    expect(sh.nextSolutionLine(), 'connect shop-server');
    sh.run('connect shop-server'); sh.run('ry1');
    expect(sh.nextSolutionLine(), 'open flag.txt');
  });
  test('kCommandChapter 는 21개 명령을 전부 안다', () {
    expect(kCommandChapter.length, 21);
    expect(kCommandChapter['scan'], 1);
    expect(kCommandChapter['|'], 3);
    expect(kCommandChapter['run'], 4);
  });
}
