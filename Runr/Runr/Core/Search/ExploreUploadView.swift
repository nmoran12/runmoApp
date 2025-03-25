//
//  ExploreUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct ExploreUploadView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Upload Type", selection: $selectedTab) {
                    Text("Blog").tag(0)
                    Text("Running Program").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                TabView(selection: $selectedTab) {
                    BlogUploadView()
                        .tag(0)
                    
                    // Pass the callback to RunningProgramUploadView:
                    RunningProgramUploadView(onProgramCreated: {
                        // This runs AFTER the user successfully uploads a program
                        // and calls onProgramCreated?() from inside RunningProgramUploadView.
                        dismiss() // <--- Dismiss the entire sheet
                    })
                    .tag(1)
                }
                .tabViewStyle(DefaultTabViewStyle())

                Spacer()

                Button("Close") {
                    // If user taps "Close" manually
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}




#Preview {
    ExploreUploadView()
}
