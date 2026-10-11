import 'dart:math';

import 'breach.dart';

/// 브리치 퍼즐 생성기. 씨앗이 같으면 늘 같은 퍼즐(스테이지 번호·날짜).
///
/// 만드는 법: 규칙에 맞는 무작위 경로를 먼저 정하고(길이 = 버퍼), 그 경로의 코드열 안에서
/// 목표들을 한 칸씩 겹치게 이어 잡는다. 그래서 심은 경로가 늘 별 3 정답이다.
const kBreachCodes = ['1C', '55', 'BD', 'E9', '7A', 'FF'];
const kBreachStages = 60;

class BreachParams {
  final int size, codes, buffer;
  final List<int> daemonLens;
  final int? time;
  const BreachParams(this.size, this.codes, this.buffer, this.daemonLens, [this.time]);
}

/// 설계 문서의 스테이지 표.
BreachParams stageParams(int n) {
  RangeError.checkValueInInterval(n, 1, kBreachStages, 'n');
  if (n <= 5) return const BreachParams(5, 4, 4, [2]);
  if (n <= 10) return const BreachParams(5, 4, 5, [3]);
  if (n <= 15) return const BreachParams(5, 4, 5, [2, 2]);
  if (n <= 20) return const BreachParams(5, 4, 6, [2, 3]);
  if (n <= 25) return const BreachParams(6, 5, 6, [2, 3]);
  if (n <= 30) return const BreachParams(6, 5, 7, [2, 2, 3]);
  if (n <= 40) return const BreachParams(6, 5, 7, [2, 3, 3], 60);
  if (n <= 45) return const BreachParams(7, 6, 7, [2, 3, 3], 50);
  if (n <= 50) return const BreachParams(7, 6, 8, [3, 3, 3], 50);
  return const BreachParams(7, 6, 8, [3, 3, 3], 40);
}

const _daily = BreachParams(7, 6, 8, [3, 3, 3], 40);

BreachPuzzle generateStage(int n) => generate(stageParams(n), 1000 + n);

BreachPuzzle generateDaily(DateTime d) => generate(_daily, d.year * 10000 + d.month * 100 + d.day);

BreachPuzzle generate(BreachParams p, int seed) {
  final rnd = Random(seed);
  final codes = kBreachCodes.take(p.codes).toList();
  String code() => codes[rnd.nextInt(codes.length)];
  // ponytail: 막힌 경로·겹치는 목표가 나오면 같은 난수열로 다시 뽑는다. 표의 크기에서는 몇 번이면 된다.
  while (true) {
    final path = _walk(rnd, p.size, p.buffer);
    if (path == null) continue;
    final seq = [for (var i = 0; i < p.buffer; i++) code()];
    final chained = p.daemonLens.fold<int>(0, (a, l) => a + l) - (p.daemonLens.length - 1);
    var at = rnd.nextInt(p.buffer - chained + 1);
    final daemons = <List<String>>[];
    for (final len in p.daemonLens) {
      daemons.add(seq.sublist(at, at + len));
      at += len - 1; // 한 칸 겹치게 잇는다
    }
    if (!_distinct(daemons)) continue;
    daemons.shuffle(rnd);
    final grid = [for (var r = 0; r < p.size; r++) [for (var c = 0; c < p.size; c++) code()]];
    for (var i = 0; i < path.length; i++) {
      grid[path[i].$1][path[i].$2] = seq[i];
    }
    return BreachPuzzle(grid: grid, buffer: p.buffer, daemons: daemons, timeLimit: p.time, solution: path);
  }
}

/// 규칙에 맞는 무작위 경로(맨 윗줄에서 시작, 세로·가로 번갈아). 막히면 null.
List<(int, int)>? _walk(Random rnd, int n, int len) {
  final path = <(int, int)>[];
  for (var k = 0; k < len; k++) {
    final opts = <(int, int)>[
      for (var i = 0; i < n; i++)
        if (k == 0) (0, i) else if (k.isOdd) (i, path.last.$2) else (path.last.$1, i),
    ]..removeWhere(path.contains);
    if (opts.isEmpty) return null;
    path.add(opts[rnd.nextInt(opts.length)]);
  }
  return path;
}

/// 목표끼리 같거나 하나가 다른 것 안에 들어 있으면 안 된다(하나 하면 공짜로 하나 더).
bool _distinct(List<List<String>> ds) {
  for (var i = 0; i < ds.length; i++) {
    for (var j = 0; j < ds.length; j++) {
      if (i != j && ' ${ds[j].join(' ')} '.contains(' ${ds[i].join(' ')} ')) return false;
    }
  }
  return true;
}
