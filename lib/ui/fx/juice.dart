import 'dart:math';

import 'package:flutter/material.dart';

import '../../sfx.dart';
import '../theme.dart';
import 'fx.dart';

// 손맛 연출 부품. [Fx.animate] 가 꺼지면(위젯 테스트) 모두 끝 모습을 바로 그린다.

/// 판을 끝낸 뒤 결과를 띄우기 전 숨 고르기 — 마지막 칸의 완료·연쇄 연출을 결과 판이 덮지 않게.
Future<void> finishBeat() => Fx.animate ? Future<void>.delayed(const Duration(milliseconds: 900)) : Future.value();

/// 한 번 도는 애니메이션의 공통 뼈대: [replay] 하면 처음부터 다시 돈다.
abstract class _OnceState<T extends StatefulWidget> extends State<T> with SingleTickerProviderStateMixin {
  Duration get duration;
  late final AnimationController ctl = AnimationController(vsync: this, duration: duration, value: 1);

  void replay() {
    if (Fx.animate) ctl.forward(from: 0);
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }
}

/// 튀어 오름: [trigger] 가 바뀌면 커졌다가 탄성 있게 제자리.
class Pop extends StatefulWidget {
  final Object? trigger;
  final double scale;
  final Widget child;
  const Pop({super.key, required this.trigger, required this.child, this.scale = 1.25});
  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends _OnceState<Pop> {
  @override
  Duration get duration => const Duration(milliseconds: 420);
  late final Animation<double> _s = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: widget.scale).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    TweenSequenceItem(tween: Tween(begin: widget.scale, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
  ]).animate(ctl);

  @override
  void didUpdateWidget(Pop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) replay();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _s, builder: (_, c) => Transform.scale(scale: _s.value, child: c), child: widget.child);
}

/// 흔들림: [trigger] 가 바뀌면 옆으로 흔들렸다가 멈춘다(틀렸을 때·연쇄).
class Shake extends StatefulWidget {
  final Object? trigger;
  final double strength;
  final Widget child;
  const Shake({super.key, required this.trigger, required this.child, this.strength = 10});
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends _OnceState<Shake> {
  @override
  Duration get duration => const Duration(milliseconds: 420);

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) replay();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ctl,
        builder: (_, c) {
          final v = ctl.value;
          return Transform.translate(offset: Offset(sin(v * pi * 7) * (1 - v) * widget.strength, 0), child: c);
        },
        child: widget.child,
      );
}

/// 파편 터짐: [trigger] 가 바뀌면 [child] 가운데서 코드 조각이 사방으로 튄다.
class Burst extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  final List<Color> colors;
  const Burst({super.key, required this.trigger, required this.child, this.colors = const [hqGreen, hqOrange]});
  @override
  State<Burst> createState() => _BurstState();
}

class _BurstState extends _OnceState<Burst> {
  @override
  Duration get duration => const Duration(milliseconds: 750);

  @override
  void didUpdateWidget(Burst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) replay();
  }

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, fit: StackFit.passthrough, children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: ctl,
              builder: (_, _) => ctl.isAnimating
                  ? CustomPaint(key: const Key('burst'), painter: _BurstPainter(ctl.value, widget.trigger.hashCode, widget.colors))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ]);
}

class _BurstPainter extends CustomPainter {
  final double v;
  final int seed;
  final List<Color> colors;
  _BurstPainter(this.v, this.seed, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final c = size.center(Offset.zero);
    final reach = size.shortestSide * 0.6 + 40;
    final ease = Curves.easeOutCubic.transform(v);
    for (var i = 0; i < 22; i++) {
      final a = r.nextDouble() * pi * 2;
      final d = reach * (0.4 + r.nextDouble() * 0.6) * ease;
      final s = 3 + r.nextDouble() * 5;
      final p = Paint()..color = colors[i % colors.length].withValues(alpha: (1 - v).clamp(0, 1));
      canvas.drawRect(Rect.fromCenter(center: c + Offset(cos(a), sin(a)) * d, width: s, height: s), p);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.v != v;
}

/// 별 하나씩: 빈 별 셋을 깔고, 얻은 별을 차례로 「딩」 하며 박는다.
class StarsReveal extends StatefulWidget {
  final int stars;
  final double size;
  const StarsReveal({super.key, required this.stars, this.size = 44});
  @override
  State<StarsReveal> createState() => _StarsRevealState();
}

class _StarsRevealState extends State<StarsReveal> with SingleTickerProviderStateMixin {
  static const _step = 0.28; // 별 사이 간격(전체 길이 비율)
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  int _played = 0;

  @override
  void initState() {
    super.initState();
    if (Fx.animate) {
      _c.addListener(() {
        // 별이 박히는 순간마다 소리
        while (_played < widget.stars && _c.value >= _played * _step + 0.05) {
          _played++;
          Sfx().play('star');
        }
      });
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              // 박히기 전엔 빈 별, 박히는 순간 꽉 찬 별로
              child: i < widget.stars && _scale(i) > 0
                  ? Transform.scale(scale: _scale(i), child: Icon(Icons.star, size: widget.size, color: hqOrange))
                  : Icon(Icons.star_border, size: widget.size, color: hqDim),
            ),
        ]),
      );

  // 0 → 1.5 → 1 로 쾅 박힌다
  double _scale(int i) {
    final t = ((_c.value - i * _step) / 0.3).clamp(0.0, 1.0);
    if (t == 0) return 0;
    return t < 0.5 ? t * 3 : 1.5 - (t - 0.5);
  }
}

/// 숫자 올라감: 0 에서 [value] 까지 빠르게 센다.
class CountUp extends StatefulWidget {
  final int value;
  final Widget Function(int n) builder;
  const CountUp({super.key, required this.value, required this.builder});
  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (Fx.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => widget.builder((Curves.easeOutCubic.transform(_c.value) * widget.value).round()),
      );
}

/// 도장 쾅: 크게 떠 있다가 내려찍힌다(사건 해결).
class Stamp extends StatefulWidget {
  final String text;
  final Color color;
  const Stamp({super.key, required this.text, this.color = hqRed});
  @override
  State<Stamp> createState() => _StampState();
}

class _StampState extends State<Stamp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void initState() {
    super.initState();
    if (Fx.animate) {
      _c.forward().whenComplete(() {
        if (mounted) Sfx().play('stamp');
      });
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) {
          final v = Curves.easeIn.transform(_c.value);
          return Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: 2.6 - 1.6 * v, child: c));
        },
        child: Transform.rotate(
          angle: -0.14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: widget.color, width: 3), borderRadius: BorderRadius.circular(6)),
            child: Text(widget.text, style: TextStyle(color: widget.color, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
          ),
        ),
      );
}
