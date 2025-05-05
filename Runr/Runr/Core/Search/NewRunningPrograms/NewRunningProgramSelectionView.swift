//
//  NewRunningProgramSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import SwiftUI

struct NewRunningProgramSelectionView: View {
    @EnvironmentObject var viewModel: NewRunningProgramViewModel
    @EnvironmentObject var onboardingData: OnboardingData

    var body: some View {
        VStack(spacing: 24) {
            NavigationLink(
                destination:
                    RunnerExperienceSelectionView(onNext: { level in
                        onboardingData.experience = level
                        onboardingData.currentStep = .age
                    })
            ) {
                MarathonCardView()
                    .frame(maxWidth: .infinity)
            }


            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Start a Program")
                    .font(.system(size: 20, weight: .semibold))
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct NewRunningProgramSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NewRunningProgramSelectionView()
                // ← Inject both env‑objects for the preview
                .environmentObject(NewRunningProgramViewModel())
                .environmentObject(OnboardingData())
        }
    }
}
