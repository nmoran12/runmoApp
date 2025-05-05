//
//  RunnerExperienceSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI

struct RunnerExperienceSelectionView: View {
    @EnvironmentObject private var viewModel: NewRunningProgramViewModel
    @EnvironmentObject private var onboardingData: OnboardingData
    let onNext: (ExperienceLevel) -> Void

    // Templates for each experience level
    let beginnerProgram = BeginnerTemplates.createBeginnerProgram(sampleWeeklyPlans: sampleWeeklyPlans)
    let intermediateProgram = IntermediateTemplates.createIntermediateProgram(allWeeks: allWeeks)
    //let advancedProgram = AdvancedTemplates.createAdvancedProgram(allWeeks: allWeeks)

    // Navigation state
    @State private var navigateToAge = false
    @State private var navigateToProgram = false
    @State private var selectedProgram: NewRunningProgram?

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Select Your Experience Level")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 16)

            // Hidden NavigationLinks for flow control
            NavigationLink(
                destination: RunnerAgeSelectionView(onNext: { _ in
                    // After age selection, proceed to program view
                    navigateToProgram = true
                }),
                isActive: $navigateToAge
            ) {
                EmptyView()
            }
            NavigationLink(
                destination: Group {
                    if let program = selectedProgram {
                        NewRunningProgramContentView(plan: program)
                            .environmentObject(viewModel)
                    }
                },
                isActive: $navigateToProgram
            ) {
                EmptyView()
            }

            // Experience Buttons
            Button(action: {
                onboardingData.experience = .beginner
                selectedProgram = beginnerProgram
                navigateToAge = true
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    Text("Beginner Runner")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 12)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .opacity(0.7)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                onboardingData.experience = .intermediate
                selectedProgram = intermediateProgram
                navigateToAge = true
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.run")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Text("Intermediate Runner")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 12)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .opacity(0.7)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                //onboardingData.experience = .advanced
                selectedProgram = advancedProgram
                navigateToAge = true
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    Text("Advanced Runner")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 12)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .opacity(0.7)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .navigationTitle("Runner Experience")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RunnerExperienceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RunnerExperienceSelectionView(onNext: { level in
            })
            .environmentObject(NewRunningProgramViewModel())
            .environmentObject(OnboardingData())
        }
    }
}
