import SwiftUI

private enum CollectionArchiveSection {
    case breakfast
    case wakeData
}

private enum CollectionArchivePeriod: Hashable {
    case week
    case month
}

private struct WakeStatPoint {
    let date: Date
    let elapsedSeconds: Int
    let wakeMinuteOfDay: Int
    let rewardAsset: String?
}

private struct CollectionChartPoint: Identifiable {
    let id: String
    let label: String
    let value: Double?
    let date: Date
    let elapsedSeconds: Int?
    let wakeMinuteOfDay: Int?
    let rewardAsset: String?
    let isCenteredWeekStart: Bool
}

private struct CollectionPositionedChartPoint: Identifiable {
    let point: CollectionChartPoint
    let position: CGPoint

    var id: String { point.id }
}

private let collectionHardShadow = Color(hex: "D2D2D2")

/// 收藏页：顶部红色横幅 + 可滚动货架；货架按完整奖励容量铺满，
/// 但早餐只展示**已解锁**的收集（按解锁顺序）。
struct CollectionView: View {
    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("userNickname") private var userNickname = ""
    @AppStorage("wakeStart") private var wakeStart = "05:00"
    @AppStorage("wakeEnd") private var wakeEnd = "08:00"
    @State private var showRewardDetail = false
    @State private var cardPresented = false
    @State private var selectedSection: CollectionArchiveSection = .breakfast
    @State private var wakeTimePeriod: CollectionArchivePeriod = .week
    @State private var elapsedPeriod: CollectionArchivePeriod = .week
    @State private var showEmptyPlateToast = false
    /// 用户点开的那个 asset（可能是 "san3" / "cake5" / …）；nil = 没有选中任何格子
    @State private var selectedRewardAsset: String? = nil
    @ObservedObject private var store = RewardCollectionStore.shared
    @ObservedObject private var streakStore = StreakStore.shared

    /// 货架上只展示**已解锁**的收集（按解锁顺序）；未解锁的奖励不出现在货架上
    private var unlockedSlots: [String] { store.unlocked }

    private let shelfColumnCount = 3

    /// 货架行数按总奖励容量生成；若调试数据里已解锁数超过总池，也保证都能显示出来。
    private var shelfRowCount: Int {
        let slotCount = max(RewardData.totalCount, unlockedSlots.count)
        return max(1, Int(ceil(Double(slotCount) / Double(shelfColumnCount))))
    }

