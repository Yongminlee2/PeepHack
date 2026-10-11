import 'package:flutter/material.dart';

import '../../engine/wordguess.dart';
import '../../sfx.dart';
import '../../strings.dart';
import '../theme.dart';

/// 단어 추리 판(폴아웃 단말기처럼). 메모리 덤프 속 단어·괄호를 누른다. 끝나면 [onFinish](성공 여부) 한 번.
class WordBoard extends StatefulWidget {
  final WordPuzzle puzzle;
  final void Function(bool solved) onFinish;
  const WordBoard({super.key, required this.puzzle, required this.onFinish});

  @override
  State<WordBoard> createState() => _WordBoardState();
}

class _WordBoardState extends State<WordBoard> {
  late final WordGame game = WordGame(widget.puzzle);
  final List<(String, bool)> notes = []; // 덤프 아래 기록(글, 강조)
  final _scroll = ScrollController();
  bool _ended = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // 새 기록이 보이게 맨 아래로
  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  static const _mono = TextStyle(fontFamily: kMono, fontSize: 15, height: 1.35);

  void _guess(String w) {
    final n = game.guess(w);
    if (n == null) return;
    setState(() {
      notes.add(('> $w', false));
      if (game.solved) {
        notes.add((S.t('wg_granted'), true));
      } else {
        notes.add((S.t('wg_denied'), false));
        notes.add((S.tn('wg_likeness', {'n': n}), true));
      }
    });
    Sfx().play(game.solved ? 'ok' : 'fail');
    _toEnd();
    _end();
  }

  void _bracket(int id) {
    final r = game.useBracket(id);
    if (r == null) return;
    Sfx().play('tap');
    setState(() => notes.add((r == 'RESET' ? S.t('wg_reset') : S.t('wg_dud'), true)));
    _toEnd();
  }

  void _end() {
    if (_ended || !game.finished) return;
    _ended = true;
    widget.onFinish(game.solved);
  }

  Widget _token(DumpToken t) {
    if (t.word != null) {
      final w = t.word!;
      if (game.removed.contains(w)) return Text('.' * w.length, style: _mono.copyWith(color: hqDim));
      final tried = game.log.any((e) => e.$1 == w);
      return GestureDetector(
        key: Key('word_$w'),
        onTap: () => _guess(w),
        child: Container(
          color: tried ? const Color(0xFF2A1A1A) : const Color(0xFF16301D),
          child: Text(w, style: _mono.copyWith(color: tried ? hqRed : hqGreen, fontWeight: FontWeight.w700)),
        ),
      );
    }
    if (t.bracket != null) {
      final used = game.bracketUsed(t.bracket!);
      return GestureDetector(
        key: Key('bracket_${t.bracket}'),
        onTap: () => _bracket(t.bracket!),
        child: Text(t.text, style: _mono.copyWith(color: used ? hqDim : hqOrange, fontWeight: FontWeight.w700)),
      );
    }
    return Text(t.text, style: _mono.copyWith(color: Colors.white24));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(S.t('wg_title'), style: const TextStyle(color: hqGreen, fontSize: 15)),
        const SizedBox(height: 6),
        Row(children: [
          Text('${S.t('wg_attempts')} ', style: const TextStyle(color: hqDim, fontSize: 13)),
          for (var i = 0; i < p.attempts; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 4),
              color: i < game.left ? hqGreen : hqPanel,
            ),
        ]),
        const SizedBox(height: 8),
        // 덤프는 폭과 높이(70%) 안에서 최대한 키우고(누르기 쉽게), 기록은 바로 아래에 터미널처럼 쌓는다
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: box.maxHeight * 0.7),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.topLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < p.lines.length; i++)
                      Row(key: Key('dump_$i'), children: [
                        Text('0x${(0xF4A0 + i * 16).toRadixString(16).toUpperCase()} ', style: _mono.copyWith(color: hqDim, fontSize: 12)),
                        for (final t in p.lines[i]) _token(t),
                      ]),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final (text, hi) in notes)
                      Text(text, style: TextStyle(fontFamily: monoFor(text), fontSize: 15, color: hi ? hqOrange : hqGreen)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
