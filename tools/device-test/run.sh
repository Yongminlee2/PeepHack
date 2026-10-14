#!/bin/bash
# 맥에 USB 로 꽂힌 아이폰에서 HackQuest 를 UI 테스트로 직접 눌러 본다. 결과: build/device-test/<시각>/ 에 단계별 화면·화면 녹화.
#
#   tools/device-test/run.sh <기기 UDID> [테스트 이름, 기본 DeviceWalkthroughUITests]
#
# APP=build/ios/iphoneos/Runner.app 을 주면 앱을 지웠다 다시 깔아 처음 상태에서 시작한다
# (`flutter build ios --release` 로 만든 개발 서명 출시판). 폰은 잠금을 풀고 도는 동안 만지지 않는다.
set -euo pipefail
cd "$(dirname "$0")"
DEV="${1:?기기 UDID (xcrun devicectl list devices)}"; TEST="${2:-DeviceWalkthroughUITests}"
ROOT="$(cd ../.. && pwd)"; DD="$ROOT/build/device-test-dd"; OUT="$ROOT/build/device-test/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
if [ -n "${APP:-}" ]; then
  xcrun devicectl device uninstall app --device "$DEV" com.peep.hack >/dev/null 2>&1 || true
  case "$APP" in /*) A="$APP" ;; *) A="$ROOT/$APP" ;; esac
  xcrun devicectl device install app --device "$DEV" "$A" >/dev/null
fi
xcodegen generate >/dev/null
xcodebuild build-for-testing -project HackDeviceTest.xcodeproj -scheme DeviceUITests -destination id="$DEV" \
  -derivedDataPath "$DD" -allowProvisioningUpdates 2>&1 | grep -E "error:|\*\* " || true
RUN=$(ls "$DD"/Build/Products/*.xctestrun | head -1)
# 첨부·녹화를 성공한 시험에서도 남긴다. xctestrun 은 Build/Products 안에 둬야 경로가 맞는다.
python3 -I - "$RUN" <<'PY'
import plistlib, sys
p = sys.argv[1]; d = plistlib.load(open(p, 'rb'))
targets = [t for c in d.get('TestConfigurations', []) for t in c['TestTargets']] if 'TestConfigurations' in d \
          else [v for k, v in d.items() if isinstance(v, dict) and 'TestBundlePath' in v]
for t in targets:
    t['SystemAttachmentLifetime'] = 'keepAlways'
    t['UserAttachmentLifetime'] = 'keepAlways'
    t['PreferredScreenCaptureFormat'] = 'screenRecording'
plistlib.dump(d, open(p, 'wb'))
PY
xcodebuild test-without-building -xctestrun "$RUN" -destination id="$DEV" \
  -only-testing:"DeviceUITests/$TEST" -resultBundlePath "$OUT/result.xcresult" 2>&1 | grep -E "Test Case|error|\*\* " || true
xcrun xcresulttool export attachments --path "$OUT/result.xcresult" --output-path "$OUT/attachments" >/dev/null
python3 -I - "$OUT" <<'PY'
import json, os, shutil, sys
out = sys.argv[1]; att = os.path.join(out, 'attachments')
for t in json.load(open(os.path.join(att, 'manifest.json'))):
    for a in t['attachments']:
        name = a['suggestedHumanReadableName']; src = os.path.join(att, a['exportedFileName'])
        if name.lower().startswith('screen recording') or src.endswith(('.mp4', '.mov')):
            shutil.copy(src, os.path.join(out, 'recording' + os.path.splitext(src)[1]))
        elif name[:2].isdigit():   # "03_title_0_<uuid>.png" → "03_title.png"
            shutil.copy(src, os.path.join(out, name.split('_0_')[0] + os.path.splitext(src)[1]))
print(out)
PY
