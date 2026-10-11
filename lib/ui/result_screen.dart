import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'brief_screen.dart';
import 'fx/crt.dart';
import 'fx/glitch_text.dart';
import 'fx/matrix_rain.dart';
import 'inbox_screen.dart';
import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Mission mission;
  final Progress progress;
  final Catalog catalog;
  final int hintsUsed;
  final Duration elapsed;
  const ResultScreen({super.key, required this.mission, required this.progress, required this.catalog, required this.hintsUsed, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final next = catalog.after(mission.id);
    final stars = progress.stars(mission.id);
    return Scaffold(
      appBar: AppBar(title: Text(S.t('result_title')), automaticallyImplyLeading: false),
      body: Stack(fit: StackFit.expand, children: [
        const MatrixRain(opacity: 0.22),
        const CrtOverlay(),
        Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 12),
          const Center(child: GlitchText('ACCESS GRANTED', style: TextStyle(
              fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3, color: hqGreen))),
          const SizedBox(height: 16),
          Text('★' * stars + '☆' * (3 - stars), textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, color: hqOrange)),
          const SizedBox(height: 8),
          Text(S.tn('result_time', {'m': elapsed.inMinutes, 's': elapsed.inSeconds % 60}), textAlign: TextAlign.center),
          Text(S.tn('result_hints', {'n': hintsUsed}), textAlign: TextAlign.center, style: const TextStyle(color: hqDim)),
          const SizedBox(height: 20),
          Expanded(child: ListView(children: [for (final d in mission.done) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr(d), style: const TextStyle(fontSize: 16)))])),
          // 광고 자리. SDK 는 2부 이후에 붙인다 — 자리를 먼저 잡아 두면 판이 안 밀린다.
          const SizedBox(height: 60),
          if (next != null)
            FilledButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => BriefScreen(mission: next, progress: progress, catalog: catalog))),
              child: Text(S.t('btn_next')),
            ),
          TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.settings.name == InboxScreen.routeName || r.isFirst), child: Text(S.t('btn_back_inbox'))),
        ]),
      ),
      ]),
    );
  }
}
