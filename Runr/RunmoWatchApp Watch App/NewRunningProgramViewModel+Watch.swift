//
//  NewRunningProgramViewModel+Watch.swift
//  RunmoWatchApp Watch App
//
//  Created by Noah Moran on 9/4/2025.
//

import Foundation
import SwiftUI

final class NewRunningProgramViewModel: ObservableObject {
    @Published var someValue: Int = 0

    init() {
        // Minimal functionality for watchOS.
        print("Initialized stub NewRunningProgramViewModel for watchOS")
    }
    
    // Provide stub implementations for any functions
    // that the iOS version offers if they are referenced by your UI.
    func doSomething() {
        // No-op or minimal behavior.
    }
}
