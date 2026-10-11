import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/strings.dart';

void main() {
  test('모든 언어가 영어와 같은 열쇠를 가진다', () {
    expect(S.missingKeys(), isEmpty);
  });
  test('열쇠를 못 찾으면 열쇠 자체를 돌려준다', () {
    expect(S.t('no_such_key_xyz'), 'no_such_key_xyz');
  });
  test('이름 자리({n} 등)가 언어마다 같다', () {
    // common/i18n/audit.py 의 slotcount 는 `{}`·`{1}` 만 세고 `{n}` 은 모른다. 그래서 여기서 본다.
    final slot = RegExp(r'\{[a-z]+\}');
    final base = S.strings['ko']!;
    S.strings.forEach((code, table) {
      table.forEach((k, v) {
        final want = slot.allMatches(base[k] ?? '').map((m) => m.group(0)).toSet();
        final got = slot.allMatches(v).map((m) => m.group(0)).toSet();
        expect(got, want, reason: '$code.$k');
      });
    });
  });
}
