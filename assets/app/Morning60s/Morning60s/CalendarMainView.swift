import SwiftUI

// MARK: - Streak Store（持久化已完成日期 + 每日实际用时 + 每日咖啡次数）
class StreakStore: ObservableObject {
    static let shared = StreakStore()
    private let key = "completedDates"
    /// 每日实际用时（历史为“分钟”，现升级为“秒”）：key = "yyyy-MM-dd"，value = 秒
    private let minutesKey = "minutesByDate"
    /// 每日咖啡解锁次数：key = "yyyy-MM-dd"，value = 0–2
    /// 午睡挑战完成时 +1；第 3 次点太阳挑战成功不再加（上限 2）
    private let coffeeKey = "coffeeCountByDate"
    /// 每日咖啡次数上限（午睡挑战）
    static let dailyCoffeeLimit = 2
    /// 早起挑战"今天主动放弃"的日期集合；存在于集合 ⇒ 即使还在 5:00–13:00 窗口内，
    /// 也不再把用户自动踢回 TodayView / 自动开倒计时。次日（跨日 5:00 后）自然过期。
    private let abandonedKey = "abandonedDates"
    /// minutesByDate 的数据版本：v1=旧「分钟」；v2=秒（v1→v2 曾误把已是秒的整数再×60）；v3=用收藏元数据纠偏
    private let elapsedSchemaVersionKey = "minutesByDateSchemaVersion"

