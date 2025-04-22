//
//  OnboardingData.swift
//  Runr
//
//  Created by Noah Moran on 22/4/2025.
//

import SwiftUI
import Foundation

enum ExperienceLevel: String {
  case beginner, intermediate //, advanced
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
  // …later you can add raceDistance, raceTime, daysPerWeek, etc.
}
