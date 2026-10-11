import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/engine/rewards.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('완료·별·힌트', () async {
    final p = await Progress.load();
    expect(p.isDone('m1_01'), isFalse);
    expect(p.stars('m1_01'), 0);
    await p.complete('m1_01', 1);
    expect(p.isDone('m1_01'), isTrue);
    expect(p.stars('m1_01'), 2);
    expect(p.hintsUsed('m1_01'), 1);
    await p.complete('m1_01', 3);
    expect(p.stars('m1_01'), 2); // 더 나쁜 결과는 덮지 않는다
    await p.complete('m1_01', 0);
    expect(p.stars('m1_01'), 3);
    expect(p.hintsUsed('m1_01'), 0);
    await p.complete('m1_02', 5);
    expect(p.stars('m1_02'), 1); // 최소 1
    final again = await Progress.load();
    expect(again.stars('m1_01'), 3); // 저장됨
  });
  test('잠금 해제 순서', () async {
    final p = await Progress.load();
    const ids = ['m1_01', 'm1_02', 'm1_03'];
    expect(p.isUnlocked('m1_01', ids), isTrue);
    expect(p.isUnlocked('m1_02', ids), isFalse);
    await p.complete('m1_01', 0);
    expect(p.isUnlocked('m1_02', ids), isTrue);
    expect(p.isUnlocked('m1_03', ids), isFalse);
  });
  test('깨진 세이브는 빈 진행으로', () async {
    SharedPreferences.setMockInitialValues({'stars.m1_01': 'garbage', 'done.m1_01': 7});
    final p = await Progress.load();
    expect(p.stars('m1_01'), 0);
    expect(p.isDone('m1_01'), isFalse);
  });
  test('초기화·소리', () async {
    final p = await Progress.load();
    await p.complete('m1_01', 0);
    await p.setSound(false);
    await p.reset();
    expect(p.isDone('m1_01'), isFalse);
    expect(p.soundOn, isFalse); // 설정은 남긴다
  });
  test('힌트 보상 경로는 지금은 항상 허용', () async {
    expect(await Rewards.unlockHint('m1_01'), isTrue);
  });
  test('브리치 별: 좋은 값만 남고, 앞 스테이지를 통과해야 다음이 열린다', () async {
    final p = await Progress.load();
    expect(p.breachStars(1), 0);
    expect(p.isBreachUnlocked(1), isTrue);
    expect(p.isBreachUnlocked(2), isFalse);
    await p.setBreachStars(1, 2);
    await p.setBreachStars(1, 1);
    expect(p.breachStars(1), 2);
    expect(p.isBreachUnlocked(2), isTrue);
    await p.setBreachStars(2, 0); // 실패는 열지 않는다
    expect(p.isBreachUnlocked(3), isFalse);
  });
  test('매일 퍼즐 별은 날짜별로', () async {
    final p = await Progress.load();
    await p.setDailyStars(DateTime(2026, 10, 11), 3);
    expect(p.dailyStars(DateTime(2026, 10, 11, 22)), 3);
    expect(p.dailyStars(DateTime(2026, 10, 12)), 0);
  });
  test('초기화하면 브리치 기록도 지운다', () async {
    final p = await Progress.load();
    await p.setBreachStars(1, 3);
    await p.setDailyStars(DateTime(2026, 10, 11), 3);
    await p.reset();
    expect(p.breachStars(1), 0);
    expect(p.dailyStars(DateTime(2026, 10, 11)), 0);
  });
  test('크레딧과 장비: 모자라면 못 사고, 산 건 다시 안 산다, 초기화하면 지운다', () async {
    final p = await Progress.load();
    expect(p.credits, 0);
    await p.addCredits(350);
    expect(await p.buy('jammer', 400), isFalse);
    expect(await p.buy('buffer', 300), isTrue);
    expect(p.credits, 50);
    expect(p.owned, {'buffer'});
    expect(await p.buy('buffer', 300), isFalse);
    final again = await Progress.load();
    expect(again.credits, 50);
    expect(again.owned, {'buffer'});
    await p.reset();
    expect(p.credits, 0);
    expect(p.owned, isEmpty);
  });
  test('사건 별: 좋은 값만, 앞 사건을 풀어야 다음이 열린다, 초기화로 지운다', () async {
    final p = await Progress.load();
    expect(p.isCaseUnlocked(1), isTrue);
    expect(p.isCaseUnlocked(2), isFalse);
    await p.setCaseStars('c01', 2);
    await p.setCaseStars('c01', 1);
    expect(p.caseStars('c01'), 2);
    expect(p.isCaseUnlocked(2), isTrue);
    await p.reset();
    expect(p.caseStars('c01'), 0);
  });
  test('10번째 사건은 9번째(c09)를 풀어야 열린다', () async {
    final p = await Progress.load();
    expect(p.isCaseUnlocked(10), isFalse);
    await p.setCaseStars('c09', 1);
    expect(p.isCaseUnlocked(10), isTrue);
  });
}
