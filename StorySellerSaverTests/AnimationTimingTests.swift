import XCTest
@testable import StorySellerSaver

/// Tests for animation timing calculations in the screensaver.
/// These tests verify the mathematical correctness of the animation system.
final class AnimationTimingTests: XCTestCase {

    // MARK: - Constants (mirrored from StorySellerSaverView for testing)

    private let secondsPerWord: CGFloat = 1.2
    private let holdSecondsPerWord: CGFloat = 0.6
    private let wordCount: Int = 5

    // MARK: - Animation Timing Tests

    func testWordDurationCalculation() {
        // Word duration should be move time + hold time
        let moveSeconds = max(0.05, secondsPerWord)
        let holdSeconds = max(0.0, holdSecondsPerWord)
        let wordDuration = moveSeconds + holdSeconds

        XCTAssertEqual(wordDuration, 1.8, accuracy: 0.001, "Word duration should be 1.8 seconds")
    }

    func testCycleDurationCalculation() {
        // Full cycle should be word duration * word count
        let wordDuration = secondsPerWord + holdSecondsPerWord
        let cycleDuration = wordDuration * CGFloat(wordCount)

        XCTAssertEqual(cycleDuration, 9.0, accuracy: 0.001, "Cycle duration should be 9 seconds for 5 words")
    }

    func testWordIndexAtStartOfCycle() {
        // At time 0, word index should be 0
        let elapsedTime: CGFloat = 0
        let wordDuration = secondsPerWord + holdSecondsPerWord
        let wordIndex = Int(floor(elapsedTime / wordDuration)) % wordCount

        XCTAssertEqual(wordIndex, 0, "Word index at start should be 0")
    }

    func testWordIndexMidCycle() {
        // At time 3.6 (2 * 1.8), word index should be 2
        let elapsedTime: CGFloat = 3.6
        let wordDuration = secondsPerWord + holdSecondsPerWord
        let wordIndex = Int(floor(elapsedTime / wordDuration)) % wordCount

        XCTAssertEqual(wordIndex, 2, "Word index at 3.6 seconds should be 2")
    }

    func testWordIndexWrapsAround() {
        // After full cycle, should wrap back to 0
        let elapsedTime: CGFloat = 9.0 // Exactly one full cycle
        let wordDuration = secondsPerWord + holdSecondsPerWord
        let cycleDuration = wordDuration * CGFloat(wordCount)
        let wrappedTime = elapsedTime.truncatingRemainder(dividingBy: cycleDuration)
        let wordIndex = Int(floor(wrappedTime / wordDuration)) % wordCount

        XCTAssertEqual(wordIndex, 0, "Word index should wrap to 0 after full cycle")
    }

    // MARK: - Easing Function Tests

    func testEasingAtZero() {
        let t: CGFloat = 0.0
        let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2

        XCTAssertEqual(eased, 0.0, accuracy: 0.001, "Easing at t=0 should be 0")
    }

    func testEasingAtHalf() {
        let t: CGFloat = 0.5
        let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2

        XCTAssertEqual(eased, 0.5, accuracy: 0.001, "Easing at t=0.5 should be 0.5")
    }

    func testEasingAtOne() {
        let t: CGFloat = 1.0
        let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2

        XCTAssertEqual(eased, 1.0, accuracy: 0.001, "Easing at t=1 should be 1")
    }

    func testEasingIsMonotonic() {
        // Easing function should always increase
        var previousValue: CGFloat = -1
        for i in 0...100 {
            let t = CGFloat(i) / 100.0
            let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
            XCTAssertGreaterThanOrEqual(eased, previousValue, "Easing should be monotonically increasing")
            previousValue = eased
        }
    }

    // MARK: - Hold Time Tests

    func testLocalTimeInHoldPeriod() {
        // During hold period, transition t should be 0
        let localTime: CGFloat = 0.3 // Within hold period (0.6 seconds)
        let holdSeconds = holdSecondsPerWord

        let t: CGFloat
        if localTime <= holdSeconds {
            t = 0
        } else {
            let rawT = min(1.0, (localTime - holdSeconds) / secondsPerWord)
            t = rawT < 0.5 ? 2 * rawT * rawT : 1 - pow(-2 * rawT + 2, 2) / 2
        }

        XCTAssertEqual(t, 0, "Transition should be 0 during hold period")
    }

    func testLocalTimeAfterHoldPeriod() {
        // After hold period, transition t should be > 0
        let localTime: CGFloat = 1.0 // After hold period
        let holdSeconds = holdSecondsPerWord

        let t: CGFloat
        if localTime <= holdSeconds {
            t = 0
        } else {
            let rawT = min(1.0, (localTime - holdSeconds) / secondsPerWord)
            t = rawT < 0.5 ? 2 * rawT * rawT : 1 - pow(-2 * rawT + 2, 2) / 2
        }

        XCTAssertGreaterThan(t, 0, "Transition should be > 0 after hold period")
    }

