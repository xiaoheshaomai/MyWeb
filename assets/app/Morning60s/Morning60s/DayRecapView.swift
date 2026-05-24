import SwiftUI

/// 白天反馈页：按你给的 Claude 原型参数复刻（仅页面 UI，不包含原型里的奖励弹层/底部 Tab）
/// 太阳同时承担「午睡挑战入口」的职责：点击触发 `onSunTap`，由 ContentView 启动 `.nap` 挑战。
struct DayRecapView: View {
    var elapsedSecondsUsed: Int
    /// 太阳被点击时的回调；默认空实现，保持 Preview 能直接跑
    /// 线上由 `ContentView` 注入 `startNapChallenge()`
    var onSunTap: () -> Void = {}

    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""
    @ObservedObject private var store = RewardCollectionStore.shared

    /// 今天是否真的完成了早起。没完成时首页只能显示空盘子，不展示任何早餐。
    private var hasCompletedToday: Bool {
        streakStore.isCompleted(Date())
    }

    /// 今天实际解锁的那款早餐 asset；未完成或无奖励时为 nil。
    private var todaysRewardAsset: String? {
        guard hasCompletedToday else { return nil }
        return store.unlocked.last
    }

    /// 午睡挑战拿到拿铁后，在首页桌面把拿铁放到早餐斜后方；不进入早餐收藏页。
    private var hasLatteOnDesk: Bool {
        streakStore.coffeeCount(for: Date()) > 0
    }

    /// 观察每日用时变化，保证拍照验证完回到首页时 UI 立即刷新
    @ObservedObject private var streakStore = StreakStore.shared

    /// 显示的起床用时（秒）：
    /// 1) 优先本次会话刚算出来的 `elapsedSecondsUsed`（解决“刚挑战完仍显示旧分钟值”）；
    /// 2) 其次读持久化当天值；
    /// 3) 都没有时兜底 45 秒。
    private var displayElapsedSeconds: Int {
        if elapsedSecondsUsed > 0 { return elapsedSecondsUsed }
        return streakStore.elapsedSeconds(for: Date()) ?? 0
    }

    /// 以分秒格式展示，<60 秒时只显示“xx秒”
    private var durationDisplayText: String {
        let s = max(1, displayElapsedSeconds)
        if s < 60 {
            switch appLanguage {
            case "en": return "\(s)s"
            default: return "\(s)秒"
            }
        }
        let m = s / 60
        let sec = s % 60
        switch appLanguage {
        case "en": return "\(m)m \(sec)s"
        default: return "\(m)分\(sec)秒"
        }
    }

    // MARK: - 原型参数（写死常数，和你发的代码一致）

    @State private var sandwichOffset: CGFloat = 40
    @State private var sandwichOpacity: Double = 0
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleOffset: CGFloat = -16
    @State private var sunScale: CGFloat = 0.5
    @State private var showCalendarPopup = false
    @State private var showRewardDetail = false
    @State private var rewardDetailAsset: String?
    @State private var cardPresented = false
    @State private var showEmptyPlateToast = false

    // MARK: - 可点击性暗示
    /// 太阳旁边的"点我开始午睡挑战"气泡；进页 0.8s 后弹出，停留 ~3.5s 后淡出
    /// 每次重新进入 DayRecapView 都会重放一次，不做「已看过就不再显示」的持久化
    @State private var showSunTooltip = false
    @State private var sunTooltipPulse = false

    private let aa: CGFloat = 85

