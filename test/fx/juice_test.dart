import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/sfx.dart';
import 'package:hack_quest/ui/fx/fx.dart';
import 'package:hack_quest/ui/fx/juice.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget app(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

double scaleOf(WidgetTester t, Key k) =>
    t.widget<Transform>(find.descendant(of: find.byKey(k), matching: find.byType(Transform)).first).transform.getMaxScaleOnAxis();

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Sfx().progress = await Progress.load();
    Sfx().log.clear();
    Fx.animate = true;
  });
  tearDown(() => Fx.animate = false);

  testWidgets('튀어 오름: 값이 바뀌면 커졌다가 제자리', (t) async {
    await t.pumpWidget(app(const Pop(key: Key('p'), trigger: 0, child: Text('A'))));
    expect(scaleOf(t, const Key('p')), 1);
    await t.pumpWidget(app(const Pop(key: Key('p'), trigger: 1, child: Text('A'))));
    await t.pump(const Duration(milliseconds: 90));
    expect(scaleOf(t, const Key('p')), greaterThan(1.05));
    await t.pump(const Duration(milliseconds: 600));
    expect(scaleOf(t, const Key('p')), closeTo(1, 0.01));
  });

  testWidgets('흔들림: 값이 바뀌면 옆으로 흔들렸다가 제자리', (t) async {
    double dx() => t.widget<Transform>(find.descendant(of: find.byKey(const Key('s')), matching: find.byType(Transform)).first)
        .transform.getTranslation().x;
    await t.pumpWidget(app(const Shake(key: Key('s'), trigger: 0, child: Text('A'))));
    await t.pumpWidget(app(const Shake(key: Key('s'), trigger: 1, child: Text('A'))));
    await t.pump(const Duration(milliseconds: 40));
    expect(dx().abs(), greaterThan(1));
    await t.pump(const Duration(milliseconds: 600));
    expect(dx(), closeTo(0, 0.01));
  });

  testWidgets('별 하나씩: 얻은 별마다 소리, 끝나면 별 셋 자리', (t) async {
    await t.pumpWidget(app(const StarsReveal(stars: 2)));
    await t.pump(const Duration(seconds: 2));
    expect(Sfx().log.where((s) => s == 'star'), hasLength(2));
    expect(find.byIcon(Icons.star), findsNWidgets(2));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('숫자 올라감: 0부터 올라 끝값에서 멈춘다', (t) async {
    await t.pumpWidget(app(CountUp(value: 250, builder: (n) => Text('+$n'))));
    await t.pump(const Duration(milliseconds: 200));
    final mid = int.parse((t.widget<Text>(find.byType(Text)).data!).substring(1));
    expect(mid, inExclusiveRange(0, 250));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('+250'), findsOneWidget);
  });

  testWidgets('파편 터짐: 잠깐 그렸다가 사라진다', (t) async {
    await t.pumpWidget(app(const SizedBox(width: 200, height: 200, child: Burst(trigger: 0, child: Text('A')))));
    expect(find.byKey(const Key('burst')), findsNothing);
    await t.pumpWidget(app(const SizedBox(width: 200, height: 200, child: Burst(trigger: 1, child: Text('A')))));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('burst')), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('burst')), findsNothing);
  });

  testWidgets('도장 쾅: 크게 찍혀 내려앉고 소리', (t) async {
    await t.pumpWidget(app(const Stamp(text: '해결')));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('해결'), findsOneWidget);
    expect(Sfx().log, contains('stamp'));
  });

  testWidgets('연출을 끄면(위젯 테스트 기본) 바로 끝 모습', (t) async {
    Fx.animate = false;
    await t.pumpWidget(app(CountUp(value: 90, builder: (n) => Text('+$n'))));
    expect(find.text('+90'), findsOneWidget);
    await t.pumpWidget(app(const StarsReveal(stars: 3)));
    expect(find.byIcon(Icons.star), findsNWidgets(3));
  });
}
