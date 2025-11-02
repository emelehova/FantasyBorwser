#!/usr/bin/env bash
set -euo pipefail
set -x

APP="${APP_NAME:-FHBrowser}"
ARCH="${ARCH:-arm64}"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SWIFTC="$(xcrun --sdk macosx --find swiftc)"
DEPLOY="${MACOSX_DEPLOYMENT_TARGET:-12.0}"

OUT_ROOT="dist"
BIN_ROOT="build"
OUT_DIR="${OUT_ROOT}/${ARCH}"
BIN_DIR="${BIN_ROOT}/${ARCH}"

rm -rf "${OUT_DIR}" "${BIN_DIR}"
mkdir -p "${OUT_DIR}" "${BIN_DIR}"

if [ "${ARCH}" = "arm64" ]; then
  TARGET="arm64-apple-macos${DEPLOY}"
else
  TARGET="x86_64-apple-macos${DEPLOY}"
fi

"${SWIFTC}" --version

"${SWIFTC}" -O \
  -sdk "${SDK_PATH}" \
  -target "${TARGET}" \
  -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
  -framework Cocoa \
  -framework WebKit \
  AppDelegate.swift \
  BrowserViewController.swift \
  -o "${BIN_DIR}/${APP}"

mkdir -p "${OUT_DIR}/${APP}.app/Contents/MacOS"
mkdir -p "${OUT_DIR}/${APP}.app/Contents/Resources"

plutil -lint Info.plist
cp Info.plist "${OUT_DIR}/${APP}.app/Contents/Info.plist"
cp "${BIN_DIR}/${APP}" "${OUT_DIR}/${APP}.app/Contents/MacOS/${APP}"
chmod +x "${OUT_DIR}/${APP}.app/Contents/MacOS/${APP}"

echo "Built app: ${OUT_DIR}/${APP}.app"
