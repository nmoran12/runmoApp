//
//  TrainingEffectCard.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct TrainingEffectCard: View {
    let teScore: Double
    // In a production app you might pass in historical or average TE data here.
    //let averageTe: Double?

    // Helper to get a descriptive label for the score
    private func descriptionForScore(_ te: Double) -> String {
        switch te {
        case ..<2.0: return "Minor Effect / Recovery"
        case 2.0..<3.0: return "Maintaining Fitness"
        case 3.0..<4.0: return "Improving Fitness"
        case 4.0..<5.0: return "Highly Improving Fitness"
        case 5.0...: return "Overreaching / Max Effort"
        default: return "Intensity Load"
        }
    }

    // Color for the gauge and number
    private func colorForScore(_ te: Double) -> Color {
        switch te {
         case ..<2.0: return .blue
         case 2.0..<3.0: return .green
         case 3.0..<4.0: return .yellow
         case 4.0..<5.0: return .orange
         case 5.0...: return .red
         default: return .gray
        }
    }
    
    // State to control display of the info alert/modal
    @State private var showInfo: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Training Effect")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                // Info button to explain training effect
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .alert(isPresented: $showInfo) {
                    Alert(
                        title: Text("What is Training Effect?"),
                        message: Text("Training Effect is a measure of how much a workout stresses your body. It’s derived from heart rate data, workout duration, and personalized parameters. Lower scores suggest a recovery or maintenance session, while higher scores indicate higher intensity that can lead to fitness improvements or, if too high, overreaching."),
                        dismissButton: .default(Text("Got it!"))
                    )
                }
            }

            // Circular gauge to visualize the TE score on a 1-5 scale
            ZStack {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .foregroundColor(Color(.systemGray5))
                    .rotationEffect(.degrees(-90))
                
                // The dynamic portion of the gauge
                Circle()
                    .trim(from: 0, to: CGFloat(min(teScore / 5.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .foregroundColor(colorForScore(teScore))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: teScore)

                // Display the numeric TE score in the center
                Text(String(format: "%.1f", teScore))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(colorForScore(teScore))
            }
            .frame(width: 120, height: 120)

            // Description below the gauge
            Text(descriptionForScore(teScore))
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Optional additional context:
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
        )
        .padding([.horizontal, .top])
    }
}

// MARK: - Preview
struct TrainingEffectCard_Previews: PreviewProvider {
    static var previews: some View {
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
}
