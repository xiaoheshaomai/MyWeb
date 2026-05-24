import SwiftUI

struct ContentView: View {
    /// 与 `RootView` 共用；开发者预览「新手引导」置为 false 后整 app 切到 `OnboardingView`
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var todayFlow: TodayFlow = .today
    @State private var challengeStartDate: Date?
    @State private var showReward = false
    /// 今日实际解锁的奖励 asset（与 `RewardCollectionStore` 保持一致），决定 RewardSuccessView 显示的图 / 标题 / 介绍
    @State private var earnedRewardAsset: String = "san1"
    /// 从挑战开始到「成功那次按下拍照按钮」的秒数，用于 DayRecap 展示（精确到分秒）
    @State private var lastWakeElapsedSeconds: Int = 0
    /// 用于按系统时间切换首页；每分钟刷新，跨越 5:00 / 13:00 / 18:00 时更新界面x
    @State private var clockNow = Date()

    /// 「起床挑战」时段的硬边界：
    /// - `challengeWindowStartHour`（含）：新的一天从这里起算；此前算夜间总结
    /// - `dailyGiveUpHour`（不含）：到点还没打开 app / 没完成挑战 = 今日自动放弃 → 走日间总结
    /// 两者不再依赖用户设置里的 wakeEnd，以免赖床过 wakeEnd 就直接被判进日间总结
    private let challengeWindowStartHour = 5
    private let dailyGiveUpHour = 13
    private let nightRecapStartHour = 18

    @EnvironmentObject private var deepLink: DeepLinkRouter
    /// 观察「今日是否已完成挑战」，用于避免起床窗口内被反复踢回 TodayView 触发重复自动倒计时
    @ObservedObject private var streakStore = StreakStore.shared
    /// 回到前台时用来把 tab/todayFlow 重新对齐到起床页
    @Environment(\.scenePhase) private var scenePhase

    enum TodayFlow {
        case today
        case napIntro
        case challenge
        case photo
        case reward
        case calendar
        case dayRecap
    }

    /// 当前挑战的"性质"。复用同一套 倒计时→拍照→奖励 视图，但奖励去向、连胜计入规则不同：
    /// - `.morning` 早起挑战：完成 → 解锁早餐 + markTodayNew + 进日历敲章 + 回 DayRecap
    /// - `.nap`     午睡挑战：完成 → 解锁咖啡（若今日 < 2）→ 奖励页 → 直接回 DayRecap（不记连胜、不进日历动画）
    enum ChallengeKind {
        case morning
        case nap
    }

    /// 每次进入 `.challenge` 前由调用方设置；读取发生在 `PhotoVerifyView.onVerified` 和 `RewardSuccessView.onDone`
    @State private var currentChallengeKind: ChallengeKind = .morning

    @State private var selectedTab = 0
    /// 设置页开发者预览用：`nil` 按当前时间；`true` 强制夜间总结；`false` 强制白天总结
    @State private var recapStyleOverride: Bool? = nil
    /// 开发者预览模式：临时绕过早起窗口路由，让 5:00–13:00 也能展示 Day/Night Recap
    /// 任何会让用户回到正常路由的动作（点 tab、进新挑战）都会重置回 false
    @State private var devForceRecap: Bool = false
    /// 开发者预览里启动的挑战进入「沙盒模式」：
    /// - 流程照走（倒计时/拍照/奖励页/日历页）
    /// - 但不写任何正式结果（不解锁奖励、不记连胜、不写分钟、不记放弃）
    /// 仅作用于“当前这次挑战”，流程结束后会自动复位为 false。
    @State private var previewSandboxActive: Bool = false
    /// 旧字段：弹窗已改成 fullScreenCover 原生盖满，无需再靠这个控制底部 tab
    /// 留一个 false 占位给 NightRecapView 的 Binding 参数（等下一版再清理 API）
    @State private var nightWishSheetCoversTabBar = false
    @State private var showSplashPreview = false
    @State private var showVerifyWaitingPreview = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                timeBasedTodayHome
                    .tag(0)

                CollectionView()
                    .tag(1)

