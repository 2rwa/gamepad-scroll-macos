import Foundation

/// Normalize gamepad axes into scroll delta per tick (positive means up/right).
enum ScrollMath {
    static let deadZone = 0.12
    static let pixelsPerSecond = 1200.0
    static let minPixelsPerSecond = 12.0
    static let gamma = 1.6

    static func pixels(axis: Float, seconds: Double, multiplier: Double = 1.0) -> Double {
        guard seconds > 0, seconds.isFinite, multiplier > 0, multiplier.isFinite else { return 0 }
        let value = min(abs(Double(axis)), 1.0)
        guard value.isFinite, value > deadZone else { return 0 }
        let normalized = (value - deadZone) / (1.0 - deadZone)
        let speed = minPixelsPerSecond + pixelsPerSecond * pow(normalized, gamma)
        return (axis >= 0 ? 1.0 : -1.0) * speed * seconds * multiplier
    }
}
