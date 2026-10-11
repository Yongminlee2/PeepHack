/// 보상이 걸리는 경로는 전부 여기를 지난다. 보상형 광고를 붙이면 이 함수 안에서
/// 광고를 보여 주고 결과를 돌려준다 — 게임 로직은 안 건드린다.
class Rewards {
  // ponytail: 지금은 무조건 허용. 광고 SDK 를 붙일 때 ad_service 호출로 교체.
  static Future<bool> unlockHint(String missionId) async => true;
}
