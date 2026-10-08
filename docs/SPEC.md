# Gamepad Scroll – prototype specification (ARM64 only)

## v0.1 implementation
- macOS 13+ on Apple Silicon (M1 or later); Swift/AppKit/GameController agent menu app.
- Right analog stick: proportional vertical/horizontal pixel wheel at 60 Hz, dead zone 0.12, exponential curve 1.6.
- D-pad: arrow keys; L1/R1: Page Up/Down. First repeat after 400ms, then every 80ms.
- Menu bar: enable/disable, connected controller, accessibility status, speed preset, quit.
- Background controller monitoring while the utility runs; OS events emitted only when enabled.
- Local UserDefaults settings. No network use, no privileged service.
- macOS Accessibility approval required before event injection.

## Build and verification
- A single ARM64 binary; x86_64/Intel and Universal binaries deliberately excluded.
- GitHub Actions macos-15 Apple Silicon runner performs scroll math tests, app compilation, codesign, architecture verification and ZIP validation.
- Physical integration acceptance (manual): Safari/Chrome scrolling; PDF Page Up/Down; pairing/disconnection; permissions; sleep/wake; no unwanted scroll after release.

## Roadmap
- Per-app exceptions, controls remapping, trigger-based speed adjustment, login-item support.
- Apple Developer ID signing and notarization if redistribution is needed.
