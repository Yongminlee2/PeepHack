import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../engine/case_file.dart';
import '../../engine/progress.dart';
import '../../strings.dart';
import '../fx/crt.dart';
import '../fx/matrix_rain.dart';
import '../theme.dart';
import 'case_screen.dart';

/// 사건 파일 목록. 앞 사건을 풀어야 다음이 열린다.
class CaseListScreen extends StatefulWidget {
  final Progress progress;
  const CaseListScreen({super.key, required this.progress});
  @override
  State<CaseListScreen> createState() => _CaseListState();
}

class _CaseListState extends State<CaseListScreen> {
  List<CaseFile?>? cases; // 깨진 파일은 null(앱은 죽지 않는다)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final out = <CaseFile?>[];
    for (var i = 1; i <= kCaseCount; i++) {
      try {
        out.add(CaseFile.parse(await rootBundle.loadString('assets/cases/${caseId(i)}.json')));
      } catch (_) {
        out.add(null);
      }
    }
    if (mounted) setState(() => cases = out);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('mode_cases'))),
      body: Stack(fit: StackFit.expand, children: [
        const MatrixRain(opacity: 0.12),
        const CrtOverlay(),
        if (cases == null)
          const Center(child: CircularProgressIndicator())
        else
          ListView(padding: const EdgeInsets.all(16), children: [
            for (var i = 0; i < cases!.length; i++) _tile(i + 1, cases![i], p),
          ]),
      ]),
    );
  }

  Widget _tile(int n, CaseFile? c, Progress p) {
    final open = c != null && p.isCaseUnlocked(n);
    final stars = c == null ? 0 : p.caseStars(c.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        key: Key('case_$n'),
        color: const Color(0xE60B0F0C),
        shape: Border.all(color: hqGreen.withValues(alpha: open ? 0.5 : 0.12)),
        child: ListTile(
          enabled: open,
          leading: Icon(open ? Icons.folder_open : Icons.lock, color: open ? hqGreen : hqDim),
          title: Text(c == null ? caseId(n) : '${S.tn('case_n', {'n': n})} · ${tr(c.title)}'),
          trailing: Text('★' * stars, style: const TextStyle(color: hqOrange)),
          onTap: open
              ? () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => CaseScreen(file: c, progress: p)));
                  setState(() {});
                }
              : null,
        ),
      ),
    );
  }
}
