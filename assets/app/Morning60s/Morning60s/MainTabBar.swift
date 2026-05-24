import SwiftUI

/// 主界面底部统一导航栏（设计稿：白底、三栏均分、选中黑胶囊白字、未选中灰字）
struct MainTabBar: View {
    @Binding var selection: Int
    /// 已在「今日」 tab、再次点「今日」时回调（用于日间总结页无「完成」时回到今日主页）
    var onReTapToday: (() -> Void)? = nil
    @AppStorage("appLanguage") private var appLanguage = "zh"

    var body: some View {
        HStack(spacing: 8) {
            tabItem(title: L10n.s("tab_today", lang: appLanguage), tag: 0)
            tabItem(title: L10n.s("tab_collection", lang: appLanguage), tag: 1)
            tabItem(title: L10n.s("tab_settings", lang: appLanguage), tag: 2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            Color.white.opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 1)
        }
    }

    private func tabItem(title: String, tag: Int) -> some View {
        let selected = selection == tag
        return Button {
            if tag == 0, selection == 0 {
                onReTapToday?()
            }
            selection = tag
        } label: {
            Text(title)
                .font(AppTheme.localizedFont(size: 15, language: appLanguage))
                .fontWeight(.regular)
                .tracking(-0.2)
                .foregroundStyle(selected ? .white : Color(hex: "878979"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(selected ? Color.black : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabBarPreview()
}

private struct MainTabBarPreview: View {
    @State private var tab = 0
    var body: some View {
        VStack {
            Spacer()
            MainTabBar(selection: $tab, onReTapToday: nil)
        }
        .background(AppTheme.background)
    }
}
