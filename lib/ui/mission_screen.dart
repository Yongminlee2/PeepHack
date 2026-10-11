import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../engine/rewards.dart';
import '../engine/shell.dart';
import '../engine/shop.dart';
import '../engine/trace.dart';
import '../sfx.dart';
import '../strings.dart';
import 'crack_panel.dart';
import 'file_view.dart';
import 'fx/glitch_text.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'input_bar.dart';
import 'network_map.dart';
import 'puzzles/puzzle_view.dart';
import 'result_screen.dart';
import 'terminal_view.dart';
import 'theme.dart';

enum _Win { terminal, file, puzzle, crack }

class MissionScreen extends StatefulWidget {
  final Mission mission;
  final Progress progress;
  final Catalog catalog;
  const MissionScreen({super.key, required this.mission, required this.progress, required this.catalog});
  @override
  State<MissionScreen> createState() => _MissionState();
}

class _MissionState extends State<MissionScreen> {
  late final Shell shell = Shell(widget.mission);
  final List<TermLine> lines = [];
  _Win win = _Win.terminal;
  String filePath = '';
  String fileText = '';
  String puzzleId = '';
  int hintsUsed = 0;
  final startedAt = DateTime.now();
  late final Trace trace = Trace(widget.mission.trace);
  Timer? _traceTimer;
  bool caught = false;
  bool _alarmed = false;
  String crackHost = '';

  @override
  void initState() {
    super.initState();
    // 접속 연출(한 글자씩 찍힌다)
    lines.addAll([TermLine(S.t('shell_boot_1')), TermLine(S.t('shell_boot_2')), TermLine(S.t('shell_welcome'))]);
    // 추적: 시작 서버를 벗어나 있는 동안 1초마다 오른다(Hacknet 처럼)
    if (trace.enabled) {
      _traceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_finished || caught) return;
        trace.tick(1, exposed: shell.hostKey != widget.mission.start, speed: traceSpeed(widget.progress.owned));
        _checkAlarm();
        _checkCaught();
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _traceTimer?.cancel();
    super.dispose();
  }

  void _checkAlarm() {
    if (_alarmed || trace.level < 0.7) return;
    _alarmed = true;
    Sfx().play('alarm');
  }

  void _checkCaught() {
    if (!trace.caught || caught) return;
    caught = true;
    _traceTimer?.cancel();
    Sfx().play('fail');
  }