    @Published private(set) var completedDates: Set<String> = []
    /// 每日实际用时（秒），按日期字符串存；写入后 DayRecap / NightRecap 直接读
    @Published private(set) var minutesByDate: [String: Int] = [:]
    /// 每日咖啡解锁次数，按日期字符串存；0 代表今天还没做过午睡挑战
    @Published private(set) var coffeeCountByDate: [String: Int] = [:]
    /// 早起挑战已主动放弃的日期；该日不再自动触发倒计时，直接进入 DayRecap
    @Published private(set) var abandonedDates: Set<String> = []

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        completedDates = Set(saved)
        var savedElapsed = UserDefaults.standard.dictionary(forKey: minutesKey) as? [String: Int] ?? [:]
        migrateElapsedStorageIfNeeded(&savedElapsed)
        minutesByDate = savedElapsed
        let savedCoffee = UserDefaults.standard.dictionary(forKey: coffeeKey) as? [String: Int] ?? [:]
        coffeeCountByDate = savedCoffee
        let savedAbandoned = UserDefaults.standard.stringArray(forKey: abandonedKey) ?? []
        abandonedDates = Set(savedAbandoned)
    }

    func markToday() {
        let today = formatter.string(from: Date())
        guard !completedDates.contains(today) else { return }
        completedDates.insert(today)
        UserDefaults.standard.set(Array(completedDates), forKey: key)
    }

    func isCompleted(_ date: Date) -> Bool {
        completedDates.contains(formatter.string(from: date))
    }

    /// 奖励页完成后调用，标记今天刚完成（用于触发敲章动画）
    func markTodayNew() {
        markToday()
        let today = formatter.string(from: Date())
        UserDefaults.standard.set(true, forKey: "newlyCompleted_\(today)")
    }

    /// 检查并消费「刚完成」标记，只触发一次动画
    func popNewlyCompleted() -> Bool {
        let today = formatter.string(from: Date())
        let flag = UserDefaults.standard.bool(forKey: "newlyCompleted_\(today)")
        if flag {
            UserDefaults.standard.removeObject(forKey: "newlyCompleted_\(today)")
        }
        return flag
    }

    /// 记录某一天的实际起床用时（秒）。由 `PhotoVerifyView.onVerified` 在验证通过那刻写入。
    /// 约束在 1–3599 秒（最多约 59 分 59 秒），避免异常值挤坏 UI。
    func setElapsedSeconds(_ seconds: Int, for date: Date = Date()) {
        let clamped = min(3599, max(1, seconds))
        let key = formatter.string(from: date)
        minutesByDate[key] = clamped
        UserDefaults.standard.set(minutesByDate, forKey: minutesKey)
    }

    /// 手动补录一条早起记录：既标记当天完成，也写入秒级用时。
    /// 用于修复/补录数据，走和正式挑战结果相同的持久化结构。
    func upsertMorningRecord(date: Date, elapsedSeconds: Int) {
        let day = formatter.string(from: date)
        let clamped = min(3599, max(1, elapsedSeconds))
        completedDates.insert(day)
        minutesByDate[day] = clamped
        abandonedDates.remove(day)

        let def = UserDefaults.standard
        def.set(Array(completedDates), forKey: key)
        def.set(minutesByDate, forKey: minutesKey)
        def.set(Array(abandonedDates), forKey: abandonedKey)
        def.set(3, forKey: elapsedSchemaVersionKey)
    }

    /// 查询某一天的实际起床用时（秒）；没记录过返回 nil
    func elapsedSeconds(for date: Date) -> Int? {
        minutesByDate[formatter.string(from: date)]
    }

    /// 向后兼容：旧调用仍按“分钟”接口拿值时，返回向上取整分钟
    func minutes(for date: Date) -> Int? {
        guard let sec = elapsedSeconds(for: date) else { return nil }
        return max(1, Int(ceil(Double(sec) / 60.0)))
    }

    /// 向后兼容：旧调用写“分钟”时自动转为秒
    func setMinutes(_ minutes: Int, for date: Date = Date()) {
        setElapsedSeconds(minutes * 60, for: date)
    }

    /// v1→v2：旧字典里存的是「分钟」整数，乘 60 变成秒。
    /// v2→v3：v2 曾把**已是秒**的小值（如 6）误当作分钟再乘 60（→360），与收藏页 `RewardMeta.elapsedSeconds` 不一致；用收藏元数据按日纠偏。
    private func migrateElapsedStorageIfNeeded(_ dict: inout [String: Int]) {
        let def = UserDefaults.standard
        var schema = def.integer(forKey: elapsedSchemaVersionKey)

        if schema < 2 {
            var migrated: [String: Int] = [:]
            for (k, v) in dict {
                let minutes = max(1, v)
                migrated[k] = min(3599, minutes * 60)
            }
            dict = migrated
            def.set(dict, forKey: minutesKey)
            schema = 2
            def.set(schema, forKey: elapsedSchemaVersionKey)
        }

        if schema < 3 {
            healMisMigratedSecondsUsingRewardMetas(&dict)
            def.set(dict, forKey: minutesKey)
            schema = 3
            def.set(schema, forKey: elapsedSchemaVersionKey)
        }
    }

    /// 与 `RewardCollectionStore` 的日键一致，便于和 `RewardMeta.date` 对齐
    private static func dayKeyGregorianPOSIX(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// 仅当 `minutesByDate[日] == RewardMeta.elapsedSeconds * 60` 且二者不等时，判定为误迁移并写回真实秒数
    private func healMisMigratedSecondsUsingRewardMetas(_ dict: inout [String: Int]) {
        let metasKey = "rewardCollection.metas.v1"
        guard let data = UserDefaults.standard.data(forKey: metasKey),
              let metas = try? JSONDecoder().decode([String: RewardMeta].self, from: data)
        else { return }

        for (_, meta) in metas {
            guard meta.elapsedSeconds > 0 else { continue }
            let m = meta.elapsedSeconds
            let keys = Set([Self.dayKeyGregorianPOSIX(for: meta.date), formatter.string(from: meta.date)])
            for day in keys {
                guard let stored = dict[day] else { continue }
                if stored == m * 60, stored != m {
                    dict[day] = min(3599, max(1, m))
                }
            }
        }
    }

    // MARK: - 咖啡 / 午睡挑战

    /// 查询某一天的咖啡解锁次数（0–2）
    func coffeeCount(for date: Date = Date()) -> Int {
        coffeeCountByDate[formatter.string(from: date)] ?? 0
    }

    /// 午睡挑战是否还能再领咖啡（今天 < 上限）
    func canUnlockCoffee(today: Date = Date()) -> Bool {
        coffeeCount(for: today) < Self.dailyCoffeeLimit
    }

    /// 午睡挑战完成时调用；超过上限返回 false（调用方负责展示"今日咖啡已满"类文案）
    @discardableResult
    func unlockCoffeeIfPossible(for date: Date = Date()) -> Bool {
        let key = formatter.string(from: date)
        let current = coffeeCountByDate[key] ?? 0
        guard current < Self.dailyCoffeeLimit else { return false }
        coffeeCountByDate[key] = current + 1
        UserDefaults.standard.set(coffeeCountByDate, forKey: coffeeKey)
        return true
    }

    // MARK: - 早起放弃

    /// 把「今天」标记为已主动放弃早起挑战（点倒计时里的"放弃"按钮后调用）
    /// 注意：这只用于路由判断——不写 completedDates，不算连胜，不解锁早餐
    func markAbandoned(for date: Date = Date()) {
        let key = formatter.string(from: date)
        guard !abandonedDates.contains(key) else { return }
        abandonedDates.insert(key)
        UserDefaults.standard.set(Array(abandonedDates), forKey: abandonedKey)
    }

    /// 某一天是否已被标记为「主动放弃」。午睡放弃不走这里，午睡就是用户自己点太阳的，
    /// 不点就不进挑战，天然不需要 abandoned 保护
    func isAbandoned(_ date: Date) -> Bool {
        abandonedDates.contains(formatter.string(from: date))
    }
}