    private var displayName: String {
        let n = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return L10n.s("onboarding_name_placeholder", lang: appLanguage) }
        return n
    }

    private var titleText: String {
        String(format: L10n.s("collection_title_personal_fmt", lang: appLanguage), displayName)
    }

    /// 取出当前点开的奖励对应的获得元信息（日期 / 用时）
    private var metaForSelected: RewardMeta? {
        guard let name = selectedRewardAsset else { return nil }
        return store.meta(for: name)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                archiveSegment
                    .zIndex(2)

                switch selectedSection {
                case .breakfast:
                    breakfastShelfContent
                        .zIndex(0)
                case .wakeData:
                    wakeDataContent
                        .zIndex(0)
                }
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
    }

    // MARK: - 顶部红条

    private var header: some View {
        Text(titleText)
            .font(AppTheme.localizedFont(size: 20, weight: .bold, language: appLanguage))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(AppTheme.accentOrange)
    }

    private var archiveSegment: some View {
        HStack(spacing: 0) {
            archiveSegmentButton(
                title: L10n.s("collection_breakfast_tab", lang: appLanguage),
                section: .breakfast
            )
            archiveSegmentButton(
                title: L10n.s("collection_wake_data_tab", lang: appLanguage),
                section: .wakeData
            )
        }
        .frame(height: 58)
        .background(Color(hex: "F9F8F4"))
        .background(alignment: .bottomTrailing) {
            Rectangle()
                .fill(collectionHardShadow)
                .offset(x: 4, y: 4)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
    }

    private func archiveSegmentButton(title: String, section: CollectionArchiveSection) -> some View {
        let selected = selectedSection == section
        return Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                selectedSection = section
                if section == .wakeData {
                    wakeTimePeriod = .week
                    elapsedPeriod = .week
                }
            }
        } label: {
            Text(title)
                .font(AppTheme.localizedFont(size: 16, weight: .semibold, language: appLanguage))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selected ? AppTheme.sunYellow : Color(hex: "F9F8F4"))
        }
        .buttonStyle(CollectionPressScaleButtonStyle(pressedScale: 0.88))
    }

    private var breakfastShelfContent: some View {
        ScrollView {
            VStack(spacing: 48) {
                ForEach(0..<shelfRowCount, id: \.self) { row in
                    shelfRow(row: row)
                }
            }
            .padding(.top, 22)
            .padding(.bottom, 48)
            .background {
                // 背景灰墙：宽度 = board 梯形上边长（332 / 402 ≈ 82.6% 图宽），
                // 居中撑满整列货架的高度
                GeometryReader { geo in
                    let padX = geo.size.width * (1 - 332.0 / 402.0) / 2
                    Color(hex: "EBEAE4")
                        .padding(.horizontal, padX)
                        .offset(x: -4)
                }
            }
        }
    }

    private var wakeDataContent: some View {
        let wakeChartPoints = chartPoints(for: wakeTimePeriod) { Double($0.wakeMinuteOfDay) }
        let elapsedChartPoints = chartPoints(for: elapsedPeriod) { Double($0.elapsedSeconds) }
        let wakeValues = wakeChartPoints.compactMap(\.value)

        return ScrollView {
            VStack(spacing: 20) {
                CollectionTrendCard(
                    title: L10n.s("collection_wake_time_trend", lang: appLanguage),
                    period: $wakeTimePeriod,
                    lang: appLanguage,
                    points: wakeChartPoints,
                    axisKind: .wakeTime,
                    yScale: wakeTimeScale(for: wakeValues),
                    threshold: nil,
                    onRewardTap: presentRewardCard
                )

                CollectionTrendCard(
                    title: L10n.s("collection_elapsed_trend", lang: appLanguage),
                    period: $elapsedPeriod,
                    lang: appLanguage,
                    points: elapsedChartPoints,
                    axisKind: .elapsedSeconds,
                    yScale: nil,
                    threshold: 60,
                    onRewardTap: presentRewardCard
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 52)
        }
    }

    // MARK: - 一整行货架（board 图做架子 + 三明治坐在架子上）

    private func shelfRow(row: Int) -> some View {
        ZStack(alignment: .bottom) {
            // 底层：整块木板，撑满一行宽度，高度由图比例决定
            Image("board")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            // 上层：三明治坐在木板上（往上偏一点，让脚落在黄色木边上方的"台面"）
            HStack(spacing: 6) {
                ForEach(0..<shelfColumnCount, id: \.self) { column in
                    if let name = rewardName(row: row, column: column) {
                        Button {
                            presentRewardCard(name)
                        } label: {
                            rewardThumb(name: name)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    } else if unlockedSlots.isEmpty, row == 0, column == 0 {
                        Button {
                            showTomorrowToast()
                        } label: {
                            emptyPlateThumb
                        }
                        .buttonStyle(CollectionPressScaleButtonStyle(pressedScale: 0.9))
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 92)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
    }

    private func rewardName(row: Int, column: Int) -> String? {
        let index = row * shelfColumnCount + column
        guard index < unlockedSlots.count else { return nil }
        return unlockedSlots[index]
    }

    // MARK: - 单格（仅已解锁，全彩可点）

    private func rewardThumb(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 92)
    }

    private var emptyPlateThumb: some View {
        Image("plate")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .opacity(0.82)
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

    // MARK: - 早起数据

    private func wakeTimeValues(for period: CollectionArchivePeriod) -> [Double] {
        statPoints(for: period).map { Double($0.wakeMinuteOfDay) }
    }

    private func elapsedValues(for period: CollectionArchivePeriod) -> [Double] {
        statPoints(for: period).map { Double($0.elapsedSeconds) }
    }

    private func wakeTimeScale(for values: [Double]) -> ClosedRange<Double> {
        guard let minValue = values.min(),
              let maxValue = values.max()
        else {
            return fallbackWakeTimeScale()
        }

        let average = values.reduce(0, +) / Double(values.count)
        let centerHour = floor(average / 60) * 60
        var centeredLower = centerHour - 60
        var centeredUpper = centerHour + 60

        if centeredLower <= minValue, maxValue <= centeredUpper {
            if centeredLower < 0 {
                centeredUpper -= centeredLower
                centeredLower = 0
            }
            return centeredLower...centeredUpper
        }

        var lower = floor(minValue / 60) * 60
        var upper = ceil(maxValue / 60) * 60

        if lower < 0 {
            upper -= lower
            lower = 0
        }

        return lower...max(lower + 60, upper)
    }

    private func fallbackWakeTimeScale() -> ClosedRange<Double> {
        let start = Double(timeMinute(from: wakeStart) ?? 5 * 60)
        let end = Double(timeMinute(from: wakeEnd) ?? 8 * 60)
        let lower = floor(min(start, end) / 60) * 60
        let upper = ceil(max(start, end) / 60) * 60
        if upper - lower >= 120 {
            return lower...upper
        }
        return lower...lower + 120
    }

    private func timeMinute(from value: String) -> Int? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    private func axisDateLabel(for date: Date, period: CollectionArchivePeriod) -> String {
        if period == .week {
            let weekday = Calendar.current.component(.weekday, from: date) - 1
            let zh = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            let en = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let ja = ["日", "月", "火", "水", "木", "金", "土"]
            switch appLanguage {
            case "en": return en[weekday]
            case "ja": return ja[weekday]
            default: return zh[weekday]
            }
        }

        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "M/d"
        return f.string(from: date)
    }

    private func chartPoints(
        for period: CollectionArchivePeriod,
        value: (WakeStatPoint) -> Double
    ) -> [CollectionChartPoint] {
        switch period {
        case .week:
            return weekChartPoints(value: value)
        case .month:
            return monthChartPoints(value: value)
        }
    }

    private func weekChartPoints(value: (WakeStatPoint) -> Double) -> [CollectionChartPoint] {
        dateSlotChartPoints(leadingDays: 6, trailingDays: 0, period: .week, value: value)
    }

    private func monthChartPoints(value: (WakeStatPoint) -> Double) -> [CollectionChartPoint] {
        dateSlotChartPoints(leadingDays: 15, trailingDays: 15, period: .month, value: value)
    }

    private func dateSlotChartPoints(
        leadingDays: Int,
        trailingDays: Int,
        period: CollectionArchivePeriod,
        value: (WakeStatPoint) -> Double
    ) -> [CollectionChartPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let centeredStart = calendar.date(byAdding: .day, value: -leadingDays, to: today) ?? today
        let centeredEnd = calendar.date(byAdding: .day, value: trailingDays, to: today) ?? today
        let all = allStatPoints
        let byDay = Dictionary(uniqueKeysWithValues: all.map { (dayKey(for: $0.date), $0) })
        let earliestDataDay = all
            .map { calendar.startOfDay(for: $0.date) }
            .min()
        let start = period == .week
            ? centeredStart
            : min(earliestDataDay ?? centeredStart, centeredStart)

        var dates: [Date] = []
        var cursor = start
        while cursor <= centeredEnd {
            dates.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? centeredEnd.addingTimeInterval(24 * 60 * 60)
        }

        return dates.map { date in
            let key = dayKey(for: date)
            return CollectionChartPoint(
                id: key,
                label: axisDateLabel(for: date, period: period),
                value: byDay[key].map(value),
                date: date,
                elapsedSeconds: byDay[key]?.elapsedSeconds,
                wakeMinuteOfDay: byDay[key]?.wakeMinuteOfDay,
                rewardAsset: byDay[key]?.rewardAsset,
                isCenteredWeekStart: calendar.isDate(date, inSameDayAs: centeredStart)
            )
        }
    }

    private func statPoints(for period: CollectionArchivePeriod) -> [WakeStatPoint] {
        let all = allStatPoints
        guard !all.isEmpty else { return [] }

        let days = period == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days + 1, to: Date()) ?? Date()
        let filtered = all.filter { $0.date >= cutoff }
        return filtered.isEmpty ? Array(all.suffix(days)) : filtered
    }

    private var allStatPoints: [WakeStatPoint] {
        var byDay: [String: WakeStatPoint] = [:]

        for (asset, meta) in store.metas where meta.elapsedSeconds > 0 {
            byDay[dayKey(for: meta.date)] = WakeStatPoint(
                date: meta.date,
                elapsedSeconds: meta.elapsedSeconds,
                wakeMinuteOfDay: minuteOfDay(for: meta.date),
                rewardAsset: asset
            )
        }

        for (key, seconds) in streakStore.minutesByDate where byDay[key] == nil {
            guard let date = dateFromDayKey(key) else { continue }
            byDay[key] = WakeStatPoint(
                date: date,
                elapsedSeconds: seconds,
                wakeMinuteOfDay: 7 * 60,
                rewardAsset: nil
            )
        }

        return byDay.values.sorted { $0.date < $1.date }
    }

    private func minuteOfDay(for date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func dateFromDayKey(_ key: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }

    // MARK: - 点击三明治后的卡片弹层（保持原逻辑）

    private var rewardCardOverlay: some View {
        ZStack {
            Color.black.opacity(cardPresented ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismissCard() }
                .animation(.easeOut(duration: 0.18), value: cardPresented)
            RewardCardView(
                appLanguage: appLanguage,
                rewardAsset: selectedRewardAsset ?? "san1",
                meta: metaForSelected,
                onDismiss: { dismissCard() }
            )
            .padding(.horizontal, 55)
            .scaleEffect(cardPresented ? 1 : 0.68)
            .offset(y: cardPresented ? 0 : 28)
            .opacity(cardPresented ? 1 : 0)
            .animation(.spring(response: 0.46, dampingFraction: 0.72), value: cardPresented)
        }
    }

    private func presentRewardCard(_ name: String) {
        selectedRewardAsset = name
        cardPresented = false
        showRewardDetail = true
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.72)) {
                cardPresented = true
            }
        }
    }

    private func dismissCard() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            cardPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRewardDetail = false
        }
    }
}