    private var displayName: String {
        let n = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return L10n.s("onboarding_name_placeholder", lang: appLanguage) }
        return n
    }

    private var primaryDeskAsset: String? {
        if hasLatteOnDesk {
            return RewardData.coffeePlaceholderAsset
        }
        return todaysRewardAsset
    }

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.96)
                // 不铺满底部安全区，避免盖住底部导航栏
                .ignoresSafeArea(edges: [.top, .leading, .trailing])

            VStack(spacing: 0) {
                //上半部分：左窗+太阳与 NightRecapView 同偏移；右日历横向排列
                HStack(alignment: .top, spacing: 20) {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 268, height: 249)
                            .offset(x: -100, y: 30)

                        Rectangle()
                            .fill(Color(red: 0.88, green: 0.87, blue: 0.82))
                            .frame(width: 268, height: 30)
                            .offset(x: -100, y: 250)

                        // 太阳：独立一层，留在左侧窗户里原位
                        // 现在它同时是「午睡挑战」的入口按钮——点击 = 跑 60 秒倒计时
                        ZStack(alignment: .topLeading) {
                            Button {
                                triggerNapChallenge()
                            } label: {
                                ZStack {
                                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                                        let t = timeline.date.timeIntervalSinceReferenceDate
                                        let rayRotation = (t.truncatingRemainder(dividingBy: 14.0) / 14.0) * 360.0
                                        SunRaysView(
                                            color: AppTheme.sunYellow,
                                            size: 150,
                                            tipRatio: 108.0 / 144.0,
                                            baseRatio: 80.0 / 144.0
                                        )
                                        .mask(RingMaskShape(innerRadiusRatio: 86.0 / 144.0).fill(style: FillStyle(eoFill: true)))
                                        .rotationEffect(.degrees(rayRotation))
                                    }
                                    .frame(width: 150, height: 150)
                                    .allowsHitTesting(false)
                                    Circle()
                                        .fill(Color(red: 1, green: 0, blue: 0))
                                        .frame(width: aa, height: aa)
                                }
                                .frame(width: 100, height: 100)
                                .scaleEffect(sunScale)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                            .accessibilityLabel(Text(L10n.s("day_recap_sun_tooltip", lang: appLanguage)))
                            .offset(y: 63)

                            Button {
                                triggerNapChallenge()
                            } label: {
                                sunTooltip
                            }
                            .buttonStyle(PressScaleButtonStyle(pressedScale: 0.96))
                            .opacity(showSunTooltip ? 1 : 0)
                            .scaleEffect(showSunTooltip ? (sunTooltipPulse ? 1.28 : 0.88) : 0.78)
                            .opacity(showSunTooltip ? (sunTooltipPulse ? 1.0 : 0.88) : 0)
                            .offset(x: 64, y: showSunTooltip ? (sunTooltipPulse ? 2 : 27) : 30)
                            .animation(.spring(response: 0.34, dampingFraction: 0.62), value: showSunTooltip)
                            .animation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true), value: sunTooltipPulse)
                            .accessibilityLabel(Text(L10n.s("day_recap_sun_tooltip", lang: appLanguage)))
                        }
                        .frame(width: 190, height: 166, alignment: .topLeading)
                        .onAppear {
                            restartSunAnimations()
                        }
                        .padding(.leading, 30)
                        .padding(.top, 3)
                    }
                    .offset(x: 25, y: 0)

                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showCalendarPopup = true
                    } label: {
                        Image("Group28")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                            .padding(.top, 36)
                            .offset(x: -38, y: 43)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityLabel("日历")

                    Spacer(minLength: 0)
                }
                .padding(.trailing, 16)
                // 文字气泡：脱离左侧窗户 ZStack 单独一层，
                // 依赖 `.frame(maxWidth: .infinity)` 在整个屏幕宽度里水平居中
                .overlay(alignment: .top) {
                    EmptyView()
                }
                //下半部分
                ZStack(alignment: .bottom) {
                    Image("Rectangle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .offset(y: 80)

                    Group {
                        if let asset = primaryDeskAsset {
                            Button {
                                presentRewardCard(asset)
                            } label: {
                                deskRewardImage(asset)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        } else {
                            Button {
                                showTomorrowToast()
                            } label: {
                                Image("plate")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 260, height: 260)
                                    .opacity(0.86)
                            }
                            .buttonStyle(PressScaleButtonStyle(pressedScale: 0.96))
                        }
                    }
                    .offset(y: sandwichOffset - 80)
                    .opacity(sandwichOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.5)) {
                            sandwichOffset = 0
                            sandwichOpacity = 1
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)
            }
        }
        .overlay {
            if showCalendarPopup {
                RecapCalendarPopupLayer(isPresented: $showCalendarPopup)
                    .transition(.opacity)
            }
        }
        .overlay {
            if showRewardDetail {
                rewardCardOverlay
            }
        }
        .overlay(alignment: .center) {
            if showEmptyPlateToast {
                emptyPlateToast
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCalendarPopup)
    }

    /// 太阳上方的黄色入口标签：直角矩形 + 下方小三角，和收集页/拍照页的硬朗视觉统一。
    private var sunTooltip: some View {
        Text(L10n.s("day_recap_sun_tooltip", lang: appLanguage))
            .font(AppTheme.localizedFont(size: 14, weight: .bold, language: appLanguage))
            .foregroundStyle(AppTheme.primaryDark)
            .frame(width: 88, height: 34)
            .background(
                Rectangle()
                    .fill(AppTheme.sunYellow)
            )
            .overlay(alignment: .bottomLeading) {
                DownTriangle()
                    .fill(AppTheme.sunYellow)
                    .frame(width: 14, height: 10)
                    .offset(x: 16, y: 9)
            }
    }

    @ViewBuilder
    private func deskRewardImage(_ asset: String) -> some View {
        if RewardData.isCoffee(asset) {
            Image(RewardData.imageName(for: asset))
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
        } else {
            Image(RewardData.imageName(for: asset))
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
        }
    }

    private var rewardCardOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismissRewardCard() }
            if let rewardAsset = rewardDetailAsset {
                RewardCardView(
                    appLanguage: appLanguage,
                    rewardAsset: rewardAsset,
                    meta: RewardData.isCoffee(rewardAsset) ? nil : store.meta(for: rewardAsset),
                    onDismiss: { dismissRewardCard() }
                )
                .padding(.horizontal, 55)
                .scaleEffect(cardPresented ? 1 : 0.85)
                .opacity(cardPresented ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: cardPresented)
            }
        }
    }

    private func dismissRewardCard() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            cardPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRewardDetail = false
            rewardDetailAsset = nil
        }
    }

    private func triggerNapChallenge() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        // 点击后立刻隐藏 tooltip，避免 tooltip 跟随新挑战页残留
        showSunTooltip = false
        onSunTap()
    }

    private func restartSunAnimations() {
        sunScale = 0.5
        showSunTooltip = false
        sunTooltipPulse = false

        withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.1)) {
            sunScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                showSunTooltip = true
            }
            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                sunTooltipPulse = true
            }
        }
    }

    private func presentRewardCard(_ asset: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        rewardDetailAsset = asset
        showRewardDetail = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            cardPresented = true
        }
    }

    private var emptyPlateToast: some View {
        Text(L10n.s("empty_plate_tomorrow", lang: appLanguage))
            .font(AppTheme.localizedFont(size: 18, weight: .regular, language: appLanguage))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(AppTheme.primaryDark)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }

    private func showTomorrowToast() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            showEmptyPlateToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.22)) {
                showEmptyPlateToast = false
            }
        }
    }
}

/// 按下时轻微缩小，松手回弹，给"可点击"元素提供明确的触觉前反馈
/// 搭配 `UIImpactFeedbackGenerator` 一起用
private struct PressScaleButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.93

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

private struct TriangleRay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    DayRecapView(elapsedSecondsUsed: 45)
}
