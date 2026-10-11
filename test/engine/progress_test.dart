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
}
