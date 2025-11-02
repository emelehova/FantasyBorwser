#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

: "${APP_NAME:?APP_NAME is required}"
: "${ARCH:?ARCH is required}"

SRC_APP="build/${ARCH}/${APP_NAME}.app"
OUT_DIR="dist/${ARCH}"
OUT_DMG="${OUT_DIR}/${APP_NAME}-${ARCH}.dmg"
VOL_NAME="${APP_NAME}"

test -d "$SRC_APP"

mkdir -p "$OUT_DIR"

TMP_DMG="${OUT_DIR}/${APP_NAME}-${ARCH}-rw.dmg"
SIZE_MB=$(( $(du -sm "$SRC_APP" | awk '{print $1}') + 50 ))

hdiutil create -size "${SIZE_MB}m" -fs HFS+ -volname "$VOL_NAME" "$TMP_DMG"
DEV="$(hdiutil attach -readwrite "$TMP_DMG" | awk '/Apple_HFS/ {print $1}')"
MNT="$(mount | awk -v dev="$DEV" '$1==dev {print $3; exit}')"

cp -R "$SRC_APP" "$MNT/"

sync

hdiutil detach "$DEV"
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUT_DMG"
rm -f "$TMP_DMG"

echo "DMG: $OUT_DMG"
