import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 의뢰인 「고스트」의 얼굴 = 어나니머스 문양(머리 없는 양복 + 물음표 + 월계관 + 지구본).
///
/// 원본: https://commons.wikimedia.org/wiki/File:Anonymous_Flag.svg (퍼블릭 도메인).
/// 깃발 바탕만 떼어 내고 초록으로 다시 칠했다(assets/images/anonymous_emblem_green.svg).
/// 가이 포크스 가면은 영화 쪽 권리가 걸려 있어 쓰지 않는다(사용자 결정 2026-10-11).
class GhostAvatar extends StatelessWidget {
  static const asset = 'assets/images/anonymous_emblem_green.svg';

  final double size;
  final bool glow;
  const GhostAvatar({super.key, this.size = 160, this.glow = true});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Ghost',
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glow ? [BoxShadow(color: const Color(0x6600FF46), blurRadius: size * 0.25, spreadRadius: size * 0.02)] : null,
            ),
            child: SvgPicture.asset(asset, width: size, height: size),
          ),
        ),
      );
}
