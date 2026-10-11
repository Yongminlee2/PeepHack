import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/breach_gen.dart';
import '../engine/case_file.dart';
import '../engine/progress.dart';
import '../music.dart';
import '../strings.dart';
import 'breach/breach_list_screen.dart';
import 'cases/case_list_screen.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'inbox_screen.dart';
import 'theme.dart';

/// 모드 선택: 작전(이야기) / 브리치(퍼즐) / 사건 파일(추리). 카드마다 진행도, 위에 크레딧.
class ModeScreen extends StatefulWidget {
  final Progress progress;
  final Catalog catalog;
  const ModeScreen({super.key, required this.progress, required this.catalog});

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  Progress get progress => widget.progress;
  Catalog get catalog => widget.catalog;

  Future<void> _go(Widget screen, {RouteSettings? settings}) async {
    await Navigator.push(context, MaterialPageRoute(settings: settings, builder: (_) => screen));
    setState(() {}); // 돌아오면 진행도·크레딧 갱신
  }

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
        appBar: AppBar(title: Text(S.t('mode_title')), actions: [
          IconButton(
            key: const Key('music_toggle'),
            tooltip: S.t('settings_music'),
            icon: Icon(progress.musicOn ? Icons.music_note : Icons.music_off),
            onPressed: () async {
              await Music().setEnabled(!progress.musicOn);
              setState(() {});
            },
          ),
        ]),
        body: Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.2),
          const CrtOverlay(),
          ListView(padding: const EdgeInsets.all(16), children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                const Icon(Icons.memory, color: hqOrange, size: 18),
                const SizedBox(width: 6),
                Text(S.tn('shop_credits', {'n': progress.credits}),
                    style: const TextStyle(color: hqOrange, fontFamily: kMono, fontSize: 15)),
              ]),
            ),
            _card(
              icon: Icons.lan,
              title: S.t('mode_campaign'),
              desc: S.t('mode_campaign_desc'),
              badge: S.tn('mode_progress', {'n': catalog.orderedIds.where(progress.isDone).length, 'm': catalog.missions.length}),
              onTap: () => _go(InboxScreen(progress: progress, catalog: catalog),
                  settings: const RouteSettings(name: InboxScreen.routeName)),
            ),
            _card(
              icon: Icons.grid_4x4,
              title: S.t('mode_breach'),
              desc: S.t('mode_breach_desc'),
              badge: S.tn('mode_progress', {
                'n': [for (var n = 1; n <= kBreachStages; n++) n].where((n) => progress.breachStars(n) > 0).length,
                'm': kBreachStages,
              }),
              onTap: () => _go(BreachListScreen(progress: progress)),
            ),
            _card(
              icon: Icons.folder_open,
              title: S.t('mode_cases'),
              desc: S.t('mode_cases_desc'),
              badge: S.tn('mode_progress', {
                'n': [for (var n = 1; n <= kCaseCount; n++) n].where((n) => progress.caseStars(caseId(n)) > 0).length,
                'm': kCaseCount,
              }),
              onTap: () => _go(CaseListScreen(progress: progress)),
            ),
          ]),
        ]),
      );
}
