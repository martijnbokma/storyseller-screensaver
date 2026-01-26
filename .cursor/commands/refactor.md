# StorySellerSaver Refactor Plan

Complete refactor based on macOS screensaver best practices and modern Swift architecture patterns.

## 🎯 Refactor Goals

1. **Separation of Concerns**: Break down the monolithic 533-line view into focused, testable components
2. **Performance Optimization**: Enhance caching strategies and reduce per-frame allocations
3. **Code Maintainability**: Improve readability, documentation, and testability
4. **Best Practices**: Align with macOS screensaver framework patterns and Swift conventions
5. **Accessibility**: Enhanced support for reduced motion and other accessibility features

---

## 📋 Refactor Structure

### Phase 1: Extract Core Components

#### 1.1 Animation Engine (`AnimationEngine.swift`)
**Purpose**: Handle all animation timing, state, and easing calculations

```swift
/// Manages animation timing, state transitions, and easing functions
final class AnimationEngine {
    // Properties:
    // - elapsedTime: CGFloat
    // - scrollOffset: CGFloat
    // - wordIndex: Int
    // - transitionProgress: CGFloat

    // Methods:
    // - update(deltaTime: CGFloat, wordCount: Int) -> AnimationState
    // - calculateEasing(t: CGFloat) -> CGFloat
    // - reset()
}
```

**Benefits**:
- Isolated animation logic for easier testing
- Reusable easing functions
- Clear state management

#### 1.2 Metrics Calculator (`MetricsCalculator.swift`)
**Purpose**: Compute and cache typography and layout metrics

```swift
/// Calculates and caches typography and layout metrics based on view bounds
struct MetricsCalculator {
    // Properties:
    // - cachedMetrics: (bounds: NSRect, metrics: Metrics)?

    // Methods:
    // - computeMetrics(for bounds: NSRect, isPreview: Bool) -> Metrics
    // - invalidateCache()
}
```

**Benefits**:
- Centralized metric calculation
- Automatic cache invalidation
- Easier to adjust scaling factors

#### 1.3 Renderer (`ScreensaverRenderer.swift`)
**Purpose**: Handle all drawing operations

```swift
/// Handles all drawing operations for the screensaver
final class ScreensaverRenderer {
    // Methods:
    // - drawBackground(in rect: NSRect, phase: CGFloat)
    // - drawCarousel(words: [String], metrics: Metrics, state: AnimationState, in rect: NSRect)
    // - drawCenterText(_ text: String, metrics: Metrics, in rect: NSRect)
    // - drawLogo(metrics: Metrics, centerY: CGFloat, lineHeight: CGFloat, in rect: NSRect)
}
```

**Benefits**:
- Separates drawing logic from view lifecycle
- Easier to test rendering independently
- Can be swapped for different rendering backends

#### 1.4 Style Manager (`StyleManager.swift`)
**Purpose**: Manage fonts, colors, and visual effects

```swift
/// Manages fonts, colors, shadows, and visual effects
final class StyleManager {
    // Properties:
    // - cachedWordAttrs: [String: [NSAttributedString.Key: Any]]
    // - cachedStoryAttrs: [NSAttributedString.Key: Any]?
    // - cachedLogoAttrs: [NSAttributedString.Key: Any]?

    // Methods:
    // - wordAttributes(fontSize: CGFloat, alpha: CGFloat, ease: CGFloat) -> [NSAttributedString.Key: Any]
    // - storyAttributes(metrics: Metrics) -> [NSAttributedString.Key: Any]
    // - logoAttributes(metrics: Metrics) -> [NSAttributedString.Key: Any]
    // - preferredFont(size: CGFloat, weight: NSFont.Weight) -> NSFont
    // - cleanupCache()
}
```

**Benefits**:
- Centralized style management
- Efficient attribute caching
- Easy theme customization

#### 1.5 Configuration (`ScreensaverConfiguration.swift`)
**Purpose**: Centralize all configuration constants and settings