// MARK: - Calendar Main View
struct CalendarMainView: View {
    /// 可选返回回调：外部传入时，底部显示一个「完成」按钮，用于在起床流程里回到 DayRecapView
    var onDone: (() -> Void)? = nil

    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""
    @State private var currentDate = Date()
    @StateObject private var store = StreakStore.shared

    @State private var titleVisible = false
    @State private var cardVisible = false
    @State private var stampToday = false
    /// 刚从奖励页进来、等待敲章动画前，今日格子先不显示静态印章
    @State private var stampEntrancePending = false

    private var streakDays: Int {
        var count = 0
        var checking = Calendar.current.startOfDay(for: Date())
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        while store.completedDates.contains(f.string(from: checking)) {
            count += 1
            checking = Calendar.current.date(byAdding: .day, value: -1, to: checking)!
        }
        return count
    }

    private var displayName: String {
        let n = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return L10n.s("onboarding_name_placeholder", lang: appLanguage) }
        return n
    }

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    if streakDays == 0 {
                        // 连续速起 0 天（例如开发者预览直进日历、或数据尚未含今日等边界）
                        Text(String(format: L10n.s("calendar_streak_encourage_fmt", lang: appLanguage), displayName))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    } else {
                        Text("好棒")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 1, green: 0, blue: 0))

                        HStack(spacing: 4) {
                            Text("已连续速起")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                            Text("\(streakDays)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 1, green: 0, blue: 0))
                            Text("天啦！")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.top, 70)
                .padding(.bottom, 50)
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : -16)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: titleVisible)

                CalendarCard(
                    date: currentDate,
                    animate: cardVisible,
                    stampToday: $stampToday,
                    stampEntrancePending: stampEntrancePending
                )
                    .padding(.horizontal, 20)
                    .opacity(cardVisible ? 1 : 0)
                    .offset(y: cardVisible ? 0 : 60)
                    .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.25), value: cardVisible)

                Spacer()

                if let onDone = onDone {
                    Button(action: onDone) {
                        Text("完成")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 54)
                            .background(Color.black)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 36)
                    .opacity(cardVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.6), value: cardVisible)
                }
            }
            .padding(.bottom, onDone == nil ? 90 : 0)
        }
        .onAppear {
            // 须在奖励页 `markTodayNew()` 之后才会为 true（只消费一次）
            let willPlayStamp = store.popNewlyCompleted()
            stampEntrancePending = willPlayStamp

            titleVisible = true
            cardVisible = true

            if willPlayStamp {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    stampToday = true
                }
            }
        }
        .onChange(of: stampToday) { _, new in
            if new { stampEntrancePending = false }
        }
    }
}

// MARK: - Calendar Card（整页与 Recap 弹层共用）
struct CalendarCard: View {
    let date: Date
    let animate: Bool
    @Binding var stampToday: Bool
    let stampEntrancePending: Bool

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月"
        return f.string(from: date)
    }

    private var daysInMonth: [CalendarDay] { generateDays(for: date) }

    var body: some View {
        VStack(spacing: 0) {
            Text(monthTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(Color(red: 1, green: 0, blue: 0))
                .offset(y: animate ? 0 : -40)
                .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.35), value: animate)

            VStack(spacing: 0) {
                WeekdayHeader()
                    .padding(.top, 25)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 25)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.45), value: animate)

                DayGrid(
                    days: daysInMonth,
                    animate: animate,
                    stampToday: $stampToday,
                    stampEntrancePending: stampEntrancePending
                )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .background(Color(hex: "F9F8F4"))
        }
        .cornerRadius(0)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 1, green: 0, blue: 0), lineWidth: 20)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .clipped()
    }

    private func generateDays(for date: Date) -> [CalendarDay] {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        let today = calendar.startOfDay(for: Date())
        let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7

        var days: [CalendarDay] = []

        if firstWeekday > 0 {
            guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
                  let prevRange = calendar.range(of: .day, in: .month, for: prevMonth) else { return [] }
            let prevCount = prevRange.count
            for i in stride(from: firstWeekday - 1, through: 0, by: -1) {
                days.append(CalendarDay(day: prevCount - i, isCurrentMonth: false, isToday: false, actualDate: nil))
            }
        }

        for day in 1...range.count {
            var comps = components
            comps.day = day
            let dayDate = calendar.date(from: comps) ?? date
            let isToday = calendar.isDate(dayDate, inSameDayAs: today)
            days.append(CalendarDay(day: day, isCurrentMonth: true, isToday: isToday, actualDate: dayDate))
        }

        let remaining = (7 - (days.count % 7)) % 7
        for day in 1...max(1, remaining) {
            days.append(CalendarDay(day: day, isCurrentMonth: false, isToday: false, actualDate: nil))
        }
        if remaining == 0 { days.removeLast() }

        return days
    }
}