private struct CollectionTrendCard: View {
    let title: String
    @Binding var period: CollectionArchivePeriod
    let lang: String
    let points: [CollectionChartPoint]
    let axisKind: CollectionChartAxisKind
    let yScale: ClosedRange<Double>?
    let threshold: Double?
    let onRewardTap: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(AppTheme.localizedFont(size: 20, weight: .bold, language: lang))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                CollectionPeriodToggle(period: $period, lang: lang)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)

            CollectionLineGraph(
                points: points,
                period: period,
                axisKind: axisKind,
                yScale: yScale,
                threshold: threshold,
                lang: lang,
                onRewardTap: onRewardTap
            )
            .frame(height: 220)
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(AppTheme.sunYellow)
    }
}

private enum CollectionChartAxisKind {
    case wakeTime
    case elapsedSeconds

    func label(for value: Double) -> String {
        switch self {
        case .wakeTime:
            let minute = max(0, Int(value.rounded()))
            return "\(minute / 60):" + String(format: "%02d", minute % 60)
        case .elapsedSeconds:
            return "\(max(0, Int(value.rounded())))s"
        }
    }

    var step: Double {
        switch self {
        case .wakeTime: return 30
        case .elapsedSeconds: return 10
        }
    }

}

private struct CollectionPeriodToggle: View {
    @Binding var period: CollectionArchivePeriod
    let lang: String

