import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'case_file.dart' show caseId;

/// 임무 진행 저장. 열쇠: `done.<id>` `stars.<id>` `hints.<id>` `sound`
class Progress {
  final SharedPreferences _p;
  Progress._(this._p);

  static Future<Progress> load() async => Progress._(await SharedPreferences.getInstance());

  bool isDone(String id) => _bool('done.$id');
  int stars(String id) => _int('stars.$id');
  int hintsUsed(String id) => _int('hints.$id');
  bool get soundOn => _p.containsKey('sound') ? _bool('sound') : true;
  bool get vibrationOn => _p.containsKey('vibration') ? _bool('vibration') : true;
  bool get musicOn => _p.containsKey('music') ? _bool('music') : true;

  // 형이 다르면(깨진 세이브) 기본값. SharedPreferences 는 형이 다르면 던진다.
  bool _bool(String k) {
    try { return _p.getBool(k) ?? false; } catch (_) { return false; }
  }
  int _int(String k) {
    try { return _p.getInt(k) ?? 0; } catch (_) { return 0; }
  }

  Future<void> complete(String id, int hintsUsed) async {
    final newStars = max(1, 3 - hintsUsed);
    await _p.setBool('done.$id', true);
    if (newStars > stars(id)) {
      await _p.setInt('stars.$id', newStars);
      await _p.setInt('hints.$id', hintsUsed);
    }
  }

  bool isUnlocked(String id, List<String> orderedIds) {
    final i = orderedIds.indexOf(id);
    return i <= 0 || isDone(orderedIds[i - 1]);
  }

  Future<void> setSound(bool v) => _p.setBool('sound', v);
  Future<void> setVibration(bool v) => _p.setBool('vibration', v);
  Future<void> setMusic(bool v) => _p.setBool('music', v);

  // 브리치 모드: breach.<번호>, daily.<yyyymmdd> 에 별(좋은 값만)
  int breachStars(int n) => _int('breach.$n');
  Future<void> setBreachStars(int n, int stars) => _best('breach.$n', stars);
  bool isBreachUnlocked(int n) => n <= 1 || breachStars(n - 1) > 0;

  static String _day(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  int dailyStars(DateTime d) => _int('daily.${_day(d)}');
  Future<void> setDailyStars(DateTime d, int stars) => _best('daily.${_day(d)}', stars);

  /// 오늘의 퍼즐 연속 기록. 오늘을 아직 안 풀었으면 어제부터 센다(하루 안에 풀면 이어진다).
  int dailyStreak(DateTime today) {
    var d = DateTime(today.year, today.month, today.day);
    if (dailyStars(d) == 0) d = DateTime(d.year, d.month, d.day - 1);
    var n = 0;
    while (dailyStars(d) > 0) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1); // 달·해가 바뀌어도 DateTime 이 맞춰 준다
    }
    return n;
  }

  // 사건 파일: case.<id> 별
  int caseStars(String id) => _int('case.$id');
  Future<void> setCaseStars(String id, int stars) => _best('case.$id', stars);
  bool isCaseUnlocked(int n) => n <= 1 || caseStars(caseId(n - 1)) > 0;

  // 크레딧·장비
  int get credits => _int('credits');
  Future<void> addCredits(int n) => _p.setInt('credits', credits + n);
  Set<String> get owned {
    try {
      return (_p.getStringList('owned') ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  /// 모자라거나 이미 있으면 false.
  Future<bool> buy(String id, int price) async {
    if (owned.contains(id) || credits < price) return false;
    // 둘 다 기다리기 전에 쓴다(캐시는 바로 바뀐다) — 두 번 눌러도 두 번째는 owned 를 본다
    await Future.wait([_p.setStringList('owned', [...owned, id]), _p.setInt('credits', credits - price)]);
    return true;
  }

  Future<void> _best(String k, int v) async {
    if (v > _int(k)) await _p.setInt(k, v);
  }

  Future<void> reset() async {
    for (final k in _p.getKeys().toList()) {
      if (k.startsWith('done.') || k.startsWith('stars.') || k.startsWith('hints.') ||
          k.startsWith('breach.') || k.startsWith('daily.') || k.startsWith('case.') || k == 'credits' || k == 'owned') {
        await _p.remove(k);
      }
    }
  }
}
