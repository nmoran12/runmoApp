//
//  OnboardingFlowView.swift
//  Runr
//
//  Created by Noah Moran on 5/5/2025.
//


import SwiftUI

struct OnboardingFlowView: View {
  @StateObject private var onboardingData = OnboardingData()
  @EnvironmentObject private var viewModel: NewRunningProgramViewModel
  @State private var path: [OnboardingStep] = []

  var body: some View {
    NavigationStack(path: $path) {
      screen(for: path.last ?? .experience)
        .navigationDestination(for: OnboardingStep.self) { step in
          screen(for: step)
        }
        .onChange(of: onboardingData.currentStep) { newStep in
          guard newStep != .done else {
            // maybe dismiss flow and go to main app
            return
          }
          path.append(newStep)
        }
    }
    .environmentObject(onboardingData)
    .environmentObject(viewModel)
  }

    @ViewBuilder
    private func screen(for step: OnboardingStep) -> some View {
        switch step {
        case .experience:
            RunnerExperienceSelectionView { level in
                onboardingData.experience = level
                onboardingData.currentStep = .age
            }
        case .age:
            RunnerAgeSelectionView { date in
                onboardingData.birthdate = date
                onboardingData.currentStep = .gender
            }
        case .gender:
            RunnerGenderSelectionView()
                .environmentObject(onboardingData)
                .environmentObject(viewModel)
        case .done:
            NewRunningProgramContentView(
                plan: template(for: onboardingData.experience!)
            )
            .environmentObject(viewModel)
        }
    }



  private func template(for level: ExperienceLevel) -> NewRunningProgram {
    switch level {
    case .beginner:    return BeginnerTemplates.createBeginnerProgram(sampleWeeklyPlans: sampleWeeklyPlans)
    case .intermediate:return IntermediateTemplates.createIntermediateProgram(allWeeks: allWeeks)
    //case .advanced:    return AdvancedTemplates.createAdvancedProgram(allWeeks: allWeeks)
    }
  }
}


#Preview {
    OnboardingFlowView()
}
