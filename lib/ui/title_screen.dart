import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'fx/crt.dart';
import 'fx/ghost_avatar.dart';
import 'fx/glitch_text.dart';
import 'fx/matrix_rain.dart';
import 'inbox_screen.dart';
import 'theme.dart';

class TitleScreen extends StatelessWidget {
  final Progress progress;
  final Catalog catalog;
  const TitleScreen({super.key, required this.progress, required this.catalog});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.55),
          const CrtOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const Spacer(flex: 2),
                const GhostAvatar(size: 200),
                const SizedBox(height: 28),
                const GlitchText('HACKQUEST', style: TextStyle(
                  fontFamily: 'monospace', fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 6, color: hqGreen)),
                const SizedBox(height: 12),
                Text(S.t('title_tagline'), textAlign: TextAlign.center, style: const TextStyle(color: hqDim, fontSize: 15)),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hqGreen,
                      side: const BorderSide(color: hqGreen, width: 1.5),
                      backgroundColor: const Color(0xCC000000),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        settings: const RouteSettings(name: InboxScreen.routeName),
                        builder: (_) => InboxScreen(progress: progress, catalog: catalog))),
                    child: Text('> ${S.t('btn_start')}_', style: const TextStyle(fontFamily: 'monospace', fontSize: 18, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      );
}