                SettingsView(devActions: devPreviewActions)
                    .tag(2)
            }
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // 起床流程（倒计时 / 拍照 / 出奖励 / 日历）期间隐藏底部导航，避免分心
                if !isInWakeFlow {
                    MainTabBar(selection: $selectedTab, onReTapToday: exitDayRecapIfNeeded)
                }
            }
            .onAppear {
                clockNow = Date()
                seedRequestedWakeRecordIfNeeded()
                if let s = streakStore.elapsedSeconds(for: Date()) {
                    lastWakeElapsedSeconds = s
                }
                alignFlowWithClockIfNeeded()
                ensureMorningTabIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                // 回到前台：若当前为起床窗口且今天未完成，强制落到"今日"tab 并进起床页
                if phase == .active {
                    clockNow = Date()
                    seedRequestedWakeRecordIfNeeded()
                    if let s = streakStore.elapsedSeconds(for: Date()) {
                        lastWakeElapsedSeconds = s
                    }
                    ensureMorningTabIfNeeded()
                    alignFlowWithClockIfNeeded()
                }
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { date in
                clockNow = date
                alignFlowWithClockIfNeeded()
            }
            .onChange(of: deepLink.pending) { _, new in
                handleDeepLink(new)
            }

            // 起床流程：独立全屏覆盖层，完全盖住 TabView（含其底部 safe area）
            // 这样不会出现挑战/拍照/奖励/日历页底部残留"透明框"的问题
            if isInWakeFlow {
                wakeFlowOverlay
                    // 只忽略底部：盖住 Home Indicator 区域，避免流程页底部露缝。
                    // 顶部保留系统安全区，否则真机上文案/数字会顶到灵动岛下缘，和 Canvas #Preview 观感不一致。
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.opacity)
                    .zIndex(10)
            }

            if showSplashPreview {
                SandwichSplashView {
                    withAnimation(.easeOut(duration: 0.24)) {
                        showSplashPreview = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }

            if showVerifyWaitingPreview {
                PhotoVerifyWaitingPreviewView()
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onLongPressGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showVerifyWaitingPreview = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: todayFlow)
    }

    /// 起床流程全屏覆盖层（挑战 / 拍照 / 奖励 / 日历）
    @ViewBuilder
    private var wakeFlowOverlay: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            switch todayFlow {
            case .challenge:
                if let start = challengeStartDate {
                    // MARK: 倒计时页「放弃」——视觉在 `ChallengeView`（搜索「放弃按钮」）；这里只注入回调
                    ChallengeView(
                        challengeStartDate: start,
                        presentation: .morning,
                        onUp: { todayFlow = .photo },
                        onGiveUp: { giveUpCurrentChallenge() }
                    )
                }
            case .photo:
                PhotoVerifyView(
                    onVerified: { capturePressedAt in
                        var elapsedSeconds = 0
                        if let start = challengeStartDate {
                            // 新口径：用“成功那次按下拍照按钮的时刻”作为终点，而不是验证返回时刻
                            let end = capturePressedAt ?? Date()
                            let s = Int(end.timeIntervalSince(start).rounded())
                            elapsedSeconds = max(1, s)
                            lastWakeElapsedSeconds = elapsedSeconds
                        }

                        switch currentChallengeKind {
                        case .morning:
                            if previewSandboxActive {
                                // 预览沙盒：不写任何正式数据，仅展示一张可用奖励图
                                earnedRewardAsset = previewRewardAsset()
                            } else {
                                // 早起挑战：持久化秒级起床用时、从收藏池里决定今日早餐
                                StreakStore.shared.setElapsedSeconds(lastWakeElapsedSeconds, for: Date())
                                let picked = RewardCollectionStore.shared.unlockForTodayIfNeeded(elapsedSeconds: elapsedSeconds)
                                    ?? RewardCollectionStore.shared.unlocked.last
                                    ?? "san1"
                                earnedRewardAsset = picked
                            }

                        case .nap:
                            // 午睡挑战：不覆盖早晨 minutes、不动早餐池；只尝试解锁咖啡（上限 2 杯）
                            // 即便已达上限仍然展示一次咖啡奖励页作为心理激励——用户体感"我又赢了一次"
                            if !previewSandboxActive {
                                _ = StreakStore.shared.unlockCoffeeIfPossible()
                            }
                            earnedRewardAsset = RewardData.coffeePlaceholderAsset
                        }

                        showReward = true
                        todayFlow = .reward
                    },
                    onBack: {
                        // 拍照页底部返回：回到倒计时页继续挑战
                        todayFlow = .challenge
                    },
                    presentation: currentChallengeKind == .nap ? .nap : .morning
                )
            case .reward:
                RewardSuccessView(
                    rewardAsset: earnedRewardAsset,
                    onDone: {
                        switch currentChallengeKind {
                        case .morning:
                            if previewSandboxActive {
                                // 沙盒：不记连胜、不进真实敲章链，直接回日总结
                                todayFlow = .dayRecap
                                challengeStartDate = nil
                                showReward = false
                                previewSandboxActive = false
                            } else {
                                // 早起完成：写入连胜、进日历敲章动画
                                StreakStore.shared.markTodayNew()
                                todayFlow = .calendar
                            }
                        case .nap:
                            // 午睡完成：跳过日历动画，直接回 DayRecap（早起连胜不被午睡影响）
                            todayFlow = .dayRecap
                            challengeStartDate = nil
                            showReward = false
                            previewSandboxActive = false
                        }
                    }
                )
            case .calendar:
                CalendarMainView(onDone: {
                    // 起床流程结束：回到白天总结（或按系统时间呈现的首页）
                    todayFlow = .dayRecap
                    challengeStartDate = nil
                    showReward = false
                    previewSandboxActive = false
                })
            case .today, .napIntro, .dayRecap:
                EmptyView()
            }
        }
    }

    /// 若处于起床窗口且今天尚未完成且没放弃过，强制对齐到"今日"tab；
    /// 放弃过的情况下保留用户在 DayRecap 上的状态，不再把他拉回自动倒计时
    private func ensureMorningTabIfNeeded() {
        guard isMorningWakePeriod(at: clockNow),
              !hasCompletedToday,
              !isAbandonedToday else { return }
        if selectedTab != 0 {
            selectedTab = 0
        }
        if todayFlow == .dayRecap {
            todayFlow = .today
            challengeStartDate = nil
            showReward = false
        }
    }

    /// 是否处于「起床流程」——此时需要隐藏 MainTabBar
    private var isInWakeFlow: Bool {
        switch todayFlow {
        case .challenge:
            return currentChallengeKind == .morning
        case .photo, .reward, .calendar:
            return true
        case .today, .napIntro, .dayRecap:
            return false
        }
    }

    /// 设置页预览覆盖；`nil` 时按系统时间（18:00–次日 5:00 为夜间总结页）
    private var useNightRecapForDisplay: Bool {
        recapStyleOverride ?? shouldUseNightRecap(at: clockNow)
    }

    /// 首页路由：
    /// - 5:00–13:00 且今天还没完成 + 没放弃过：TodayView（进去即自动倒计时）
    /// - 5:00–13:00 但已完成 / 已主动放弃 / 到 13:00 仍没打开：DayRecap
    /// - 18:00–次日 5:00：NightRecap（夜间）
    @ViewBuilder
    private var timeBasedTodayHome: some View {
        if todayFlow == .napIntro {
            NapChallengeIntroView(
                onStartNow: { beginNapChallengeCountdown() },
                onDismiss: { dismissNapChallengeIntro() }
            )
        } else if todayFlow == .challenge,
                  currentChallengeKind == .nap,
                  let start = challengeStartDate {
            ChallengeView(
                challengeStartDate: start,
                presentation: .nap,
                onUp: { todayFlow = .photo },
                onGiveUp: { giveUpCurrentChallenge() }
            )
        } else if !devForceRecap && isMorningWakePeriod(at: clockNow) && !hasCompletedToday && !isAbandonedToday {
            TodayView(onStart: { startChallengeIfAllowed() })
        } else if useNightRecapForDisplay {
            NightRecapView(
                minutesUsed: max(1, Int(ceil(Double(lastWakeElapsedSeconds) / 60.0))),
                wishSheetCoversTabBar: $nightWishSheetCoversTabBar
            )
        } else {
            DayRecapView(
                elapsedSecondsUsed: lastWakeElapsedSeconds,
                onSunTap: { startNapChallenge() }
            )
        }
    }

    private func exitDayRecapIfNeeded() {
        guard todayFlow == .dayRecap || todayFlow == .napIntro else { return }
        // 顺手退出开发者强制预览：用户主动点"今日"tab = 想看真实路由
        devForceRecap = false
        recapStyleOverride = nil
        todayFlow = .today
        challengeStartDate = nil
        showReward = false
    }

    /// 夜间总结时段：18:00（含）至次日 5:00（不含）
    private func shouldUseNightRecap(at date: Date) -> Bool {
        let total = Self.minutesSinceMidnight(date)
        return total >= nightRecapStartHour * 60 || total < challengeWindowStartHour * 60
    }

    /// 起床挑战窗口：5:00（含）至 13:00（不含）
    /// 在这个区间内首次打开 app 就触发倒计时，不再依赖用户的 `wakeEnd` 闹钟
    private func isMorningWakePeriod(at date: Date) -> Bool {
        let total = Self.minutesSinceMidnight(date)
        return total >= challengeWindowStartHour * 60 && total < dailyGiveUpHour * 60
    }

    /// 若仍停留在 `.dayRecap` 而当前应显示起床页，则与 `.today` 对齐（两者首页已合并为按时间切换）
    /// 今天已完成 / 已放弃时不再对齐，避免 dayRecap 被反复切回 today 触发自动倒计时
    private func alignFlowWithClockIfNeeded() {
        guard todayFlow == .dayRecap,
              isMorningWakePeriod(at: clockNow),
              !hasCompletedToday,
              !isAbandonedToday else { return }
        todayFlow = .today
        challengeStartDate = nil
        showReward = false
    }

    /// 今天是否已完成挑战（奖励页完成时 `markTodayNew()` 会写入 StreakStore）
    private var hasCompletedToday: Bool {
        streakStore.isCompleted(Date())
    }

    /// 今天是否已主动放弃早起挑战（倒计时页点了放弃并确认）
    /// 只影响路由，不记连胜、不影响午睡挑战
    private var isAbandonedToday: Bool {
        streakStore.isAbandoned(Date())
    }

    private static func minutesSinceMidnight(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    // MARK: - Challenge entry & deep link

    /// 进入 TodayView 时自动触发，或深链说「去挑战」时调用
    /// 新机制：只要当天 5:00–13:00 首次打开、且没完成、也没放弃，就开倒计时
    private func startChallengeIfAllowed() {
        guard isMorningWakePeriod(at: clockNow) else { return }
        guard !hasCompletedToday else { return }              // 今天已经完成过了 → 不再重复开挑战
        guard !isAbandonedToday else { return }               // 今天已主动放弃 → 不再打回倒计时
        previewSandboxActive = false                          // 正常入口：写正式结果
        currentChallengeKind = .morning
        challengeStartDate = Date()
        todayFlow = .challenge
    }

    /// 午睡挑战入口：由 DayRecapView 的太阳按钮触发
    /// 不受"早起是否完成""当前是否在早起窗口内"限制——用户任何时候点太阳都能跑一次午睡倒计时
    /// 是否解锁咖啡由 `PhotoVerifyView.onVerified` 分支里 `StreakStore.unlockCoffeeIfPossible()` 决定（上限 2/天）
    private func startNapChallenge() {
        previewSandboxActive = false                          // 正常入口：写正式结果
        currentChallengeKind = .nap
        challengeStartDate = nil
        todayFlow = .napIntro
    }

    private func beginNapChallengeCountdown() {
        currentChallengeKind = .nap
        challengeStartDate = Date()
        todayFlow = .challenge
    }

    private func dismissNapChallengeIntro() {
        challengeStartDate = nil
        todayFlow = .dayRecap
    }

    /// 手动补录这次要求的数据：2026-05-04 08:26 起床，用时 12 秒。
    /// 只在当天、只写一次，避免以后新安装时凭空出现假记录。
    private func seedRequestedWakeRecordIfNeeded() {
        let seedKey = "manualSeed.wakeRecord.2026-05-04.0826.v1"
        let def = UserDefaults.standard
        guard !def.bool(forKey: seedKey) else { return }

        let calendar = Calendar.current
        let nowParts = calendar.dateComponents([.year, .month, .day], from: clockNow)
        guard nowParts.year == 2026, nowParts.month == 5, nowParts.day == 4 else { return }

        var parts = DateComponents()
        parts.year = 2026
        parts.month = 5
        parts.day = 4
        parts.hour = 8
        parts.minute = 26
        parts.second = 0
        guard let wakeDate = calendar.date(from: parts) else { return }

        StreakStore.shared.upsertMorningRecord(date: wakeDate, elapsedSeconds: 12)
        _ = RewardCollectionStore.shared.upsertMorningReward(on: wakeDate, elapsedSeconds: 12)
        lastWakeElapsedSeconds = 12
        def.set(true, forKey: seedKey)
    }

    // MARK: - 放弃挑战（倒计时页按钮点确认后 · 路由 / 持久化）

    /// 倒计时页点「放弃」→ 二次确认通过后调用
    /// - morning：写入 abandoned 集合，保证剩下的早起窗口里不再自动把用户踢回 TodayView
    /// - nap：直接回 DayRecap，不持久化（午睡本来就是用户手动点太阳才进，不怕被路由拉回）
    private func giveUpCurrentChallenge() {
        switch currentChallengeKind {
        case .morning:
            if !previewSandboxActive {
                StreakStore.shared.markAbandoned(for: Date())
            }
        case .nap:
            break
        }
        challengeStartDate = nil
        showReward = false
        todayFlow = .dayRecap
        previewSandboxActive = false
    }

    private func handleDeepLink(_ intent: DeepLinkRouter.Intent?) {
        guard let intent = intent else { return }
        switch intent {
        case .startChallenge:
            // 已经在挑战链里就别打断
            if todayFlow == .today || todayFlow == .dayRecap {
                startChallengeIfAllowed()
            }
        case .today:
            selectedTab = 0
        }
        deepLink.pending = nil
    }

    /// 预览奖励页时用哪张早餐：优先显示用户已经解锁的最近一张；从未解锁过就给一个默认
    private func previewRewardAsset() -> String {
        RewardCollectionStore.shared.unlocked.last ?? "san1"
    }

    // MARK: - 开发者预览面板

    /// 收集所有"跳到指定界面"的动作，传给 SettingsView 的开发者 section
    /// 每个动作都会先把 tab 切回 today，再设置必要的 state。`devForceRecap` 用于绕开
    /// 早起窗口路由，让你在 5:00–13:00 也能查看 Day/Night Recap
    private var devPreviewActions: DevPreviewActions {
        DevPreviewActions(
            morningChallenge: {
                // 先进入挑战流程再切 tab，避免「今日」里 TodayView 的 onAppear 与预览入口抢同一帧状态
                devForceRecap = false
                previewSandboxActive = true                    // 预览入口：不污染真实数据
                currentChallengeKind = .morning
                challengeStartDate = Date()
                todayFlow = .challenge
                selectedTab = 0
            },
            napChallenge: {
                devForceRecap = false
                previewSandboxActive = true                    // 预览入口：不污染真实数据
                currentChallengeKind = .nap
                challengeStartDate = nil
                todayFlow = .napIntro
                selectedTab = 0
            },
            dayRecap: {
                selectedTab = 0
                lastWakeElapsedSeconds = 45
                recapStyleOverride = false
                devForceRecap = true
                todayFlow = .dayRecap
                challengeStartDate = nil
                showReward = false
            },
            nightRecap: {
                selectedTab = 0
                lastWakeElapsedSeconds = 45
                recapStyleOverride = true
                devForceRecap = true
                todayFlow = .dayRecap
                challengeStartDate = nil
                showReward = false
            },
            calendar: {
                selectedTab = 0
                devForceRecap = false
                todayFlow = .calendar
            },
            splash: {
                showSplashPreview = false
                DispatchQueue.main.async {
                    showSplashPreview = true
                }
            },
            verifyWaiting: {
                showVerifyWaitingPreview = false
                DispatchQueue.main.async {
                    showVerifyWaitingPreview = true
                }
            },
            resetForceRecap: {
                devForceRecap = false
                recapStyleOverride = nil
                previewSandboxActive = false
            },
            restartOnboarding: {
                // 关掉起床流程覆盖层，避免状态残留在 UserDefaults 之外
                todayFlow = .today
                challengeStartDate = nil
                showReward = false
                previewSandboxActive = false
                hasCompletedOnboarding = false
            }
        )
    }
}