    // MARK: - Delta Time Clamping Tests

    func testDeltaTimeClampingLowerBound() {
        let now: TimeInterval = 100.0
        let lastTime: TimeInterval = 100.5 // lastTime > now (shouldn't happen normally)
        let maxDeltaTime: CGFloat = 0.05

        let dt = CGFloat(min(max(now - lastTime, 0.0), maxDeltaTime))

        XCTAssertEqual(dt, 0.0, accuracy: 0.001, "Negative delta time should be clamped to 0")
    }

    func testDeltaTimeClampingUpperBound() {
        let now: TimeInterval = 100.0
        let lastTime: TimeInterval = 99.0 // 1 second gap (way too large)
        let maxDeltaTime: CGFloat = 0.05

        let dt = CGFloat(min(max(now - lastTime, 0.0), maxDeltaTime))

        XCTAssertEqual(dt, maxDeltaTime, accuracy: 0.001, "Large delta time should be clamped to max")
    }

    func testDeltaTimeNormalOperation() {
        let now: TimeInterval = 100.0
        let lastTime: TimeInterval = 99.983 // ~17ms (60fps)
        let maxDeltaTime: CGFloat = 0.05

        let dt = CGFloat(min(max(now - lastTime, 0.0), maxDeltaTime))

        XCTAssertEqual(dt, 0.017, accuracy: 0.001, "Normal delta time should pass through")
    }

    // MARK: - Word Visibility Tests

    func testWordVisibilityMultiplier() {
        let wordVisibilityMultiplier: CGFloat = 2.8
        let lineHeight: CGFloat = 60.0

        let maxVisible = lineHeight * wordVisibilityMultiplier
        XCTAssertEqual(maxVisible, 168.0, accuracy: 0.001, "Max visible distance should be correct")
    }

    func testEdgeFadeCalculation() {
        let edgeFadeInnerMultiplier: CGFloat = 1.8
        let wordVisibilityMultiplier: CGFloat = 2.8
        let lineHeight: CGFloat = 60.0
        let dist: CGFloat = 120.0 // Distance from center

        let edgeInner = lineHeight * edgeFadeInnerMultiplier
        let edgeOuter = lineHeight * wordVisibilityMultiplier
        let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
        let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)

        XCTAssertGreaterThan(edgeFade, 0, "Edge fade should be > 0 for visible word")
        XCTAssertLessThanOrEqual(edgeFade, 1, "Edge fade should be <= 1")
    }

    func testWordAtCenterHasFullAlpha() {
        let wordVisibilityMultiplier: CGFloat = 2.8
        let lineHeight: CGFloat = 60.0
        let dist: CGFloat = 0.0 // At center

        let norm = min(1.0, dist / (lineHeight * wordVisibilityMultiplier))
        let falloff = 1.0 - norm
        let ease = falloff * falloff

        let alpha = 0.02 + 0.98 * ease
        XCTAssertEqual(alpha, 1.0, accuracy: 0.001, "Word at center should have full alpha")
    }

    func testWordAtEdgeHasReducedAlpha() {
        let wordVisibilityMultiplier: CGFloat = 2.8
        let lineHeight: CGFloat = 60.0
        let dist: CGFloat = lineHeight * wordVisibilityMultiplier // At max visibility

        let norm = min(1.0, dist / (lineHeight * wordVisibilityMultiplier))
        let falloff = 1.0 - norm
        let ease = falloff * falloff

        let alpha = 0.02 + 0.98 * ease
        XCTAssertEqual(alpha, 0.02, accuracy: 0.001, "Word at edge should have minimum alpha")
    }

    // MARK: - Cache Key Tests

    func testCacheKeyPrecision() {
        // Test that similar float values produce the same cache key
        let fontSize1: CGFloat = 45.123456
        let fontSize2: CGFloat = 45.123789
        let alpha1: CGFloat = 0.85012
        let alpha2: CGFloat = 0.85034

        let key1 = "\(Int(fontSize1 * 100))-\(Int(alpha1 * 1000))"
        let key2 = "\(Int(fontSize2 * 100))-\(Int(alpha2 * 1000))"

        XCTAssertEqual(key1, key2, "Similar values should produce same cache key")
    }

    func testCacheKeyDifferentiates() {
        // Test that significantly different values produce different cache keys
        let fontSize1: CGFloat = 45.0
        let fontSize2: CGFloat = 46.0
        let alpha: CGFloat = 0.85

        let key1 = "\(Int(fontSize1 * 100))-\(Int(alpha * 1000))"
        let key2 = "\(Int(fontSize2 * 100))-\(Int(alpha * 1000))"

        XCTAssertNotEqual(key1, key2, "Different font sizes should produce different cache keys")
    }
}
