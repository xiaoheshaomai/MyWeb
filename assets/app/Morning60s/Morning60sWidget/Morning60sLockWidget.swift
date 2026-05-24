import WidgetKit
import SwiftUI

/// 锁屏 Widget：一个静态入口，点一下 → 通过 deep link 直达 60 秒挑战
///
/// 支持家族：
/// - `.accessoryCircular` 小圆圈（锁屏下方）
/// - `.accessoryRectangular` 矩形（锁屏下方 2x1）
/// - `.accessoryInline` 行内文字（锁屏最顶部）
///
/// 内容本身不随时间变化 → 用空 Timeline；iOS 只渲染一次。
struct Morning60sLockWidget: Widget {
    let kind: String = "Morning60sLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Morning60sProvider()) { _ in
            Morning60sLockEntryView()
                // 点 widget 唤起 app，走 morning60s://start → ContentView 直接切到挑战页
                .widgetURL(URL(string: "morning60s://start"))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Morning60s")
        .description("锁屏点一下，直接开始 60 秒起床挑战。")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Timeline

struct Morning60sEntry: TimelineEntry {
    let date: Date
}

struct Morning60sProvider: TimelineProvider {
    func placeholder(in context: Context) -> Morning60sEntry {
        Morning60sEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (Morning60sEntry) -> Void) {
        completion(Morning60sEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Morning60sEntry>) -> Void) {
        // 内容不变，一条 entry + never policy
        let entry = Morning60sEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - View

struct Morning60sLockEntryView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            Text("起床 60s")
        default:
            circular
        }
    }

    private var circular: some View {
        ZStack {
            // AccessoryWidgetBackground 让圆形在锁屏上有毛玻璃底
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("60s")
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 22, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("起床 60 秒")
                    .font(.system(size: 14, weight: .bold))
                Text("点一下，开始挑战")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview(as: .accessoryCircular) {
    Morning60sLockWidget()
} timeline: {
    Morning60sEntry(date: .now)
}

#Preview(as: .accessoryRectangular) {
    Morning60sLockWidget()
} timeline: {
    Morning60sEntry(date: .now)
}
