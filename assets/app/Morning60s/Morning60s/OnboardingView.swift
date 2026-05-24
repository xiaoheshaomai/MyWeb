import SwiftUI

/// 首次打开流程：用 5 张短教程页，让用户快速理解速起的早晨、奖励、白天、夜晚和小组件。
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = "zh"

    private enum Step: Int, CaseIterable, Hashable {
        case countdown
        case reward
        case day
        case night
        case widget
    }

    @State private var step: Step = .countdown
    @State private var countdownRemaining: Int = 60
    @State private var textOpacity: Double = 0
    @State private var daySandwichDropOffset: CGFloat = -82
    @State private var daySandwichOpacity: Double = 0
    @State private var daySandwichScale: CGFloat = 0.96
    @State private var nightPaperDropOffset: CGFloat = -82
    @State private var nightPaperOpacity: Double = 0
    @State private var nightPaperScale: CGFloat = 0.96
    @State private var showOpeningSplash = true

    private let redInset: CGFloat = 20
    private let topBandHeight: CGFloat = 64
    private let progressTabTopOffset: CGFloat = 36
    private let topCopyPadding: CGFloat = 46
    private let headlineSize: CGFloat = 22
    private let headlineWeight: Font.Weight = .semibold

    /// 每秒驱动 onboarding 上倒计时与「我起来啦」太阳光芒灰化
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let safeBottom = geo.safeAreaInsets.bottom
            let innerWidth = max(260, geo.size.width - redInset * 2)
            let innerBottomInset = max(20, safeBottom + 16)
            let innerHeight = max(420, geo.size.height - topBandHeight - innerBottomInset)

            ZStack(alignment: .top) {
                AppTheme.accentOrange
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topBandHeight)

                    ZStack {
                        Color(hex: "F8F7F2")

                        if step == .countdown || step == .reward {
                            morningIntroPage(width: innerWidth, height: innerHeight)
                                .frame(width: innerWidth, height: innerHeight)
                                .transition(.opacity)
                        }

                        ForEach([Step.day, .night, .widget], id: \.self) { item in
                            if step == item {
                                pageView(for: item, width: innerWidth, height: innerHeight)
                                    .frame(width: innerWidth, height: innerHeight)
                                    .transition(pageTransition)
                            }
                        }
                    }
                    .frame(width: innerWidth, height: innerHeight)
                    .padding(.horizontal, redInset)

                    Spacer(minLength: 0)
                }

                progressTabs(width: innerWidth)
                    .padding(.horizontal, redInset)
                    .offset(y: progressTabTopOffset)

                if showOpeningSplash {
                    SandwichSplashView {
                        withAnimation(.easeOut(duration: 0.18)) {
                            showOpeningSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .onReceive(countdownTimer) { _ in
                guard step == .countdown else { return }
                if countdownRemaining > 0 {
                    countdownRemaining -= 1
                } else {
                    countdownRemaining = 60
                }
            }
            .onChange(of: step) { _, newValue in
                if newValue == .countdown {
                    countdownRemaining = 60
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    textOpacity = 1
                }
            }
        }
    }

    private var pageTransition: AnyTransition {
        .opacity
    }

    private func progressTabs(width: CGFloat) -> some View {
        let spacing: CGFloat = 10
        let tabWidth = (width - spacing * CGFloat(Step.allCases.count - 1)) / CGFloat(Step.allCases.count)

        return HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Step.allCases, id: \.self) { item in
                let isSelected = item == step

                Rectangle()
                    .fill(isSelected ? AppTheme.sunYellow : Color(hex: "D9D9D9"))
                    .frame(width: tabWidth, height: isSelected ? 12 : 6)
                    .animation(.spring(response: 0.32, dampingFraction: 0.72), value: step)
            }
        }
        .frame(width: width)
    }

    @ViewBuilder
    private func pageView(for item: Step, width: CGFloat, height: CGFloat) -> some View {
        switch item {
        case .countdown:
            countdownGuidePage(width: width, height: height)
        case .reward:
            rewardGuidePage(width: width, height: height)
        case .day:
            fullSceneDayPage(width: width, height: height)
        case .night:
            fullSceneNightPage(width: width, height: height)
        case .widget:
            finalPage(width: width, height: height)
        }
    }

    // MARK: - Pages 1 / 2：固定灰色框，内部内容渐隐渐显

    private func morningIntroPage(width: CGFloat, height: CGFloat) -> some View {
        let box = previewBoxSize(width: width, height: height)

        return VStack(spacing: 0) {
            ZStack {
                introTitle("每天清晨第一次打开 App 时\n自动开始 1 分钟倒计时")
                    .opacity(step == .countdown ? textOpacity : 0)

                introTitle("按照指引完成起床验证\n获得一个早餐奖励")
                    .opacity(step == .reward ? textOpacity : 0)
            }
            .padding(.top, topCopyPadding)
            .padding(.horizontal, 18)
            .animation(.easeInOut(duration: 0.34), value: step)

            Spacer(minLength: 12)

            unifiedPreviewBox(width: width, height: height) { box in
                ZStack {
                    if step == .countdown {
                        VStack(spacing: 20) {
                            Text(formattedCountdown)
                                .font(.system(size: min(64, box.width * 0.21), weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.primaryDark)

                            countdownSun(size: min(box.width * 0.78, 220))
                        }
                        .transition(.opacity)
                    }

                    if step == .reward {
                        Image("sand1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: box.width * 0.74, height: box.height * 0.74)
                            .offset(y: 6)
                            .shadow(color: .black.opacity(0.12), radius: 7, y: 4)
                            .transition(.opacity)
                    }
                }
                .frame(width: box.width, height: box.height)
                .animation(.easeInOut(duration: 0.34), value: step)
            }
            .frame(width: box.width, height: box.height)

            Spacer(minLength: 12)

            onboardingButton(title: "好滴") {
                goNext()
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func introTitle(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
            .foregroundStyle(AppTheme.primaryDark)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Page 1: 倒计时

    private func countdownGuidePage(width: CGFloat, height: CGFloat) -> some View {
        let box = previewBoxSize(width: width, height: height)

        return VStack(spacing: 0) {
            Text("每天清晨第一次打开 App 时\n自动开始 1 分钟倒计时")
                .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topCopyPadding)
                .padding(.horizontal, 18)
                .opacity(textOpacity)

            Spacer(minLength: 12)

            unifiedPreviewBox(width: width, height: height) { box in
                VStack(spacing: 20) {
                    Text(formattedCountdown)
                        .font(.system(size: min(64, box.width * 0.21), weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.primaryDark)

                    countdownSun(size: min(box.width * 0.78, 220))
                }
            }
            .frame(width: box.width, height: box.height)

            Spacer(minLength: 12)

            onboardingButton(title: "好滴") {
                goNext()
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var formattedCountdown: String {
        let m = countdownRemaining / 60
        let s = countdownRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func countdownSun(size: CGFloat) -> some View {
        let circleSize = size * (AppTheme.bigCircleSize / 360)
        let buttonFontSize = circleSize * (22 / AppTheme.bigCircleSize)

        return ZStack {
            // 真的倒计时太阳：黄色光芒随秒数变灰
            SunProgressRing(
                remainingSeconds: countdownRemaining,
                totalSeconds: 60,
                size: size
            )
            .animation(.linear(duration: 0.6), value: countdownRemaining)

            Circle()
                .fill(AppTheme.accentOrange)
                .frame(width: circleSize, height: circleSize)

            Text("我起来啦")
                .font(AppTheme.localizedFont(size: buttonFontSize, weight: .bold, language: appLanguage))
                .tracking(-0.5 * (circleSize / AppTheme.bigCircleSize))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Page 2: 早餐奖励

    private func rewardGuidePage(width: CGFloat, height: CGFloat) -> some View {
        let box = previewBoxSize(width: width, height: height)

        return VStack(spacing: 0) {
            Text("按照指引完成起床验证\n获得一个早餐奖励")
                .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topCopyPadding)
                .padding(.horizontal, 18)
                .opacity(textOpacity)

            Spacer(minLength: 36)

            unifiedPreviewBox(width: width, height: height) { box in
                Image("sand1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: box.width * 0.74, height: box.height * 0.74)
                    .offset(y: 6)
                    .shadow(color: .black.opacity(0.12), radius: 7, y: 4)
            }
            .frame(width: box.width, height: box.height)

            Spacer(minLength: 14)

            onboardingButton(title: "好滴") {
                goNext()
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 通用文字 + 视觉 + 按钮 容器

    private func previewBoxSize(width: CGFloat, height: CGFloat) -> CGSize {
        let boxWidth = min(width * 0.84, 300)
        let boxHeight = min(height * 0.52, boxWidth * 1.16)
        return CGSize(width: boxWidth, height: boxHeight)
    }

    private func unifiedPreviewBox<Content: View>(
        width: CGFloat,
        height: CGFloat,
        content: (CGSize) -> Content
    ) -> some View {
        let box = previewBoxSize(width: width, height: height)

        return ZStack {
            Color(hex: "F1F0EC")
            content(box)
                .frame(width: box.width, height: box.height)
        }
        .frame(width: box.width, height: box.height)
        .clipped()
    }

    private func guidePage<Visual: View>(
        text: String,
        visualHeight: CGFloat,
        buttonTitle: String,
        visualTopPadding: CGFloat = 24,
        @ViewBuilder visual: () -> Visual,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topCopyPadding)
                .padding(.horizontal, 18)

            visual()
                .frame(height: visualHeight)
                .frame(maxWidth: .infinity)
                .padding(.top, visualTopPadding)

            Spacer(minLength: 0)

            onboardingButton(title: buttonTitle, action: action)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Page 5: 锁屏小组件教程

    private func finalPage(width: CGFloat, height: CGFloat) -> some View {
        let box = previewBoxSize(width: width, height: height)

        return VStack(spacing: 0) {
            Text("最后\n请将速起小组件添加至锁屏")
                .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topCopyPadding)
                .padding(.horizontal, 18)
                .opacity(textOpacity)

            Spacer(minLength: 18)

            unifiedPreviewBox(width: width, height: height) { box in
                widgetTutorial(width: box.width - 20)
                    .padding(.horizontal, 10)
            }
            .frame(width: box.width, height: box.height)

            Spacer(minLength: 14)

            Text("明天一醒来\n不要滑手机，直接打开速起\n开启清爽的一天！")
                .font(AppTheme.localizedFont(size: 15, weight: .bold, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .padding(.bottom, 18)
                .opacity(textOpacity)

            onboardingButton(title: "好滴") {
                hasCompletedOnboarding = true
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func widgetTutorial(width: CGFloat) -> some View {
        let arrowWidth: CGFloat = 12
        let horizontalSpacing: CGFloat = 6
        let available = width - 20 - arrowWidth * 2 - horizontalSpacing * 4
        let phoneWidth = max(56, min(78, available / 3))
        let phoneHeight = phoneWidth * 1.78

        return HStack(alignment: .top, spacing: horizontalSpacing) {
            tutorialStep(number: 1, label: "长按锁屏", phoneWidth: phoneWidth, phoneHeight: phoneHeight) {
                lockScreenLongPress(width: phoneWidth, height: phoneHeight)
            }

            tutorialArrow()
                .frame(width: arrowWidth)
                .padding(.top, phoneHeight / 2 - 6)

            tutorialStep(number: 2, label: "点「自定义」", phoneWidth: phoneWidth, phoneHeight: phoneHeight) {
                lockScreenCustomize(width: phoneWidth, height: phoneHeight)
            }

            tutorialArrow()
                .frame(width: arrowWidth)
                .padding(.top, phoneHeight / 2 - 6)

            tutorialStep(number: 3, label: "添加速起", phoneWidth: phoneWidth, phoneHeight: phoneHeight) {
                lockScreenWithWidget(width: phoneWidth, height: phoneHeight)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tutorialStep<Mockup: View>(
        number: Int,
        label: String,
        phoneWidth: CGFloat,
        phoneHeight: CGFloat,
        @ViewBuilder mockup: () -> Mockup
    ) -> some View {
        VStack(spacing: 8) {
            mockup()
                .frame(width: phoneWidth, height: phoneHeight)

            HStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentOrange)
                        .frame(width: 14, height: 14)
                    Text("\(number)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                }
                Text(label)
                    .font(AppTheme.localizedFont(size: 11, weight: .bold, language: appLanguage))
                    .foregroundStyle(AppTheme.primaryDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private func tutorialArrow() -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(AppTheme.primaryDark.opacity(0.45))
    }

    private func phoneFrame<Inner: View>(
        width: CGFloat,
        height: CGFloat,
        background: Color,
        @ViewBuilder content: () -> Inner
    ) -> some View {
        let corner = width * 0.22

        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(background)
            content()
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(AppTheme.primaryDark, lineWidth: 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private func lockScreenLongPress(width: CGFloat, height: CGFloat) -> some View {
        phoneFrame(width: width, height: height, background: Color(hex: "1F2A44")) {
            ZStack {
                VStack(spacing: 1) {
                    Text("9:41")
                        .font(.system(size: width * 0.3, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                    Text("周一  5月17日")
                        .font(.system(size: width * 0.09, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .offset(y: -height * 0.18)

                ZStack {
                    Circle()
                        .stroke(AppTheme.sunYellow.opacity(0.85), lineWidth: 2)
                        .frame(width: width * 0.55, height: width * 0.55)
                    Circle()
                        .stroke(AppTheme.sunYellow.opacity(0.5), lineWidth: 2)
                        .frame(width: width * 0.78, height: width * 0.78)
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: width * 0.36, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-12))
                }
                .offset(y: height * 0.12)
            }
        }
    }

    private func lockScreenCustomize(width: CGFloat, height: CGFloat) -> some View {
        phoneFrame(width: width, height: height, background: Color(hex: "1F2A44").opacity(0.65)) {
            ZStack {
                VStack(spacing: 1) {
                    Text("9:41")
                        .font(.system(size: width * 0.28, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .offset(y: -height * 0.2)

                ZStack {
                    Capsule()
                        .fill(.white)
                    Text("自定义")
                        .font(.system(size: width * 0.13, weight: .heavy))
                        .foregroundStyle(AppTheme.primaryDark)
                }
                .frame(width: width * 0.62, height: height * 0.13)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.sunYellow, lineWidth: 2.5)
                )
                .offset(y: height * 0.16)
            }
        }
    }

    private func lockScreenWithWidget(width: CGFloat, height: CGFloat) -> some View {
        phoneFrame(width: width, height: height, background: Color(hex: "1F2A44")) {
            ZStack {
                miniWidgetCircle(size: width * 0.32)
                    .offset(y: -height * 0.32)

                VStack(spacing: 1) {
                    Text("9:41")
                        .font(.system(size: width * 0.3, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                    Text("周一  5月17日")
                        .font(.system(size: width * 0.09, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .offset(y: -height * 0.08)

                Circle()
                    .stroke(AppTheme.sunYellow, lineWidth: 2)
                    .frame(width: width * 0.42, height: width * 0.42)
                    .offset(y: -height * 0.32)
            }
        }
    }

    private func miniWidgetCircle(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.22))
            Image(systemName: "sun.max.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(AppTheme.sunYellow)
                .offset(y: -size * 0.06)
            Text("60s")
                .font(.system(size: size * 0.22, weight: .heavy))
                .foregroundStyle(.white)
                .offset(y: size * 0.24)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Pages 3 / 4：标题居顶 + 白天 / 夜晚原版面填满整张卡片

    /// 白天页：顶部 cream 标题区 + 下方场景撑满（按宽度等比缩放，溢出部分由卡片裁掉）
    private func fullSceneDayPage(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text("奖励会展示在白天桌面上")
                .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topCopyPadding)
                .padding(.bottom, 18)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F8F7F2"))
                .opacity(textOpacity)

            GeometryReader { geo in
                dayScene(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            onboardingButton(title: "好滴") {
                goNext()
            }
            .padding(.bottom, 30)
        }
    }

    private func fullSceneNightPage(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                nightScene(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            Text("夜晚\n在纸条上写下明天最期待的事\n激励自己起床吧！")
                .font(AppTheme.localizedFont(size: headlineSize, weight: headlineWeight, language: appLanguage))
                .foregroundStyle(AppTheme.primaryDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topCopyPadding)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .opacity(textOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            onboardingButton(title: "好滴") {
                goNext()
            }
            .padding(.bottom, 30)
        }
    }

    private func dayScene(width: CGFloat, height: CGFloat) -> some View {
        let sourceWidth: CGFloat = 362
        let sourceHeight: CGFloat = 582
        let scale = max(width / sourceWidth, height / sourceHeight)
        let renderedWidth = sourceWidth * scale
        let horizontalCrop = max(0, (renderedWidth - width) / 2)
        let sandwichSrc = CGRect(x: 94, y: 312, width: 250, height: 250)
        let nudge = CGSize(width: -24, height: -64 + 24)
        let sandwichCenter = CGPoint(
            x: sandwichSrc.midX * scale - horizontalCrop + nudge.width,
            y: sandwichSrc.midY * scale + nudge.height
        )

        return ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.96)

            Image("day")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height, alignment: .top)
                .offset(y: 24)
                .clipped()

            Image("sand1")
                .resizable()
                .scaledToFit()
                .frame(width: sandwichSrc.width * scale, height: sandwichSrc.height * scale)
                .scaleEffect(daySandwichScale)
                .opacity(daySandwichOpacity)
                .offset(y: daySandwichDropOffset)
                .position(x: sandwichCenter.x, y: sandwichCenter.y)
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private func nightScene(width: CGFloat, height: CGFloat) -> some View {
        let sourceWidth: CGFloat = 362
        let sourceHeight: CGFloat = 688
        let scale = max(width / sourceWidth, height / sourceHeight)
        let renderedWidth = sourceWidth * scale
        let horizontalCrop = max(0, (renderedWidth - width) / 2)
        let paperFrame = CGRect(x: 94, y: 414, width: 207, height: 127)
        let paperNudge = CGSize(width: 0, height: 0)
        let paperCenter = CGPoint(
            x: paperFrame.midX * scale - horizontalCrop + paperNudge.width,
            y: paperFrame.midY * scale + paperNudge.height
        )

        return ZStack {
            Color(red: 0.72, green: 0.72, blue: 0.78)

            Image("night")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height, alignment: .top)
                .clipped()

            Image("paper")
                .resizable()
                .scaledToFit()
                .frame(width: paperFrame.width * scale, height: paperFrame.height * scale)
                .scaleEffect(nightPaperScale)
                .opacity(nightPaperOpacity)
                .offset(y: nightPaperDropOffset)
                .position(x: paperCenter.x, y: paperCenter.y)
        }
        .frame(width: width, height: height)
        .clipped()
    }

    /// 白天版面：和 `DayRecapView` body 一致（去掉按钮/store 依赖）
    private var dayBaseContent: some View {
        VStack(spacing: 0) {
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
                            .frame(width: 85, height: 85)
                    }
                    .frame(width: 100, height: 100)
                    .offset(y: 63)
                    .padding(.leading, 30)
                    .padding(.top, 3)
                }
                .offset(x: 25, y: 0)

                Image("Group28")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .padding(.top, 36)
                    .offset(x: -38, y: 43)

                Spacer(minLength: 0)
            }
            .padding(.trailing, 16)

            ZStack(alignment: .bottom) {
                Image("Rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 414)
                    .offset(x: -10, y: 56)

                Image("sand1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .offset(y: -80)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// 夜晚版面：和 `NightRecapView` body 一致
    private var nightBaseContent: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 20) {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color(red: 0.25, green: 0.28, blue: 0.47))
                        .frame(width: 268, height: 249)
                        .offset(x: -100, y: 30)

                    Rectangle()
                        .fill(Color(red: 0.88, green: 0.87, blue: 0.82))
                        .frame(width: 268, height: 30)
                        .offset(x: -100, y: 250)

                    ZStack {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            let rayRotation = (t.truncatingRemainder(dividingBy: 14.0) / 14.0) * 360.0
                            ZStack {
                                ForEach(0..<18, id: \.self) { i in
                                    NightTriangleRay()
                                        .fill(Color(red: 1.0, green: 0.87, blue: 0.22))
                                        .frame(width: 10, height: 20)
                                        .offset(y: 0)
                                        .rotationEffect(.degrees(Double(i) * 20.0 + rayRotation))
                                }
                            }
                            .frame(width: 100, height: 100)
                        }
                        .frame(width: 100, height: 100)
                        .allowsHitTesting(false)

                        Circle()
                            .fill(Color(red: 0.95, green: 0.92, blue: 0.07))
                            .frame(width: 85, height: 85)
                    }
                    .frame(width: 100, height: 100)
                    .offset(y: 30)
                    .padding(.leading, 30)
                    .padding(.top, 36)
                }
                .offset(x: 25, y: 0)

                Image("Group28")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .padding(.top, 36)
                    .offset(x: -38, y: 43)

                Spacer(minLength: 0)
            }
            .padding(.trailing, 16)

            ZStack(alignment: .bottom) {
                Image("Rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 414)
                    .offset(x: -10, y: 56)

                Image("word")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 210, height: 210)
                    .offset(y: -62)
                    .offset(x: 48)

                Image("pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 92)
                    .offset(y: -106)
                    .offset(x: -98)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 通用按钮

    private func onboardingButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.localizedFont(size: 15, weight: .heavy, language: appLanguage))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 126, height: 52)
                .background(AppTheme.primaryDark)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Navigation

    private func goNext() {
        guard let index = Step.allCases.firstIndex(of: step),
              Step.allCases.indices.contains(index + 1)
        else {
            hasCompletedOnboarding = true
            return
        }

        let next = Step.allCases[index + 1]
        let isIntroSwap = step == .countdown && next == .reward
        if !isIntroSwap {
            textOpacity = 0
        }
        if next == .day {
            daySandwichDropOffset = -82
            daySandwichOpacity = 0
            daySandwichScale = 0.96
        }
        if next == .night {
            nightPaperDropOffset = -82
            nightPaperOpacity = 0
            nightPaperScale = 0.96
        }

        withAnimation(.easeInOut(duration: 0.34)) {
            step = next
        }
        if next == .day {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.68)) {
                    daySandwichDropOffset = 0
                    daySandwichOpacity = 1
                    daySandwichScale = 1
                }
            }
        }
        if next == .night {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.68)) {
                    nightPaperDropOffset = 0
                    nightPaperOpacity = 1
                    nightPaperScale = 1
                }
            }
        }
        if !isIntroSwap {
            withAnimation(.easeOut(duration: 0.48).delay(0.22)) {
                textOpacity = 1
            }
        }
    }
}

/// 夜间月亮的三角光芒（和 NightRecapView 内私有 TriangleRay 形状一致）
private struct NightTriangleRay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    OnboardingView()
}
