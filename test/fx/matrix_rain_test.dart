import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/fx/matrix_rain.dart';

void main() {
  test('빗줄기는 아래로 떨어지고 화면을 벗어나면 위에서 다시 시작한다', () {
    final rain = RainField(seed: 1, columns: 4, rows: 10);
    final y0 = rain.heads[0];
    rain.step(0.1);
    expect(rain.heads[0], greaterThan(y0));
    for (var i = 0; i < 400; i++) {
      rain.step(0.1);
    }
    for (final h in rain.heads) {
      expect(h, lessThan(10 + RainField.trail + 1));
    }
  });
  test('글자는 정해진 글자판에서만 고른다', () {
    final rain = RainField(seed: 2, columns: 3, rows: 5);
    for (var c = 0; c < 3; c++) {
      for (var r = 0; r < 5; r++) {
        expect(RainField.glyphs.contains(rain.glyphAt(c, r)), isTrue);
      }
    }
  });
}
