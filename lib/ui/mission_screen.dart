// mission_screen.dart (임시)
import 'package:flutter/material.dart';
import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
class MissionScreen extends StatelessWidget {
  final Mission mission; final Progress progress; final Catalog catalog;
  const MissionScreen({super.key, required this.mission, required this.progress, required this.catalog});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('mission')));
}