    var body: some View {
        HStack(spacing: 0) {
            periodButton(.week, title: periodTitle(.week))
            periodButton(.month, title: periodTitle(.month))
        }
        .frame(width: 68, height: 32)
        .background(Color.white)
        .background(alignment: .bottomTrailing) {
            Rectangle()
                .fill(collectionHardShadow)
                .offset(x: 4, y: 4)
        }
    }

    private func periodButton(_ option: CollectionArchivePeriod, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.42)) {
                period = option
            }
        } label: {
            Text(title)
                .font(AppTheme.localizedFont(size: 14.4, weight: .semibold, language: lang))
                .foregroundStyle(period == option ? .white : Color(hex: "B8B8B8"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(period == option ? AppTheme.accentOrange : Color.white)
        }
        .buttonStyle(CollectionPressScaleButtonStyle(pressedScale: 0.84))
    }

    private func periodTitle(_ option: CollectionArchivePeriod) -> String {
        if lang == "en" {
            return option == .week ? "W" : "M"
        }
        return L10n.s(option == .week ? "collection_period_week" : "collection_period_month", lang: lang)
    }
}

private struct CollectionLineGraph: View {
    let points: [CollectionChartPoint]
    let period: CollectionArchivePeriod
    let axisKind: CollectionChartAxisKind
    let yScale: ClosedRange<Double>?
    let threshold: Double?
    let lang: String
    let onRewardTap: (String) -> Void
    @State private var selectedPointID: String?
    @State private var lastPointTapDate = Date.distantPast

    private var displayValues: [Double] {
        points.compactMap(\.value)
    }

    var body: some View {
        GeometryReader { geo in
            let scale = chartScale(for: displayValues, threshold: threshold)
            let yMarks = yAxisMarks(for: scale)

            dateSlotGraph(
                size: geo.size,
                scale: scale,
                yMarks: yMarks,
                visibleSlotCount: period == .week ? 7 : 31,
                labelStride: period == .week ? 1 : 5
            )
        }
    }

