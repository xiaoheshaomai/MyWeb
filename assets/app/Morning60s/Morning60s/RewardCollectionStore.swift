import Foundation
import Combine

/// 单个奖励的获得元信息：获得当下的时间戳 + 起床用时（秒）
/// - `elapsedSeconds == 0` 视为旧数据/调试数据占位，收藏页卡片不展示用时
struct RewardMeta: Codable, Equatable {
    var date: Date
    var elapsedSeconds: Int
}

/// 小和的「收集库」：每天早起成功只解锁 1 个奖励
/// - 首次启动不赠送奖励；完成一次早起挑战后才解锁第一个早餐
/// - 每天拍照验证成功一次 → 再解锁下一个（从尚未解锁的池子里随机）
/// - 收藏页只展示 `unlocked` 里的已解锁奖励，未解锁奖励不占位
@MainActor
final class RewardCollectionStore: ObservableObject {
    static let shared = RewardCollectionStore()

    /// 完整奖励池；收藏页一共就这么多格子（顺序固定，已解锁的会填到前 N 个格子）
    static let all: [String] = [
        "san1", "san2", "san3", "san4", "san5", "san6",
        "cake1", "cake2", "cake3", "cake4", "cake5", "cake6",
        "hg1", "hg2", "hg3", "hg4", "hg5", "hg6",
        "rice1", "rice2", "rice3", "rice4", "rice5", "rice6",
        "ch1", "ch2", "ch3", "ch4", "ch5",
    ]

    /// 已解锁的奖励名（按解锁先后顺序）
    @Published private(set) var unlocked: [String] = []

    /// 每个奖励对应的获得日期与用时元信息
    @Published private(set) var metas: [String: RewardMeta] = [:]

    private let unlockedKey = "rewardCollection.unlocked.v1"
    private let lastDayKey = "rewardCollection.lastUnlockDay.v1"
    private let metasKey = "rewardCollection.metas.v1"

    private init() {
        let def = UserDefaults.standard
        if let data = def.data(forKey: unlockedKey),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            self.unlocked = arr
        }
        if let data = def.data(forKey: metasKey),
           let dict = try? JSONDecoder().decode([String: RewardMeta].self, from: data) {
            self.metas = dict
        }
        removeLegacySeedIfNeeded()

        if !unlocked.isEmpty {
            // 兼容老数据：若 unlocked 里有奖励还没记 meta，补一个仅含今日日期的占位
            var changed = false
            for name in unlocked where metas[name] == nil {
                metas[name] = RewardMeta(date: Date(), elapsedSeconds: 0)
                changed = true
            }
            if changed { save() }
        }
    }

    /// 是否已解锁某个奖励
    func isUnlocked(_ name: String) -> Bool { unlocked.contains(name) }

    /// 查询某个奖励的获得元信息（日期 / 用时）
    func meta(for name: String) -> RewardMeta? { metas[name] }

    /// 今日是否已经发放过奖励
    var hasUnlockedToday: Bool {
        UserDefaults.standard.string(forKey: lastDayKey) == Self.dayKey()
    }

    /// 一天最多解锁一次；今天已解锁则返回 nil。
    /// 通常在「拍照验证成功」时调用。
    /// - Parameter elapsedSeconds: 挑战开始 → 验证成功的总用时（秒），用于卡片展示
    @discardableResult
    func unlockForTodayIfNeeded(elapsedSeconds: Int = 0) -> String? {
        let def = UserDefaults.standard
        let today = Self.dayKey()
        if def.string(forKey: lastDayKey) == today { return nil }

        let remaining = Self.all.filter { !unlocked.contains($0) }
        guard let pick = remaining.randomElement() else { return nil }

        unlocked.append(pick)
        metas[pick] = RewardMeta(date: Date(), elapsedSeconds: max(0, elapsedSeconds))
        save()
        def.set(today, forKey: lastDayKey)
        return pick
    }

    /// 手动补录某天的早餐奖励，用于和早起数据一起修复/创建历史记录。
    /// 若当天已有奖励，只更新它的时间与用时；否则稳定解锁第一个尚未获得的早餐。
    @discardableResult
    func upsertMorningReward(on date: Date, elapsedSeconds: Int) -> String? {
        let day = Self.dayKey(date)
        if let existing = metas.first(where: { Self.dayKey($0.value.date) == day })?.key {
            metas[existing] = RewardMeta(date: date, elapsedSeconds: max(0, elapsedSeconds))
            save()
            UserDefaults.standard.set(day, forKey: lastDayKey)
            return existing
        }

        let pick = Self.all.first { !unlocked.contains($0) } ?? unlocked.last
        guard let pick else { return nil }

        if !unlocked.contains(pick) {
            unlocked.append(pick)
        }
        metas[pick] = RewardMeta(date: date, elapsedSeconds: max(0, elapsedSeconds))
        save()
        UserDefaults.standard.set(day, forKey: lastDayKey)
        return pick
    }

    /// 调试：清空解锁进度（不会自动 seed；下次 App 冷启动才会再 seed）
    func resetForDebug() {
        unlocked = []
        metas = [:]
        let def = UserDefaults.standard
        def.removeObject(forKey: unlockedKey)
        def.removeObject(forKey: lastDayKey)
        def.removeObject(forKey: metasKey)
    }

    private func save() {
        let def = UserDefaults.standard
        if let data = try? JSONEncoder().encode(unlocked) {
            def.set(data, forKey: unlockedKey)
        }
        if let data = try? JSONEncoder().encode(metas) {
            def.set(data, forKey: metasKey)
        }
    }

    /// 旧版本首次启动会免费写入 `ch5`。如果用户没有任何完成日期，
    /// 且收藏里只有这个 0 秒占位，就把它当作旧 seed 清掉。
    private func removeLegacySeedIfNeeded() {
        guard unlocked == ["ch5"],
              metas["ch5"]?.elapsedSeconds == 0,
              (UserDefaults.standard.stringArray(forKey: "completedDates") ?? []).isEmpty
        else { return }

        unlocked = []
        metas = [:]
        let def = UserDefaults.standard
        def.removeObject(forKey: unlockedKey)
        def.removeObject(forKey: lastDayKey)
        def.removeObject(forKey: metasKey)
    }

    private static func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
