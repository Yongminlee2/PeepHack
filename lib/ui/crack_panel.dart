import 'package:flutter/material.dart';

import '../engine/breach.dart';
import '../engine/mission.dart';
import '../engine/shop.dart';
import '../strings.dart';
import 'breach/breach_board.dart';
import 'fx/juice.dart';
import 'wordguess/word_board.dart';
import 'theme.dart';

/// 포트 크랙: 포트 하나 = 브리치 판 하나. 다 뚫으면 [onCracked], 판을 놓치면 [onFail](추적 벌칙) 뒤 같은 포트를 새 판으로.
class CrackPanel extends StatefulWidget {
  final Mission mission;
  final String hostKey;
  final Set<String> owned;
  final VoidCallback onCracked;
  final VoidCallback onFail;
  final VoidCallback onClose;
  const CrackPanel({
    super.key,
    required this.mission,
    required this.hostKey,
    required this.owned,
    required this.onCracked,
    required this.onFail,
    required this.onClose,
  });

  @override
  State<CrackPanel> createState() => _CrackPanelState();
}

class _CrackPanelState extends State<CrackPanel> {
  int port = 0;
  int attempt = 0;

  int get ports => widget.mission.portsFor(widget.mission.hosts[widget.hostKey]!);

  BreachPuzzle get puzzle => crackPuzzle(
        missionId: widget.mission.id,
        host: widget.hostKey,
        port: port,
        attempt: attempt,
        chapter: widget.mission.chapter,
        owned: widget.owned,
      );

  Future<void> _done(BreachGame g) => _result(g.stars > 0);

  Future<void> _result(bool ok) async {
    if (ok) {
      await finishBeat(); // 뚫는 순간의 연출을 보고 넘어간다
      if (!mounted) return;
      if (port + 1 >= ports) {
        widget.onCracked();
      } else {
        setState(() => port++);
      }
      return;
    }
    widget.onFail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('crack_fail')), duration: const Duration(seconds: 1)));
    await Future<void>.delayed(const Duration(milliseconds: 700)); // 실패한 판을 잠깐 보여 준다
    if (mounted) setState(() => attempt++);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: hqPanel,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Icon(Icons.vpn_key, color: hqOrange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.tn('crack_title', {'i': port + 1, 'n': ports, 'host': widget.mission.hosts[widget.hostKey]!.name}),
                style: const TextStyle(color: hqOrange),
              ),
            ),
            TextButton(onPressed: widget.onClose, child: Text(S.t('btn_close'))),
          ]),
        ),
        // 처음 보는 판이어도 바로 할 수 있게 규칙 한 줄
        Container(
          color: const Color(0xFF101810),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Text(
            S.t(isWordPort(chapter: widget.mission.chapter, port: port) ? 'crack_rule_word' : 'crack_rule_breach'),
            style: const TextStyle(color: hqDim, fontSize: 12, height: 1.35),
          ),
        ),
        Expanded(
          child: isWordPort(chapter: widget.mission.chapter, port: port)
              ? WordBoard(
                  key: ValueKey('w$port-$attempt'),
                  puzzle: wordCrackPuzzle(
                    missionId: widget.mission.id,
                    host: widget.hostKey,
                    port: port,
                    attempt: attempt,
                    chapter: widget.mission.chapter,
                    owned: widget.owned,
                  ),
                  onFinish: _result,
                )
              : BreachBoard(
                  key: ValueKey('$port-$attempt'),
                  puzzle: puzzle,
                  hints: widget.mission.chapter == 1, // 2장부터는 스스로 찾는다
                  onFinish: _done,
                ),
        ),
      ]);
}
