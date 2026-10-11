import 'package:flutter/material.dart';

import '../strings.dart';
import 'theme.dart';

class FileView extends StatelessWidget {
  final String path;
  final String text;
  final VoidCallback onClose;
  final String? closeLabel; // 목표를 이룬 뒤엔 「임무 완료」
  const FileView({super.key, required this.path, required this.text, required this.onClose, this.closeLabel});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: hqPanel,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(child: Text(path, style: const TextStyle(color: hqOrange, fontFamily: 'monospace'))),
              TextButton(key: const Key('file_close'), onPressed: onClose, child: Text(closeLabel ?? S.t('btn_close'))),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(text, style: TextStyle(fontSize: 15, height: 1.5, fontFamily: monoFor(text))),
            ),
          ),
        ],
      );
}
