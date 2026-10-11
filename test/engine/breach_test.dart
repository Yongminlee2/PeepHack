import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/breach.dart';

// 3×3 작은 판
//   r0: 1C 55 BD
//   r1: E9 1C 55
//   r2: BD E9 1C
BreachPuzzle small({List<List<String>>? daemons, int buffer = 4, int? time}) => BreachPuzzle(
      grid: const [
        ['1C', '55', 'BD'],
        ['E9', '1C', '55'],
        ['BD', 'E9', '1C'],
      ],
      buffer: buffer,
      daemons: daemons ?? const [['55', 'E9']],
      timeLimit: time,
    );

void main() {
  test('첫 선택은 맨 윗줄만', () {
    final g = BreachGame(small());
    expect(g.legalCells(), {(0, 0), (0, 1), (0, 2)});
    expect(g.pick(1, 1), isFalse);
    expect(g.picks, isEmpty);
    expect(g.pick(0, 1), isTrue);
  });
  test('그다음은 세로줄, 그다음은 가로줄을 번갈아', () {
    final g = BreachGame(small(daemons: const [['FF']])); // 달성 안 되는 목표 — 도중에 끝나지 않게
    g.pick(0, 1); // 55, 이제 1번 세로줄
    expect(g.legalCells(), {(1, 1), (2, 1)});
    expect(g.pick(0, 2), isFalse);
    g.pick(2, 1); // E9, 이제 2번 가로줄
    expect(g.legalCells(), {(2, 0), (2, 2)});
    g.pick(2, 0); // BD, 이제 0번 세로줄
    expect(g.legalCells(), {(0, 0), (1, 0)});
  });
  test('같은 칸은 두 번 못 고른다', () {
    final g = BreachGame(small(buffer: 6, daemons: const [['FF']]));
    g.pick(0, 0); // 0번 세로줄
    g.pick(1, 0); // 1번 가로줄
    g.pick(1, 2); // 2번 세로줄
    g.pick(0, 2); // 0번 가로줄: (0,0) 은 이미 씀
    expect(g.legalCells(), {(0, 1)});
  });
  test('목표 달성과 별, 버퍼가 차면 끝', () {
    final g = BreachGame(small(daemons: const [['55', 'E9'], ['E9', 'BD']], buffer: 3));
    g.pick(0, 1); // 55
    expect(g.daemonDone(0), isFalse);
    g.pick(2, 1); // E9
    expect(g.daemonDone(0), isTrue);
    expect(g.finished, isFalse);
    g.pick(2, 0); // BD → 두 목표가 겹쳐서 둘 다
    expect(g.daemonDone(1), isTrue);
    expect(g.finished, isTrue);
    expect(g.stars, 3);
    expect(g.pick(1, 0), isFalse); // 끝난 뒤엔 못 고른다
  });
  test('별: 목표 3개 중 2개=2, 1개=1, 0개=0, 2개 중 1개=1', () {
    BreachGame play(List<List<String>> d, List<(int, int)> moves) {
      final g = BreachGame(small(daemons: d, buffer: moves.length));
      for (final m in moves) {
        g.pick(m.$1, m.$2);
      }
      return g;
    }
    expect(play(const [['55'], ['E9'], ['FF']], [(0, 1), (2, 1)]).stars, 2);
    expect(play(const [['55'], ['FF'], ['7A']], [(0, 1), (2, 1)]).stars, 1);
    expect(play(const [['FF'], ['7A']], [(0, 1), (2, 1)]).stars, 0);
    expect(play(const [['55'], ['7A']], [(0, 1), (2, 1)]).stars, 1);
  });
  test('시간이 끝나면 그 자리에서 끝나고 더 못 고른다', () {
    final g = BreachGame(small(time: 30));
    g.pick(0, 1);
    g.timeUp();
    expect(g.finished, isTrue);
    expect(g.legalCells(), isEmpty);
    expect(g.pick(1, 1), isFalse);
  });
  test('둘 곳이 없으면 끝', () {
    final p = BreachPuzzle(grid: const [['1C']], buffer: 5, daemons: const [['55']]);
    final g = BreachGame(p);
    g.pick(0, 0);
    expect(g.finished, isTrue);
    expect(g.stars, 0);
  });
}
