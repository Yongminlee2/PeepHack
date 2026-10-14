import 'package:flutter/material.dart';

import '../engine/progress.dart';
import '../strings.dart';
import 'theme.dart';

/// 「하는 법」 카드(사람 플레이: 무엇을 어떻게 하는지 모르겠다).
/// 모드에 처음 들어가면 한 번 뜨고, 목록 화면 위 「?」 로 언제든 다시 본다.
class HowTo {
  /// 위젯 테스트에서는 끈다(test/flutter_test_config.dart) — 안 그러면 화면마다 카드가 가린다.
  static bool autoShow = true;

  /// 모드별 카드 장수. 글 열쇠는 howto_(모드)_(번호)_t / _b.
  static const pages = {'ops': 4, 'breach': 4, 'cases': 3};
  static const _icons = {
    'ops': [Icons.mail_outline, Icons.terminal, Icons.lan, Icons.radar],
    'breach': [Icons.grid_on, Icons.swap_vert, Icons.link, Icons.star_outline],
    'cases': [Icons.find_in_page_outlined, Icons.lock_open, Icons.gavel],
  };

  /// 처음이면 한 번 띄운다. 화면 initState 에서 부른다.
  static void maybeShow(BuildContext context, String mode, Progress p) {
    if (!autoShow || p.seenHowTo(mode)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) show(context, mode, p);
    });
  }

  static Future<void> show(BuildContext context, String mode, Progress p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: hqPanel,
      builder: (_) => _HowToSheet(mode: mode),
    );
    await p.markHowTo(mode);
  }

  /// 목록 화면 앱바의 「?」.
  static Widget button(BuildContext context, String mode, Progress p) => IconButton(
        key: const Key('howto_btn'),
        tooltip: S.t('howto_title'),
        icon: const Icon(Icons.help_outline),
        onPressed: () => show(context, mode, p),
      );
}

class _HowToSheet extends StatefulWidget {
  final String mode;
  const _HowToSheet({required this.mode});
  @override
  State<_HowToSheet> createState() => _HowToSheetState();
}

class _HowToSheetState extends State<_HowToSheet> {
  final _pc = PageController();
  int _page = 0;

  int get _n => HowTo.pages[widget.mode]!;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _n - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(S.t('howto_title'), style: const TextStyle(color: hqOrange, fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(
            height: 300,
            child: PageView(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (var i = 1; i <= _n; i++)
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(HowTo._icons[widget.mode]![i - 1], size: 64, color: hqGreen),
                    const SizedBox(height: 16),
                    Text(S.t('howto_${widget.mode}_${i}_t'),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: hqText)),
                    const SizedBox(height: 12),
                    Text(S.t('howto_${widget.mode}_${i}_b'),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6, color: hqText)),
                  ]),
              ],
            ),
          ),
          // 몇 장 중 몇째인지
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _n; i++)
              Container(
                width: i == _page ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: i == _page ? hqOrange : hqDim, borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('howto_next'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => last
                ? Navigator.pop(context)
                : _pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
            child: Text(S.t(last ? 'howto_start' : 'howto_next'), style: const TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}