```swift
/// Centralized configuration for the screensaver
struct ScreensaverConfiguration {
    // Animation
    static let targetFrameRate: Double = 60.0
    static let maxDeltaTime: CGFloat = 0.05
    static let secondsPerWord: CGFloat = 1.2
    static let holdSecondsPerWord: CGFloat = 0.6

    // Visual
    static let wordVisibilityMultiplier: CGFloat = 2.8
    static let edgeFadeInnerMultiplier: CGFloat = 1.8
    static let logoSizeScale: CGFloat = 0.025
    static let logoSpacingMultiplier: CGFloat = 1.5
    static let wordGap: CGFloat = 16
    static let carouselVerticalOffset: CGFloat = -25.0

    // Performance
    static let cacheCleanupInterval: Int = 60

    // Content
    static let words: [String] = ["create", "develop", "produce", "manage", "sell"]
    static let centerText: String = "the story"
    static let logoText: String = "CREATIVE BUSINESS"
}
```

**Benefits**:
- Single source of truth for constants
- Easy to adjust without code changes
- Better documentation of magic numbers

---

### Phase 2: Enhanced Error Handling

#### 2.1 Error Types (`ScreensaverError.swift`)
```swift
enum ScreensaverError: LocalizedError {
    case invalidMetrics(String)
    case invalidGraphicsContext
    case invalidBounds
    case fontLoadFailure(String)

    var errorDescription: String? { ... }
}
```

#### 2.2 Result Types
Use `Result<Success, Failure>` for operations that can fail:
- Metrics calculation
- Font loading
- Attribute creation

---

### Phase 3: Performance Optimizations

#### 3.1 Enhanced Caching Strategy
- **Metrics Cache**: Invalidate only on bounds change
- **Attribute Cache**: Use more granular keys (font size + alpha + weight)
- **Font Cache**: Cache loaded fonts to avoid repeated lookups
- **Periodic Cleanup**: More intelligent cache cleanup based on memory pressure

#### 3.2 Drawing Optimizations
- **Dirty Rect Tracking**: Only redraw changed regions when possible
- **Layer Backing**: Optimize `wantsLayer` usage
- **Reduce Allocations**: Reuse objects across frames

#### 3.3 Memory Management
- **Weak References**: Use weak references where appropriate
- **Cache Limits**: Implement cache size limits
- **Memory Warnings**: Respond to memory pressure notifications

---

### Phase 4: Accessibility Enhancements

#### 4.1 Reduced Motion Support
```swift
/// Enhanced reduced motion support
struct AccessibilityManager {
    static var shouldReduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static var prefersHighContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    static func adjustedAnimationSpeed(baseSpeed: CGFloat) -> CGFloat {
        shouldReduceMotion ? 0 : baseSpeed
    }
}
```

#### 4.2 High Contrast Mode
- Detect high contrast preference
- Adjust colors and opacity for better visibility
- Increase font weights if needed

#### 4.3 VoiceOver Support
- Add accessibility labels to text elements
- Provide meaningful descriptions

---

### Phase 5: Code Organization

#### 5.1 File Structure
```
StorySellerSaver/
├── StorySellerSaverView.swift          # Main view (simplified)
├── Core/
│   ├── AnimationEngine.swift
│   ├── MetricsCalculator.swift
│   ├── ScreensaverRenderer.swift
│   └── StyleManager.swift
├── Configuration/
│   ├── ScreensaverConfiguration.swift
│   └── ScreensaverError.swift
├── Accessibility/
│   └── AccessibilityManager.swift
└── Extensions/
    └── NSFont+Extensions.swift
```

#### 5.2 Protocol-Based Design
```swift
protocol Animatable {
    func update(deltaTime: CGFloat)
    func reset()
}

protocol Renderable {
    func draw(in rect: NSRect, context: NSGraphicsContext)
}

protocol Styleable {
    func attributes(for state: RenderState) -> [NSAttributedString.Key: Any]
}
```

---

### Phase 6: Testing Improvements

#### 6.1 Unit Tests
- **AnimationEngineTests**: Test timing calculations, easing functions
- **MetricsCalculatorTests**: Test metric calculations, caching
- **StyleManagerTests**: Test font loading, attribute creation
- **RendererTests**: Test drawing operations (using mock contexts)

#### 6.2 Integration Tests
- **End-to-end animation**: Verify complete animation cycles
- **Performance tests**: Measure frame rates, memory usage
- **Accessibility tests**: Verify reduced motion behavior

