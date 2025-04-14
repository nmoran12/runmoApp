//
//  RunLiveActivityWidgetBundle.swift
//  RunLiveActivityWidget
//
//  Created by Noah Moran on 14/4/2025.
//

import WidgetKit
import SwiftUI

@main
struct RunLiveActivityWidgetBundle: WidgetBundle {
    @available(iOSApplicationExtension 18.0, *)
    var body: some Widget {
        RunLiveActivityWidget()
        RunLiveActivityWidgetControl()
        RunLiveActivityWidgetLiveActivity()
    }
}
