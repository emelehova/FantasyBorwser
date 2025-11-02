#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

: "${APP_NAME:?APP_NAME is required}"
: "${ARCH:?ARCH is required}"
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-12.0}"

case "$ARCH" in
  arm64)   TARGET="arm64-apple-macosx${MACOSX_DEPLOYMENT_TARGET}" ;;
  x86_64)  TARGET="x86_64-apple-macosx${MACOSX_DEPLOYMENT_TARGET}" ;;
  *) echo "Unknown ARCH=$ARCH"; exit 2 ;;
esac

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

BUILD_DIR="build/${ARCH}"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RES_DIR="${CONTENTS_DIR}/Resources"
BIN_PATH="${MACOS_DIR}/${APP_NAME}"

mkdir -p "$MACOS_DIR" "$RES_DIR"

cp -f Info.plist "${CONTENTS_DIR}/Info.plist"

swiftc \
  -target "$TARGET" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  -framework WebKit \
  AppDelegate.swift \
  BrowserViewController.swift \
  -o "$BIN_PATH"

printf "APPL????" > "${CONTENTS_DIR}/PkgInfo"

codesign --force --sign - --timestamp=none "$APP_DIR"

echo "=== OUTPUT TREE (${ARCH}) ==="
find "build/${ARCH}" -maxdepth 4 -print
