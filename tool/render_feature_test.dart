// 플레이 스토어 대표 그래픽(1024×500)을 언어별로 뽑는다.
//   flutter test tool/render_feature_test.dart   → store/feature_ko.png, feature_en.png
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _green = Color(0xFF00FF46);
const _orange = Color(0xFFFFB000);

void main() {
  testWidgets('대표 그래픽 뽑기', (t) async {
    t.view.physicalSize = const Size(1100, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      final font = FontLoader('HackMono')..addFont(rootBundle.load('assets/fonts/HackMono.ttf'));
      await font.load();
      // HackMono 에는 한글이 없다 — 앱처럼 기본(맑은 고딕) 글꼴로 받친다
      final ko = FontLoader('Ko')..addFont(Future.value(ByteData.sublistView(File('C:/Windows/Fonts/malgun.ttf').readAsBytesSync())));
      await ko.load();
    });
    final svg = (await t.runAsync(() => rootBundle.loadString('assets/images/anonymous_emblem_green.svg')))!;
    for (final lang in ['ko', 'en']) {
      final s = (jsonDecode(File('i18n/$lang.json').readAsStringSync()) as Map).cast<String, dynamic>();
      final key = GlobalKey();
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(width: 1024, height: 500, child: _Feature(svg: svg, s: s)),
          ),
        ),
      ));
      await t.pump();
      await t.runAsync(() async {
        final img = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('store/feature_$lang.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}

class _Feature extends StatelessWidget {
  final String svg;
  final Map<String, dynamic> s;
  const _Feature({required this.svg, required this.s});

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'HackMono', fontFamilyFallback: ['Ko'], decoration: TextDecoration.none);
    final modes = [s['mode_campaign'], s['mode_breach'], s['mode_cases']];
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xFF050906)),
      CustomPaint(painter: _Rain()),
      // 왼쪽: 고스트 문양
      Positioned(
        left: 70,
        top: 70,
        child: Container(
          width: 360,
          height: 360,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF050906),
            boxShadow: [BoxShadow(color: Color(0x6600FF46), blurRadius: 60, spreadRadius: 6)],
          ),
          child: SvgPicture.string(svg),
        ),
      ),
      // 오른쪽: 이름·한 줄·모드 셋
      Positioned(
        left: 480,
        right: 40,
        top: 0,
        bottom: 0,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HACKQUEST', style: mono.copyWith(color: _green, fontSize: 84, fontWeight: FontWeight.w700, letterSpacing: 4,
              shadows: const [Shadow(color: Color(0xAA00FF46), blurRadius: 24)])),
          const SizedBox(height: 14),
          Text('> ${s['title_tagline']}_', style: mono.copyWith(color: const Color(0xFFCCFFDA), fontSize: 30)),
          const SizedBox(height: 34),
          Wrap(spacing: 12, runSpacing: 10, children: [
            for (final m in modes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: _orange.withValues(alpha: 0.8), width: 2), color: const Color(0xCC0B0F0C)),
                child: Text('$m', style: mono.copyWith(color: _orange, fontSize: 26)),
              ),
          ]),
        ]),
      ),
    ]);
  }
}

/// 매트릭스 비 느낌의 흐린 글자 기둥(고정 시드라 매번 같은 그림).
class _Rain extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(7);
    const cell = 22.0;
    const glyphs = '0101ABCDEF<>/{}#=+*';
    for (var x = 0.0; x < size.width; x += cell) {
      if (r.nextDouble() < 0.35) continue;
      final head = r.nextDouble() * size.height;
      final len = 6 + r.nextInt(14);
      for (var i = 0; i < len; i++) {
        final y = head - i * cell;
        if (y < -cell) break;
        final a = (i == 0 ? 0.4 : 0.18 * (1 - i / len));
        final tp = TextPainter(
          text: TextSpan(text: glyphs[r.nextInt(glyphs.length)], style: TextStyle(fontFamily: 'HackMono', fontSize: 18, color: _green.withValues(alpha: a))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_Rain old) => false;
}
