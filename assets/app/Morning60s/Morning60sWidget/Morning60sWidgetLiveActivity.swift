//
//  Morning60sWidgetLiveActivity.swift
//  Morning60sWidget
//
//  Created by 小和烧麦 on 2026/4/17.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Morning60sWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Morning60sWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Morning60sWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Morning60sWidgetAttributes {
    fileprivate static var preview: Morning60sWidgetAttributes {
        Morning60sWidgetAttributes(name: "World")
    }
}

extension Morning60sWidgetAttributes.ContentState {
    fileprivate static var smiley: Morning60sWidgetAttributes.ContentState {
        Morning60sWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Morning60sWidgetAttributes.ContentState {
         Morning60sWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Morning60sWidgetAttributes.preview) {
   Morning60sWidgetLiveActivity()
} contentStates: {
    Morning60sWidgetAttributes.ContentState.smiley
    Morning60sWidgetAttributes.ContentState.starEyes
}