  // 지도에서 서버를 눌렀다
  void _tapHost(String key) {
    if (caught || key == shell.hostKey) return;
    final m = widget.mission;
    final h = m.hosts[key]!;
    if (!h.isProtected || shell.isUnlocked(key)) {
      _onRun('connect ${h.name}');
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(h.name, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: hqOrange)),
          const SizedBox(height: 4),
          Text(S.t('map_choose'), style: const TextStyle(color: hqDim)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(S.t('map_open_clue')),
            onPressed: () {
              Navigator.pop(ctx);
              if (h.user != null) {
                setState(() => lines.add(TermLine(S.tn('map_need_ssh', {'host': h.name}), isError: true)));
              } else {
                _onRun('connect ${h.name}');
              }
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.vpn_key),
            label: Text(S.tn('map_crack', {'n': m.portsFor(h)})),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                crackHost = key;
                win = _Win.crack;
              });
            },
          ),
          const SizedBox(height: 4),
          Text(S.t('map_crack_note'), style: const TextStyle(color: hqDim, fontSize: 12)),
        ]),
      ),
    );
  }

  void _cracked() {
    Sfx().play('ok');
    final r = shell.crack(crackHost);
    win = _Win.terminal;
    _show(r);
    _afterAction();
  }

  void _crackFailed() {
    trace.penalty();
    _checkAlarm();
    _checkCaught();
    setState(() {});
  }

  void _show(ShellResult r) {
    if (r.key != null) lines.add(TermLine(S.tn(r.key!, r.args), isError: r.isError));
    // 파일 내용도 터미널 기록에 남긴다. 창을 닫은 뒤에도 비밀번호 같은 걸 다시 볼 수 있게.
    if (r.text.isNotEmpty) lines.add(TermLine(tr(r.text)));
    if (r.openFile != null) {
      filePath = r.openFile!;
      fileText = tr(r.fileText ?? '');
      win = _Win.file;
    } else if (r.openPuzzle != null) {
      puzzleId = r.openPuzzle!;
      win = _Win.puzzle;
    } else {
      win = _Win.terminal; // 결과가 창 뒤에 숨지 않게
    }
  }

  bool _finished = false;

  void _afterAction() {
    setState(() {});
    // 목표 파일을 막 열었으면 내용을 먼저 읽게 둔다. 창을 닫을 때 완료로 넘어간다.
    if (shell.goalDone && win != _Win.file) _finish();
  }

  void _closeFile() {
    setState(() => win = _Win.terminal);
    if (shell.goalDone) _finish();
  }

  void _onRun(String line) {
    lines.add(TermLine(shell.awaitingPassword ? '••••' : line, isCmd: true));
    final r = shell.run(line);
    if (r.isError) Sfx().play('fail');
    _show(r);
    _afterAction();
  }

  bool _onPuzzle(Object answer) {
    final r = shell.submitPuzzle(puzzleId, answer);
    if (r.key == 'puzzle_wrong') {
      Sfx().play('fail');
      return false;
    }
    Sfx().play('ok');
    win = _Win.terminal;
    _show(r);
    _afterAction();
    return true;
  }

  Future<void> _finish() async {
    if (_finished) return; // 전환 중에 한 번 더 불려도 완료 화면은 하나
    _finished = true;
    Sfx().play('ok');
    _traceTimer?.cancel();
    final p = widget.progress;
    final id = widget.mission.id;
    final firstClear = !p.isDone(id);
    final before = p.stars(id);
    await p.complete(id, hintsUsed);
    final earned = missionReward(firstClear: firstClear, starsGained: math.max(0, p.stars(id) - before));
    await p.addCredits(earned);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(
      mission: widget.mission, progress: widget.progress, catalog: widget.catalog,
      hintsUsed: hintsUsed, elapsed: DateTime.now().difference(startedAt), earned: earned,
    )));
  }

  String _hintText(int i) {
    final h = widget.mission.hints;
    if (i < h.length) return tr(h[i]);
    return S.tn('hint_next_cmd', {'cmd': shell.nextSolutionLine() ?? '-'});
  }

  void _openHints() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(S.tn('hint_title', {'n': math.max(1, 3 - hintsUsed)}), style: const TextStyle(color: hqOrange, fontSize: 16)),
          const SizedBox(height: 8),
          for (var i = 0; i < hintsUsed; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${i + 1}. ${_hintText(i)}')),
          if (hintsUsed < 3)
            FilledButton(
              onPressed: () async {
                if (!await Rewards.unlockHint(widget.mission.id)) return;
                setState(() => hintsUsed++);
                setSheet(() {});
              },
              child: Text(S.t('btn_hint_next')),
            )
          else
            Text(S.t('hint_none_left'), style: const TextStyle(color: hqDim)),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final Widget window = switch (win) {
      _Win.terminal => Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.07),
          TerminalView(lines: lines),
          const CrtOverlay(),
        ]),
      _Win.file => FileView(key: const Key('file_view'), path: filePath, text: fileText, onClose: _closeFile,
          closeLabel: shell.goalDone ? S.t('result_title') : null),
      _Win.puzzle => PuzzleView(
          key: ValueKey(puzzleId),
          puzzle: m.puzzleById(puzzleId)!,
          onSubmit: _onPuzzle,
          onClose: () => setState(() => win = _Win.terminal),
        ),
      _Win.crack => CrackPanel(
          key: ValueKey('crack_$crackHost'),
          mission: m,
          hostKey: crackHost,
          owned: widget.progress.owned,
          onCracked: _cracked,
          onFail: _crackFailed,
          onClose: () => setState(() => win = _Win.terminal),
        ),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('${shell.host.name}:${shell.cwd}', style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: S.t('btn_exit'), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton.icon(
            onPressed: _openHints,
            icon: const Icon(Icons.lightbulb_outline, color: hqOrange),
            label: Text('${S.t('btn_hint')} ${'★' * math.max(1, 3 - hintsUsed)}', style: const TextStyle(color: hqOrange)),
          ),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          if (trace.enabled) _traceBar(),
          // 지도는 터미널에서만. 퍼즐·크랙·파일 창에는 자리를 돌려준다(작은 화면에서 퍼즐 칸이 잘렸다).
          if (win == _Win.terminal) NetworkMap(mission: m, shell: shell, onTap: _tapHost),
          Expanded(child: window),
          InputBar(
            suggestions: shell.suggestions(),
            editable: m.input == 'keyboard',
            password: shell.awaitingPassword,
            onRun: _onRun,
          ),
        ]),
        // 추적 70% 이상: 화면 가장자리 붉은빛
        if (trace.level >= 0.7 && !caught)
          const Positioned.fill(
            child: IgnorePointer(
              key: Key('trace_alarm'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(radius: 1.0, colors: [Color(0x00FF2E2E), Color(0x00FF2E2E), Color(0x66FF2E2E)], stops: [0, 0.65, 1]),
                ),
              ),
            ),
          ),
        if (caught) _caughtPanel(),
      ]),
    );
  }

  Widget _traceBar() {
    final pct = (trace.level * 100).round();
    final color = trace.level >= 0.7 ? hqRed : (trace.level >= 0.4 ? hqOrange : hqGreen);
    return Container(
      color: hqPanel,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(children: [
        Icon(Icons.radar, size: 16, color: color),
        const SizedBox(width: 6),
        Text(S.tn('trace_label', {'n': pct}), style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace')),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            key: const Key('trace_bar'),
            value: trace.level,
            color: color,
            backgroundColor: const Color(0xFF1C2620),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }

  Widget _caughtPanel() => TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: const Color(0xDDB00020), end: const Color(0xE6000000)),
        duration: const Duration(milliseconds: 600),
        builder: (_, color, child) => Container(color: color, child: child),
        child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: GlitchText(S.t('trace_caught'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: hqRed))),
          const SizedBox(height: 12),
          Text(S.t('trace_caught_desc'), textAlign: TextAlign.center, style: const TextStyle(color: hqDim)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => MissionScreen(mission: widget.mission, progress: widget.progress, catalog: widget.catalog))),
            child: Text(S.t('btn_retry')),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(S.t('btn_back_inbox'))),
        ]),
        ),
      );
}
