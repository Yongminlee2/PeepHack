import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'brief_screen.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'promo_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class InboxScreen extends StatefulWidget {
  /// 완료 화면이 돌아올 자리. 맨 처음 화면은 타이틀이라 isFirst 로는 못 찾는다.
  static const routeName = 'inbox';

  final Progress progress;
  final Catalog catalog;
  const InboxScreen({super.key, required this.progress, required this.catalog});
  @override
  State<InboxScreen> createState() => _InboxState();
}

class _InboxState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final c = widget.catalog;
    final ids = c.orderedIds;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('inbox_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.videogame_asset),
            tooltip: S.t('btn_promo'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: S.t('btn_settings'),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(progress: p)));
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        const MatrixRain(opacity: 0.16),
        const CrtOverlay(),
        ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          for (final ch in c.chapters) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text('// ${S.tn('inbox_chapter_n', {'n': ch})}', style: const TextStyle(color: hqOrange, fontSize: 16, letterSpacing: 1)),
            ),
            for (final m in c.chapter(ch))
              _card(p.isUnlocked(m.id, ids), ListTile(
                enabled: p.isUnlocked(m.id, ids),
                leading: Icon(p.isDone(m.id) ? Icons.check_circle : (p.isUnlocked(m.id, ids) ? Icons.mail : Icons.lock),
                    color: p.isDone(m.id) ? hqGreen : hqDim),
                title: Text(tr(m.title)),
                subtitle: p.isUnlocked(m.id, ids) ? null : Text(S.t('inbox_locked')),
                trailing: Text('★' * p.stars(m.id), style: const TextStyle(color: hqOrange)),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BriefScreen(mission: m, progress: p, catalog: c)));
                  setState(() {});
                },
              )),
          ],
          for (final id in c.broken)
            ListTile(enabled: false, leading: const Icon(Icons.error), title: Text(id), subtitle: Text(S.t('mission_broken'))),
        ],
      ),
      ]),
    );
  }

  // 메시지 한 통 = 테두리 있는 반투명 카드. 잠긴 건 흐리게.
  Widget _card(bool open, Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: const Color(0xD90B0F0C),
          shape: Border.all(color: hqGreen.withValues(alpha: open ? 0.45 : 0.12)),
          child: child,
        ),
      );
}
