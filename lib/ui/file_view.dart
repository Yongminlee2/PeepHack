import 'package:flutter/material.dart';

import '../strings.dart';
import 'readable_text.dart';
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
              Expanded(child: Text(path, style: const TextStyle(color: hqOrange, fontFamily: kMono))),
              TextButton(key: const Key('file_close'), onPressed: onClose, child: Text(closeLabel ?? S.t('btn_close'))),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ReadableText(text),
            ),
          ),
          // 목표를 이뤘으면 아래에 큰 버튼. 위쪽 작은 글자만으로는 실기기에서 눈에 안 띄었다.
          if (closeLabel != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(
                key: const Key('file_finish'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: onClose,
                child: Text('$closeLabel ▶', style: const TextStyle(fontSize: 17)),
              ),
            ),
        ],
      );
}
