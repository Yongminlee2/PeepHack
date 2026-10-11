// settings_screen.dart (임시)
import 'package:flutter/material.dart';
import '../engine/progress.dart';
class SettingsScreen extends StatelessWidget {
  final Progress progress;
  const SettingsScreen({super.key, required this.progress});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('settings')));
}
