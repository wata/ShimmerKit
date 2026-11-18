import Foundation
@testable import ShimmerKit
import Testing

struct ShimmerTests {
    /// 1周（間 0.25 秒＋流れる 1.5 秒）の頭から測れる時刻
    private let cycleStart = Date(timeIntervalSinceReferenceDate: 1.75 * 1000)

    @Test func waitsBeforeEachSweep() {
        #expect(Shimmer.progress(at: cycleStart, delay: 0) == 0)
        #expect(Shimmer.progress(at: cycleStart + 0.2, delay: 0) == 0)
    }

    @Test func sweepsAcrossOverTheDuration() {
        #expect(Shimmer.progress(at: cycleStart + 0.25 + 0.75, delay: 0) == 0.5)
        #expect(abs(Shimmer.progress(at: cycleStart + 1.749, delay: 0) - 1) < 0.001)
    }

    @Test func restartsEveryCycle() {
        let first = Shimmer.progress(at: cycleStart + 1, delay: 0)
        #expect(Shimmer.progress(at: cycleStart + 1.75 + 1, delay: 0) == first)
    }

    /// 行ごとにずらした帯は、何周たっても同じだけ遅れたまま流れる
    @Test func delayKeepsItsLagAcrossCycles() {
        for cycle in 0..<100 {
            let date = cycleStart + Double(cycle) * 1.75 + 1
            #expect(Shimmer.progress(at: date + 0.3, delay: 0.3) == Shimmer.progress(at: date, delay: 0))
        }
    }
}
