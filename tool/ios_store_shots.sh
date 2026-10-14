#!/bin/bash
# 앱스토어 스크린샷(6.9″ 아이폰 1320×2868)을 한국어·영어로 찍는다 (맥 + Xcode 시뮬레이터).
#
#   tool/ios_store_shots.sh           # ko,en
#   tool/ios_store_shots.sh en        # 지정한 언어만
#
# 이 앱 전용 시뮬레이터 "HackQuest iPhone 17 Pro Max" 를 쓴다(없으면 만든다). 다른 작업과 같은
# 시뮬레이터를 쓰면 화면이 섞인다. 끝나면 끈다.
# 원본은 build/store_shots/ 에, 올릴 것은 store/ios/screenshots/(언어)/ 에 JPEG 로 둔다
# (앱스토어는 알파 채널 있는 PNG 를 거부한다).
#
# 시뮬레이터 안의 진행 기록을 지운다. 실제 폰에 대고 돌리지 말 것.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/flutter/bin:$PATH"

NAME="HackQuest iPhone 17 Pro Max"
UDID=$(xcrun simctl list devices | grep -F "    $NAME (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)
if [ -z "$UDID" ]; then
  RT=$(xcrun simctl list runtimes | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | tail -1)
  UDID=$(xcrun simctl create "$NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max "$RT")
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
# bootstatus 는 다른 세션이 시뮬레이터를 여럿 켜 두면 Booted 가 된 뒤에도 끝나지 않을 때가 있다 — 목록을 본다.
for _ in $(seq 60); do
  xcrun simctl list devices | grep -F "($UDID) (Booted)" >/dev/null && break
  sleep 2
done
# 상태 막대를 스토어용으로 고정(9:41, 배터리 가득)
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 --dataNetwork wifi 2>/dev/null || true

rm -rf build/store_shots
flutter drive -d "$UDID" \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_shots_test.dart \
  --dart-define=SHOT_LANGS="${1:-ko,en}"

xcrun simctl shutdown "$UDID" || true

python3 - <<'PY'
import glob, os
from PIL import Image
n = 0
for src in sorted(glob.glob('build/store_shots/*/*.png')):
    lang, name = src.split(os.sep)[-2:]
    im = Image.open(src).convert('RGB')
    assert im.size == (1320, 2868), (src, im.size)
    dst = os.path.join('store', 'ios', 'screenshots', lang, name.replace('.png', '.jpg'))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    im.save(dst, 'JPEG', quality=90, optimize=True)
    n += 1
print(f'{n}장 → store/ios/screenshots/')
PY
