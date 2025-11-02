#!/usr/bin/env bash
set -euo pipefail
APP=FHBrowser
OUT=dist
BIN=build
rm -rf "$OUT" "$BIN"
mkdir -p "$OUT" "$BIN"

swiftc -O \
  -framework Cocoa \
  -framework WebKit \
  -target x86_64-apple-macos12 \
  AppDelegate.swift BrowserViewController.swift \
  -o "$BIN/$APP"

mkdir -p "$OUT/$APP.app/Contents/MacOS"
mkdir -p "$OUT/$APP.app/Contents/Resources"
cp Info.plist "$OUT/$APP.app/Contents/Info.plist"
cp "$BIN/$APP" "$OUT/$APP.app/Contents/MacOS/$APP"
chmod +x "$OUT/$APP.app/Contents/MacOS/$APP"
