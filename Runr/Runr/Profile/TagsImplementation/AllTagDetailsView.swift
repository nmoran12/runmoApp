//
//  AllTagDetailsView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

// MARK: - TagDetailRowView

struct TagDetailRowView: View {
    let tag: String
    let detail: (icon: String, description: String)
    let gradient: LinearGradient?
    
    var body: some View {
        HStack(spacing: 12) {
            // Display the tag "badge" with its gradient background.
            Text(tag)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(gradient ?? LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))

                .cornerRadius(8)
            
            // Display the description.
            Text(detail.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .id(tag) // For scrolling
    }
}

// MARK: - AllTagDetailsView

struct AllTagDetailsView: View {
    let selectedTag: String?
    let tagGradientColors: [String: GradientTagColor]
    
    // Define tag details.
    let tagDetails: [String: (icon: String, description: String)] = [
        "Ultra Legend": ("crown.fill", "Earned by completing a 100 km run in under 12 hours."),
        "Elite Marathoner": ("trophy.fill", "Earned by completing a marathon in under 2 hours 30 minutes."),
        "10K Runner": ("figure.run.circle.fill", "Earned by achieving an equivalent 10K time under 40 minutes."),
        "Veteran Runner": ("star.fill", "Earned by completing 50 or more runs."),
        "Marathon Runner": ("flag.checkered", "Earned by completing at least one run of 42,195 meters."),
        "5K Speed Demon": ("bolt.fill", "Earned by achieving an equivalent 5K time under 15 minutes."),
        "Pace Setter": ("speedometer", "Earned by maintaining an overall average pace under 5 minutes per km (with at least 10 runs)."),
        "Consistent Runner": ("calendar.badge.clock", "Earned by running on 7 or more distinct days."),
        "Distance Dominator": ("ruler.fill", "Earned by accumulating at least 1,000 km total distance.")
    ]
    
    // Define rarity order (lower number = more rare).
    let rarityOrder: [String: Int] = [
        "Ultra Legend": 1,
        "Elite Marathoner": 1,
        "10K Runner": 2,
        "Veteran Runner": 2,
        "Marathon Runner": 3,
        "5K Speed Demon": 3,
        "Pace Setter": 3,
        "Consistent Runner": 4,
        "Distance Dominator": 5
    ]
    
    var body: some View {
        // Compute the sorted tags as a local constant.
        let sorted = tagDetails.keys.sorted { tag1, tag2 in
            (rarityOrder[tag1] ?? Int.max) < (rarityOrder[tag2] ?? Int.max)
        }
        
        return NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(sorted, id: \.self) { tag in
                        if let detail = tagDetails[tag] {
                            TagDetailRowView(
                                tag: tag,
                                detail: detail,
                                gradient: tagGradientColors[tag]?.gradient
                            )
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Tag Details")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    // Scroll to the selected tag if provided.
                    if let selectedTag = selectedTag {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                proxy.scrollTo(selectedTag, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AllTagDetailsView_Previews: PreviewProvider {
    // Define a constant preview dictionary.
    static let previewTagGradientColors: [String: GradientTagColor] = [
        "Ultra Legend": GradientTagColor(
            startColor: Color(#colorLiteral(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)),
            endColor: Color(#colorLiteral(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0))
        ),
        "Elite Marathoner": GradientTagColor(
            startColor: .yellow,
            endColor: .orange
        ),
        "Marathon Runner": GradientTagColor(
            startColor: .blue,
            endColor: .green
        )
        // Add additional entries as needed.
    ]
    
    static var previews: some View {
        AllTagDetailsView(
            selectedTag: "Marathon Runner",
            tagGradientColors: previewTagGradientColors
        )
    }
}

