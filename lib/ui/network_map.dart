import 'package:flutter/material.dart';

import '../engine/mission.dart';
import '../engine/shell.dart';
import 'fx/juice.dart';
import 'theme.dart';

/// 임무의 서버 지도(Hacknet 처럼). 집(시작 서버)에서 각 서버로 선을 긋는다.
/// 서버 상태: 지금 있는 곳(주황) / 열림(초록) / 잠김(자물쇠) / 계정 필요(사람).
class NetworkMap extends StatelessWidget {
  final Mission mission;
  final Shell shell;
  final void Function(String hostKey) onTap;
  const NetworkMap({super.key, required this.mission, required this.shell, required this.onTap});

  static const height = 112.0;

  @override
  Widget build(BuildContext context) {
    final home = mission.start;
    final others = mission.hosts.keys.where((k) => k != home).toList();
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (_, box) {
        final w = box.maxWidth;
        Offset pos(String key) {
          if (key == home) return Offset(w * 0.12, height * 0.45);
          final i = others.indexOf(key);
          final n = others.length;
          final x = n == 1 ? w * 0.7 : w * (0.36 + 0.56 * i / (n - 1));
          final y = height * (n > 2 ? (i.isEven ? 0.28 : 0.62) : 0.45);
          return Offset(x, y);
        }

        return Stack(children: [
          Positioned.fill(
            child: CustomPaint(painter: _Links([for (final k in others) (pos(home), pos(k), _open(k))])),
          ),
          for (final k in mission.hosts.keys) _node(k, pos(k)),
        ]);
      }),
    );
  }

  bool _open(String key) => !mission.hosts[key]!.isProtected || shell.isUnlocked(key);

  Widget _node(String key, Offset c) {
    final h = mission.hosts[key]!;
    final here = shell.hostKey == key;
    final open = _open(key);
    final color = here ? hqOrange : (open ? hqGreen : hqRed);
    final icon = key == mission.start
        ? Icons.laptop
        : (open ? Icons.dns : (h.lock == null && h.user != null ? Icons.person_outline : Icons.lock));
    return Positioned(
      left: c.dx - 40,
      top: c.dy - 20,
      width: 80,
      child: GestureDetector(
        key: Key('node_$key'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(key),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Pop(
            trigger: here,
            scale: 1.4,
            child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xEE0B0F0C),
              border: Border.all(color: color, width: here ? 2.5 : 1.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          ),
          const SizedBox(height: 2),
          Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kMono, fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}

class _Links extends CustomPainter {
  final List<(Offset, Offset, bool)> links;
  _Links(this.links);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (a, b, open) in links) {
      canvas.drawLine(a, b, Paint()
        ..strokeWidth = 1.5
        ..color = (open ? hqGreen : hqRed).withValues(alpha: 0.45));
    }
  }

  @override
  bool shouldRepaint(_Links old) => true;
}
