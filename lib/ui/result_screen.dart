// lib/ui/result_screen.dart (임시, Task 12 에서 교체)
import 'package:flutter/material.dart';
import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
class ResultScreen extends StatelessWidget {
  final Mission mission; final Progress progress; final Catalog catalog; final int hintsUsed; final Duration elapsed;
  const ResultScreen({super.key, required this.mission, required this.progress, required this.catalog, required this.hintsUsed, required this.elapsed});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('result')));
}
