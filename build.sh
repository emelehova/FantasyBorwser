#!/usr/bin/env bash
set -euo pipefail

APP=FHBrowser
SRC1=AppDelegate.swift
SRC2=BrowserViewController.swift

ARCH="${ARCH:-arm64}"
OUT_ROOT="dist"
BIN_ROOT="build"

OUT_DIR="${OUT_ROOT}/${ARCH}"
BIN_DIR="${BIN_ROOT}/${ARCH}"

rm -rf "${OUT_DIR}" "${BIN_DIR}"
mkdir -p "${OUT_DIR}" "${BIN_DIR}"

if [ "${ARCH}" = "arm64" ]; then
  TARGET="arm64-apple-macos13"
else
  TARGET="x86_64-apple-macos12"
fi

swiftc -O \
  -framework Cocoa \
  -framework WebKit \
  -target "${TARGET}" \
  "${SRC1}" "${SRC2}" \
  -o "${BIN_DIR}/${APP}"

mkdir -p "${OUT_DIR}/${APP}.app/Contents/MacOS"
mkdir -p "${OUT_DIR}/${APP}.app/Contents/Resources"

cp Info.plist "${OUT_DIR}/${APP}.app/Contents/Info.plist"
cp "${BIN_DIR}/${APP}" "${OUT_DIR}/${APP}.app/Contents/MacOS/${APP}"
chmod +x "${OUT_DIR}/${APP}.app/Contents/MacOS/${APP}"
