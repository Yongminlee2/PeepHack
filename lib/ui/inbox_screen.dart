import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'brief_screen.dart';
import 'promo_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class InboxScreen extends StatefulWidget {
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
      body: ListView(
        children: [
          for (final ch in c.chapters) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(S.tn('inbox_chapter_n', {'n': ch}), style: const TextStyle(color: hqOrange, fontSize: 18)),
            ),
            for (final m in c.chapter(ch))
              ListTile(
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
              ),
          ],
          for (final id in c.broken)
            ListTile(enabled: false, leading: const Icon(Icons.error), title: Text(id), subtitle: Text(S.t('mission_broken'))),
        ],
      ),
    );
  }
}
