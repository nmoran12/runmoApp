//
//  OnboardingData.swift
//  Runr
//
//  Created by Noah Moran on 22/4/2025.
//

// This class 'OnboardingData' stores all the data collected in the onboarding process of creating a personalised running program so we can modify the running program
// based on this user-inputted data

import SwiftUI
import Foundation

enum ExperienceLevel: String {
  case beginner, intermediate //, advanced
}

enum OnboardingStep: Hashable {
  case experience, age, gender, done
}

enum Gender: String, CaseIterable {
  case female, male, nonBinary = "non‑binary", preferNotToSay = "prefer-not-to-say"

  var displayName: String {
    switch self {
    case .female: return "Female"
    case .male: return "Male"
    case .nonBinary: return "Non‑Binary"
    case .preferNotToSay: return "Prefer not to say"
    }
  }
}

class OnboardingData: ObservableObject {
    @Published var experience: ExperienceLevel?
    @Published var gender: Gender?
    @Published var birthdate: Date?
    @Published var currentStep: OnboardingStep = .experience
  // add raceDistance, raceTime, daysPerWeek, etc. as we add more views to the onboarding process
}
