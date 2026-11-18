import SwiftUI

public extension View {
    /**
     読み込み中の場所取りに、左上から右下へ光の帯を流す。

     - active: false のときは何もしない
     - delay: 帯の遅れ（秒）。行ごとに少しずつ増やすと、帯が行をまたいで下へ流れる
     */
    @ViewBuilder
    func shimmering(active: Bool = true, delay: TimeInterval = 0) -> some View {
        if active {
            modifier(Shimmer(delay: delay))
        } else {
            self
        }
    }

    /// 読み込み中の間、中身を伏せ字にして光を流し、押せなくする。読み込み中に見せるサンプルの内容に付ける
    func shimmering(isLoading: Bool, delay: TimeInterval = 0) -> some View {
        redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading, delay: delay)
            .allowsHitTesting(!isLoading)
    }

    /// この中の光のマスクを替える。帯の外の濃さを上げたいとき（明るい地で伏せ字が背景に溶けるときなど）に、アプリの一番外で一度だけ付ける
    func shimmerGradient(_ gradient: Gradient) -> some View {
        environment(\.shimmerGradient, gradient)
    }
}

public extension EnvironmentValues {
    /// 光のマスク。帯の外を 0.3、帯を 1 にした黒が既定
    @Entry var shimmerGradient = Gradient(colors: [.black.opacity(0.3), .black, .black.opacity(0.3)])
}

/**
 repeatForever のアニメーションではなく、TimelineView で時刻から帯の位置を決めて描く。

 - repeatForever は、そのビューが画面から外れても回り続ける。一覧から外れた場所取りが光り続け、何もしていない画面で CPU を 15〜70% 使い続けた（HomeReel の Mac 版、2026-11-19）
 - 一覧の画面外に作り置かれたビューでは TimelineView も進むことがあるので、画面から外れている間は止める（止めないと同じ画面で 20〜30% 残った）
 - 位置を時刻だけから決めるので、同じ画面の光はいつもそろって流れ、`delay` でずらした行の間隔も崩れない（repeatForever に付けた delay は周期ごとに挟まるので、行ごとに周期が変わってばらける）
 - 視差効果を減らす設定では流さない（HIG: Motion）。伏せ字だけで読み込み中と分かる
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

    /// 帯が左上の外から右下の外へ抜けるまでの進み具合（0〜1）。抜けたあと、次に入るまで少し間を置く
    static func progress(at date: Date, delay: TimeInterval) -> Double {
        let elapsed = (date.timeIntervalSinceReferenceDate - delay).truncatingRemainder(dividingBy: duration + pause)
        return max(0, elapsed - pause) / duration
    }

    private static let duration = 1.5
    private static let pause = 0.25
}

extension Shimmer {
    /// 帯の幅だけ枠の外から入り、枠の外へ抜ける斜めのグラデーション
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
