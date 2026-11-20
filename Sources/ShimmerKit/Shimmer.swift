import SwiftUI

public extension View {
    /**
     Sweeps a band of light from the top leading corner to the bottom trailing corner of a loading placeholder.

     - active: Does nothing when false.
     - delay: How far the band lags, in seconds. Increase it a little per row to make the band travel down across rows.
     */
    @ViewBuilder
    func shimmering(active: Bool = true, delay: TimeInterval = 0) -> some View {
        if active {
            modifier(Shimmer(delay: delay))
        } else {
            self
        }
    }

    /// While loading, redacts the content, shimmers it, and disables hit testing. Apply it to the sample content shown during loading.
    func shimmering(isLoading: Bool, delay: TimeInterval = 0) -> some View {
        redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading, delay: delay)
            .allowsHitTesting(!isLoading)
    }

    /// Replaces the shimmer mask for everything inside. Use it to raise the resting opacity outside the band (for example when placeholders fade into a light background), once at the root of the app.
    func shimmerGradient(_ gradient: Gradient) -> some View {
        environment(\.shimmerGradient, gradient)
    }
}

public extension EnvironmentValues {
    /// The shimmer mask. Defaults to black at 0.3 opacity outside the band and 1 inside it.
    @Entry var shimmerGradient = Gradient(colors: [.black.opacity(0.3), .black, .black.opacity(0.3)])
}

/**
 Draws the band at a position computed from the clock in a `TimelineView`, rather than with a `repeatForever` animation.

 - A `repeatForever` animation keeps running after its view leaves the screen. Placeholders scrolled out of a list kept shimmering and burning CPU while the window sat idle.
 - A `TimelineView` can also keep ticking in views a lazy stack has prepared off screen, so the timeline is paused while the view is off screen.
 - Because the position depends only on the clock, every shimmer on screen stays in sync, and the spacing between rows offset by `delay` never drifts. (A delay on a `repeatForever` animation is inserted every cycle, so each row ends up with a different period and they scatter.)
 - Doesn't move when Reduce Motion is on (HIG: Motion). The redaction alone shows that the content is loading.
 */
struct Shimmer: ViewModifier {
    let delay: TimeInterval
    @Environment(\.shimmerGradient) private var gradient
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .mask {
                    TimelineView(.animation(paused: !isVisible)) { context in
                        Band(gradient: gradient, progress: Self.progress(at: context.date, delay: delay))
                    }
                    .flipsForRightToLeftLayoutDirection(true)
                }
                .onAppear {
                    isVisible = true
                }
                .onDisappear {
                    isVisible = false
                }
        }
    }

    /// How far the band has traveled from outside the top leading corner to outside the bottom trailing corner (0–1). Pauses briefly after it leaves before the next sweep.
    nonisolated static func progress(at date: Date, delay: TimeInterval) -> Double {
        let elapsed = (date.timeIntervalSinceReferenceDate - delay).truncatingRemainder(dividingBy: duration + pause)
        return max(0, elapsed - pause) / duration
    }

    nonisolated static let duration = 1.5
    nonisolated static let pause = 0.25
}

extension Shimmer {
    /// A diagonal gradient that enters from one band width outside the frame and exits fully outside it.
    private struct Band: View {
        let gradient: Gradient
        let progress: Double

        var body: some View {
            let start = -Self.width + (1 + Self.width) * progress
            let end = (1 + Self.width) * progress

            LinearGradient(gradient: gradient, startPoint: UnitPoint(x: start, y: start), endPoint: UnitPoint(x: end, y: end))
        }

        private static let width = 0.3
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(0..<4) { row in
            Text(verbatim: "A placeholder line of text")
                .font(.title3)
                .shimmering(isLoading: true, delay: Double(row) * 0.1)
        }

        RoundedRectangle(cornerRadius: 12)
            .fill(.gray.opacity(0.3))
            .frame(height: 120)
            .shimmering()
    }
    .padding()
}
