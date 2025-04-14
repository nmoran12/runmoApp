//
//  NewRunningProgramSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import SwiftUI

struct NewRunningProgramSelectionView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Wrap the MarathonCardView in a NavigationLink for direct navigation.
            NavigationLink(
                destination: RunnerExperienceSelectionView()
                                .environmentObject(NewRunningProgramViewModel())
            ) {
                MarathonCardView()
                    .frame(maxWidth: .infinity)
            }
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
