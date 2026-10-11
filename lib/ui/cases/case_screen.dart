import 'package:flutter/material.dart';

import '../../engine/case_file.dart';
import '../../engine/progress.dart';
import '../../engine/shop.dart';
import '../../sfx.dart';
import '../../strings.dart';
import '../fx/crt.dart';
import '../fx/ghost_avatar.dart';
import '../fx/glitch_text.dart';
import '../fx/matrix_rain.dart';
import '../theme.dart';
import '../wordguess/word_board.dart';

/// 사건 하나: 의뢰 → 자료 읽기(잠긴 건 단어 추리) → 결론 질문 → 결과.
class CaseScreen extends StatefulWidget {
  final CaseFile file;
  final Progress progress;
  const CaseScreen({super.key, required this.file, required this.progress});
  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  late final CaseGame game = CaseGame(widget.file);
  final Set<String> unlocked = {};
  final Map<String, int> lockAttempts = {};
  bool concluding = false;
  final Set<int> wrongPicks = {}; // 지금 질문에서 틀린 선택지
  int? earned;

  CaseFile get c => widget.file;

  Future<void> _openDoc(CaseDoc d) async {
    if (d.lockLength != null && !unlocked.contains(d.name)) {
      final attempt = lockAttempts[d.name] ?? 0;
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(
          builder: (_) => _LockPage(caseId: c.id, doc: d, attempt: attempt)));
      if (!mounted) return;
      if (ok != true) {
        lockAttempts[d.name] = attempt + 1; // 다음엔 다른 퍼즐
        if (ok == false) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('case_lock_failed')), duration: const Duration(seconds: 1)));
        }
        return;
      }
      setState(() => unlocked.add(d.name));
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _DocPage(doc: d)));
  }

  Future<void> _pick(int i) async {
    if (wrongPicks.contains(i)) return;
    if (!game.answer(i)) {
      Sfx().play('fail');
      setState(() => wrongPicks.add(i));
      return;
    }
    Sfx().play('ok');
    setState(wrongPicks.clear);
    if (game.finished) {
      final p = widget.progress;
      final before = p.caseStars(c.id);
      await p.setCaseStars(c.id, game.stars);
      final gained = game.stars > before ? game.stars - before : 0;
      final credits = caseReward(starsGained: gained);
      await p.addCredits(credits);
      if (mounted) setState(() => earned = credits);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr(c.title))),
        body: Stack(fit: StackFit.expand, children: [
          const MatrixRain(opacity: 0.1),
          const CrtOverlay(),
          if (earned != null) _result() else if (concluding) _questions() else _evidence(),
        ]),
      );

  Widget _evidence() => ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const GhostAvatar(size: 56),
          const SizedBox(width: 12),
          Expanded(child: Text(S.t('brief_from'), style: const TextStyle(color: hqDim))),
        ]),
        const SizedBox(height: 12),
        for (final b in c.brief)
          Container(
            margin: const EdgeInsets.only(bottom: 10, right: 24),
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xE6121A14), border: Border(left: BorderSide(color: hqGreen, width: 3))),
            child: Text(tr(b), style: const TextStyle(fontSize: 15, height: 1.45)),
          ),
        const SizedBox(height: 12),
        Text('// ${S.t('case_docs')}', style: const TextStyle(color: hqOrange)),
        const SizedBox(height: 6),
        for (final d in c.docs)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              key: Key('doc_${d.name}'),
              color: const Color(0xE60B0F0C),
              shape: Border.all(color: hqGreen.withValues(alpha: 0.35)),
              child: ListTile(
                leading: Icon(
                  d.lockLength != null && !unlocked.contains(d.name) ? Icons.lock : Icons.description,
                  color: d.lockLength != null && !unlocked.contains(d.name) ? hqOrange : hqGreen,
                ),
                title: Text(d.name, style: const TextStyle(fontFamily: 'monospace')),
                onTap: () => _openDoc(d),
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('case_conclude'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => setState(() => concluding = true),
          child: Text(S.t('case_conclude')),
        ),
      ]);

  Widget _questions() {
    final q = game.current!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(S.tn('case_question_n', {'i': game.index + 1, 'n': c.questions.length}), style: const TextStyle(color: hqOrange)),
      const SizedBox(height: 8),
      Text(tr(q.q), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.4)),
      const SizedBox(height: 16),
      for (var i = 0; i < q.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            key: Key('opt_$i'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.centerLeft,
              foregroundColor: wrongPicks.contains(i) ? hqRed : hqGreen,
              side: BorderSide(color: wrongPicks.contains(i) ? hqRed : hqGreen.withValues(alpha: 0.6)),
            ),
            onPressed: () => _pick(i),
            child: Text(
              '${wrongPicks.contains(i) ? '✗ ' : ''}${tr(q.options[i])}',
              style: TextStyle(fontFamily: monoFor(tr(q.options[i])), fontSize: 15),
            ),
          ),
        ),
      TextButton(onPressed: () => setState(() => concluding = false), child: Text(S.t('case_back_docs'))),
    ]);
  }

  Widget _result() => ListView(padding: const EdgeInsets.all(24), children: [
        Center(child: GlitchText(S.t('case_solved'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: hqGreen))),
        const SizedBox(height: 12),
        Text('★' * game.stars + '☆' * (3 - game.stars), textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, color: hqOrange)),
        if (earned! > 0)
          Text(S.tn('result_credits', {'n': earned!}), textAlign: TextAlign.center, style: const TextStyle(color: hqOrange, fontFamily: 'monospace')),
        const SizedBox(height: 20),
        for (final d in c.done) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(tr(d), style: const TextStyle(fontSize: 16, height: 1.45))),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(S.t('btn_list'))),
      ]);
}

class _DocPage extends StatelessWidget {
  final CaseDoc doc;
  const _DocPage({required this.doc});
  @override
  Widget build(BuildContext context) {
    final text = tr(doc.text);
    return Scaffold(
      appBar: AppBar(title: Text(doc.name, style: const TextStyle(fontFamily: 'monospace', fontSize: 16))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(text, style: TextStyle(fontFamily: monoFor(text), fontSize: 15, height: 1.6)),
      ),
    );
  }
}

/// 잠긴 자료 열기: 단어 추리. 맞히면 true, 기회를 다 쓰면 false 로 돌아간다.
class _LockPage extends StatelessWidget {
  final String caseId;
  final CaseDoc doc;
  final int attempt;
  const _LockPage({required this.caseId, required this.doc, required this.attempt});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${doc.name} · ${S.t('case_locked')}', style: const TextStyle(fontSize: 16))),
        body: WordBoard(
          puzzle: caseLockPuzzle(caseId, doc.name, doc.lockLength!, attempt),
          onFinish: (ok) async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            if (context.mounted) Navigator.pop(context, ok);
          },
        ),
      );
}
