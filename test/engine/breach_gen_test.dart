import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/breach.dart';
import 'package:hack_quest/engine/breach_gen.dart';

/// 심은 정답 경로를 실제로 눌러 별 3 이 나오는지.
int replay(BreachPuzzle p) {
  final g = BreachGame(p);
  for (final (r, c) in p.solution) {
    if (g.finished) break;
    expect(g.pick(r, c), isTrue, reason: '정답 경로가 규칙에 안 맞음 ($r,$c) after ${g.picks}');
  }
  return g.stars;
}

void main() {
  test('스테이지 표(설계 문서)', () {
    expect(kBreachStages, 60);
    final s1 = stageParams(1);
    expect((s1.size, s1.codes, s1.buffer, s1.daemonLens.length, s1.time), (5, 4, 3, 2, null));
    final s35 = stageParams(35);
    expect((s35.size, s35.codes, s35.buffer, s35.daemonLens.length, s35.time), (7, 6, 8, 3, 40));
    final s60 = stageParams(60);
    expect((s60.size, s60.codes, s60.buffer, s60.daemonLens.length, s60.time), (7, 6, 9, 4, 30)); // 끝은 목표 넷
    for (var n = 1; n <= kBreachStages; n++) {
      final p = stageParams(n);
      final chained = p.daemonLens.fold<int>(0, (a, l) => a + l) - (p.daemonLens.length - 1);
      // 1단계부터 목표 둘 이상 — 하나짜리는 두 번 누르면 끝나 고민할 게 없었다
      expect(p.daemonLens.length, greaterThanOrEqualTo(2), reason: '스테이지 $n');
      // 모든 단계에서 버퍼가 꼭 맞다 — 목표를 겹쳐 잇지 않으면 별 3 이 안 나온다.
      // (1단계 연습판도: 손가락이 가리키는 칸마다 목표가 채워져야 따라 하며 이해된다)
      expect(chained, p.buffer, reason: '스테이지 $n');
      // 11단계부터 시간 제한
      expect(p.time != null, n >= 11, reason: '스테이지 $n');
    }
    expect(() => stageParams(0), throwsRangeError);
    expect(() => stageParams(61), throwsRangeError);
  });

  test('60 스테이지 모두 별 3 정답이 있고 규칙대로 생겼다', () {
    for (var n = 1; n <= kBreachStages; n++) {
      final prm = stageParams(n);
      final p = generateStage(n);
      expect(p.size, prm.size, reason: '스테이지 $n');
      expect(p.buffer, prm.buffer);
      expect(p.timeLimit, prm.time);
      expect([for (final d in p.daemons) d.length]..sort(), [...prm.daemonLens]..sort()); // 표시 순서는 섞는다
      expect(p.daemons.map((d) => d.join(' ')).toSet().length, p.daemons.length, reason: '같은 목표가 둘');
      final codes = kBreachCodes.take(prm.codes).toSet();
      for (final row in p.grid) {
        expect(row.length, prm.size);
        expect(codes.containsAll(row), isTrue, reason: '스테이지 $n 에 쓰면 안 되는 코드');
      }
      expect(replay(p), 3, reason: '스테이지 $n 정답 경로로 별 3 이 안 나옴');
    }
  });

  test('빛나는 칸 안내는 10단계까지만', () {
    expect(breachHints(1), isTrue);
    expect(breachHints(10), isTrue);
    expect(breachHints(11), isFalse);
  });

  test('같은 번호는 늘 같은 퍼즐', () {
    expect(generateStage(17).grid, generateStage(17).grid);
    expect(generateStage(17).daemons, generateStage(17).daemons);
  });

  test('매일 퍼즐: 같은 날 같고, 다른 날 다르고, 늘 풀린다', () {
    final d1 = DateTime(2026, 10, 11);
    expect(generateDaily(d1).grid, generateDaily(DateTime(2026, 10, 11, 23, 59)).grid);
    expect(generateDaily(d1).grid, isNot(generateDaily(DateTime(2026, 10, 12)).grid));
    for (var i = 0; i < 30; i++) {
      final p = generateDaily(d1.add(Duration(days: i)));
      expect(p.timeLimit, 40);
      expect(replay(p), 3, reason: '매일 퍼즐 $i');
    }
  });
}
