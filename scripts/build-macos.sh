#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test "$(uname -s)" = Darwin
test "$(uname -m)" = arm64
mkdir -p build
# Unit tests on the Apple Silicon runner.
swiftc -Onone Sources/ScrollMath.swift Tests/ScrollMathTests.swift -o build/ScrollMathTests
./build/ScrollMathTests
plutil -lint Resources/Info.plist
APP="build/GamepadScroll.app"
mkdir -p "$APP/Contents/MacOS"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# ARM64 only. No x86_64 slice and no universal executable.
swiftc -O -target arm64-apple-macosx13.0 Sources/ScrollMath.swift Sources/main.swift \
  -framework AppKit -framework ApplicationServices -framework GameController \
  -o "$APP/Contents/MacOS/GamepadScroll"
chmod +x "$APP/Contents/MacOS/GamepadScroll"
test "$(lipo -archs "$APP/Contents/MacOS/GamepadScroll")" = arm64
codesign --force --sign - "$APP"
codesign --verify --verbose "$APP"
cd build
/usr/bin/zip -qry GamepadScroll-macOS-arm64.zip GamepadScroll.app
unzip -t GamepadScroll-macOS-arm64.zip
