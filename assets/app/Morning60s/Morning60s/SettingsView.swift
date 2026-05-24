import SwiftUI

struct SettingsView: View {
    /// 开发者预览面板：传入则展示对应 section；nil 时不展示，保持 release 风干净
    var devActions: DevPreviewActions? = nil

    @AppStorage("appLanguage") private var appLanguage = "zh"
    @AppStorage("wakeStart") private var wakeStart = "05:00"
    @AppStorage("wakeEnd") private var wakeEnd = "08:00"
    @AppStorage("photoVerifyOn") private var photoVerifyOn = true
    @AppStorage("notificationOn") private var notificationOn = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    var body: some View {
        NavigationStack {
            Form {
                if let dev = devActions {
                    devPreviewSection(dev: dev)
                }
                Section("原型预览") {
                    NavigationLink("Claude 原型页面") {
                        ClaudePrototypeView()
                    }
                }
                Section(L10n.s("language", lang: appLanguage)) {
                    Picker("", selection: $appLanguage) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                    }
                    .pickerStyle(.menu)
                }
                Section(L10n.s("wake_window", lang: appLanguage)) {
                    HStack {
                        Text(L10n.s("start", lang: appLanguage))
                        Spacer()
                        Text(wakeStart).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(L10n.s("end", lang: appLanguage))
                        Spacer()
                        Text(wakeEnd).foregroundStyle(.secondary)
                    }
                }
                Section {
                    Toggle(L10n.s("photo_verify", lang: appLanguage), isOn: $photoVerifyOn)
                }
                Section {
                    Toggle(L10n.s("notification", lang: appLanguage), isOn: $notificationOn)
                }
                Section {
                    Button(L10n.s("reset_onboarding", lang: appLanguage)) {
                        hasCompletedOnboarding = false
                    }
                }
                Section {
                    Text(L10n.s("privacy_note", lang: appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .tint(AppTheme.accentOrange)
            .navigationTitle(L10n.s("settings_title", lang: appLanguage))
        }
    }

    // MARK: - 开发者预览（不影响真实数据，仅切换 UI 状态）
    @ViewBuilder
    private func devPreviewSection(dev: DevPreviewActions) -> some View {
        Section {
            Button {
                dev.morningChallenge()
            } label: {
                Label("起床倒计时（早起）", systemImage: "sun.max.fill")
            }
            Button {
                dev.napChallenge()
            } label: {
                Label("起床倒计时（午睡 → 咖啡）", systemImage: "cup.and.saucer.fill")
            }
            Button {
                dev.dayRecap()
            } label: {
                Label("白天总结页", systemImage: "sun.haze")
            }
            Button {
                dev.nightRecap()
            } label: {
                Label("夜间总结页", systemImage: "moon.stars.fill")
            }
            Button {
                dev.calendar()
            } label: {
                Label("日历敲章页", systemImage: "calendar")
            }
            Button {
                dev.splash()
            } label: {
                Label("开屏三明治动效", systemImage: "play.rectangle.fill")
            }
            Button {
                dev.verifyWaiting()
            } label: {
                Label("验证等待页", systemImage: "hourglass")
            }
            Button {
                dev.restartOnboarding()
            } label: {
                Label("新手引导（首次打开流程）", systemImage: "hand.wave.fill")
            }
            Button(role: .destructive) {
                dev.resetForceRecap()
            } label: {
                Label("退出预览，按真实时间路由", systemImage: "arrow.uturn.backward")
            }
        } header: {
            Text("开发者预览")
        } footer: {
            Text("点上面的按钮会立刻跳到对应界面。\n「新手引导」会退出主界面并重走首次打开流程，走完后与设置里的「重置新手引导」相同。\n白天 / 夜间总结会临时绕开 5:00–13:00 的自动倒计时路由；点「退出预览」可恢复正常路由。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView(devActions: nil)
}
