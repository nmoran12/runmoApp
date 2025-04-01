//
//  FloatingActionButtonsView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

struct FloatingActionButtonsView: View {
    @Binding var isRunning: Bool
    @Binding var showPostRunDetails: Bool
    @Binding var selectedFootwear: String
    
    /// Action to perform when the calendar button is tapped.
    var calendarAction: () -> Void
    /// Action to perform when the goal setting button is tapped.
    var goalsAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Calendar button always shown.
            CalendarButtonView {
                calendarAction()
            }
            
            // Goals button always shown.
            GoalsButtonView {
                goalsAction()
            }
            
            // Footwear button only shown if not running and not showing post-run details.
            if !isRunning && !showPostRunDetails {
                FootwearButtonView(selectedFootwear: $selectedFootwear)
            }
        }
    }
}

// A simple Goals button styled similarly to your Calendar button.
struct GoalsButtonView: View {
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: "target")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: Color.primary.opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }
}

#Preview {
    @State var previewIsRunning = false
    @State var previewShowPostRunDetails = false
    @State var previewFootwear = "Select Footwear"
    
    return FloatingActionButtonsView(
        isRunning: $previewIsRunning,
        showPostRunDetails: $previewShowPostRunDetails,
        selectedFootwear: $previewFootwear
    ) {
        print("Calendar tapped!")
    } goalsAction: {
        print("Goals tapped!")
    }
}



