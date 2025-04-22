//
//  RunningGenderSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 22/4/2025.
//

import SwiftUI

struct RunnerGenderSelectionView: View {
  @EnvironmentObject var data: OnboardingData
  @State private var selection: Gender?

  var body: some View {
    VStack(spacing: 20) {
      Text("What’s your gender?")
        .font(.headline)

      ForEach(Gender.allCases, id: \.self) { gender in
        Button {
          selection = gender
        } label: {
          HStack {
            Image(systemName: selection == gender ? "largecircle.fill.circle" : "circle")
            Text(gender.displayName)
          }
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(8)
        }
      }

      Spacer()

      NavigationLink(
        destination: NewRunningProgramContentView(
          plan: makeProgram()
        )
        .environmentObject(NewRunningProgramViewModel()),
        isActive: Binding(
          get: { selection != nil },
          set: { _ in }
        )
      ) {
        Text("Continue")
          .frame(maxWidth: .infinity)
          .padding()
          .background(selection != nil ? Color.blue : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .disabled(selection == nil)
      .onChange(of: selection) { new in
        if let g = new {
          data.gender = g
        }
      }
    }
    .padding()
    .navigationTitle("Your Gender")
  }

  private func makeProgram() -> NewRunningProgram {
    // you can now read data.experience and data.gender,
    // pick your template and set any gender‑specific params.
    switch data.experience! {
      case .beginner:    return BeginnerTemplates.createBeginnerProgram(sampleWeeklyPlans: sampleWeeklyPlans)
      case .intermediate:return IntermediateTemplates.createIntermediateProgram(allWeeks: allWeeks)
      //case .advanced:    return AdvancedTemplates.createAdvancedProgram(allWeeks: allWeeks)
    }
  }
}

#Preview {
    RunnerGenderSelectionView()
}