// MARK: - DevPreviewActions
/// 开发者预览面板用的动作集合；放在文件外层方便 SettingsView 直接使用
/// 不在 release 里隐藏（用户不开 settings/不点这一栏就感知不到），需要时改成 `#if DEBUG`
struct DevPreviewActions {
    /// 进入早起倒计时（kind = morning，60s）
    var morningChallenge: () -> Void
    /// 进入午睡倒计时（kind = nap，奖励是咖啡）
    var napChallenge: () -> Void
    /// 强制显示白天总结页（绕过早起窗口路由）
    var dayRecap: () -> Void
    /// 强制显示夜间总结页（绕过早起窗口路由）
    var nightRecap: () -> Void
    /// 进入日历敲章动画页（早起完成后那张）
    var calendar: () -> Void
    /// 播放启动开屏三明治动效
    var splash: () -> Void
    /// 全屏预览验证等待页
    var verifyWaiting: () -> Void
    /// 重置强制总结模式 → 回到按时间的正常路由
    var resetForceRecap: () -> Void
    /// 重新走「首次打开」新手引导（`RootView` 切到 `OnboardingView`，当前主界面会消失）
    var restartOnboarding: () -> Void
}

#Preview {
    ContentView()
}

private struct NapChallengeIntroView: View {
    var onStartNow: () -> Void
    var onDismiss: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "zh"

