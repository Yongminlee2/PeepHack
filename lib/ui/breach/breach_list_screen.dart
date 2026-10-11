import 'package:flutter/material.dart';

import '../../engine/breach_gen.dart';
import '../../engine/progress.dart';
import '../../strings.dart';
import '../fx/crt.dart';
import '../fx/matrix_rain.dart';
import '../theme.dart';
import 'breach_play_screen.dart';

/// 브리치 목록: 오늘의 퍼즐 + 묶음 3개 × 20 스테이지.
class BreachListScreen extends StatefulWidget {
  final Progress progress;
  const BreachListScreen({super.key, required this.progress});
  @override
  State<BreachListScreen> createState() => _BreachListState();
}

class _BreachListState extends State<BreachListScreen> {
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    setState(() {}); // 돌아오면 별 갱신
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final today = DateTime.now();
    final daily = p.dailyStars(today);
    return Scaffold(
      appBar: AppBar(title: Text(S.t('mode_breach'))),
      body: Stack(fit: StackFit.expand, children: [
        const MatrixRain(opacity: 0.12),
        const CrtOverlay(),
        ListView(padding: const EdgeInsets.all(16), children: [
          Material(
            key: const Key('daily'),
            color: const Color(0xE6122017),
            shape: Border.all(color: hqOrange.withValues(alpha: 0.7)),
            child: InkWell(
              onTap: () => _open(BreachPlayScreen.daily(progress: p, day: today)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.today, color: hqOrange, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(S.t('breach_daily'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (p.dailyStreak(today) > 0)
                        Text(S.tn('breach_streak', {'n': p.dailyStreak(today)}), style: const TextStyle(color: hqOrange, fontSize: 13)),
                    ]),
                  ),
                  Text('★' * daily + '☆' * (3 - daily), style: const TextStyle(color: hqOrange, fontSize: 18)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(S.t('breach_howto'), style: const TextStyle(color: hqDim, fontSize: 13, height: 1.4)),
          for (var pack = 0; pack < kBreachStages ~/ 20; pack++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
              child: Text('// ${S.tn('breach_pack_n', {'n': pack + 1})}', style: const TextStyle(color: hqOrange, fontSize: 16)),
            ),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [for (var n = pack * 20 + 1; n <= pack * 20 + 20; n++) _tile(n)],
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _tile(int n) {
    final p = widget.progress;
    final open = p.isBreachUnlocked(n);
    final stars = p.breachStars(n);
    return Material(
      key: Key('stage_$n'),
      color: const Color(0xE60B0F0C),
      shape: Border.all(color: open ? hqGreen.withValues(alpha: stars > 0 ? 0.8 : 0.5) : hqPanel),
      child: InkWell(
        onTap: open ? () => _open(BreachPlayScreen.stage(progress: p, n: n)) : null,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          open
              ? Text('$n', style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w700))
              : const Icon(Icons.lock, size: 18, color: hqDim),
          Text('★' * stars, style: const TextStyle(color: hqOrange, fontSize: 11)),
        ]),
      ),
    );
  }
}