    private func dateSlotGraph(
        size: CGSize,
        scale: ClosedRange<Double>,
        yMarks: [Double],
        visibleSlotCount: Int,
        labelStride: Int
    ) -> some View {
        let yAxisWidth: CGFloat = 50
        let rightPadding: CGFloat = 22
        let edgeLabelInset: CGFloat = 17
        let plotViewportWidth = max(1, size.width - yAxisWidth - rightPadding)
        let dayStep = max(1, (plotViewportWidth - edgeLabelInset * 2) / CGFloat(max(1, visibleSlotCount - 1)))
        let plotContentWidth = max(
            plotViewportWidth,
            edgeLabelInset * 2 + CGFloat(max(points.count - 1, 0)) * dayStep
        )
        let fixedRect = CGRect(
            x: yAxisWidth,
            y: 76,
            width: plotViewportWidth,
            height: max(1, size.height - 116)
        )
        let plotRect = CGRect(
            x: 0,
            y: fixedRect.minY,
            width: plotContentWidth,
            height: fixedRect.height
        )
        let initialScrollTargetID = period == .week
            ? points.first { Calendar.current.isDateInToday($0.date) }?.id
            : points.first(where: \.isCenteredWeekStart)?.id
        let initialScrollAnchor: UnitPoint = period == .week ? .center : .leading
        let positionedPoints = positionedChartPoints(
            for: points,
            xPosition: { index in edgeLabelInset + CGFloat(index) * dayStep },
            yPosition: { value in yPosition(for: value, in: plotRect, scale: scale) }
        )
        let selectedPositionedPoint = period == .week ? positionedPoints.first { $0.id == selectedPointID } : nil

        return ZStack(alignment: .topLeading) {
            Color(hex: "F9F8F4")
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissSelectedPointFromBackgroundTap()
                }
                .allowsHitTesting(selectedPointID != nil)

            yAxisLayer(yMarks: yMarks, rect: fixedRect, scale: scale)

            Path { path in
                path.move(to: CGPoint(x: fixedRect.minX, y: fixedRect.minY))
                path.addLine(to: CGPoint(x: fixedRect.minX, y: fixedRect.maxY))
            }
            .stroke(AppTheme.accentOrange, lineWidth: 3)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.001))
                            .frame(width: plotContentWidth + 1, height: size.height)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismissSelectedPointFromBackgroundTap()
                            }
                            .allowsHitTesting(selectedPointID != nil)

                        ForEach(points.indices, id: \.self) { index in
                            let x = edgeLabelInset + CGFloat(index) * dayStep

                            Color.clear
                                .frame(width: 1, height: 1)
                                .position(x: x, y: 1)
                                .id(points[index].id)

                            if shouldShowXLabel(index: index, count: points.count, labelStride: labelStride) {
                                xAxisLabel(points[index].label, x: x, y: plotRect.maxY + 18)

                                Path { path in
                                    path.move(to: CGPoint(x: x, y: plotRect.maxY))
                                    path.addLine(to: CGPoint(x: x, y: plotRect.maxY + 4))
                                }
                                .stroke(AppTheme.accentOrange, lineWidth: 2)
                            }
                        }

                        thresholdLine(in: plotRect, scale: scale)

                        Path { path in
                            path.move(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                            path.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                        }
                        .stroke(AppTheme.accentOrange, lineWidth: 3)

                        dataLine(positionedPoints.map(\.position))

                        dataDots(positionedPoints)

                        if let selectedPositionedPoint {
                            chartPointBubble(
                                for: selectedPositionedPoint,
                                plotContentWidth: plotContentWidth
                            )
                            .id(selectedPositionedPoint.id)
                            .zIndex(999)
                        }
                    }
                    .frame(width: plotContentWidth + 1, height: size.height, alignment: .topLeading)
                }
                .frame(width: plotViewportWidth, height: size.height)
                .padding(.leading, yAxisWidth)
                .onAppear {
                    scrollToChartTarget(initialScrollTargetID, anchor: initialScrollAnchor, proxy: proxy)
                }
                .onChange(of: initialScrollTargetID) { _, newValue in
                    scrollToChartTarget(newValue, anchor: initialScrollAnchor, proxy: proxy)
                }
                .onChange(of: period) { _, _ in
                    selectedPointID = nil
                }
            }
        }
    }

    private func chartScale(for values: [Double], threshold: Double?) -> ClosedRange<Double> {
        if let yScale {
            return yScale
        }

        var all = values
        if let threshold { all.append(threshold) }
        let minValue = all.min() ?? 0
        let maxValue = all.max() ?? 1
        let span = max(1, maxValue - minValue)
        let lower = minValue - span * 0.25
        let upper = maxValue + span * 0.25
        let roundedLower = floor(lower / axisKind.step) * axisKind.step
        let roundedUpper = ceil(upper / axisKind.step) * axisKind.step
        return roundedLower...max(roundedLower + axisKind.step, roundedUpper)
    }

    private func positionedChartPoints(
        for points: [CollectionChartPoint],
        xPosition: (Int) -> CGFloat,
        yPosition: (Double) -> CGFloat
    ) -> [CollectionPositionedChartPoint] {
        points.enumerated().compactMap { index, point in
            guard let value = point.value else { return nil }
            return CollectionPositionedChartPoint(
                point: point,
                position: CGPoint(x: xPosition(index), y: yPosition(value))
            )
        }
    }

    private func yAxisLayer(
        yMarks: [Double],
        rect: CGRect,
        scale: ClosedRange<Double>
    ) -> some View {
        ForEach(yMarks, id: \.self) { value in
            let y = yPosition(for: value, in: rect, scale: scale)
            Text(axisKind.label(for: value))
                .font(AppTheme.localizedFont(size: 9, weight: .medium, language: lang))
                .foregroundStyle(.black.opacity(0.55))
                .frame(width: 40, alignment: .trailing)
                .position(x: rect.minX - 26, y: y)

            Path { path in
                path.move(to: CGPoint(x: rect.minX - 4, y: y))
                path.addLine(to: CGPoint(x: rect.minX, y: y))
            }
            .stroke(AppTheme.accentOrange, lineWidth: 2)
        }
    }

    private func xAxisLabel(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(AppTheme.localizedFont(size: 9, weight: .medium, language: lang))
            .foregroundStyle(.black.opacity(0.55))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: 34)
            .position(x: x, y: y)
    }

    @ViewBuilder
    private func thresholdLine(in rect: CGRect, scale: ClosedRange<Double>) -> some View {
        if let threshold, !displayValues.isEmpty {
            let y = yPosition(for: threshold, in: rect, scale: scale)
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            .stroke(
                Color.black,
                style: StrokeStyle(lineWidth: 1.5, dash: [2, 3])
            )
        }
    }

    private func axisPath(in rect: CGRect) -> some View {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        .stroke(AppTheme.accentOrange, lineWidth: 3)
    }

    private func dataLine(_ points: [CGPoint]) -> some View {
        AnimatablePolylineShape(points: points)
        .stroke(
            AppTheme.accentOrange,
            style: StrokeStyle(lineWidth: points.count >= 2 ? 2.25 : 0, lineCap: .square, lineJoin: .round)
        )
    }

    private func dataDots(_ points: [CollectionPositionedChartPoint]) -> some View {
        ForEach(points) { positioned in
            if period == .week {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(AppTheme.accentOrange)
                        .frame(width: 5.5, height: 5.5)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        selectPointBubble(positioned.id)
                    }
                )
                .accessibilityAddTraits(.isButton)
                .zIndex(200)
                .position(positioned.position)
            } else {
                Circle()
                    .fill(AppTheme.accentOrange)
                    .frame(width: 5.5, height: 5.5)
                    .position(positioned.position)
            }
        }
    }

    private func selectPointBubble(_ id: String) {
        guard period == .week else { return }
        lastPointTapDate = Date()
        withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
            selectedPointID = selectedPointID == id ? nil : id
        }
    }

    private func dismissSelectedPointFromBackgroundTap() {
        guard Date().timeIntervalSince(lastPointTapDate) > 0.18 else { return }
        withAnimation(.easeOut(duration: 0.16)) {
            selectedPointID = nil
        }
    }

    private func chartPointBubble(
        for positioned: CollectionPositionedChartPoint,
        plotContentWidth: CGFloat
    ) -> some View {
        CollectionPointBubbleView(
            positioned: positioned,
            plotContentWidth: plotContentWidth,
            lang: lang,
            onRewardTap: onRewardTap
        )
    }

    private func shortDateText(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.month, .day], from: date)
        let month = comps.month ?? 0
        let day = comps.day ?? 0

        switch lang {
        case "en":
            return "\(month)/\(day)"
        case "ja":
            return "\(month)月\(day)日"
        default:
            return "\(month)月\(day)日"
        }
    }

    private func wakeTimeText(for point: CollectionChartPoint) -> String {
        let minute = point.wakeMinuteOfDay ?? 0
        let text = "\(minute / 60):" + String(format: "%02d", minute % 60)

        switch lang {
        case "en":
            return "\(text) wake 😁"
        case "ja":
            return "\(text) 起床 😁"
        default:
            return "\(text)起床 😁"
        }
    }

    private func scrollToChartTarget(
        _ id: String?,
        anchor: UnitPoint,
        proxy: ScrollViewProxy
    ) {
        guard let id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.42)) {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }

    private func shouldShowXLabel(index: Int, count: Int, labelStride: Int) -> Bool {
        guard count > 0 else { return false }
        if labelStride <= 1 { return true }
        return index == 0 || index == count - 1 || index % labelStride == 0 || points[index].isCenteredWeekStart
    }

    private func yAxisMarks(for scale: ClosedRange<Double>) -> [Double] {
        switch axisKind {
        case .wakeTime:
            let firstHour = Int(ceil(scale.lowerBound / 60))
            let lastHour = Int(floor(scale.upperBound / 60))
            guard lastHour >= firstHour else { return [scale.lowerBound, scale.upperBound] }
            return (firstHour...lastHour).map { Double($0 * 60) }
        case .elapsedSeconds:
            return [
                scale.upperBound,
                (scale.lowerBound + scale.upperBound) / 2,
                scale.lowerBound
            ]
        }
    }

    private func yPosition(for value: Double, in rect: CGRect, scale: ClosedRange<Double>) -> CGFloat {
        let span = max(1, scale.upperBound - scale.lowerBound)
        let t = min(1, max(0, (value - scale.lowerBound) / span))
        return rect.maxY - rect.height * CGFloat(t)
    }
}

