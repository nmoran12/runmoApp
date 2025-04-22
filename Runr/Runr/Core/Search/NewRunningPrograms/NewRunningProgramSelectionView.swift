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
            NavigationLink(
                destination: RunnerExperienceSelectionView()
                    .environmentObject(NewRunningProgramViewModel())
            ) {
                MarathonCardView()
                    .frame(maxWidth: .infinity)
            }

            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        //.navigationTitle("Running Programs")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Start a Program")
                    .font(.system(size: 20, weight: .semibold))
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    
    struct NewRunningProgramSelectionView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                NewRunningProgramSelectionView()
            }
        }
    }
}
