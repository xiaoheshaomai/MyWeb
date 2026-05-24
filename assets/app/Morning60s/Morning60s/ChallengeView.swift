import SwiftUI

// MARK: - 设计稿配色（倒计时页按钮/文字，太阳环灰黄见 SunRaysRing）
private enum ChallengeDesign {
    static let buttonRed = Color(hex: "FF2E1F")
    static let textMain = Color(hex: "000000")
    /// 倒计时整页背景（与日历/收藏内米色块统一）
    static let pageBackground = Color(hex: "F9F8F4")
    /// 「放弃」胶囊按钮底色（与页面背景区分）
    static let giveUpCapsuleFill = Color.white
}

enum ChallengePresentation {
    case morning
    case nap
}

/// 挑战页：1 分钟倒计时 + 设计稿太阳环与呼吸按钮
/// 早起 / 午睡复用；路由由 `ContentView` 按 `ChallengeKind` 决定。「放弃」按钮 UI：见本 struct 内 `// MARK: - 放弃按钮`
struct ChallengeView: View {
    var challengeStartDate: Date
    var presentation: ChallengePresentation = .morning
    var onUp: () -> Void
    /// 放弃挑战回调；`nil` 则不显示「放弃」按钮（老调用方保持向后兼容）
    /// 触发前有一次原生 `.alert` 二次确认，避免误触
    var onGiveUp: (() -> Void)? = nil

    @AppStorage("appLanguage") private var appLanguage = "zh"
    @State private var ringVisible = false
    /// 放弃二次确认的弹窗开关
    @State private var showGiveUpConfirm = false

    /// 倒计时总时长（秒）。当前产品决定：无论早起 / 午睡都是 60 秒
    /// 改常量即可同步 `ChallengeView` 与 `SunProgressRing`；别忘了把 `SunRaysRing.totalSeconds` 一起调
    private let challengeTotalSeconds = 60

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let now = context.date
            let displaySeconds = max(0, challengeTotalSeconds - Int(now.timeIntervalSince(challengeStartDate)))
            let minutes = displaySeconds / 60
            let seconds = displaySeconds % 60

