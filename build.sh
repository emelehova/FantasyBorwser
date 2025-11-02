#!/usr/bin/env bash
set -euo pipefail
set -x

APP=FHBrowser
SRC1=AppDelegate.swift
SRC2=BrowserViewController.swift

ARCH="${ARCH:-arm64}"
OUT_ROOT="dist"
BIN_ROOT="build"

OUT_DIR="${OUT_ROOT}/${ARCH}"
BIN_DIR="${BIN_ROOT}/${ARCH}"

echo "BUILD START: ARCH=${ARCH}"
echo "Work dir: $(pwd)"
echo "Listing repo root:"
ls -la

echo "Check swiftc"
if command -v xcrun >/dev/null 2>&1; then
  SWIFTC="$(xcrun --sdk macosx --find swiftc || true)"
else
  SWIFTC="$(command -v swiftc || true)"
fi

if [ -z "${SWIFTC}" ]; then
  echo "ERROR: swiftc not found on runner"
  exit 2
fi

echo "Using swiftc: ${SWIFTC}"
"${SWIFTC}" --version || true

rm -rf "${OUT_DIR}" "${BIN_DIR}"
mkdir -p "${OUT_DIR}" "${BIN_DIR}"

if [ "${ARCH}" = "arm64" ]; then
  TARGET="arm64-apple-macos13"
else
  TARGET="x86_64-apple-macos12"
fi

echo "Attempting compile with -target ${TARGET}"
COMPILE_LOG="${BIN_DIR}/compile.log"
mkdir -p "$(dirname "${COMPILE_LOG}")"

# try compile with target first, capture stderr/stdout
if "${SWIFTC}" -O -framework Cocoa -framework WebKit -target "${TARGET}" "${SRC1}" "${SRC2}" -o "${BIN_DIR}/${APP}" >"${COMPILE_LOG}" 2>&1; then
  echo "Compile with -target SUCCESS"
else
  echo "Compile with -target FAILED. Dumping ${COMPILE_LOG}:"
  sed -n '1,200p' "${COMPILE_LOG}" || true

  echo "Retrying compile WITHOUT -target (fallback)"
  if "${SWIFTC}" -O -framework Cocoa -framework WebKit "${SRC1}" "${SRC2}" -o "${BIN_DIR}/${APP}" >"${COMPILE_LOG}" 2>&1; then
    echo "Compile WITHOUT -target SUCCESS"
  else
    echo "Compile WITHOUT -target FAILED. Dumping ${COMPILE_LOG}:"
    sed -n '1,400p' "${COMPILE_LOG}" || true
    echo "ERROR: compilation failed on runner. See logs above."
    exit 3
  fi
fi

echo "Creating .app structure for ${ARCH}"
mkdir -p "${OUT_DIR}/${APP}.app/Contents/MacOS"
mkdir -p "${OUT_DIR}/${APP}.app/Contents/Resources"

if [ ! -f Info.plist ]; then
  echo "ERROR: Info.plist not found in repo root"
  exit 4
fi

cp Info.plist "${OUT_DIR}/${APP}.app/Contents/Info.plist"
cp "${BIN_DIR}/${APP}" "${OUT_DIR}/${APP}.app/Contents/MacOS/${APP}"
chmod +x "${OUT_DIR}/${APP}.app/Contents/MacOS/${APP}"

echo "Build finished, artifact at ${OUT_DIR}/${APP}.app"