private struct CollectionPointBubbleView: View {
    let positioned: CollectionPositionedChartPoint
    let plotContentWidth: CGFloat
    let lang: String
    let onRewardTap: (String) -> Void

    @State private var presented = false

    var body: some View {
        let bubbleWidth: CGFloat = 132
        let bubbleHeight: CGFloat = 50
        let pointerHeight: CGFloat = 11
        let totalHeight = bubbleHeight + pointerHeight
        let pointerGap: CGFloat = 4
        let x = min(
            max(positioned.position.x, bubbleWidth / 2 + 4),
            max(bubbleWidth / 2 + 4, plotContentWidth - bubbleWidth / 2 - 4)
        )
        let y = positioned.position.y - pointerGap - totalHeight / 2
        let pointerOffsetX = min(
            max(positioned.position.x - x, -bubbleWidth / 2 + 11),
            bubbleWidth / 2 - 11
        )
        let pointerAnchorX = min(1, max(0, (bubbleWidth / 2 + pointerOffsetX) / bubbleWidth))
        let popAnchor = UnitPoint(x: pointerAnchorX, y: 1)

        return VStack(spacing: 0) {
            HStack(spacing: 7) {
                if let asset = positioned.point.rewardAsset {
                    Button {
                        onRewardTap(asset)
                    } label: {
                        Image(RewardData.imageName(for: asset))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 40)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image("plate")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 40)
                        .opacity(0.82)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(shortDateText(positioned.point.date))
                        .font(AppTheme.localizedFont(size: 11, weight: .bold, language: lang))
                        .fixedSize(horizontal: true, vertical: false)
                    Text(wakeTimeText(for: positioned.point))
                        .font(AppTheme.localizedFont(size: 11, weight: .bold, language: lang))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundStyle(.black)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .frame(width: bubbleWidth, height: bubbleHeight)
            .background(Color(hex: "D9D9D9"))

            CollectionDownTriangle()
                .fill(Color(hex: "D9D9D9"))
                .frame(width: 14, height: pointerHeight)
                .offset(x: pointerOffsetX)
        }
        .frame(width: bubbleWidth, height: totalHeight)
        .scaleEffect(presented ? 1 : 0.08, anchor: popAnchor)
        .offset(y: presented ? 0 : 12)
        .opacity(presented ? 1 : 0)
        .position(x: x, y: y)
        .onAppear {
            presented = false
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.74)) {
                    presented = true
                }
            }
        }
    }

    private func shortDateText(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.month, .day], from: date)
        let month = comps.month ?? 0
        let day = comps.day ?? 0

        switch lang {
        case "en":
            return "\(month)/\(day)"
        case "ja":
            return "\(month)月\(day)日"
        default:
            return "\(month)月\(day)日"
        }
    }

    private func wakeTimeText(for point: CollectionChartPoint) -> String {
        let minute = point.wakeMinuteOfDay ?? 0
        let text = "\(minute / 60):" + String(format: "%02d", minute % 60)

        switch lang {
        case "en":
            return "\(text) wake 😁"
        case "ja":
            return "\(text) 起床 😁"
        default:
            return "\(text)起床 😁"
        }
    }
}

