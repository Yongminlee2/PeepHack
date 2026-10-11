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
    expect(sh.awaitingPassword, isFalse); // 틀리면 대기에서 빠져나온다(다시 connect 하면 된다)
    expect(sh.run('connect shop-server').key, 'shell_password_prompt');
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
  Mission mk34() => Mission.fromJson({
    'id': 'm9_02', 'chapter': 9, 'input': 'keyboard',
    'commands': ['ls', 'cd', 'cat', 'find', 'ssh', 'head', 'tail', '|', 'grep', 'history',
                 'git', 'env', 'crontab', 'fix', 'run', 'connect'],
    'hosts': {
      'home': {'name': 'my-laptop', 'fs': {
        '.bash_history': 'ssh dev@api-box\ncat notes.txt',
        'notes.txt': 'l1\nl2\nl3\nl4',
        'src/': {'deep/': {'app.py': 'x = 1\nif x <= 1:\n  print(x)'}}}},
      'api': {'name': 'api-box', 'user': 'dev',
        'git': [{'hash': 'a1b2', 'message': 'tweak limit', 'diff': '-limit = 10\n+limit = 1'}],
        'env': {'MODE': 'prod', 'LIMIT': '1'}, 'cron': ['0 3 * * * /opt/backup.sh'],
        'fs': {'server.py': 'limit = 1\nfor i in range(limit):\n  work(i)'}},
    },
    'puzzles': [
      {'id': 'c1', 'type': 'codefix', 'file': 'api:/server.py',
       'data': {'lang': 'python', 'lines': ['limit = 1', 'for i in range(limit):', '  work(i)'],
                'bugs': [{'line': 0, 'choices': ['1', '10', '100'], 'answer': '10'}],
                'failOutput': 'Traceback: limit too small', 'okOutput': 'served 10 requests'},
       'answer': 'bugs'},
    ],
    'goal': {'run': 'api:/server.py'},
    'solution': ['ssh dev@api-box', 'fix server.py', {'puzzle': 'c1'}, 'run server.py'],
  });

  test('find·head·tail·pipe·history', () {
    final sh = Shell(mk34());
    expect(sh.run('find app').text, '/src/deep/app.py');
    expect(sh.run('find zzz').key, 'shell_empty');
    expect(sh.run('head -n 2 notes.txt').text, 'l1\nl2');
    expect(sh.run('tail -n 1 notes.txt').text, 'l4');
    expect(sh.run('head notes.txt').text, 'l1\nl2\nl3\nl4');
    expect(sh.run('cat notes.txt | grep l3').text, 'l3');
    expect(sh.run('cat notes.txt | grep zz').key, 'shell_empty');
    expect(sh.run('cat notes.txt | wc').key, 'shell_err_usage');
    expect(sh.run('history').text, 'ssh dev@api-box\ncat notes.txt');
  });
  test('ssh 는 계정이 맞아야', () {
    final sh = Shell(mk34());
    expect(sh.run('ssh root@api-box').key, 'shell_err_ssh_denied');
    expect(sh.run('ssh dev@zzz').key, 'shell_err_no_host');
    expect(sh.run('ssh dev').key, 'shell_err_usage');
    expect(sh.run('ssh dev@api-box').key, 'shell_connected');
    expect(sh.hostKey, 'api');
  });
  test('git·env·crontab', () {
    final sh = Shell(mk34());
    sh.run('ssh dev@api-box');
    expect(sh.run('git log').text, 'a1b2  tweak limit');
    expect(sh.run('git diff a1b2').text, '-limit = 10\n+limit = 1');
    expect(sh.run('git diff zz').key, 'shell_err_no_commit');
    expect(sh.run('git').key, 'shell_err_usage');
    expect(sh.run('env').text, 'MODE=prod\nLIMIT=1');
    expect(sh.run('crontab -l').text, '0 3 * * * /opt/backup.sh');
    expect(sh.run('crontab').key, 'shell_err_usage');
  });
  test('fix·run·codefix', () {
    final sh = Shell(mk34());
    sh.run('ssh dev@api-box');
    expect(sh.run('run server.py').text, 'Traceback: limit too small');
    expect(sh.goalDone, isFalse);
    expect(sh.run('fix notes.txt').key, 'shell_err_nothing_to_fix');
    expect(sh.run('cat server.py').fileText, isNotNull); // codefix 는 cat 을 막지 않는다
    expect(sh.run('fix server.py').openPuzzle, 'c1');
    expect(sh.submitPuzzle('c1', {0: '1'}).key, 'puzzle_wrong');
    expect(sh.submitPuzzle('c1', {0: '10'}).key, 'puzzle_solved');
    expect(sh.run('run server.py').text, 'served 10 requests');
    expect(sh.goalDone, isTrue);
    expect(sh.run('run notes.txt').key, 'shell_err_nothing_to_run');
  });
  test('키보드 임무의 칩에는 ssh 계정·커밋 해시가 들어간다', () {
    final sh = Shell(mk34());
    expect(sh.suggestions().args, contains('dev@api-box'));
    sh.run('ssh dev@api-box');
    expect(sh.suggestions().args, containsAll(['log', 'diff', 'a1b2', '-l', '-n']));
  });
  test('비밀번호를 틀린 뒤 다른 명령이 비밀번호로 먹히지 않는다', () {
    final sh = Shell(mk());
    sh.run('connect shop-server');
    sh.run('nope');
    expect(sh.run('scan').text, contains('shop-server'));
    sh.run('connect shop-server'); sh.run('ry1');
    sh.run('cat safe.txt');
    expect(sh.run('nope').key, 'shell_err_wrong_password');
    expect(sh.run('ls').text, contains('flag.txt'));
  });
  test('닫아 버린 호스트 퍼즐이 나중 파일 퍼즐 결과를 가로채지 않는다', () {
    final sh = Shell(mk());
    expect(sh.run('connect vault').openPuzzle, 'p1'); // 창만 열고 안 푼다
    sh.run('connect shop-server'); sh.run('ry1');
    expect(sh.run('cat box.txt').openPuzzle, 'p2');
    final r = sh.submitPuzzle('p2', 'Bx');
    expect(sh.hostKey, 'shop');
    expect(r.fileText, 'B');
    expect(sh.run('connect vault').openPuzzle, 'p1'); // vault 는 여전히 잠겨 있다
    expect(sh.submitPuzzle('p1', [1, 0]).key, 'shell_connected');
    expect(sh.hostKey, 'vault');
  });
  test('칩에 하위 폴더 경로(깊이 3)와 find 가 찾은 경로가 들어간다 — 키보드 없이 풀 수 있게', () {
    final sh = Shell(mk34());
    final args = sh.suggestions().args;
    expect(args, contains('src/deep/app.py'));
    expect(args, isNot(contains('.bash_history'))); // 숨김은 ls -a 전엔 안 보인다
    sh.run('find app');
    expect(sh.suggestions().args, contains('/src/deep/app.py'));
    sh.run('ssh dev@api-box');
    expect(sh.suggestions().args, isNot(contains('/src/deep/app.py'))); // 다른 서버의 경로는 빠진다
  });
  test('파일 비밀번호를 묻는 중에 다른 서버를 크랙하면 묻기는 취소된다', () {
    final sh = Shell(mk());
    sh.run('connect shop-server'); sh.run('ry1');
    expect(sh.run('cat safe.txt').key, 'shell_password_prompt');
    sh.crack('vault');
    expect(sh.awaitingPassword, isFalse);
    expect(sh.run('ls').text, contains('v.txt')); // 예전엔 여기서 죽었다
  });
}
