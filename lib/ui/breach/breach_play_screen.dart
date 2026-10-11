import 'package:flutter/material.dart';

import '../../engine/breach.dart';
import '../../engine/breach_gen.dart';
import '../../engine/progress.dart';
import '../../strings.dart';
import '../fx/crt.dart';
import '../fx/glitch_text.dart';
import '../fx/matrix_rain.dart';
import '../theme.dart';
import 'breach_board.dart';

/// 브리치 한 판: 스테이지 n 또는 오늘의 퍼즐.
class BreachPlayScreen extends StatefulWidget {
  final Progress progress;
  final int? n;
  final DateTime? day;

  const BreachPlayScreen.stage({super.key, required this.progress, required int this.n}) : day = null;
  const BreachPlayScreen.daily({super.key, required this.progress, required DateTime this.day}) : n = null;

  @override
  State<BreachPlayScreen> createState() => _BreachPlayState();
}

class _BreachPlayState extends State<BreachPlayScreen> {
  late final BreachPuzzle puzzle = widget.n != null ? generateStage(widget.n!) : generateDaily(widget.day!);
  int attempt = 0; // 「다시」 할 때마다 판을 새로 만든다
  BreachGame? result;

  String get _title => widget.n != null
      ? S.tn('breach_stage_n', {'n': widget.n!})
      : S.tn('breach_daily_title', {'date': '${widget.day!.month}.${widget.day!.day}'});

  Future<void> _finish(BreachGame g) async {
    if (widget.n != null) {
      await widget.progress.setBreachStars(widget.n!, g.stars);
    } else {
      await widget.progress.setDailyStars(widget.day!, g.stars);
    }
    if (mounted) setState(() => result = g);
  }

  void _retry() => setState(() {
        attempt++;
        result = null;
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: S.t('btn_retry'), onPressed: _retry)],
        ),
        body: Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.08),
          const CrtOverlay(), // 판 아래에 깐다 — 위에 덮으면 버퍼·목표 글자가 어두워진다(실기기)
          BreachBoard(key: ValueKey(attempt), puzzle: puzzle, onFinish: _finish),
          if (result != null) _resultPanel(result!),
        ]),
      );

  Widget _resultPanel(BreachGame g) {
    final ok = g.stars > 0;
    final next = widget.n != null && widget.n! < kBreachStages && ok;
    return Container(
      color: const Color(0xD9000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: GlitchText(ok ? S.t('breach_success') : S.t('breach_fail'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: ok ? hqGreen : hqRed)),
        ),
        if (g.timedOut) Text(S.t('breach_timeout'), textAlign: TextAlign.center, style: const TextStyle(color: hqOrange)),
        const SizedBox(height: 12),
        Text('★' * g.stars + '☆' * (3 - g.stars), textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, color: hqOrange)),
        const SizedBox(height: 24),
        if (next)
          FilledButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => BreachPlayScreen.stage(progress: widget.progress, n: widget.n! + 1))),
            child: Text(S.t('btn_next_stage')),
          ),
        OutlinedButton(onPressed: _retry, child: Text(S.t('btn_retry'))),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(S.t('btn_list'))),
      ]),
    );
  }
}
