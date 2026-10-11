import 'dart:async';

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'engine/progress.dart';
import 'music.dart';
import 'sfx.dart';
import 'strings.dart';
import 'ui/title_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLang().load();
  final progress = await Progress.load();
  final catalog = await Catalog.load();
  runApp(HackQuestApp(progress: progress, catalog: catalog));
  // 소리는 첫 화면이 뜬 뒤에 불러온다. 플레이어 15개 준비가 첫 화면을 붙잡지 않게.
  unawaited(Sfx().load(progress));
  unawaited(Music().start(progress));
}

class HackQuestApp extends StatefulWidget {
  final Progress progress;
  final Catalog catalog;
  const HackQuestApp({super.key, required this.progress, required this.catalog});

  @override
  State<HackQuestApp> createState() => _HackQuestAppState();
}

class _HackQuestAppState extends State<HackQuestApp> with WidgetsBindingObserver {
  Progress get progress => widget.progress;
  Catalog get catalog => widget.catalog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 다른 앱으로 나가면 음악을 멈추고, 돌아오면 이어서
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Music().resume();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      Music().pause();
    }
  }

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
