//
//  TrainingEffectCard.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct TrainingEffectCard: View {
    let teScore: Double

    // Helper to get a descriptive label for the score
    private func descriptionForScore(_ te: Double) -> String {
        switch te {
        case ..<2.0: return "Minor Effect / Recovery"
        case 2.0..<3.0: return "Maintaining Fitness"
        case 3.0..<4.0: return "Improving Fitness"
        case 4.0..<5.0: return "Highly Improving Fitness"
        case 5.0...: return "Overreaching / Max Effort" // Handle score of 5.0 or slightly above
        default: return "Intensity Load" // Fallback
        }
    }

    // Helper for color remains the same
    private func colorForScore(_ te: Double) -> Color {
        switch te {
         case ..<2.0: return .blue // Use blue for recovery? Or keep green
         case 2.0..<3.0: return .green // Maintaining
         case 3.0..<4.0: return .yellow // Improving
         case 4.0..<5.0: return .orange // Highly Improving
         case 5.0...: return .red    // Overreaching
         default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 8) { // Add spacing
            Text("Training Effect")
                .font(.headline)
                .foregroundColor(.secondary) // Subdue the title slightly

            Text(String(format: "%.1f", teScore))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(colorForScore(teScore)) // Color the score

            // Use the dynamic description
            Text(descriptionForScore(teScore))
                .font(.subheadline)
                .foregroundColor(.primary) // Make description primary
                .multilineTextAlignment(.center) // Center if it wraps

        }
        // Keep padding and background consistent with SectionContainer or standalone style
        // If used within SectionContainer, these modifiers might not be needed here.
        // If used standalone:
         .padding()
         .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground)) // Use adaptive bg
                         .shadow(radius: 3, x: 0, y: 1)) // Subtle shadow
    }
}

// Preview for testing different scores
#Preview {
    VStack(spacing: 20) {
        TrainingEffectCard(teScore: 1.5)
        TrainingEffectCard(teScore: 2.8)
        TrainingEffectCard(teScore: 3.9)
        TrainingEffectCard(teScore: 4.7)
        TrainingEffectCard(teScore: 5.0)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