            GeometryReader { geo in
                // 真机宽度小于 Canvas 时，太阳环按宽度收缩，避免左右裁切导致「和预览完全不是一张脸」
                let ringSize = min(360, max(260, geo.size.width - 32))
                let topPad = geo.safeAreaInsets.top + 12

                ZStack {
                    // 整页背景 #F9F8F4（wakeFlowOverlay 底层仍是 AppTheme.background，此处盖住挑战页区域）
                    ChallengeDesign.pageBackground
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Text(challengeTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primaryDark)
                            .multilineTextAlignment(.center)
                            .padding(.top, topPad)

                        Text(String(format: "%02d:%02d", minutes, seconds))
                            .font(AppTheme.localizedFont(size: 80, weight: .bold, language: appLanguage))
                            .monospacedDigit()
                            .tracking(0)
                            .foregroundStyle(ChallengeDesign.textMain)
                            .padding(.top, 8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)

                        // 倒计时自然走到 00:00、尚未点「我起床啦」：一句轻提示（仍可继续点红圆进拍照）
                        if displaySeconds == 0 {
                            Text(L10n.s("challenge_countdown_expired_hint", lang: appLanguage))
                                .font(AppTheme.localizedFont(size: 17, weight: .medium, language: appLanguage))
                                .foregroundStyle(AppTheme.primaryDark.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 28)
                                .padding(.top, 12)
                        }

                        ZStack {
                            SunProgressRing(
                                remainingSeconds: displaySeconds,
                                totalSeconds: challengeTotalSeconds,
                                size: ringSize
                            )
                            .scaleEffect(ringVisible ? 1 : 0.4)
                            .opacity(ringVisible ? 1 : 0)
                            .animation(.spring(response: 0.48, dampingFraction: 0.72), value: ringVisible)
                            BreatheUpButton(
                                title: upButtonTitle,
                                fillColor: presentation == .nap ? AppTheme.sunYellow : ChallengeDesign.buttonRed,
                                textColor: presentation == .nap ? AppTheme.primaryDark : .white,
                                action: onUp
                            )
                        }
                        .frame(width: ringSize, height: ringSize)
                        .padding(.top, 12)

                        // MARK: - 放弃按钮（白底胶囊 + xmark + 文案 16pt；仅 `onGiveUp != nil` 时显示）
                        if onGiveUp != nil {
                            Button {
                                showGiveUpConfirm = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark")
                                        .font(AppTheme.localizedFont(size: 16, weight: .bold, language: appLanguage))
                                    Text(L10n.s("challenge_give_up", lang: appLanguage))
                                        .font(AppTheme.localizedFont(size: 16, weight: .bold, language: appLanguage))
                                }
                                .foregroundStyle(Color(hex: "878979"))
                                .padding(.horizontal, 25)
                                .padding(.vertical, 20)
                                .background(
                                    Capsule()
                                        .fill(ChallengeDesign.giveUpCapsuleFill)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 3, y: 5)
                                )
                                .overlay(
                                    Capsule().stroke(Color.black.opacity(0.18), lineWidth: 0)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 20)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 只触发一次进场动画；不要挂在 TimelineView 内部，否则每秒刷新可能反复 onAppear，真机布局和 Canvas 不一致
        .onAppear {
            ringVisible = true
        }
        // MARK: - 放弃二次确认（系统 Alert）
        .alert(
            Text(giveUpConfirmTitle),
            isPresented: $showGiveUpConfirm
        ) {
            Button(L10n.s("challenge_give_up_confirm_yes", lang: appLanguage), role: .destructive) {
                onGiveUp?()
            }
            Button(L10n.s("cancel", lang: appLanguage), role: .cancel) {}
        } message: {
            Text(giveUpConfirmBody)
        }
    }

    private var challengeTitle: String {
        switch presentation {
        case .morning:
            return L10n.s("go_leave_bed", lang: appLanguage)
        case .nap:
            return L10n.s("nap_challenge_countdown_title", lang: appLanguage)
        }
    }

    private var upButtonTitle: String {
        switch presentation {
        case .morning:
            return L10n.s("i_am_up", lang: appLanguage)
        case .nap:
            return L10n.s("nap_i_am_up", lang: appLanguage)
        }
    }

    private var giveUpConfirmTitle: String {
        switch presentation {
        case .morning:
            return L10n.s("challenge_give_up_confirm_title", lang: appLanguage)
        case .nap:
            return L10n.s("nap_give_up_confirm_title", lang: appLanguage)
        }
    }

    private var giveUpConfirmBody: String {
        switch presentation {
        case .morning:
            return L10n.s("challenge_give_up_confirm_body", lang: appLanguage)
        case .nap:
            return L10n.s("nap_give_up_confirm_body", lang: appLanguage)
        }
    }
}

/// 中心红色「我起床啦」按钮，带呼吸动效（4s 循环 scale 1 ↔ 0.97）
private struct BreatheUpButton: View {
    var title: String
    var fillColor: Color = ChallengeDesign.buttonRed
    var textColor: Color = .white
    var action: () -> Void
    @State private var breathing = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .tracking(-0.5)
                .foregroundStyle(textColor)
                .frame(width: AppTheme.bigCircleSize, height: AppTheme.bigCircleSize)
                .background(Circle().fill(fillColor))
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(breathing ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathing)
        .onAppear { breathing = true }
    }
}

#Preview("倒计时页 · 进行中") {
    ChallengeView(
        challengeStartDate: Date().addingTimeInterval(-30),
        onUp: {},
        onGiveUp: {}
    )
}

#Preview("午睡倒计时") {
    ChallengeView(
        challengeStartDate: Date().addingTimeInterval(-1),
        presentation: .nap,
        onUp: {},
        onGiveUp: {}
    )
}

#Preview("倒计时页 · 已归零") {
    ChallengeView(
        challengeStartDate: Date().addingTimeInterval(-65),
        onUp: {},
        onGiveUp: {}
    )
}
