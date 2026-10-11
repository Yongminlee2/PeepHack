import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/theme.dart';

void main() {
  test('코딩 글꼴(HackMono = 나눔고딕코딩)은 영문·한글까지, 그 밖의 글자가 섞이면 기본 글꼴', () {
    expect(kMono, 'HackMono');
    expect(monoFor('ls -a'), kMono);
    expect(monoFor('2024-05-01 ERROR login'), kMono);
    expect(monoFor('접속 준비 완료'), kMono); // 한글도 고정폭으로 고르게
    expect(monoFor('cat menu.txt 를 치세요'), kMono);
    expect(monoFor('ファイル'), isNull);
    expect(monoFor('文件'), isNull);
    expect(monoFor('ไฟล์'), isNull);
    expect(monoFor('Подключено'), isNull);
  });
}
