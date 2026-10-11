import 'package:flutter/material.dart';

import 'catalog.dart';
import 'engine/progress.dart';
import 'strings.dart';
import 'ui/inbox_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLang().load();
  final progress = await Progress.load();
  final catalog = await Catalog.load();
  runApp(HackQuestApp(progress: progress, catalog: catalog));
}

class HackQuestApp extends StatelessWidget {
  final Progress progress;
  final Catalog catalog;
  const HackQuestApp({super.key, required this.progress, required this.catalog});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: AppLang(),
        builder: (_, _, _) => MaterialApp(
          title: 'HackQuest',
          theme: hqTheme,
          home: InboxScreen(progress: progress, catalog: catalog),
        ),
      );
}
