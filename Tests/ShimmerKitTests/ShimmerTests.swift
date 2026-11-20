import Foundation
@testable import ShimmerKit
import Testing

struct ShimmerTests {
    private let cycle = Shimmer.pause + Shimmer.duration
    /// A time that falls exactly on the start of a cycle.
    private var cycleStart: Date {
        Date(timeIntervalSinceReferenceDate: cycle * 1000)
    }

    @Test func waitsBeforeEachSweep() {
        #expect(Shimmer.progress(at: cycleStart, delay: 0) == 0)
        #expect(Shimmer.progress(at: cycleStart + Shimmer.pause * 0.9, delay: 0) == 0)
    }

    @Test func sweepsAcrossOverTheDuration() {
        #expect(abs(Shimmer.progress(at: cycleStart + Shimmer.pause + Shimmer.duration / 2, delay: 0) - 0.5) < 0.001)
        #expect(abs(Shimmer.progress(at: cycleStart + cycle - 0.001, delay: 0) - 1) < 0.001)
    }

    @Test func restartsEveryCycle() {
        let first = Shimmer.progress(at: cycleStart + 1, delay: 0)
        #expect(abs(Shimmer.progress(at: cycleStart + cycle + 1, delay: 0) - first) < 0.001)
    }

    /// A band delayed per row keeps the same lag no matter how many cycles pass.
    @Test func delayKeepsItsLagAcrossCycles() {
        for count in 0..<100 {
            let date = cycleStart + Double(count) * cycle + 1
            #expect(abs(Shimmer.progress(at: date + 0.3, delay: 0.3) - Shimmer.progress(at: date, delay: 0)) < 0.001)
        }
    }
}
