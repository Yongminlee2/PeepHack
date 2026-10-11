import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// 임무 진행 저장. 열쇠: `done.<id>` `stars.<id>` `hints.<id>` `sound`
class Progress {
  final SharedPreferences _p;
  Progress._(this._p);

  static Future<Progress> load() async => Progress._(await SharedPreferences.getInstance());

  bool isDone(String id) => _bool('done.$id');
  int stars(String id) => _int('stars.$id');
  int hintsUsed(String id) => _int('hints.$id');
  bool get soundOn => _p.containsKey('sound') ? _bool('sound') : true;

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

  Future<void> reset() async {
    for (final k in _p.getKeys().toList()) {
      if (k.startsWith('done.') || k.startsWith('stars.') || k.startsWith('hints.')) {
        await _p.remove(k);
      }
    }
  }
}
