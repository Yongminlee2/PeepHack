/// 브리치 프로토콜(사이버펑크 2077 해킹 미니게임과 같은 규칙). Flutter 의존 없음.
///
/// 첫 선택은 맨 윗줄, 이후는 방금 고른 칸의 세로줄 → 가로줄 → 세로줄… 을 번갈아.
/// 고른 코드는 버퍼에 쌓이고, 목표 순서(데몬)가 버퍼 안에 연속으로 나타나면 달성.
class BreachPuzzle {
  final List<List<String>> grid;
  final int buffer;
  final List<List<String>> daemons;
  final int? timeLimit; // 초. null 이면 시간 제한 없음
  final List<(int, int)> solution; // 생성기가 심은 별 3 경로(없을 수 있음)

  const BreachPuzzle({
    required this.grid,
    required this.buffer,
    required this.daemons,
    this.timeLimit,
    this.solution = const [],
  });

  int get size => grid.length;
}

class BreachGame {
  final BreachPuzzle puzzle;
  final List<(int, int)> picks = [];
  bool _timeUp = false;

  BreachGame(this.puzzle);

  List<String> get bufferCodes => [for (final p in picks) puzzle.grid[p.$1][p.$2]];

  bool get timedOut => _timeUp;

  /// 지금 고를 수 있는 칸. 끝났으면 비어 있다.
  Set<(int, int)> legalCells() {
    if (_timeUp || picks.length >= puzzle.buffer || doneCount == puzzle.daemons.length) return {};
    return _candidates();
  }

  Set<(int, int)> _candidates() {
    final n = puzzle.size;
    final k = picks.length;
    final out = <(int, int)>{};
    for (var i = 0; i < n; i++) {
      final (int, int) cell;
      if (k == 0) {
        cell = (0, i); // 맨 윗줄
      } else if (k.isOdd) {
        cell = (i, picks.last.$2); // 같은 세로줄
      } else {
        cell = (picks.last.$1, i); // 같은 가로줄
      }
      if (!picks.contains(cell)) out.add(cell);
    }
    return out;
  }

  bool pick(int r, int c) {
    if (!legalCells().contains((r, c))) return false;
    picks.add((r, c));
    return true;
  }

  bool daemonDone(int i) {
    final d = puzzle.daemons[i];
    final b = bufferCodes;
    for (var s = 0; s + d.length <= b.length; s++) {
      var ok = true;
      for (var j = 0; j < d.length; j++) {
        if (b[s + j] != d[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  int get doneCount => [for (var i = 0; i < puzzle.daemons.length; i++) daemonDone(i)].where((x) => x).length;

  bool get finished => legalCells().isEmpty;

  /// 전부 달성 3, 아니면 달성한 수(최대 2). 0 이면 실패.
  int get stars {
    final d = doneCount;
    return d == puzzle.daemons.length ? 3 : (d > 2 ? 2 : d);
  }

  void timeUp() => _timeUp = true;
}
