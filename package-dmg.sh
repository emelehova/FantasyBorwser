#!/usr/bin/env bash
set -euo pipefail
APP=FHBrowser
OUT=dist
DMG="$OUT/$APP.dmg"
test -d "$OUT/$APP.app"
hdiutil create -volname "$APP" -srcfolder "$OUT/$APP.app" -ov -format UDZO "$DMG"
