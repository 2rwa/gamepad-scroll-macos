import Foundation

@main struct ScrollMathTests {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fatalError("FAILED: \(message)") }
    }

    static func main() {
        require(ScrollMath.pixels(axis: 0, seconds: 1) == 0, "neutral must stop")
        require(ScrollMath.pixels(axis: 0.1, seconds: 1) == 0, "deadzone must stop")
        require(ScrollMath.pixels(axis: 0.5, seconds: 1) > 0, "positive axis moves")
        require(ScrollMath.pixels(axis: -0.5, seconds: 1) < 0, "negative axis reverses")
        require(ScrollMath.pixels(axis: 0.9, seconds: 1) > ScrollMath.pixels(axis: 0.5, seconds: 1), "speed monotonic")
        let full = ScrollMath.pixels(axis: 1, seconds: 1)
        require(abs(full - 1212) < 0.01, "speed cap")
        require(abs(ScrollMath.pixels(axis: 0.6, seconds: 0.5) * 2 - ScrollMath.pixels(axis: 0.6, seconds: 1)) < 0.001, "frame independence")
        require(abs(ScrollMath.pixels(axis: 0.8, seconds: 1, multiplier: 2) - ScrollMath.pixels(axis: 0.8, seconds: 1) * 2) < 0.001, "speed multiplier")
        require(ScrollMath.pixels(axis: 1, seconds: -1) == 0, "invalid time")
        require(ScrollMath.pixels(axis: .nan, seconds: 1) == 0, "NaN axis must stop")
        print("PASS: 10 scroll-math assertions")
    }
}
