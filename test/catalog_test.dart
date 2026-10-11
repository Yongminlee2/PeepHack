import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';

const good = '{"id":"m1_01","chapter":1,"title":"@t","brief":["@b"],"done":["@d"],"commands":["scan"],'
    '"hosts":{"home":{"name":"h","fs":{}}},"goal":{"connect":"home"},"hints":["@1","@2","@3"],"solution":[]}';

void main() {
  test('깨진 임무는 빼고 broken 에 남긴다', () {
    final c = Catalog.fromTexts({'m1_01': good, 'm1_02': '{not json', 'm1_03': null});
    expect(c.missions.map((m) => m.id), ['m1_01']);
    expect(c.broken, {'m1_02'});
    expect(c.chapters, [1]);
    expect(c.chapter(1).length, 1);
    expect(c.byId('m1_01'), isNotNull);
    expect(c.after('m1_01'), isNull);
    expect(c.orderedIds, ['m1_01']);
  });
  test('진짜 자산이 전부 읽힌다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final c = await Catalog.load();
    expect(c.broken, isEmpty);
    expect(c.chapter(1).length, 6);
    expect(c.after('m1_01')!.id, 'm1_02');
  });
}