private struct CollectionPressScaleButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct CollectionDownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct AnimatablePolylineShape: Shape {
    var pointsVector: AnimatableCGFloatVector

    init(points: [CGPoint]) {
        pointsVector = AnimatableCGFloatVector(values: points.flatMap { [$0.x, $0.y] })
    }

    var animatableData: AnimatableCGFloatVector {
        get { pointsVector }
        set { pointsVector = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let values = pointsVector.values
        guard values.count >= 2 else { return path }

        path.move(to: CGPoint(x: values[0], y: values[1]))
        var index = 2
        while index + 1 < values.count {
            path.addLine(to: CGPoint(x: values[index], y: values[index + 1]))
            index += 2
        }
        return path
    }
}

private struct AnimatableCGFloatVector: VectorArithmetic {
    var values: [CGFloat]

    static var zero: AnimatableCGFloatVector {
        AnimatableCGFloatVector(values: [])
    }

    static func + (lhs: AnimatableCGFloatVector, rhs: AnimatableCGFloatVector) -> AnimatableCGFloatVector {
        var result = lhs
        result += rhs
        return result
    }

    static func - (lhs: AnimatableCGFloatVector, rhs: AnimatableCGFloatVector) -> AnimatableCGFloatVector {
        var result = lhs
        result -= rhs
        return result
    }

    static func += (lhs: inout AnimatableCGFloatVector, rhs: AnimatableCGFloatVector) {
        let count = max(lhs.values.count, rhs.values.count)
        lhs.values = (0..<count).map { index in
            lhs.value(at: index) + rhs.value(at: index)
        }
    }

    static func -= (lhs: inout AnimatableCGFloatVector, rhs: AnimatableCGFloatVector) {
        let count = max(lhs.values.count, rhs.values.count)
        lhs.values = (0..<count).map { index in
            lhs.value(at: index) - rhs.value(at: index)
        }
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * CGFloat(rhs) }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { partial, value in
            partial + Double(value * value)
        }
    }

    private func value(at index: Int) -> CGFloat {
        guard values.indices.contains(index) else { return 0 }
        return values[index]
    }
}

/// 奖励介绍卡：直角外红框、右上角黄叉、直角内白底（标题 + 三明治 + 描述）
///
/// =======================================================================
///  🔧 想自己调？全部可调参数都集中在下面，按序号找就行
/// =======================================================================
///  【①】外层红框厚度：topFrameInset / sideFrameInset
///  【②】卡片离屏幕左右距离：不在这里改，改调用点 .padding(.horizontal, XX)
///       - CollectionView.rewardCardOverlay 里 RewardCardView 后面的 .padding(.horizontal, 30)
///       - DayRecapView.rewardCardOverlay 里同名 padding
///  【③】黄色 × 按钮：fontSize / 粗细 / 颜色 / 位置 padding
///  【④】内部三块内容：标题 / 三明治 / 描述，各自 font、颜色、上下内边距
///  【⑤】阴影：卡片最外面的 .shadow(...)
/// =======================================================================
struct RewardCardView: View {
    var appLanguage: String
    /// 该卡片要展示的奖励 asset（如 "san3"、"cake5"）；决定图片 / 标题 / 介绍
    var rewardAsset: String
    /// 该奖励的获得元信息（日期 / 用时）。为 nil 时不展示获得信息
    var meta: RewardMeta? = nil
    var onDismiss: () -> Void

