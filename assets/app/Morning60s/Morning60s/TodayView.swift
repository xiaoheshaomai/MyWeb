import SwiftUI

/// 今日/首页：过去是「我起床啦」大圆按钮，现改为进入页面即自动开始倒计时。
///
/// 新机制下（5:00–13:00 首次打开 app 就进倒计时）不再存在"窗口已过"的过期态——
/// 超过窗口的场景已经由 `ContentView.timeBasedTodayHome` 直接路由到 DayRecap，
/// 根本不会进到这里。
struct TodayView: View {
    var onStart: () -> Void

    @State private var didAutoStart = false

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .onAppear {
                guard !didAutoStart else { return }
                didAutoStart = true
                onStart()
            }
    }
}

#Preview("Normal · auto start") {
    TodayView(onStart: {})
}
