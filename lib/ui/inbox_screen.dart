import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'brief_screen.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'promo_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
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
  // 개발용: 디버그 빌드에서 제목을 7번 누르면 모든 임무가 열린다(실기기 확인용). 출시 빌드엔 없다.
  int _devTaps = 0;
  bool _devUnlock = false;
  bool _open(Progress p, String id, List<String> ids) => _devUnlock || p.isUnlocked(id, ids);

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final c = widget.catalog;
    final ids = c.orderedIds;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: kDebugMode ? () => setState(() => _devUnlock = ++_devTaps >= 7) : null,
          child: Text(S.t('inbox_title')),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.memory),
            tooltip: S.t('shop_title'),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(progress: widget.progress)));
              setState(() {});
            },
          ),
          // 「다른 게임」은 아직 "준비 중" 자리다. 아이폰 심사는 빈 자리를 미완성으로 보고(지침 2.1),
          // 목록을 채울 때도 앱스토어 번호가 있는 게임만 보여야 한다(2.3.10) — 그때까지 아이폰에선 숨긴다.
          if (defaultTargetPlatform != TargetPlatform.iOS)
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
              _card(_open(p, m.id, ids), ListTile(
                enabled: _open(p, m.id, ids),
                leading: Icon(p.isDone(m.id) ? Icons.check_circle : (_open(p, m.id, ids) ? Icons.mail : Icons.lock),
                    color: p.isDone(m.id) ? hqGreen : hqDim),
                title: Text(tr(m.title)),
                subtitle: _open(p, m.id, ids) ? null : Text(S.t('inbox_locked')),
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
