import Foundation
import Combine
import UserNotifications
import UIKit

/// 全局深链接收中枢
///
/// 任何来源（锁屏 Widget 点击 / 通知点击 / 手动输入 URL）走进 app 时，
/// 最终都会把意图 flush 到这里。`ContentView` 订阅 `pending` 决定跳哪页。
final class DeepLinkRouter: NSObject, ObservableObject {
    static let shared = DeepLinkRouter()

    enum Intent: Equatable {
        /// 直接去挑战页开始 60s 倒计时
        case startChallenge
        /// 去今日主页（默认）
        case today
    }

    /// 最新一条待消费的意图；ContentView 处理完后自己置 `nil`
    @Published var pending: Intent?

    /// 外部（widget / notification / custom URL）把 URL 传进来，解析并缓存
    func handle(url: URL) {
        // 允许形如 morning60s://start / morning60s://today 的格式
        let host = url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch host.lowercased() {
        case "start":
            pending = .startChallenge
        case "today", "":
            pending = .today
        default:
            pending = .today
        }
    }
}

// MARK: - 通知点击回调

/// 承接 UNUserNotificationCenter 的 delegate 回调；独立出来避免 App 主体变复杂
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    /// app 在前台时也让通知显示（否则默认吞掉）—— 虽然我们设了 passive 一般不会响，但保险起见
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    /// 用户点了通知 → 读 userInfo 里的深链 → 交给 DeepLinkRouter
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo[WakeNotificationService.deepLinkKey] as? String,
           let url = URL(string: urlString) {
            DispatchQueue.main.async {
                DeepLinkRouter.shared.handle(url: url)
            }
        }
        completionHandler()
    }
}
