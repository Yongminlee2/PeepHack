import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/theme.dart';

void main() {
  test('영문 명령·코드만 고정폭, 한글·가나·한자·태국어가 있으면 기본 글꼴', () {
    expect(monoFor('ls -a'), 'monospace');
    expect(monoFor('2024-05-01 ERROR login'), 'monospace');
    expect(monoFor('접속 준비 완료'), isNull);
    expect(monoFor('cat menu.txt 를 치세요'), isNull);
    expect(monoFor('ファイル'), isNull);
    expect(monoFor('文件'), isNull);
    expect(monoFor('ไฟล์'), isNull);
    expect(monoFor('Подключено'), 'monospace');
  });
}
