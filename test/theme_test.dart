import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/ui/theme.dart';

void main() {
  test('영문 명령·코드는 HackMono, 한글·가나·한자·태국어·키릴이 섞이면 기본 글꼴', () {
    expect(kMono, 'HackMono');
    expect(kSans, 'Roboto'); // 고정폭 글꼴을 물려받지 않게 기본 글꼴 이름을 직접 준다
    expect(monoFor('ls -a'), kMono);
    expect(monoFor('2024-05-01 ERROR login'), kMono);
    expect(monoFor('접속 준비 완료'), kSans); // 한글은 고정폭으로 그리면 글자 사이가 벌어진다
    expect(monoFor('cat menu.txt 를 치세요'), kSans);
    expect(monoFor('ファイル'), kSans);
    expect(monoFor('文件'), kSans);
    expect(monoFor('ไฟล์'), kSans);
    expect(monoFor('Подключено'), kSans);
  });
}
