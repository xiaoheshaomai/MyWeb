import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

/// 统一配色：以倒计时页设计为主，橙色强调 + 深灰 + 米白
enum AppTheme {
    /// 主 CTA / 强调色（与倒计时页红色按钮一致）
    static let accentOrange = Color(hex: "FF2E1F")
    /// 深灰：主按钮、重要文字
    static let primaryDark = Color(hex: "2C2C2E")
    /// 背景
    static let background = Color(hex: "FAF8F5")
    /// 成功/倒计时最后阶段
    static let success = Color(hex: "7BC9A0")
    /// 收集页等处统一使用的「太阳黄」，与 NightRecap 太阳 / 光线一致
    static let sunYellow = Color(red: 1.0, green: 0.87, blue: 0.22)
    /// 收集页货架暖灰板（偏米的冷灰，和 background 搭得上又能让三明治跳出来）
    static let shelfPlate = Color(hex: "D9D6CF")
    /// 贯穿始终的大圆按钮尺寸
    static let bigCircleSize: CGFloat = 220

    static func localizedFontSize(_ size: CGFloat, language: String) -> CGFloat {
        language == "en" ? size * 0.88 : size
    }

    static func localizedFont(size: CGFloat, weight: Font.Weight = .regular, language: String) -> Font {
        .system(size: localizedFontSize(size, language: language), weight: weight)
    }
}

/// 按下时缩小、松手 Q 弹回弹的按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.05, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
