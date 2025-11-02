#!/usr/bin/env bash
set -euo pipefail

APP=FHBrowser
ARCH="${ARCH:-arm64}"
OUT_DIR="dist/${ARCH}"
DMG="${OUT_DIR}/${APP}-${ARCH}.dmg"

test -d "${OUT_DIR}/${APP}.app"

hdiutil create \
  -volname "${APP}-${ARCH}" \
  -srcfolder "${OUT_DIR}/${APP}.app" \
  -ov -format UDZO "${DMG}"
