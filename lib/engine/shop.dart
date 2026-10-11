import 'breach.dart';
import 'breach_gen.dart';
import 'hash.dart';
import 'wordguess.dart';

/// 장비(상점)와 그 효과, 크레딧 보상.
class Upgrade {
  final String id;
  final int price;
  const Upgrade(this.id, this.price);
}

const kUpgrades = [Upgrade('buffer', 300), Upgrade('overclock', 250), Upgrade('jammer', 400)];

/// 추적 교란기가 있으면 추적이 70% 속도로 오른다.
double traceSpeed(Set<String> owned) => owned.contains('jammer') ? 0.7 : 1.0;

int missionReward({required bool firstClear, required int starsGained}) => (firstClear ? 100 : 0) + 50 * starsGained;
int breachReward({required int starsGained}) => 10 * starsGained;
int caseReward({required int starsGained}) => 30 * starsGained;

/// 포트 크랙에 쓰는 브리치 판. 챕터별 표 + 장비(버퍼 +1, 시간 +10초). 같은 임무·서버·포트·시도면 같은 판.
BreachPuzzle crackPuzzle({
  required String missionId,
  required String host,
  required int port,
  required int attempt,
  required int chapter,
  required Set<String> owned,
}) {
  final base = switch (chapter) {
    1 => const BreachParams(5, 4, 4, [2]),
    2 => const BreachParams(5, 4, 5, [2, 2], 45),
    3 => const BreachParams(6, 5, 6, [2, 3], 40),
    4 => const BreachParams(6, 5, 7, [2, 2, 3], 40),
    _ => const BreachParams(7, 6, 7, [2, 3, 3], 35),
  };
  final p = BreachParams(
    base.size,
    base.codes,
    base.buffer + (owned.contains('buffer') ? 1 : 0),
    base.daemonLens,
    base.time == null ? null : base.time! + (owned.contains('overclock') ? 10 : 0),
  );
  return generate(p, stableHash('$missionId/$host/$port/$attempt'));
}

/// 2장부터 짝수 번째 포트(2, 4…)는 단어 추리 — 판이 섞여야 지루하지 않다.
bool isWordPort({required int chapter, required int port}) => chapter >= 2 && port.isOdd;

/// 포트 크랙용 단어 추리. 2장 5글자·8개, 3·4장 6글자·9개, 5장 7글자·10개. 오버클럭 = 기회 +1.
WordPuzzle wordCrackPuzzle({
  required String missionId,
  required String host,
  required int port,
  required int attempt,
  required int chapter,
  required Set<String> owned,
}) {
  final (len, count) = switch (chapter) { <= 2 => (5, 8), 3 || 4 => (6, 9), _ => (7, 10) };
  return generateWordPuzzle(
    length: len,
    count: count,
    seed: stableHash('w/$missionId/$host/$port/$attempt'),
    attempts: 4 + (owned.contains('overclock') ? 1 : 0),
  );
}
