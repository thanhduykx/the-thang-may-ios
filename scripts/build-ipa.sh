#!/usr/bin/env bash
# Build file .ipa trên máy Mac. Chạy: ./scripts/build-ipa.sh
# Kết quả: dist/TheThangMay-unsigned.ipa (hoặc .ipa có ký nếu đã cấu hình signing)
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Build Release cho thiết bị thật"
xcodebuild \
  -project TheThangMay.xcodeproj \
  -scheme TheThangMay \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH=$(find build/Build/Products/Release-iphoneos -maxdepth 1 -name "*.app" | head -n 1)
if [ -z "$APP_PATH" ]; then
  echo "Không tìm thấy .app sau khi build" >&2
  exit 1
fi

echo "==> Đóng gói IPA"
rm -rf dist
mkdir -p dist/Payload
cp -R "$APP_PATH" dist/Payload/
(cd dist && zip -qry TheThangMay-unsigned.ipa Payload)

echo "==> Xong: $(pwd)/dist/TheThangMay-unsigned.ipa"
ls -lh dist/TheThangMay-unsigned.ipa
