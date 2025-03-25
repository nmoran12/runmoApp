//
//  RunningActivityWidgetLiveActivity.swift
//  RunningActivityWidget
//
//  Created by Noah Moran on 24/3/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RunningActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RunningActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunningActivityWidgetAttributes.self) { context in
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

extension RunningActivityWidgetAttributes {
    fileprivate static var preview: RunningActivityWidgetAttributes {
        RunningActivityWidgetAttributes(name: "World")
    }
}

extension RunningActivityWidgetAttributes.ContentState {
    fileprivate static var smiley: RunningActivityWidgetAttributes.ContentState {
        RunningActivityWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RunningActivityWidgetAttributes.ContentState {
         RunningActivityWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RunningActivityWidgetAttributes.preview) {
   RunningActivityWidgetLiveActivity()
} contentStates: {
    RunningActivityWidgetAttributes.ContentState.smiley
    RunningActivityWidgetAttributes.ContentState.starEyes
}