---

### Phase 7: Documentation

#### 7.1 Code Documentation
- Add comprehensive doc comments to all public APIs
- Document complex algorithms (easing, baseline alignment)
- Add usage examples

#### 7.2 Architecture Documentation
- Create `ARCHITECTURE.md` explaining component relationships
- Document design decisions
- Add performance notes

---

## 🔧 Implementation Steps

### Step 1: Create Configuration Module
1. Extract all constants to `ScreensaverConfiguration.swift`
2. Replace magic numbers with configuration references
3. Add documentation for each constant

### Step 2: Extract Animation Engine
1. Create `AnimationEngine.swift`
2. Move animation logic from `animateOneFrame()`
3. Update view to use engine
4. Add unit tests

### Step 3: Extract Metrics Calculator
1. Create `MetricsCalculator.swift`
2. Move `computeMetrics()` logic
3. Improve caching strategy
4. Add unit tests

### Step 4: Extract Style Manager
1. Create `StyleManager.swift`
2. Move font loading and attribute creation
3. Improve attribute caching
4. Add unit tests

### Step 5: Extract Renderer
1. Create `ScreensaverRenderer.swift`
2. Move all drawing code from `draw(_:)`
3. Separate background, carousel, text, and logo rendering
4. Add rendering tests

### Step 6: Simplify Main View
1. Refactor `StorySellerSaverView` to orchestrate components
2. Reduce to ~150 lines
3. Focus on lifecycle management

### Step 7: Add Error Handling
1. Create `ScreensaverError` enum
2. Add error handling to all components
3. Implement fallback rendering

### Step 8: Enhance Accessibility
1. Create `AccessibilityManager`
2. Add high contrast support
3. Improve reduced motion handling
4. Add VoiceOver labels

### Step 9: Performance Tuning
1. Optimize caching strategies
2. Reduce allocations
3. Profile and optimize hot paths

### Step 10: Documentation
1. Add comprehensive doc comments
2. Create architecture documentation
3. Update README with new structure

---

## ✅ Success Criteria

- [ ] Main view class reduced to < 200 lines
- [ ] All components have > 80% test coverage
- [ ] Zero magic numbers (all in configuration)
- [ ] All drawing operations isolated in renderer
- [ ] Comprehensive error handling with fallbacks
- [ ] Enhanced accessibility support
- [ ] Performance: 60 FPS on target hardware
- [ ] Memory usage: < 50MB during operation
- [ ] All SwiftLint warnings resolved
- [ ] Complete documentation

---

## 📊 Expected Improvements

### Code Quality
- **Maintainability**: ⬆️ 80% (smaller, focused files)
- **Testability**: ⬆️ 90% (isolated components)
- **Readability**: ⬆️ 70% (clear separation of concerns)

### Performance
- **Frame Rate**: Maintain 60 FPS (current: 60 FPS)
- **Memory**: Reduce by ~20% (better caching)
- **CPU**: Reduce by ~10% (optimized calculations)

### Developer Experience
- **Onboarding**: Faster (clear architecture)
- **Debugging**: Easier (isolated components)
- **Testing**: Comprehensive (unit testable)

---

## 🚀 Migration Strategy

1. **Incremental Refactoring**: Extract one component at a time
2. **Maintain Functionality**: Each step should maintain current behavior
3. **Test After Each Step**: Verify no regressions
4. **Document Changes**: Update docs as you go

---

## 📝 Notes

- Keep existing public API if any
- Maintain backward compatibility with configuration
- Preserve all visual effects and animations
- Ensure preview mode continues to work
- Maintain all accessibility features

---

## 🔍 Code Review Checklist

Before considering refactor complete:

- [ ] All components follow single responsibility principle
- [ ] No circular dependencies
- [ ] All public APIs documented
- [ ] Error handling comprehensive
- [ ] Performance benchmarks met
- [ ] All tests passing
- [ ] SwiftLint clean
- [ ] Preview mode tested
- [ ] Accessibility tested
- [ ] Memory leaks checked

---

**Status**: Ready for implementation
**Priority**: High
**Estimated Effort**: 2-3 days
**Risk**: Low (incremental refactoring)
