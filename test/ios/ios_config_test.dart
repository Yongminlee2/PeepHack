import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/strings.dart';

/// 아이폰 설정 파일이 안드로이드·게임 코드와 어긋나지 않는지 본다.
/// 아이폰 빌드는 맥에서만 되므로, 윈도우에서 안드로이드만 고치다가 벌어진
/// 차이(번들 ID·앱 이름·언어·아이콘)를 여기서 먼저 잡는다.
void main() {
  // 윈도우에서 받은 저장소는 줄 끝이 CRLF 라, 줄 단위로 비교하기 전에 맞춘다.
  final plist = File('ios/Runner/Info.plist').readAsStringSync().replaceAll('\r\n', '\n');
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  String? plistString(String key) => RegExp('<key>$key</key>\\s*<string>([^<]*)</string>').firstMatch(plist)?.group(1);

  test('번들 ID가 안드로이드 패키지 이름과 같다', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final androidId = RegExp(r'applicationId = "([^"]+)"').firstMatch(gradle)!.group(1);
    final iosIds = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([\w.]+);').allMatches(pbxproj).map((m) => m.group(1)).toSet();
    expect(iosIds.where((id) => !id!.endsWith('.RunnerTests')), everyElement(androidId));
  });

  test('홈 화면 이름이 안드로이드 android:label 과 같다', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final label = RegExp(r'android:label="([^"]+)"').firstMatch(manifest)!.group(1);
    expect(plistString('CFBundleDisplayName'), label);
    for (final code in S.strings.keys) {
      final strings = File('ios/Runner/$code.lproj/InfoPlist.strings').readAsStringSync();
      expect(strings, contains('"CFBundleDisplayName" = "$label";'), reason: code);
    }
  });

  test('게임이 고를 수 있는 언어를 아이폰에도 전부 신고한다', () {
    // 앱 스토어의 "언어" 칸과 기기 언어 판정이 이 목록을 따른다.
    for (final code in S.strings.keys) {
      expect(plist, contains('<string>$code</string>'), reason: code);
      expect(pbxproj, contains('path = $code.lproj/InfoPlist.strings;'), reason: '$code.lproj');
    }
  });

  test('세로 전용 아이폰 앱이다(아이패드를 켜면 아이패드 스크린샷도 내야 한다)', () {
    expect(RegExp(r'TARGETED_DEVICE_FAMILY = ([^;]+);').allMatches(pbxproj).map((m) => m.group(1)).toSet(), {'1'});
    expect(plist, contains('UIInterfaceOrientationPortrait'));
    expect(plist, isNot(contains('Landscape')));
  });

  test('수출 규정 질문을 건너뛴다(표준 암호화도 안 쓴다)', () {
    expect(plist, contains('<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>'));
  });

  test('앱 아이콘은 1024 한 장이고 투명 픽셀이 없다(앱 스토어가 거부한다)', () {
    final png = File('ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png').readAsBytesSync();
    // IHDR: 폭·높이(4바이트씩), 비트 깊이, 색 형식. 색 형식 2 = 알파 없는 RGB.
    int u32(int o) => (png[o] << 24) | (png[o + 1] << 16) | (png[o + 2] << 8) | png[o + 3];
    expect(u32(16), 1024);
    expect(u32(20), 1024);
    expect(png[25], 2);
  });

  test('개인정보 매니페스트가 앱에 실리고, 추적하지 않는다고 적혀 있다', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync().replaceAll('\r\n', '\n');
    expect(manifest, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
    expect(manifest, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(pbxproj, contains('PrivacyInfo.xcprivacy in Resources'));
  });

  test('명령 입력칸이 아이폰 둥근 따옴표·긴 줄표 바꾸기를 끈다', () {
    final src = File('lib/ui/input_bar.dart').readAsStringSync();
    expect(src, contains('smartQuotesType: SmartQuotesType.disabled'));
    expect(src, contains('smartDashesType: SmartDashesType.disabled'));
  });
}
