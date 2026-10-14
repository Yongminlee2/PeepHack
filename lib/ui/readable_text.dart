import 'package:flutter/material.dart';

import 'theme.dart';

/// 읽는 글 한 덩어리(파일 창·사건 자료).
/// - 한글 등 사람이 읽는 글: 밝은 글씨, 넓은 줄 간격, 줄을 바꾼다.
/// - 영문 기록·코드: 고정폭. 한 기록이 두 줄로 꺾이면 맞춰 보기 어려워서(실기기) 가장 긴 줄에 맞춰
///   글자 크기를 줄이고(10~15), 그래도 넘치면 옆으로 민다.
///
/// [prose] 는 번역되는 글('@열쇠' — 메모·채팅·쪽지)이다. 영어로 보면 영문뿐이라 기록처럼 보이지만 문장이라 꺾는다.
/// 꺾지 않으면 한 줄로 늘어져 뒷부분이 화면 밖에 숨는다(아이폰 SE 영어에서 찾음).
class ReadableText extends StatelessWidget {
  final String text;
  final bool prose;
  const ReadableText(this.text, {super.key, this.prose = false});

  @override
  Widget build(BuildContext context) {
    if (prose || monoFor(text) != kMono) {
      return SelectableText(text, style: const TextStyle(fontFamily: kSans, color: hqText, fontSize: 16, height: 1.65));
    }
    return LayoutBuilder(builder: (_, box) {
      final longest = text.split('\n').fold<int>(1, (m, l) => l.length > m ? l.length : m);
      final size = (box.maxWidth / (longest * 0.62)).clamp(10.0, 15.0);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(text, style: TextStyle(fontFamily: kMono, color: hqGreen, fontSize: size, height: 1.7)),
      );
    });
  }
}
