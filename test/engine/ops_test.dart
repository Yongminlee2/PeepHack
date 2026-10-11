import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/breach.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/shell.dart';
import 'package:hack_quest/engine/shop.dart';
import 'package:hack_quest/engine/trace.dart';

Mission mk({int chapter = 2, int? trace, int? ports}) => Mission.fromJson({
      'id': 'm9_01', 'chapter': chapter, 'title': '@t', 'brief': ['@b'], 'done': ['@d'],
      'commands': ['scan', 'connect', 'ssh', 'ls', 'cat'],
      if (trace != null) 'trace': trace,
      'hosts': {
        'home': {'name': 'my-laptop', 'fs': {}},
        'shop': {'name': 'shop-server', 'lock': {'type': 'password', 'answer': 'pw'}, if (ports != null) 'ports': ports, 'fs': {'f.txt': 'F'}},
        'vault': {'name': 'vault', 'lock': {'type': 'puzzle', 'puzzle': 'p1'}, 'fs': {}},
        'db': {'name': 'db-server', 'user': 'dba', 'fs': {}},
        'open': {'name': 'open-box', 'fs': {}},
      },
      'puzzles': [{'id': 'p1', 'type': 'order', 'data': {'items': ['a', 'b']}, 'answer': [1, 0]}],
      'goal': {'all': [{'puzzle': 'p1'}, {'connect': 'vault'}]},
      'hints': [], 'solution': [],
    });

void main() {
  group('추적', () {
    test('노출된 동안만 오르고, 한도 초에 100%', () {
      final t = Trace(100);
      t.tick(10, exposed: false);
      expect(t.level, 0);
      t.tick(50, exposed: true);
      expect(t.level, closeTo(0.5, 1e-9));
      t.tick(60, exposed: true);
      expect(t.level, 1);
      expect(t.caught, isTrue);
    });
    test('교란기는 속도를 늦추고, 실패 벌칙은 15%', () {
      final t = Trace(100);
      t.tick(10, exposed: true, speed: 0.7);
      expect(t.level, closeTo(0.07, 1e-9));
      t.penalty();
      expect(t.level, closeTo(0.22, 1e-9));
    });
    test('한도 0 이면 꺼져 있다', () {
      final t = Trace(0);
      t.tick(1000, exposed: true);
      t.penalty();
      expect(t.caught, isFalse);
      expect(t.enabled, isFalse);
    });
  });

  group('임무 기본값', () {
    test('챕터별 추적 한도·포트 수, JSON 이 덮어쓴다', () {
      expect(mk(chapter: 1).trace, 300);
      expect(mk(chapter: 3).trace, 200);
      expect(mk(trace: 0).trace, 0);
      expect(mk(chapter: 3).portsFor(mk(chapter: 3).hosts['shop']!), 2);
      final m = mk(chapter: 5, ports: 1);
      expect(m.portsFor(m.hosts['shop']!), 1);
      expect(m.portsFor(m.hosts['vault']!), 3);
    });
    test('보호된 서버 = 잠금이 있거나 계정이 필요한 서버', () {
      final m = mk();
      expect(m.hosts['shop']!.isProtected, isTrue);
      expect(m.hosts['db']!.isProtected, isTrue);
      expect(m.hosts['open']!.isProtected, isFalse);
    });
  });

  group('크랙', () {
    test('크랙하면 잠금이 풀리고 그 서버로 들어간다', () {
      final sh = Shell(mk());
      final r = sh.crack('shop');
      expect(r.key, 'shell_cracked');
      expect(sh.hostKey, 'shop');
      sh.run('back');
      expect(sh.run('connect shop-server').key, 'shell_connected'); // 다시 묻지 않는다
    });
    test('퍼즐 잠금 서버를 크랙하면 그 퍼즐도 푼 것으로 친다', () {
      final sh = Shell(mk());
      sh.crack('vault');
      expect(sh.state.solved, contains('p1'));
      expect(sh.goalDone, isTrue);
    });
    test('계정 서버도 크랙으로 들어간다', () {
      final sh = Shell(mk());
      sh.crack('db');
      expect(sh.hostKey, 'db');
      sh.run('back');
      expect(sh.run('connect db-server').key, 'shell_connected');
    });
    test('계정이 필요한 서버에 connect 로 그냥 들어갈 수 없다(ssh)', () {
      final sh = Shell(mk());
      final r = sh.run('connect db-server');
      expect(r.key, 'shell_err_need_ssh');
      expect(sh.hostKey, 'home');
      expect(sh.run('ssh dba@db-server').key, 'shell_connected');
    });
    test('크랙 판: 챕터 표대로, 장비가 버퍼·시간을 늘린다, 같은 씨앗은 같은 판', () {
      final a = crackPuzzle(missionId: 'm3_01', host: 'corp', port: 0, attempt: 0, chapter: 3, owned: const {});
      expect((a.size, a.buffer, a.daemons.length, a.timeLimit), (6, 6, 2, 40));
      final b = crackPuzzle(missionId: 'm3_01', host: 'corp', port: 0, attempt: 0, chapter: 3, owned: const {'buffer', 'overclock'});
      expect((b.buffer, b.timeLimit), (7, 50));
      expect(crackPuzzle(missionId: 'm3_01', host: 'corp', port: 0, attempt: 0, chapter: 3, owned: const {}).grid, a.grid);
      expect(crackPuzzle(missionId: 'm3_01', host: 'corp', port: 1, attempt: 0, chapter: 3, owned: const {}).grid, isNot(a.grid));
      expect(crackPuzzle(missionId: 'm1_01', host: 'x', port: 0, attempt: 0, chapter: 1, owned: const {}).timeLimit, isNull);
      final g = BreachGame(b);
      for (final (r, c) in b.solution) {
        if (g.finished) break;
        g.pick(r, c);
      }
      expect(g.stars, 3);
    });
  });

  group('상점·보상', () {
    test('장비 표', () {
      expect({for (final u in kUpgrades) u.id: u.price}, {'buffer': 300, 'overclock': 250, 'jammer': 400});
      expect(traceSpeed(const {}), 1.0);
      expect(traceSpeed(const {'jammer'}), 0.7);
    });
    test('보상: 처음 깨면 100 + 늘어난 별당 50, 브리치는 늘어난 별당 10', () {
      expect(missionReward(firstClear: true, starsGained: 3), 250);
      expect(missionReward(firstClear: false, starsGained: 1), 50);
      expect(missionReward(firstClear: false, starsGained: 0), 0);
      expect(breachReward(starsGained: 2), 20);
    });
  });
}
