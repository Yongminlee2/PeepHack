import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'breach/breach_list_screen.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'inbox_screen.dart';
import 'theme.dart';

/// 모드 선택: 작전(이야기) / 브리치(퍼즐) / 사건 파일(준비 중).
class ModeScreen extends StatelessWidget {
  final Progress progress;
  final Catalog catalog;
  const ModeScreen({super.key, required this.progress, required this.catalog});

  Widget _card({required IconData icon, required String title, required String desc, VoidCallback? onTap, String? badge}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: const Color(0xE60B0F0C),
          shape: Border.all(color: hqGreen.withValues(alpha: onTap == null ? 0.15 : 0.6)),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Icon(icon, size: 40, color: onTap == null ? hqDim : hqGreen),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onTap == null ? hqDim : Colors.white)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Text(badge, style: const TextStyle(color: hqOrange, fontSize: 13)),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(color: hqDim, fontSize: 14)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.t('mode_title'))),
        body: Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.2),
          const CrtOverlay(),
          ListView(padding: const EdgeInsets.all(16), children: [
            _card(
              icon: Icons.lan,
              title: S.t('mode_campaign'),
              desc: S.t('mode_campaign_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  settings: const RouteSettings(name: InboxScreen.routeName),
                  builder: (_) => InboxScreen(progress: progress, catalog: catalog))),
            ),
            _card(
              icon: Icons.grid_4x4,
              title: S.t('mode_breach'),
              desc: S.t('mode_breach_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BreachListScreen(progress: progress))),
            ),
            _card(icon: Icons.folder_open, title: S.t('mode_cases'), desc: S.t('mode_cases_desc'), badge: S.t('mode_soon')),
          ]),
        ]),
      );
}