    // ─────────────── ① 外层红框厚度 ───────────────
    /// 顶部红边距（黄叉就放在这条里，想让叉有更多呼吸空间就调大）
    private let topFrameInset: CGFloat = 40
    /// 左 / 右 / 下 三条红边的厚度（要更粗的边框就调大；想更细就调小，可以 0）
    private let sideFrameInset: CGFloat = 10
    /// 部分早餐 PNG 底部带尖角装饰（画在图里），裁掉底部一截避免夹在图与文案之间像 UI 尾巴
    private let rewardImageBottomClip: CGFloat = 14
    private var frameColor: Color {
        RewardData.isCoffee(rewardAsset) ? AppTheme.sunYellow : AppTheme.accentOrange
    }
    private var closeColor: Color {
        RewardData.isCoffee(rewardAsset) ? AppTheme.accentOrange : AppTheme.sunYellow
    }
    private var imageBottomClip: CGFloat {
        RewardData.isCoffee(rewardAsset) ? 0 : rewardImageBottomClip
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // ─────────────── ④ 白色内容区（标题 / 三明治 / 描述）───────────────
            VStack(spacing: 18) {       // ← 三块内容之间的垂直间距
                // ④a 标题
                Text(RewardData.title(for: rewardAsset, lang: appLanguage))
                    .font(AppTheme.localizedFont(size: 24, weight: .bold, language: appLanguage))  // ← 标题字号 / 粗细
                    .foregroundStyle(.black)                 // ← 标题颜色
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 28)                       // ← 标题距离白色区顶部的距离
                    .padding(.horizontal, 16)

                // ④b 奖励大图（跟随当前格子的 asset；底部裁切去掉素材里自带的「小尖角」）
                Image(RewardData.imageName(for: rewardAsset))
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200 + imageBottomClip)
                    .frame(maxHeight: 200, alignment: .top)
                    .clipped()
                    .padding(.horizontal, 12)

                // ④c 描述文字
                Text(RewardData.desc(for: rewardAsset, lang: appLanguage))
                    .font(AppTheme.localizedFont(size: 16, weight: .medium, language: appLanguage)) // ← 描述字号 / 粗细
                    .foregroundStyle(.black.opacity(0.72))    // ← 描述颜色 / 透明度
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)

                // ④d 获得信息（日期 + 起床用时）
                if let m = meta {
                    VStack(spacing: 4) {
                        Text(earnedDateText(m.date))
                        if m.elapsedSeconds > 0 {
                            Text(elapsedText(m.elapsedSeconds))
                        }
                    }
                    .font(AppTheme.localizedFont(size: 14, weight: .medium, language: appLanguage))
                    .foregroundStyle(.black.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                } else {
                    Spacer().frame(height: 16)
                }
            }
            .padding(.bottom, 16)                               // ← 整体内容距离内层底部的距离
            .frame(maxWidth: .infinity)
            .background(Color(hex: "F9F8F4"))       // ← 内层背景色（米色，和日历统一）

            // ─────────────── ① 红框厚度在这里落到视图上 ───────────────
            .padding(.top, topFrameInset)         // 顶边（放黄叉）
            .padding(.horizontal, sideFrameInset) // 左右两边
            .padding(.bottom, sideFrameInset)     // 底边
            .background(frameColor)    // ← 红框颜色（改去 AppTheme 改最稳）

            // ─────────────── ③ 右上角黄色 × 按钮 ───────────────
            //   关键思路：把按钮的高度强行等于顶部红条高度（topFrameInset），
            //   再让 Image 在这个 frame 里自动垂直居中，就永远正好在橙色条中间
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(AppTheme.localizedFont(size: 18, weight: .heavy, language: appLanguage))       // ← ③a 叉叉大小 / 粗细
                    .foregroundStyle(closeColor)                    // ← ③b 叉叉颜色
                    .frame(height: topFrameInset)                  // ← ③c 锁高 = 顶部红条高，自动竖直居中
                    .padding(.trailing, 10)                        // ← ③d 叉叉离卡片右边的距离
                    .padding(.leading, 10)                          // ← 点击热区左侧 padding（只影响可点范围）
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.s("done", lang: appLanguage))
        }
        // ─────────────── ⑤ 卡片整体阴影 ───────────────
        //   不想要阴影就删掉这行；想更飘就 radius 调大；想偏下就 y 调大
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
    }

    /// "x 月 x 日 HH:mm 获得" —— 同时展示起床那天的日期和具体时刻
    private func earnedDateText(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date)
        let month = comps.month ?? 0
        let day = comps.day ?? 0
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        return String(
            format: L10n.s("reward_card_earned_at_fmt", lang: appLanguage),
            month, day, hour, minute
        )
    }

    /// "起床用时 x 秒"
    private func elapsedText(_ seconds: Int) -> String {
        String(format: L10n.s("reward_card_elapsed_fmt", lang: appLanguage), seconds)
    }
}

#Preview {
    CollectionView()
}
