import WidgetKit
import SwiftUI

/// Widget extension 的 @main 入口。
///
/// 目前真正上线的是 `Morning60sLockWidget`（锁屏一键起床）。
/// `Morning60sWidgetControl` / `Morning60sWidgetLiveActivity` 是 Xcode 建 target 时
/// 自动生成的脚手架，先留着占位，不影响 Lock Widget 的功能。
@main
struct Morning60sWidgetBundle: WidgetBundle {
    var body: some Widget {
        Morning60sLockWidget()
        Morning60sWidgetLiveActivity()
    }
}
