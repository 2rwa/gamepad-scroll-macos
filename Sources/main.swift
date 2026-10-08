import AppKit
import ApplicationServices
import CoreGraphics
import GameController

/// Lightweight macOS menu-bar agent; only ever posts input while enabled.
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private var toggleItem: NSMenuItem!
    private var connectionItem: NSMenuItem!
    private var permissionItem: NSMenuItem!
    private var speedItems: [NSMenuItem] = []
    private var timer: Timer?
    private var controller: GCController?

    private var enabled = UserDefaults.standard.bool(forKey: "scrollEnabled")
    private var speedMultiplier: Double = {
        if UserDefaults.standard.object(forKey: "speedMultiplier") == nil { return 1.0 }
        return UserDefaults.standard.double(forKey: "speedMultiplier")
    }()
    private var scrollRemainderX = 0.0
    private var scrollRemainderY = 0.0
    private var lastTick = ProcessInfo.processInfo.systemUptime
    private var keyRepeatDeadline: [String: Double] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Allow using Safari, Chrome, Preview while the utility reads the pad.
        GCController.shouldMonitorBackgroundEvents = true
        buildMenu()
        NotificationCenter.default.addObserver(self, selector: #selector(connected(_:)),
                                               name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnected(_:)),
                                               name: .GCControllerDidDisconnect, object: nil)
        chooseController()
        GCController.startWirelessControllerDiscovery(completionHandler: nil)
        lastTick = ProcessInfo.processInfo.systemUptime
        timer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self,
                                     selector: #selector(tick), userInfo: nil, repeats: true)
        refreshMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        GCController.shouldMonitorBackgroundEvents = false
        NotificationCenter.default.removeObserver(self)
    }

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🎮"
        statusItem.button?.toolTip = "Gamepad Scroll"
        menu.delegate = self

        toggleItem = NSMenuItem(title: "Enable scrolling", action: #selector(toggleScrolling(_:)),
                                keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        connectionItem = NSMenuItem(title: "Controller: not connected", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu.addItem(connectionItem)

        permissionItem = NSMenuItem(title: "Accessibility: not granted",
                                    action: #selector(openAccessibility(_:)), keyEquivalent: "")
        permissionItem.target = self
        menu.addItem(permissionItem)
        menu.addItem(.separator())

        let speedMenu = NSMenu(title: "Scroll speed")
        for (label, value) in [("Slow (0.5×)", 50), ("Normal (1×)", 100), ("Fast (2×)", 200)] {
            let item = NSMenuItem(title: label, action: #selector(setSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = value
            speedMenu.addItem(item)
            speedItems.append(item)
        }
        let speedParent = NSMenuItem(title: "Scroll speed", action: nil, keyEquivalent: "")
        speedParent.submenu = speedMenu
        menu.addItem(speedParent)
        menu.addItem(.separator())

        let helpItem = NSMenuItem(title: "Right stick: scroll • L1/R1: page",
                                  action: nil, keyEquivalent: "")
        helpItem.isEnabled = false
        menu.addItem(helpItem)

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }

    private func refreshMenu() {
        toggleItem.state = enabled ? .on : .off
        connectionItem.title = "Controller: " + (controller?.vendorName ?? "not connected")
        permissionItem.title = AXIsProcessTrusted() ? "Accessibility: granted" : "Accessibility: open settings…"
        for item in speedItems {
            item.state = item.tag == Int((speedMultiplier * 100).rounded()) ? .on : .off
        }
        statusItem.button?.title = enabled ? "🎮" : "🎮·"
    }

    @objc private func toggleScrolling(_ sender: Any?) {
        if !enabled {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            guard AXIsProcessTrustedWithOptions(options) else {
                refreshMenu()
                return
            }
        }
        enabled.toggle()
        UserDefaults.standard.set(enabled, forKey: "scrollEnabled")
        resetInputState()
        refreshMenu()
    }

    @objc private func openAccessibility(_ sender: Any?) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func setSpeed(_ sender: NSMenuItem) {
        speedMultiplier = Double(sender.tag) / 100.0
        UserDefaults.standard.set(speedMultiplier, forKey: "speedMultiplier")
        refreshMenu()
    }

    @objc private func quitApp(_ sender: Any?) { NSApp.terminate(nil) }

    @objc private func connected(_ notification: Notification) { chooseController() }

    @objc private func disconnected(_ notification: Notification) {
        if let lost = notification.object as? GCController,
           let current = controller, lost === current {
            controller = nil
            resetInputState()
            chooseController()
        }
    }

    private func chooseController() {
        if controller == nil || controller?.extendedGamepad == nil {
            controller = GCController.controllers().first(where: { $0.extendedGamepad != nil })
            resetInputState()
        }
        if statusItem != nil { refreshMenu() }
    }

    private func resetInputState() {
        scrollRemainderX = 0
        scrollRemainderY = 0
        keyRepeatDeadline.removeAll()
    }

    @objc private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = min(max(now - lastTick, 0), 0.05)
        lastTick = now
        guard enabled, AXIsProcessTrusted(), let pad = controller?.extendedGamepad else {
            resetInputState()
            return
        }

        scrollRemainderY += ScrollMath.pixels(axis: pad.rightThumbstick.yAxis.value,
                                               seconds: elapsed, multiplier: speedMultiplier)
        scrollRemainderX += ScrollMath.pixels(axis: pad.rightThumbstick.xAxis.value,
                                               seconds: elapsed, multiplier: speedMultiplier)
        let vertical = Int32(scrollRemainderY.rounded(.towardZero))
        let horizontal = Int32(scrollRemainderX.rounded(.towardZero))
        scrollRemainderY -= Double(vertical)
        scrollRemainderX -= Double(horizontal)
        if vertical != 0 || horizontal != 0 {
            CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
                    wheel1: vertical, wheel2: horizontal, wheel3: 0)?.post(tap: .cghidEventTap)
        }

        // HID virtual key codes for arrows (up/down/left/right) and Page Up/Down.
        handleKey("up", pressed: pad.dpad.up.isPressed, code: 126, now: now)
        handleKey("down", pressed: pad.dpad.down.isPressed, code: 125, now: now)
        handleKey("left", pressed: pad.dpad.left.isPressed, code: 123, now: now)
        handleKey("right", pressed: pad.dpad.right.isPressed, code: 124, now: now)
        handleKey("pageUp", pressed: pad.leftShoulder.isPressed, code: 116, now: now)
        handleKey("pageDown", pressed: pad.rightShoulder.isPressed, code: 121, now: now)
    }

    private func handleKey(_ id: String, pressed: Bool, code: CGKeyCode, now: Double) {
        guard pressed else {
            keyRepeatDeadline.removeValue(forKey: id)
            return
        }
        if let next = keyRepeatDeadline[id] {
            guard now >= next else { return }
            emitKey(code)
            keyRepeatDeadline[id] = now + 0.08
        } else {
            emitKey(code)
            keyRepeatDeadline[id] = now + 0.40
        }
    }

    private func emitKey(_ code: CGKeyCode) {
        CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false)?.post(tap: .cghidEventTap)
    }
}

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
