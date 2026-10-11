import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'fx/crt.dart';
import 'fx/ghost_avatar.dart';
import 'fx/matrix_rain.dart';
import 'mission_screen.dart';
import 'theme.dart';

class BriefScreen extends StatelessWidget {
  final Mission mission;
  final Progress progress;
  final Catalog catalog;
  const BriefScreen({super.key, required this.mission, required this.progress, required this.catalog});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr(mission.title))),
        body: Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.12),
          const CrtOverlay(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const GhostAvatar(size: 72),
                  const SizedBox(width: 12),
                  Expanded(child: Text(S.t('brief_from'), style: const TextStyle(color: hqDim))),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(children: [
                    for (final b in mission.brief)
                      // 고스트가 보낸 메시지 말풍선
                      Container(
                        margin: const EdgeInsets.only(bottom: 12, right: 24),
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xE6121A14),
                          border: Border(left: BorderSide(color: hqGreen, width: 3)),
                        ),
                        child: Text(tr(b), style: const TextStyle(fontSize: 16, height: 1.45)),
                      ),
                  ]),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => MissionScreen(mission: mission, progress: progress, catalog: catalog))),
                  child: Text('> ${S.t('btn_connect')}', style: const TextStyle(fontSize: 17)),
                ),
              ],
            ),
          ),
        ]),
      );
}
