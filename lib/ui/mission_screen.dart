import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../engine/rewards.dart';
import '../engine/shell.dart';
import '../strings.dart';
import 'file_view.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'input_bar.dart';
import 'puzzles/puzzle_view.dart';
import 'result_screen.dart';
import 'terminal_view.dart';
import 'theme.dart';

enum _Win { terminal, file, puzzle }

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

  @override
  void initState() {
    super.initState();
    lines.add(TermLine(S.t('shell_welcome')));
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
    _show(shell.run(line));
    _afterAction();
  }

  bool _onPuzzle(Object answer) {
    final r = shell.submitPuzzle(puzzleId, answer);
    if (r.key == 'puzzle_wrong') return false;
    win = _Win.terminal;
    _show(r);
    _afterAction();
    return true;
  }

  Future<void> _finish() async {
    if (_finished) return; // 전환 중에 한 번 더 불려도 완료 화면은 하나
    _finished = true;
    await widget.progress.complete(widget.mission.id, hintsUsed);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(
      mission: widget.mission, progress: widget.progress, catalog: widget.catalog,
      hintsUsed: hintsUsed, elapsed: DateTime.now().difference(startedAt),
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
          Text(S.tn('hint_title', {'n': 3 - hintsUsed}), style: const TextStyle(color: hqOrange, fontSize: 16)),
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
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('${shell.host.name}:${shell.cwd}', style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: S.t('btn_exit'), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton.icon(
            onPressed: _openHints,
            icon: const Icon(Icons.lightbulb_outline, color: hqOrange),
            label: Text('${S.t('btn_hint')} ${'★' * (3 - hintsUsed)}', style: const TextStyle(color: hqOrange)),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(child: window),
        InputBar(
          suggestions: shell.suggestions(),
          editable: m.input == 'keyboard',
          password: shell.awaitingPassword,
          onRun: _onRun,
        ),
      ]),
    );
  }
}
