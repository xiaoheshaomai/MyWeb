import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Reward Success View
// ─────────────────────────────────────────────
struct RewardSuccessView: View {
    /// 今天实际解锁的 asset 名（如 "san3"、"cake5"）；决定图片 / 标题 / 介绍。
    var rewardAsset: String = "san1"
    var onDone: () -> Void = {}

    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""

    private let cream = Color(red: 0.98, green: 0.97, blue: 0.90)
    private let red   = Color(red: 1, green: 0, blue: 0)
    private let yellow = AppTheme.sunYellow

    private var displayName: String {
        let n = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return L10n.s("onboarding_name_placeholder", lang: appLanguage) }
        return n
    }

    var body: some View {
        ZStack {
            RewardSunrayBackground()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                headerBlock()
                    .padding(.top, 82)

                rewardCard()

                Spacer(minLength: 0)

                acceptButton()
                    .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Header
    private func headerBlock() -> some View {
        VStack(spacing: 4) {
            Text(L10n.s("reward_verify_success", lang: appLanguage))
                .foregroundColor(red)
            Text(String(format: L10n.s("reward_verify_praise_fmt", lang: appLanguage), displayName))
                .foregroundColor(.black)
        }
        .font(AppTheme.localizedFont(size: 24, weight: .semibold, language: appLanguage))
        .multilineTextAlignment(.center)
        .frame(width: 301)
    }

    private func rewardCard() -> some View {
        let outerW: CGFloat = 308
        let outerH: CGFloat = 459
        let innerW: CGFloat = 289
        let innerH: CGFloat = 403

        return ZStack {
            Rectangle()
                .foregroundColor(yellow)
                .frame(width: outerW, height: outerH)

            Rectangle()
                .foregroundColor(.white)
                .frame(width: innerW, height: innerH)
                .offset(y: 14)

            VStack(spacing: 0) {
                Text(RewardData.title(for: rewardAsset, lang: appLanguage))
                    .font(AppTheme.localizedFont(size: 25, weight: .bold, language: appLanguage))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(width: 260, height: 82, alignment: .center)

                rewardImage()

                Spacer(minLength: 0)

                Text(RewardData.desc(for: rewardAsset, lang: appLanguage))
                    .font(AppTheme.localizedFont(size: 21, weight: .regular, language: appLanguage))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 248, alignment: .center)
                    .padding(.bottom, 45)
            }
            .frame(width: innerW, height: innerH, alignment: .top)
            .padding(.top, 30)
            .offset(y: 14)
        }
        .frame(width: outerW, height: outerH)
    }

    @ViewBuilder
    private func rewardImage() -> some View {
        if RewardData.isCoffee(rewardAsset) && UIImage(named: RewardData.imageName(for: rewardAsset)) == nil {
            Image(systemName: "cup.and.saucer.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(red: 0.45, green: 0.30, blue: 0.15))
                .frame(width: 180)
                .padding(.vertical, 30)
        } else {
            Image(RewardData.imageName(for: rewardAsset))
                .resizable()
                .scaledToFit()
                .frame(width: RewardData.isCoffee(rewardAsset) ? 246 : 240)
        }
    }

    // MARK: Button
    private func acceptButton() -> some View {
        Button(action: onDone) {
            Text(L10n.s("reward_accept", lang: appLanguage))
                .font(AppTheme.localizedFont(size: 17, language: appLanguage))
                .foregroundColor(.white)
                .frame(width: 115, height: 59)
                .background(Color.black)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────
// MARK: - Sunray Background（TimelineView 真正逐帧旋转）
// ─────────────────────────────────────────────
struct RewardSunrayBackground: View {
    // 用 Date 记录动画开始时间，在 TimelineView 里算出当前角度
    @State private var startDate: Date = .now

    private let bgColor      = Color.white
    private let rayColor     = Color(red: 1.0, green: 0.89, blue: 0.28)
    private let rayCount     = 18
    private let rayHalfAngle = 6.8
    private let period       = 24.0

    var body: some View {
        GeometryReader { geo in
            let w      = geo.size.width
            let h      = geo.size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let radius = sqrt(w * w + h * h)   // 保证覆盖四角

            ZStack {
                bgColor

                // TimelineView 每帧触发 Canvas 重绘 → rotation 真正每帧更新
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    let rotation = (elapsed / period) * 360.0   // 当前旋转角度（度）

                    Canvas { ctx, _ in
                        for i in 0..<rayCount {
                            let angleDeg = Double(i) * (360.0 / Double(rayCount)) + rotation
                            var path = Path()
                            path.move(to: center)
                            path.addArc(
                                center: center,
                                radius: radius,
                                startAngle: .degrees(angleDeg - rayHalfAngle),
                                endAngle:   .degrees(angleDeg + rayHalfAngle),
                                clockwise: false
                            )
                            path.closeSubpath()
                            ctx.fill(path, with: .color(rayColor))
                        }
                    }
                }
            }
        }
        .onAppear {
            startDate = .now
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────
#Preview {
    struct RewardWithTab: View {
        @State private var tab = 0
        var body: some View {
            ZStack {
                RewardSuccessView(rewardAsset: "san3", onDone: {})
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MainTabBar(selection: $tab)
            }
        }
    }
    return RewardWithTab()
}
