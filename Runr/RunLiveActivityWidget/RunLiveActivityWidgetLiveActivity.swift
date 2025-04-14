//
//  RunLiveActivityWidgetLiveActivity.swift
//  RunLiveActivityWidget
//
//  Created by Noah Moran on 14/4/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RunLiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RunLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunLiveActivityWidgetAttributes.self) { context in
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

extension RunLiveActivityWidgetAttributes {
    fileprivate static var preview: RunLiveActivityWidgetAttributes {
        RunLiveActivityWidgetAttributes(name: "World")
    }
}

extension RunLiveActivityWidgetAttributes.ContentState {
    fileprivate static var smiley: RunLiveActivityWidgetAttributes.ContentState {
        RunLiveActivityWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RunLiveActivityWidgetAttributes.ContentState {
         RunLiveActivityWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RunLiveActivityWidgetAttributes.preview) {
   RunLiveActivityWidgetLiveActivity()
} contentStates: {
    RunLiveActivityWidgetAttributes.ContentState.smiley
    RunLiveActivityWidgetAttributes.ContentState.starEyes
}
