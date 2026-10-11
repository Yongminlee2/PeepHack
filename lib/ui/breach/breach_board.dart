import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/breach.dart';
import '../../sfx.dart';
import '../../strings.dart';
import '../theme.dart';

/// 브리치 프로토콜 판(버퍼·목표·남은 시간·격자). 브리치 모드와 작전 모드(포트 크랙)가 같이 쓴다.
/// 끝나면 [onFinish] 를 한 번 부른다.
class BreachBoard extends StatefulWidget {
  final BreachPuzzle puzzle;
  final void Function(BreachGame game) onFinish;
  const BreachBoard({super.key, required this.puzzle, required this.onFinish});

  @override
  State<BreachBoard> createState() => _BreachBoardState();
}

class _BreachBoardState extends State<BreachBoard> {
  late BreachGame game = BreachGame(widget.puzzle);
  Timer? _timer;
  late int _left = widget.puzzle.timeLimit ?? 0;
  bool _ended = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap(int r, int c) {
    if (!game.pick(r, c)) return;
    Sfx().play('tap');
    // 제한 시간은 첫 선택부터 흐른다(사이버펑크와 같음)
    if (game.picks.length == 1 && widget.puzzle.timeLimit != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _left--);
        if (_left <= 0) {
          game.timeUp();
          _end();
        }
      });
    }
    setState(() {});
    _end();
  }

  void _end() {
    if (_ended || !game.finished) return;
    _ended = true;
    _timer?.cancel();
    Sfx().play(game.stars > 0 ? 'ok' : 'fail');
    widget.onFinish(game);
  }

  /// 버퍼 끝이 목표의 앞부분과 몇 칸 맞는지(진행 표시용).
  int _progress(List<String> d) {
    final b = game.bufferCodes;
    for (var k = d.length - 1; k > 0; k--) {
      if (b.length >= k && List.generate(k, (i) => b[b.length - k + i]).join() == d.sublist(0, k).join()) return k;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final legal = game.legalCells();
    final k = game.picks.length;
    final finished = game.finished;
    bool inLine(int r, int c) {
      if (finished) return false;
      if (k == 0) return r == 0;
      return k.isOdd ? c == game.picks.last.$2 : r == game.picks.last.$1;
    }

    const mono = TextStyle(fontFamily: kMono, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // 버퍼
        Text(S.t('breach_buffer'), style: const TextStyle(color: hqDim, fontSize: 12)),
        const SizedBox(height: 4),
        // 버퍼 칸은 한 줄에 다 들어가게 폭을 나눈다(8칸이 360dp 폰에서 줄을 넘었다)
        LayoutBuilder(builder: (_, box) {
          final w = ((box.maxWidth - 6 * (p.buffer - 1)) / p.buffer).clamp(0.0, 40.0);
          return Row(children: [
            for (var i = 0; i < p.buffer; i++)
              Container(
                key: Key('buf_$i'),
                width: w,
                height: 34,
                margin: EdgeInsets.only(right: i < p.buffer - 1 ? 6 : 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: i < k ? hqGreen : hqDim.withValues(alpha: 0.5))),
                child: FittedBox(child: Text(i < k ? game.bufferCodes[i] : '', style: mono.copyWith(color: hqGreen))),
              ),
          ]);
        }),
        const SizedBox(height: 12),
        // 목표 순서
        Text(S.t('breach_targets'), style: const TextStyle(color: hqDim, fontSize: 12)),
        const SizedBox(height: 4),
        for (var i = 0; i < p.daemons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(game.daemonDone(i) ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18, color: game.daemonDone(i) ? hqGreen : hqDim),
              const SizedBox(width: 8),
              for (var j = 0; j < p.daemons[i].length; j++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(p.daemons[i][j],
                      style: mono.copyWith(
                          color: game.daemonDone(i) ? hqGreen : (j < _progress(p.daemons[i]) ? hqOrange : Colors.white70))),
                ),
            ]),
          ),
        // 남은 시간
        if (p.timeLimit != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: LinearProgressIndicator(
                key: const Key('breach_timer'),
                value: _left / p.timeLimit!,
                color: _left <= 10 ? hqRed : hqOrange,
                backgroundColor: hqPanel,
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 8),
            Text('${_left ~/ 60}:${(_left % 60).toString().padLeft(2, '0')}', style: mono.copyWith(color: _left <= 10 ? hqRed : hqOrange)),
          ]),
        ],
        const SizedBox(height: 12),
        // 격자
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Column(children: [
                for (var r = 0; r < p.size; r++)
                  Expanded(
                    child: Row(children: [
                      for (var c = 0; c < p.size; c++)
                        Expanded(
                          child: GestureDetector(
                            key: Key('cell_${r}_$c'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _tap(r, c),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: inLine(r, c) ? const Color(0xFF16301D) : const Color(0xCC0B0F0C),
                                border: Border.all(color: legal.contains((r, c)) ? hqGreen : hqPanel, width: legal.contains((r, c)) ? 1.5 : 1),
                              ),
                              child: Text(
                                game.picks.contains((r, c)) ? '[ ]' : p.grid[r][c],
                                style: mono.copyWith(
                                  fontSize: 18,
                                  color: game.picks.contains((r, c))
                                      ? hqDim
                                      : (legal.contains((r, c)) ? hqGreen : Colors.white38),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
