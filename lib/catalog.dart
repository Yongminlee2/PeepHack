import 'package:flutter/services.dart' show rootBundle;

import 'engine/mission.dart';

/// 임무 전부. 파일이 없거나 깨지면 그 임무만 빠진다(앱은 죽지 않는다).
class Catalog {
  final List<Mission> missions;
  final Set<String> broken;
  Catalog._(this.missions, this.broken);

  /// id → JSON 글. null 이면 파일 없음(조용히 건너뜀), 깨진 글이면 broken.
  static Catalog fromTexts(Map<String, String?> texts) {
    final out = <Mission>[];
    final broken = <String>{};
    texts.forEach((id, text) {
      if (text == null) return;
      try {
        out.add(Mission.parse(text));
      } catch (_) {
        broken.add(id);
      }
    });
    out.sort((a, b) => a.id.compareTo(b.id));
    return Catalog._(out, broken);
  }

  static Future<Catalog> load() async {
    final texts = <String, String?>{};
    for (var c = 1; c <= 5; c++) {
      for (var n = 1; n <= 6; n++) {
        final id = 'm${c}_0$n';
        try {
          texts[id] = await rootBundle.loadString('assets/missions/$id.json');
        } catch (_) {
          texts[id] = null;
        }
      }
    }
    return fromTexts(texts);
  }

  List<int> get chapters => missions.map((m) => m.chapter).toSet().toList()..sort();
  List<Mission> chapter(int c) => missions.where((m) => m.chapter == c).toList();
  List<String> get orderedIds => missions.map((m) => m.id).toList();
  Mission? byId(String id) {
    for (final m in missions) {
      if (m.id == id) return m;
    }
    return null;
  }
  Mission? after(String id) {
    final i = orderedIds.indexOf(id);
    return i < 0 || i + 1 >= missions.length ? null : missions[i + 1];
  }
}
