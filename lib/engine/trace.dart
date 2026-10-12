import 'dart:math';

/// 추적 게이지(Hacknet 의 추적처럼). 시작 서버를 벗어나 있는 동안 오른다. 1.0 = 들킴.
class Trace {
  final int limitSec; // 0 이면 꺼짐
  double level = 0;
  Trace(this.limitSec);

  bool get enabled => limitSec > 0;
  bool get caught => enabled && level >= 1;

  void tick(double sec, {required bool exposed, double speed = 1}) {
    if (!enabled || !exposed) return;
    level = min(1, level + sec / limitSec * speed);
  }

  /// 크랙 실패 벌칙.
  void penalty([double amount = 0.2]) {
    if (!enabled) return;
    level = min(1, level + amount);
  }
}

/// 챕터 기본 추적 한도(초). 임무 JSON 의 `trace` 가 덮어쓴다.
// 뒤 챕터일수록 빠듯하게(사람 플레이: 너무 여유로웠다)
int defaultTrace(int chapter) => const {1: 240, 2: 160, 3: 150, 4: 150, 5: 140}[chapter] ?? 0;

/// 챕터 기본 포트 수. 호스트 JSON 의 `ports` 가 덮어쓴다.
int defaultPorts(int chapter) => const {1: 1, 2: 2, 3: 2, 4: 3, 5: 3}[chapter] ?? 1;