// MARK: - Weekday Header
private struct WeekdayHeader: View {
    private let weekdays = ["一", "二", "三", "四", "五", "六", "七"]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Day Grid
private struct DayGrid: View {
    let days: [CalendarDay]
    let animate: Bool
    @Binding var stampToday: Bool
    let stampEntrancePending: Bool
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                DayCell(
                    day: day,
                    triggerStamp: day.isToday ? $stampToday : .constant(false),
                    stampEntrancePending: stampEntrancePending
                )
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1 : 0.7)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(0.5 + Double(index / 7) * 0.01 + Double(index % 7) * 0.01),
                    value: animate
                )
            }
        }
    }
}

// MARK: - Day Cell
private struct DayCell: View {
    let day: CalendarDay
    @Binding var triggerStamp: Bool
    let stampEntrancePending: Bool
    @ObservedObject private var store = StreakStore.shared

    @State private var stampScale: CGFloat = 1
    @State private var stampOpacity: Double = 0
    @State private var stampRotation: Double = -8

    private var isCompleted: Bool {
        guard let d = day.actualDate else { return false }
        return store.isCompleted(d)
    }

    /// 今日已完成但还在等「敲章」触发，避免先闪一帧静态章
    private var waitingForStampAnimation: Bool {
        day.isToday && isCompleted && stampEntrancePending && !triggerStamp
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 底色格子
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(hex: "D9D9D9"))
                .frame(height: 52)

            // 日期数字
            Text("\(day.day)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .semibold))
                .foregroundColor(day.isCurrentMonth ? .black : Color.gray.opacity(0.5))
                .padding(5)

            // 图章（覆盖在格子上）
            if isCompleted {
                Image("stamp1")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .opacity(stampOpacity)
                    .scaleEffect(stampScale)
                    .rotationEffect(.degrees(stampRotation))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        if triggerStamp {
                            playStampAnimation()
                        } else if waitingForStampAnimation {
                            stampOpacity = 0
                            stampScale = 1.0
                            stampRotation = -8
                        } else {
                            stampOpacity = 0.82
                            stampScale = 1.0
                            stampRotation = -8
                        }
                    }
            }
        }
        .onChange(of: triggerStamp) { _, fired in
            if fired && isCompleted {
                playStampAnimation()
            }
        }
        .onChange(of: waitingForStampAnimation) { _, waiting in
            if waiting {
                stampOpacity = 0
            }
        }
    }

    /// 敲章动画：从高处砸下来 + 弹跳
    private func playStampAnimation() {
        stampOpacity = 0
        stampScale = 2.0
        stampRotation = -25

        // 快速落下
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
            stampScale = 0.8
            stampOpacity = 1.0
            stampRotation = -5
        }
        // 弹回稳定
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.65)) {
                stampScale = 1.0
                stampOpacity = 0.82
                stampRotation = -8
            }
            triggerStamp = false
        }
    }
}

// MARK: - Recap 弹层（仅卡片，无整页底色；左右边距由 `RecapCalendarPopupLayer` 控制）
struct RecapCalendarCardView: View {
    @State private var currentDate = Date()
    @State private var animateCard = true
    @State private var stampToday = false

    var body: some View {
        CalendarCard(
            date: currentDate,
            animate: animateCard,
            stampToday: $stampToday,
            stampEntrancePending: false
        )
    }
}

/// 半透明压暗背景 + 左右各 20pt 边距的日历弹层（点背景关闭）
struct RecapCalendarPopupLayer: View {
    @Binding var isPresented: Bool
    @State private var contentPresented = false

    private let horizontalInset: CGFloat = 40
    /// 灰色压暗（黑 + 透明度，视觉上偏灰蒙层）
    private let dimColor = Color.black.opacity(0.45)

    var body: some View {
        ZStack {
            dimColor
                .opacity(contentPresented ? 1 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            RecapCalendarCardView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalInset)
                .scaleEffect(contentPresented ? 1 : 0.86)
                .offset(y: contentPresented ? 0 : 26)
                .opacity(contentPresented ? 1 : 0)
        }
        .onAppear {
            contentPresented = false
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                contentPresented = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.18)) {
            contentPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            isPresented = false
        }
    }
}

// MARK: - Data Model
private struct CalendarDay {
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let actualDate: Date?
}

// MARK: - Preview（模拟今日完成）
#Preview {
    StreakStore.shared.markTodayNew()
    return CalendarMainView()
}
