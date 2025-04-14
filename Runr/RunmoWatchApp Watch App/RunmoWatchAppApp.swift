//
//  RunmoWatchAppApp.swift
//  RunmoWatchApp Watch App
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI

@main
struct RunmoWatchApp_Watch_AppApp: App {
    @StateObject var runningProgramViewModel = NewRunningProgramViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(runningProgramViewModel)
        }
    }
}
