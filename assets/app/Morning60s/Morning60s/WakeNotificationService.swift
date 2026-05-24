import Foundation
import UserNotifications

/// 早上起床提醒通知
///
/// 触发逻辑:
/// - 每次 app 进入后台时，排一条本地通知
/// - 触发时间 = max(今天 05:00, 现在) + 3 小时
/// - 如果该时间已经超过今天上午 11:00（不算起床窗口了），顺延到明天早上 08:00
/// - 每次 app 回到前台，取消尚未触发的通知
///
/// 这样只要用户在 3 小时内打开过 app,通知永远不会响；只有"夜间关掉 app
/// 然后超过 3 小时没再打开"的情况才会在早上弹 lock-screen 提醒。
enum WakeNotificationService {

    /// 本地通知唯一 ID（只排一条，取消时用它）
    static let notificationIdentifier = "morning60s.wakeReminder"

    /// 通知 userInfo 里带的 deep link URL 字符串
    /// 点通知 → iOS 调用 UNUserNotificationCenterDelegate → app 读这个值 → 跳挑战页
    static let deepLinkKey = "morning60s.deepLink"
    static let deepLinkValue = "morning60s://start"

    /// 可触发窗口的起点（5 AM）
    static let wakeWindowStartHour = 5
    /// 需要累计空闲的小时数（3h）
    static let idleHours = 3
    /// 可触发窗口的终点（11 AM）——超过就顺延到次日
    static let wakeWindowEndHour = 11

    // MARK: - 权限

    /// 请求通知权限；如果已经决定过（授权或拒绝），不再重复弹窗。返回是否授权
    @discardableResult
    static func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - 排期 / 取消

    /// 计算下一条通知应当触发的时刻
    ///
    /// fireTime = max(当天 5:00 AM, 上次使用时间 + 3h)
    /// - 若 (lastUse + 3h) 落在凌晨 5 点之前 → 抬高到 5:00 AM
    /// - 若 (lastUse + 3h) 落在 5-11 AM 之间 → 就用这个时间
    /// - 若 (lastUse + 3h) 超过 11 AM（已经不是起床窗口）→ 顺延到次日 5:00 AM
    ///
    /// 通知到时间后由 iOS 投递到通知中心 / 锁屏，用户下一次拿起手机就能看到。
    static func computeNextFireDate(
        from referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let idle = TimeInterval(idleHours * 3600)
        // 3h 空闲结束的时刻（"最早满足 3h 未用"的时间点）
        let earliestByIdle = referenceDate.addingTimeInterval(idle)

        // 以 earliestByIdle 那一天为基准取 5:00 / 11:00
        let sameDay5AM = calendar.date(
            bySettingHour: wakeWindowStartHour, minute: 0, second: 0, of: earliestByIdle
        ) ?? earliestByIdle
        let sameDay11AM = calendar.date(
            bySettingHour: wakeWindowEndHour, minute: 0, second: 0, of: earliestByIdle
        ) ?? earliestByIdle

        // Case A: 3h 条件在凌晨 5 点之前就已满足 → 抬高到当天 5:00
        if earliestByIdle < sameDay5AM {
            return sameDay5AM
        }
        // Case B: 落在 5-11 AM 起床窗口内 → 用 idle 结束点
        if earliestByIdle <= sameDay11AM {
            return earliestByIdle
        }
        // Case C: 超过 11 AM，已经不算起床时间 → 推到第二天早上 5:00
        let nextDay = calendar.date(byAdding: .day, value: 1, to: earliestByIdle) ?? earliestByIdle
        let nextDay5AM = calendar.date(
            bySettingHour: wakeWindowStartHour, minute: 0, second: 0, of: nextDay
        ) ?? nextDay
        return nextDay5AM
    }

    /// 排下一条通知（会先取消已有同 ID 的旧通知）
    static func scheduleNext() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral else {
                return
            }

            let fireDate = computeNextFireDate()

            let content = UNMutableNotificationContent()
            content.title = "准备起床了吗？"
            content.body = "点开 app，60 秒内起床，领取今天的赛博早餐"
            // 静音 + 被动投递:不发声、不震、不亮屏,只是在锁屏队列里等用户下次主动解锁看到
            content.sound = nil
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .passive
            }
            // 点通知 → 深链到挑战页（交给 UNUserNotificationCenterDelegate 解析）
            content.userInfo = [deepLinkKey: deepLinkValue]

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationIdentifier,
                content: content,
                trigger: trigger
            )

            center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            center.add(request) { error in
                if let error = error {
                    print("[WakeNotification] schedule failed: \(error.localizedDescription)")
                } else {
                    print("[WakeNotification] scheduled at \(fireDate)")
                }
            }
        }
    }

    /// 取消尚未触发的起床通知
    static func cancelPending() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}
