import Foundation
import HealthKit

/// 从 HealthKit 读取「最近一次真实的醒来时刻」
///
/// 数据源：`HKCategoryTypeIdentifierSleepAnalysis`
/// - iPhone + Apple Watch / 第三方睡眠 app / 自动睡眠检测 都会写入此类型
/// - 我们取最近 24 小时里最后一段 *asleep* 样本的 `endDate`，视为「出睡眠的时刻」
///
/// 有数据：可以用来判断「用户刚醒 vs 醒了很久」。
/// 没数据（用户没戴表 / 没开睡眠跟踪）：`fetchLastWakeDate` 返回 `nil`，
/// 调用方回退到荣誉制（不卡挑战），避免误伤。
enum WakeSleepService {

    // MARK: - 类型

    /// 是否拿到了睡眠读权限（仅 read，不写）
    static var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }

    static let store: HKHealthStore? = {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        return HKHealthStore()
    }()

    // MARK: - 权限

    /// 请求读取睡眠分析的权限。iOS 的 HealthKit 权限对外永远返回 "notDetermined" / "sharingDenied"，
    /// 所以即便用户点过拒绝，这里也不会再次弹窗（Apple 规则）。
    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        guard let store = store, let sleepType = sleepType else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            return true
        } catch {
            print("[WakeSleep] auth failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 查询

    /// 取用户最近一次醒来的时间（过去 24h 内，最后一段 asleep 样本的 endDate）
    /// - Returns: 有睡眠数据返回 `Date`；无权限 / 无数据返回 `nil`
    static func fetchLastWakeDate() async -> Date? {
        guard let store = store, let sleepType = sleepType else { return nil }

        let end = Date()
        let start = end.addingTimeInterval(-24 * 3600)
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictEndDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { (cont: CheckedContinuation<Date?, Never>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 200,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    print("[WakeSleep] query failed: \(error.localizedDescription)")
                    cont.resume(returning: nil); return
                }
                guard let samples = samples as? [HKCategorySample] else {
                    cont.resume(returning: nil); return
                }
                // 过滤所有 "asleep*" 样本，取最晚 endDate
                let asleepEnds = samples
                    .filter { isAsleepValue($0.value) }
                    .map { $0.endDate }
                cont.resume(returning: asleepEnds.max())
            }
            store.execute(query)
        }
    }

    /// 距离最近一次醒来过了多少分钟；无数据返回 `nil`
    static func minutesSinceLastWake() async -> Int? {
        guard let wake = await fetchLastWakeDate() else { return nil }
        let elapsed = Date().timeIntervalSince(wake)
        guard elapsed >= 0 else { return 0 }
        return Int(elapsed / 60)
    }

    // MARK: - Helpers

    private static func isAsleepValue(_ raw: Int) -> Bool {
        guard let v = HKCategoryValueSleepAnalysis(rawValue: raw) else { return false }
        switch v {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            return true
        case .asleep:
            // iOS < 16 旧值，仍可能出现
            return true
        default:
            return false
        }
    }
}
