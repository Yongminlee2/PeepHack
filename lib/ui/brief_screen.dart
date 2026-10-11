import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../strings.dart';
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.t('brief_from'), style: const TextStyle(color: hqDim)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [for (final b in mission.brief) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr(b), style: const TextStyle(fontSize: 16)))],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => MissionScreen(mission: mission, progress: progress, catalog: catalog))),
                child: Text(S.t('btn_connect')),
              ),
            ],
          ),
        ),
      );
}
