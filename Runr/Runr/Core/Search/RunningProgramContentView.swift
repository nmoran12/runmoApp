//
//  RunningProgramDetailView.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI

// MARK: - Data Models

/// Represents a single week's plan in your program.
struct WeeklyPlan: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let title: String
    let details: String
}

/// Represents the entire running program, including metadata and weekly plans.
struct RunningProgram {
    let title: String
    let subtitle: String
    let imageUrl: String
    let planOverview: String
    let experienceLevel: String
    let weeklyPlans: [WeeklyPlan]
}

/// If you're using ExploreFeedItem or similar, you can map fields here.
extension RunningProgram {
    init(from item: ExploreFeedItem) {
        self.title = item.title
        // Provide any default or derived value for the subtitle:
        self.subtitle = "Subtitle here"
        self.imageUrl = item.imageUrl
        // Map the content or provide a default:
        self.planOverview = item.content
        // Provide a default or derive from item:
        self.experienceLevel = "Beginner"
        // If ExploreFeedItem doesn’t have weekly plan info, use an empty array or sample data:
        self.weeklyPlans = []
    }
}

// MARK: - Main View

struct RunningProgramContentView: View {
    let program: RunningProgram

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // MARK: - Hero Image (60% screen height)
                AsyncImage(url: URL(string: program.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill() // Fill while keeping aspect ratio
                    case .failure:
                        Color.red
                            .overlay(
                                Text("Image failed to load")
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: UIScreen.main.bounds.width,
                       height: UIScreen.main.bounds.height * 0.6)
                .clipped()
                
                // MARK: - Title & Subtitle
                VStack(alignment: .leading, spacing: 16) {
                    Text(program.title)
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                    
                    Text(program.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // MARK: - Plan Overview
                Text("Plan Overview")
                    .fontWeight(.semibold)
                    .font(.system(size: 20))
                    .padding(.horizontal, 10)
                
                Spacer()
                
                Text(program.planOverview)
                    .font(.body)
                    .padding(.horizontal)
                
                Spacer()
                
                // MARK: - Experience Level
                Text("Experience Level")
                    .fontWeight(.semibold)
                    .font(.system(size: 20))
                    .padding(.horizontal)
                
                Spacer()
                
                Text(program.experienceLevel)
                    .font(.body)
                    .padding(.horizontal)
                
                // MARK: - Weekly Plans
                ForEach(program.weeklyPlans) { weeklyPlan in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Week \(weeklyPlan.weekNumber): \(weeklyPlan.title)")
                            .font(.headline)
                        
                        Text(weeklyPlan.details)
                            .font(.body)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Divider between weeks
                    Divider()
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 32)
            }
            // No .padding(.top) here
        }
        // Make the image go under the navigation bar (ignore top safe area)
        .ignoresSafeArea(edges: .top)
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct RunningProgramContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        // Example Weekly Plans
        let weeklyPlans = [
            WeeklyPlan(weekNumber: 1,
                       title: "Welcome to the Starting Line",
                       details: """
2 Recovery/Easy Runs
2 Speed Runs: Intervals
1 Long Run (1.5–3 miles)
"""),
            WeeklyPlan(weekNumber: 2,
                       title: "Set Good Habits",
                       details: """
2 Recovery/Easy Runs
2 Speed Runs: Intervals
1 Long Run (3–4 miles)
"""),
            WeeklyPlan(weekNumber: 3,
                       title: "Develop Consistency",
                       details: """
2 Recovery/Easy Runs
2 Speed Runs: Fartlek
1 Long Run (4–5 miles)
""")
        ]
        
        let program = RunningProgram(
            title: "5K Beginner Plan",
            subtitle: "Up to 5 runs a week, 8 weeks total",
            imageUrl: "https://via.placeholder.com/500",
            planOverview: """
This training plan is built to help you reach the starting line of your 5K. 
We recommend you begin this programme with no more than 4 weeks to go before your race date.
""",
            experienceLevel: """
We offer up to 5 runs each week. We recommend that you do at least 3 runs per week 
and have worked up to a consistent running routine before starting.
""",
            weeklyPlans: weeklyPlans
        )
        
        NavigationView {
            RunningProgramContentView(program: program)
        }
    }
}


