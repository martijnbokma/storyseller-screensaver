import Foundation
import AppKit

/// Animation state information.
struct AnimationState {
    /// Current scroll offset in points.
    let scrollOffset: CGFloat

    /// Current word index (0-based).
    let wordIndex: Int

    /// Transition progress (0.0 to 1.0).
    let transitionProgress: CGFloat

    /// Elapsed time within current cycle.
    let elapsedTime: CGFloat
}

/// Manages animation timing, state transitions, and easing functions.
final class AnimationEngine {
    // MARK: - Properties

    /// Elapsed time accumulator for move + hold timing.
    private var elapsedTime: CGFloat = 0

    /// Whether to reduce motion for accessibility.
    private let reduceMotion: Bool

    /// Number of words in the carousel.
    private let wordCount: Int

    /// Line height for scroll calculations.
    private var lineHeight: CGFloat = 0

    // MARK: - Initialization

    /// Initialize the animation engine.
    /// - Parameters:
    ///   - wordCount: Number of words in the carousel
    ///   - reduceMotion: Whether to reduce motion for accessibility
    init(wordCount: Int, reduceMotion: Bool) {
        self.wordCount = wordCount
        self.reduceMotion = reduceMotion
    }

    // MARK: - Animation Control

    /// Reset animation state.
    func reset() {
        elapsedTime = 0
    }

    /// Update animation state based on delta time.
    /// - Parameters:
    ///   - deltaTime: Time elapsed since last frame
    ///   - lineHeight: Current line height for scroll calculations
    /// - Returns: Updated animation state
    func update(deltaTime: CGFloat, lineHeight: CGFloat) -> AnimationState {
        self.lineHeight = lineHeight

        if reduceMotion {
            return AnimationState(
                scrollOffset: 0,
                wordIndex: 0,
                transitionProgress: 0,
                elapsedTime: elapsedTime
            )
        }

        // Move downward with a brief hold at center for each word.
        let moveSeconds = max(0.05, ScreensaverConfiguration.secondsPerWord)
        let holdSeconds = max(0.0, ScreensaverConfiguration.holdSecondsPerWord)
        let wordDuration = moveSeconds + holdSeconds
        let cycleDuration = wordDuration * CGFloat(wordCount)

        elapsedTime = (elapsedTime + deltaTime).truncatingRemainder(dividingBy: cycleDuration)
        let wordIndex = Int(floor(elapsedTime / wordDuration)) % wordCount
        let localTime = elapsedTime - CGFloat(wordIndex) * wordDuration

        let t: CGFloat
        if localTime <= holdSeconds {
            t = 0
        } else {
            let rawT = min(1.0, (localTime - holdSeconds) / moveSeconds)
            // Smooth easing for more natural movement
            t = calculateEasing(t: rawT)
        }

        let scrollOffset = (CGFloat(wordIndex) + t) * lineHeight

        return AnimationState(
            scrollOffset: scrollOffset,
            wordIndex: wordIndex,
            transitionProgress: t,
            elapsedTime: elapsedTime
        )
    }

    // MARK: - Easing Functions

    /// Calculate easing value using smooth in-out curve.
    /// - Parameter t: Input value (0.0 to 1.0)
    /// - Returns: Eased value (0.0 to 1.0)
    func calculateEasing(t: CGFloat) -> CGFloat {
        if t < 0.5 {
            return 2 * t * t
        } else {
            return 1 - pow(-2 * t + 2, 2) / 2
        }
    }
}