    private let cardWidth: CGFloat = 238
    private let cardHeight: CGFloat = 344
    private let headerHeight: CGFloat = 56

    var body: some View {
        GeometryReader { geo in
            let width = min(cardWidth, max(210, geo.size.width - 136))
            let bodyHeight = cardHeight - headerHeight - 8

            ZStack {
                Color(hex: "E9E8E4")
                    .ignoresSafeArea(edges: [.top, .leading, .trailing])

                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(AppTheme.sunYellow)
                        .frame(width: width, height: cardHeight)

                    VStack(spacing: 0) {
                        Text(L10n.s("day_recap_sun_tooltip", lang: appLanguage))
                            .font(AppTheme.localizedFont(size: 17, weight: .bold, language: appLanguage))
                            .foregroundStyle(.black)
                            .frame(width: width, height: headerHeight)

                        VStack(spacing: 0) {
                            Spacer(minLength: 0)

                            Text(L10n.s("nap_intro_body", lang: appLanguage))
                                .font(AppTheme.localizedFont(size: 14, weight: .bold, language: appLanguage))
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)

                            Spacer(minLength: 0)

                            HStack(spacing: 10) {
                                Button {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    onStartNow()
                                } label: {
                                    Text(L10n.s("nap_intro_start", lang: appLanguage))
                                        .font(AppTheme.localizedFont(size: 13, weight: .bold, language: appLanguage))
                                        .foregroundStyle(.white)
                                        .frame(width: 96, height: 44)
                                        .background(Capsule().fill(Color.black))
                                }
                                .buttonStyle(ScaleButtonStyle())

                                Button {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    onDismiss()
                                } label: {
                                    Text(L10n.s("nap_intro_later", lang: appLanguage))
                                        .font(AppTheme.localizedFont(size: 13, weight: .bold, language: appLanguage))
                                        .foregroundStyle(.black)
                                        .frame(width: 74, height: 44)
                                        .background(Capsule().fill(AppTheme.sunYellow))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.bottom, 34)
                        }
                        .frame(width: width - 14, height: bodyHeight)
                        .background(Color.white)
                    }
                }
                .frame(width: width, height: cardHeight)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
