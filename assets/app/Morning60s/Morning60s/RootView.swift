import SwiftUI

/// 根据是否完成新手流程，显示 Onboarding 或主界面
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }

            if showSplash {
                SandwichSplashView {
                    withAnimation(.easeOut(duration: 0.36)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

#Preview {
    RootView()
}
