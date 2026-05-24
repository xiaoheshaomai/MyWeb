import SwiftUI

// MARK: - 太阳环配色（灰底加深以便与黄色区分）
enum SunRaysColors {
    static let track = Color(hex: "8C887A")       // 加深的灰
    static let progressYellow = Color(hex: "FFD600")
}

/// 从 12 点钟方向顺时针扫过的扇形
struct PieProgressShape: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        guard r > 0, progress > 0 else { return Path() }
        var path = Path()
        path.move(to: center)
        let startAngle = 270.0 * .pi / 180
        let sweep = progress * 2 * .pi
        path.addArc(center: center, radius: r, startAngle: .radians(startAngle), endAngle: .radians(startAngle - sweep), clockwise: true)
        path.closeSubpath()
        return path
    }
}

/// 环形遮罩：外圆可见，内圆镂空
struct RingMaskShape: Shape {
    var innerRadiusRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let R = min(rect.width, rect.height) / 2
        let r = R * innerRadiusRatio
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - R, y: center.y - R, width: 2 * R, height: 2 * R))
        path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
        return path
    }
}

/// 24 根太阳射线路径（设计稿 288 时 tip=114、base=80；可通过比例收紧环径）
struct SunRaysShape: Shape {
    let rayCount = 24
    var tipRatio: CGFloat = 114 / 144
    var baseRatio: CGFloat = 80 / 144

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let R = min(rect.width, rect.height) / 2
        let tipRadius = R * tipRatio
        let baseRadius = R * baseRatio
        var combined = Path()
        for i in 0..<rayCount {
            let angle = (Double(i) * 15) * .pi / 180
            let a1 = (Double(i) * 15 - 7.5) * .pi / 180
            let a2 = (Double(i) * 15 + 7.5) * .pi / 180
            let tip = CGPoint(x: cx + tipRadius * CGFloat(sin(angle)), y: cy - tipRadius * CGFloat(cos(angle)))
            let b1 = CGPoint(x: cx + baseRadius * CGFloat(sin(a1)), y: cy - baseRadius * CGFloat(cos(a1)))
            let b2 = CGPoint(x: cx + baseRadius * CGFloat(sin(a2)), y: cy - baseRadius * CGFloat(cos(a2)))
            combined.move(to: tip)
            combined.addLine(to: b1)
            combined.addLine(to: b2)
            combined.closeSubpath()
        }
        return combined
    }
}

/// 单色射线环视图
struct SunRaysView: View {
    var color: Color
    var size: CGFloat = 360
    var tipRatio: CGFloat = 114 / 144
    var baseRatio: CGFloat = 80 / 144

    var body: some View {
        SunRaysShape(tipRatio: tipRatio, baseRatio: baseRatio)
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// 太阳进度环（挑战页用）：灰底 + 按剩余时间裁剪的黄色
/// 总时长由调用方传入，和 `ChallengeView.challengeTotalSeconds` 保持一致
struct SunProgressRing: View {
    var remainingSeconds: Int
    /// 倒计时总秒数，决定进度条满格对应几秒
    /// 默认 60 与当前挑战配置一致；调用方可覆盖
    var totalSeconds: Int = 60
    var size: CGFloat = 360
    let innerRatio: CGFloat = 92 / 144

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1, max(0, Double(remainingSeconds) / Double(totalSeconds)))
    }

    var body: some View {
        ZStack {
            SunRaysView(color: SunRaysColors.track, size: size)
                .mask(RingMaskShape(innerRadiusRatio: innerRatio).fill(style: FillStyle(eoFill: true)))
            SunRaysView(color: SunRaysColors.progressYellow, size: size)
                .mask(RingMaskShape(innerRadiusRatio: innerRatio).fill(style: FillStyle(eoFill: true)))
                .mask(PieProgressShape(progress: progress).fill(style: FillStyle(eoFill: true)))
        }
        .frame(width: size, height: size)
    }
}

/// 满圈太阳环（首页用）：可选灰底；满黄圈 + 三角呼吸律动。
/// 日间反馈页手调光芒半径：改 `DayRecapView` 里 `sunRingSize` / `recapSunInnerRatio` / `rayTipRatio` / `rayBaseRatio`，勿改本 struct 默认值即可不影响其它界面。
struct SunFullRingView: View {
    var size: CGFloat = 360
    /// 是否显示灰底（封面不显示，避免灰边）
    var showTrack: Bool = false
    var yellowBreathe: Bool = true
    /// 内圆镂空比例（越小露出的黄圈越靠内；日间反馈页用较小值让光芒贴近红日）
    var innerRadiusRatio: CGFloat = 92 / 144
    /// 三角尖端/底边相对外圈半径的比例，同步略调可收紧整个光环
    var rayTipRatio: CGFloat = 114 / 144
    var rayBaseRatio: CGFloat = 80 / 144
    @State private var breathe = false

    private var yellowRays: some View {
        SunRaysView(
            color: SunRaysColors.progressYellow,
            size: size,
            tipRatio: rayTipRatio,
            baseRatio: rayBaseRatio
        )
        .opacity(yellowBreathe ? (breathe ? 0.82 : 1.0) : 1.0)
        .scaleEffect(yellowBreathe ? (breathe ? 0.96 : 1.0) : 1.0)
        .mask(RingMaskShape(innerRadiusRatio: innerRadiusRatio).fill(style: FillStyle(eoFill: true)))
        .mask(PieProgressShape(progress: 1).fill(style: FillStyle(eoFill: true)))
    }

    var body: some View {
        ZStack {
            if showTrack {
                SunRaysView(color: SunRaysColors.track, size: size, tipRatio: rayTipRatio, baseRatio: rayBaseRatio)
                    .mask(RingMaskShape(innerRadiusRatio: innerRadiusRatio).fill(style: FillStyle(eoFill: true)))
            }
            yellowRays
        }
        .frame(width: size, height: size)
        .onAppear { if yellowBreathe { breathe = true } }
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathe)
    }
}
