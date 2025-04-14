//
//  NewRunningProgramSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import SwiftUI

struct NewRunningProgramSelectionView: View {
    @State private var navigateToExperience: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                MarathonCardView()
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        print("Marathon card tapped")
                        navigateToExperience = true
                    }
            }
            // Hidden NavigationLink triggers when navigateToExperience becomes true.
            NavigationLink(
                destination: RunnerExperienceSelectionView()
                                .environmentObject(NewRunningProgramViewModel()),
                isActive: $navigateToExperience,
                label: {
                    EmptyView()
                }
            )
            .hidden() // Hides the link's label
        }
        .padding()
        .navigationTitle("Choose a Running Program")
    }
}

struct NewRunningProgramSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NewRunningProgramSelectionView()
        }
    }
}
