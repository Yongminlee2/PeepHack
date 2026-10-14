// 스토어 스크린샷을 받아 build/store_shots/ 아래에 쓰는 드라이버.
// 사용법은 integration_test/store_shots_test.dart 맨 위 참고.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final f = File('build/store_shots/$name.png');
        f.parent.createSync(recursive: true);
        f.writeAsBytesSync(bytes);
        return true;
      },
    );
