//
//  DailyTaskWidgetLiveActivity.swift
//  DailyTaskWidget
//
//  Created by Baldwin Kiel Malabanan on 2025-06-14.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DailyTaskWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DailyTaskWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyTaskWidgetAttributes.self) { context in
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

extension DailyTaskWidgetAttributes {
    fileprivate static var preview: DailyTaskWidgetAttributes {
        DailyTaskWidgetAttributes(name: "World")
    }
}

extension DailyTaskWidgetAttributes.ContentState {
    fileprivate static var smiley: DailyTaskWidgetAttributes.ContentState {
        DailyTaskWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DailyTaskWidgetAttributes.ContentState {
         DailyTaskWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DailyTaskWidgetAttributes.preview) {
   DailyTaskWidgetLiveActivity()
} contentStates: {
    DailyTaskWidgetAttributes.ContentState.smiley
    DailyTaskWidgetAttributes.ContentState.starEyes
}
