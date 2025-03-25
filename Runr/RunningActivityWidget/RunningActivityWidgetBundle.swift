//
//  RunningActivityWidgetBundle.swift
//  RunningActivityWidget
//
//  Created by Noah Moran on 24/3/2025.
//

import WidgetKit
import SwiftUI

@main
struct RunningActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        RunningActivityWidget()
        RunningActivityWidgetControl()
        RunningActivityWidgetLiveActivity()
    }
}
