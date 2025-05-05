//
//  RunnerAgeSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 5/5/2025.
//

import SwiftUI

// A view that allows the user to select their birthdate and calculates their age.
struct RunnerAgeSelectionView: View {
    @EnvironmentObject private var onboardingData: OnboardingData
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var onNext: (Date) -> Void

    // Computed age in years based on the selected birthdate.
    private var age: Int {
        Calendar.current
            .dateComponents([.year], from: birthdate, to: Date())
            .year ?? 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            Text("When were you born?")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Date picker wheel
            DatePicker(
                "Birthdate",
                selection: $birthdate,
                in: Calendar.current.date(byAdding: .year, value: -120, to: Date())!...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            // Display computed age
            Text("You are \(age) years old")
                .font(.headline)

            Spacer()

            // Next button
            Button(action: {
                onNext(birthdate)
                onboardingData.birthdate = birthdate
            }) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(age <= 0)
        }
        .padding(.vertical)
        .navigationTitle("Your Age")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

struct RunnerAgeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RunnerAgeSelectionView { selectedDate in
                // next action
                print("Birthdate selected: \(selectedDate)")
            }
        }
    }
}
