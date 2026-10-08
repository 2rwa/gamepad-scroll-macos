# Gamepad Scroll for macOS

A small MIT-licensed Swift/AppKit menu-bar utility. **Apple Silicon (M1 or later) only**; macOS 13+.
No Intel build, no Universal binary, no Electron and no network access.

## Controls (prototype v0.1)

| Input | Result |
|---|---|
| Right analog stick up/down | Vertical scroll |
| Right analog stick left/right | Horizontal scroll |
| D-pad | Keyboard arrow keys |
| L1 / R1 | Page Up / Page Down |

The 🎮 menu-bar item enables/disables input and offers 0.5× / 1× / 2× scroll speeds.
New installs start with input **disabled**. The first supported extended gamepad is used.

## Build using GitHub Actions

On a push to main, the [macOS ARM64 workflow](.github/workflows/macos-build.yml) builds and tests on GitHub's standard Apple Silicon \`macos-15\` runner.

1. Open the repo **Actions** tab, select **macOS ARM64 build and test**.
2. Open a successful run and download artifact **GamepadScroll-macOS-arm64**.
3. Extract the downloaded Actions artifact and then \`GamepadScroll-macOS-arm64.zip\` to obtain \`GamepadScroll.app\`.
4. Drag the app into Applications if desired.

The workflow tests scroll math, compiles the app, verifies ARM64 architecture and ad-hoc signature, and checks the ZIP archive.
Controller interactions cannot be tested automatically on GitHub's headless runner.

## First launch

1. Pair or connect a game controller to the Mac.
2. Open \`GamepadScroll.app\` using Finder. Since this is not signed with an Apple Developer ID and is not notarized, macOS may refuse first launch. Inspect the source and use **System Settings → Privacy & Security → Open Anyway** only if you trust the app.
3. Click the 🎮 menu-bar icon and choose **Enable scrolling**.
4. Grant **Accessibility** permission when prompted, then enable again.
5. Try right-stick scrolling in Safari/Chrome and shoulder-button paging in Preview.

The app deliberately uses background controller monitoring. Disable the app's scrolling before playing games to avoid duplicate input.

## Build locally on Apple Silicon

\`\`\`bash
bash scripts/build-macos.sh
\`\`\`

Requires macOS 13+ and Xcode command line tools.
Further details in [docs/SPEC.md](docs/SPEC.md).

## Current limitations

- User-facing scroll mapping is fixed; remapping, application exclusions and login at startup are future work.
- Accessibility permissions and hardware input must be checked on a real Mac.
- Not Apple Developer-ID-signed or notarized. Do not distribute as a trusted installer.
