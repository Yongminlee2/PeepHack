#!/bin/bash
# 아이폰 화면 둘러보기 — 작은 아이폰(SE 3세대)과 큰 아이폰에서 모든 화면을 돌며 넘침을 잡고 찍는다.
#
#   tool/ios_screen_tour.sh           # SE + 17 Pro Max, ko,en
#   tool/ios_screen_tour.sh se ko     # 기기·언어 고르기 (se | max)
#
# 결과 원본: build/store_shots/tour/(언어)/ → build/ios_tour/(기기)/(언어)/ 로 옮기고, 기기·언어마다 한 장짜리 모음(contact.png).
# 시뮬레이터 안의 진행 기록을 지운다. 끝나면 켠 시뮬레이터를 끈다.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/flutter/bin:$PATH"
LANGS="${2:-ko,en}"

run() { # 기기키 이름 기기형식
  local key=$1 name=$2 type=$3 udid rt
  udid=$(xcrun simctl list devices | grep -F "    $name (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)
  if [ -z "$udid" ]; then
    rt=$(xcrun simctl list runtimes | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | tail -1)
    udid=$(xcrun simctl create "$name" "$type" "$rt")
  fi
  xcrun simctl boot "$udid" 2>/dev/null || true
  for _ in $(seq 60); do
    xcrun simctl list devices | grep -F "($udid) (Booted)" >/dev/null && break
    sleep 2
  done
  rm -rf build/store_shots/tour
  flutter drive -d "$udid" --driver=test_driver/integration_test.dart \
    --target=integration_test/screen_tour_test.dart --dart-define=SHOT_LANGS="$LANGS"
  xcrun simctl shutdown "$udid" || true
  rm -rf "build/ios_tour/$key"; mkdir -p "build/ios_tour/$key"
  mv build/store_shots/tour/* "build/ios_tour/$key/"
  python3 - "$key" <<'PY'
import glob, os, sys
from PIL import Image
key = sys.argv[1]
for d in sorted(glob.glob(f'build/ios_tour/{key}/*')):
    fs = sorted(glob.glob(d + '/*.png'))
    ims = [Image.open(f).convert('RGB') for f in fs]
    w = 300; h = int(ims[0].height * w / ims[0].width); cols = 8
    out = Image.new('RGB', (w * cols, h * ((len(ims) + cols - 1) // cols)), 'white')
    for i, im in enumerate(ims):
        out.paste(im.resize((w, h)), ((i % cols) * w, (i // cols) * h))
    out.save(d + '/contact.png')
    print(d, len(fs))
PY
}

case "${1:-all}" in
  se) run se "HackQuest iPhone SE (3rd generation)" com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation ;;
  max) run max "HackQuest iPhone 17 Pro Max" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max ;;
  *) "$0" se "$LANGS"; "$0" max "$LANGS" ;;
esac
