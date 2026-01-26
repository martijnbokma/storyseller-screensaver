import AppKit

/// Animation state information
struct AnimationState {
    let scrollOffset: CGFloat
    let wordIndex: Int
    let transitionProgress: CGFloat
    let elapsedTime: CGFloat
}

/// Manages animation timing, state transitions, and easing functions
final class AnimationEngine {
    // MARK: - Properties

    /// Elapsed time accumulator for move + hold timing
    private var elapsedTime: CGFloat = 0

    /// Whether motion should be reduced for accessibility
    private let reduceMotion: Bool

    // MARK: - Configuration

    private let secondsPerWord: CGFloat
    private let holdSecondsPerWord: CGFloat

    // MARK: - Initialization

    init(
        reduceMotion: Bool = false,
        secondsPerWord: CGFloat = ScreensaverConfiguration.secondsPerWord,
        holdSecondsPerWord: CGFloat = ScreensaverConfiguration.holdSecondsPerWord
    ) {
        self.reduceMotion = reduceMotion
        self.secondsPerWord = secondsPerWord
        self.holdSecondsPerWord = holdSecondsPerWord
    }

    // MARK: - Animation

    /// Updates animation state based on elapsed time
    /// - Parameters:
    ///   - deltaTime: Time elapsed since last update
    ///   - wordCount: Total number of words in the carousel
    ///   - lineHeight: Height of one line in the carousel
    ///   - reduceMotion: Whether motion should be reduced for accessibility
    /// - Returns: Current animation state
    func update(deltaTime: CGFloat, wordCount: Int, lineHeight: CGFloat, reduceMotion: Bool = false) -> AnimationState {
        guard !reduceMotion, wordCount > 0, lineHeight > 0 else {
            return AnimationState(
                scrollOffset: 0,
                wordIndex: 0,
                transitionProgress: 0,
                elapsedTime: elapsedTime
            )
        }

        let moveSeconds = max(0.05, secondsPerWord)
        let holdSeconds = max(0.0, holdSecondsPerWord)
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
            t = rawT < 0.5 ? 2 * rawT * rawT : 1 - pow(-2 * rawT + 2, 2) / 2
        }

        let scrollOffset = (CGFloat(wordIndex) + t) * lineHeight

        return AnimationState(
            scrollOffset: scrollOffset,
            wordIndex: wordIndex,
            transitionProgress: t,
            elapsedTime: elapsedTime
        )
    }

    /// Resets animation to initial state
    func reset() {
        elapsedTime = 0
    }
}
