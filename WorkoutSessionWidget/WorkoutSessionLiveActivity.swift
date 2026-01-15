//
//  WorkoutSessionLiveActivity.swift
//  WorkoutSessionWidget
//
//  Created by Sebastian Sciuba on 15/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WorkoutSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutSessionAttributes.self) { context in
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

extension WorkoutSessionAttributes {
    fileprivate static var preview: WorkoutSessionAttributes {
        WorkoutSessionAttributes(name: "World")
    }
}

extension WorkoutSessionAttributes.ContentState {
    fileprivate static var smiley: WorkoutSessionAttributes.ContentState {
        WorkoutSessionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WorkoutSessionAttributes.ContentState {
         WorkoutSessionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WorkoutSessionAttributes.preview) {
   WorkoutSessionLiveActivity()
} contentStates: {
    WorkoutSessionAttributes.ContentState.smiley
    WorkoutSessionAttributes.ContentState.starEyes
}
