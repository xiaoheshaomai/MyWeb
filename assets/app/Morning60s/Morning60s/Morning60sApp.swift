import SwiftUI
import UserNotifications

@main
struct Morning60sApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var deepLinkRouter = DeepLinkRouter.shared

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // 接管通知点击回调：点锁屏通知 → DeepLinkRouter → ContentView 自动跳挑战页
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deepLinkRouter)
                // Widget / Safari / 任意来源的 morning60s:// 链接走这里
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // 进入后台：排下一次"准备起床了吗?"提醒
                WakeNotificationService.scheduleNext()
            case .active:
                // 回到前台：视为用户已开 app,取消任何待触发的提醒
                WakeNotificationService.cancelPending()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
