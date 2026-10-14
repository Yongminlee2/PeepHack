#!/bin/sh
# 앱스토어용으로 보관(archive)하고 App Store Connect 에 올린다. Xcode 를 열지 않고 명령 한 줄로.
#
#   tool/ios_archive.sh          보관 + ipa 내보내기만(build/ios-export/export)
#   tool/ios_archive.sh upload   보관 + 업로드
#
# - Xcode → Settings → Accounts 에 개발자 계정이 로그인돼 있어야 한다. 배포 인증서·프로파일은 Xcode 가 만든다.
# - 버전·빌드 번호는 pubspec.yaml 의 version(예: 1.0.0+1)이 그대로 들어가 안드로이드와 같아진다.
#   같은 빌드 번호는 두 번 못 올린다 — 다시 올릴 때는 pubspec 의 +숫자를 올린다.
# - 올린 뒤 App Store Connect 처리(15분쯤)가 끝나야 버전 페이지에 「빌드 추가」 가 보인다.
set -e
cd "$(dirname "$0")/.."
export PATH="$HOME/flutter/bin:$PATH"
OUT="$PWD/build/ios-export"
DEST=export
[ "$1" = "upload" ] && DEST=upload
mkdir -p "$OUT"

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>$DEST</string>
	<key>teamID</key><string>3276G27R59</string>
	<key>signingStyle</key><string>automatic</string>
	<key>uploadSymbols</key><true/>
	<key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

flutter build ios --release --config-only   # Generated.xcconfig(버전·빌드 번호)를 만든다
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/Runner.xcarchive" \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath "$OUT/Runner.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/$DEST" -allowProvisioningUpdates
echo "끝: $OUT/$DEST"
