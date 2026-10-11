import 'package:flutter/material.dart';

import 'catalog.dart';
import 'engine/progress.dart';
import 'sfx.dart';
import 'strings.dart';
import 'ui/title_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLang().load();
  final progress = await Progress.load();
  final catalog = await Catalog.load();
  await Sfx().load(progress);
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
          // 안드로이드 15 부터 앱이 화면 끝까지 그린다(edge-to-edge). 아래 시스템 바 밑으로
          // 버튼이 깔리지 않게 모든 화면을 바 위로 올린다. 위쪽은 AppBar 가 처리한다.
          builder: (_, child) => ColoredBox(color: hqBg, child: SafeArea(top: false, child: child!)),
          home: TitleScreen(progress: progress, catalog: catalog),
        ),
      );
}
