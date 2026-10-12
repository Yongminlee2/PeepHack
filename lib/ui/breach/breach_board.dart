import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/breach.dart';
import '../../sfx.dart';
import '../../strings.dart';
import '../theme.dart';

/// 목표(데몬)마다 붙는 효과 이름 — 코드 줄이 「무엇을 얻는지」로 읽히게.
const kBreachEffects = ['alarm', 'door', 'camera'];
String breachEffectName(int i) => S.t('breach_d_${kBreachEffects[i % kBreachEffects.length]}');

/// 브리치 프로토콜 판(버퍼·목표·남은 시간·격자). 브리치 모드와 작전 모드(포트 크랙)가 같이 쓴다.
/// 끝나면 [onFinish] 를 한 번 부른다.
/// 누르면 목표가 한 칸 나아가는 칸은 주황으로 빛난다. [guide] 면 따라 하기 연습판(정답 칸을 가리키고 규칙을 한 줄씩).
class BreachBoard extends StatefulWidget {
  final BreachPuzzle puzzle;
  final void Function(BreachGame game) onFinish;
  final bool guide;
  const BreachBoard({super.key, required this.puzzle, required this.onFinish, this.guide = false});

  @override
  State<BreachBoard> createState() => _BreachBoardState();
}

class _BreachBoardState extends State<BreachBoard> {
  late BreachGame game = BreachGame(widget.puzzle);
  Timer? _timer;
  late int _left = widget.puzzle.timeLimit ?? 0;
  bool _ended = false;
  String? _flash; // 「경보 끄기 완료」·「연쇄!」 — 잠깐 떴다 사라진다
  bool _flashChain = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _showDone() {
    final done = game.lastCompleted;
    if (done.isEmpty) return;
    if (!game.finished) Sfx().play('ok'); // 마지막 칸은 _end 가 울린다
    _flashChain = game.lastChained;
    _flash = _flashChain ? S.t('breach_chain') : S.tn('breach_done', {'name': done.map(breachEffectName).join(', ')});
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  /// 연습판에서 다음에 누를 정답 칸(정답대로 따라오고 있을 때만).
  (int, int)? get _guideCell {
    final sol = widget.puzzle.solution;
    final k = game.picks.length;
    if (!widget.guide || game.finished || k >= sol.length) return null;
    for (var i = 0; i < k; i++) {
      if (game.picks[i] != sol[i]) return null;
    }
    return sol[k];
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
    setState(_showDone);
    _end();
  }

  void _end() {
    if (_ended || !game.finished) return;
    _ended = true;
    _timer?.cancel();
    Sfx().play(game.stars > 0 ? 'ok' : 'fail');
    widget.onFinish(game);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final legal = game.legalCells();
    // 연습판에선 손가락 칸만 빛낸다(여럿 빛나면 어느 걸 누를지 헷갈렸다 — 실기기)
    final hints = widget.guide ? const <(int, int)>{} : game.hintCells();
    final guideCell = _guideCell;
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
              const SizedBox(width: 6),
              // 효과 이름: 이 줄을 채우면 무엇을 얻는지
              SizedBox(
                width: 96,
                child: Text(breachEffectName(i), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: game.daemonDone(i) ? hqGreen : Colors.white70)),
              ),
              for (var j = 0; j < p.daemons[i].length; j++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(p.daemons[i][j],
                      style: mono.copyWith(
                          color: game.daemonDone(i) ? hqGreen : (j < game.progress(i) ? hqOrange : Colors.white70))),
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
        // 연습판 안내 한 줄 + 완료·연쇄 알림(자리를 늘 잡아 판이 출렁이지 않게)
        if (widget.guide && !finished)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(S.t(k == 0 ? 'breach_tut_top' : (k.isOdd ? 'breach_tut_col' : 'breach_tut_row')),
                textAlign: TextAlign.center, style: const TextStyle(color: hqOrange, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        SizedBox(
          height: 30,
          child: Center(
            child: _flash == null
                ? null
                : Text(_flash!,
                    style: TextStyle(
                        color: _flashChain ? hqOrange : hqGreen,
                        fontSize: _flashChain ? 20 : 16,
                        fontWeight: FontWeight.w900)),
          ),
        ),
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
                            child: _cell(r, c, legal: legal.contains((r, c)), hint: hints.contains((r, c)),
                                guide: guideCell == (r, c), line: inLine(r, c), mono: mono),
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

  Widget _cell(int r, int c, {required bool legal, required bool hint, required bool guide, required bool line, required TextStyle mono}) {
    final p = widget.puzzle;
    final picked = game.picks.contains((r, c));
    final glow = hint || guide;
    return Container(
      key: guide ? Key('guide_${r}_$c') : (hint ? Key('hint_${r}_$c') : null),
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: glow ? const Color(0xFF33260A) : (line ? const Color(0xFF16301D) : const Color(0xCC0B0F0C)),
        border: Border.all(
          color: glow ? hqOrange : (legal ? hqGreen : hqPanel),
          width: guide ? 3 : (glow || legal ? 1.5 : 1),
        ),
      ),
      // 손가락은 칸 귀퉁이에(글자를 가리지 않게) — Stack 이 칸 전체를 차지해야 귀퉁이가 칸 귀퉁이다
      child: Stack(fit: StackFit.expand, children: [
        Center(
          child: Text(
            picked ? '[ ]' : p.grid[r][c],
            style: mono.copyWith(
              fontSize: 18,
              color: picked ? hqDim : (glow ? hqOrange : (legal ? hqGreen : Colors.white38)),
            ),
          ),
        ),
        if (guide) const Positioned(right: 2, bottom: 2, child: Icon(Icons.touch_app, size: 16, color: hqOrange)),
      ]),
    );
  }
}
