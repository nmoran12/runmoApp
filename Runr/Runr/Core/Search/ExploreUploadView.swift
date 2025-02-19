//
//  ExploreUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct ExploreUploadView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0 // 🔹 Track selected tab

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
                    BlogUploadView() // 🔹 Blog Upload Screen
                        .tag(0)

                    RunningProgramUploadView() // 🔹 Running Program Upload Screen
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Spacer()
                
                Button("Close") {
                    dismiss() // 🔹 Dismiss modal
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
