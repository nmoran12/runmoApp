//
//  ShowCurrentDayPlanView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI

struct ShowCurrentDayPlanView: View {
    @EnvironmentObject var viewModel: NewRunningProgramViewModel

    var body: some View {
        Group {
            if let todayPlan = viewModel.getTodaysDailyPlan() {
                // Wrap content in an HStack with a left accent bar:
                HStack(spacing: 0) {
                    // Accent bar for prominence
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 8)
                        .cornerRadius(4)
                    
                    // Main content card for today's plan
                    HStack(spacing: 12) {
                        if todayPlan.dailyDistance > 0 {
                            // Run day details
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Today: \(todayPlan.day)")
                                    .font(.title3) // increased for prominence
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Text("Run Type:")
                                        .font(.subheadline)
                                    Text(todayPlan.dailyRunType ?? "Unknown")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Distance:")
                                        .font(.subheadline)
                                    Text("\(todayPlan.dailyDistance, specifier: "%.1f") km")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                        } else {
                            // Rest day details
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Today: \(todayPlan.day)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Rest Day")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // Play button appears on run days only.
                        if todayPlan.dailyDistance > 0 {
                            NavigationLink(destination: RunningView(targetDistance: todayPlan.dailyDistance)
                                            .environmentObject(viewModel)) {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            } else {
                // For a rest day with no specific plan, add an accent bar as well.
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 8)
                        .cornerRadius(4)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .padding(.leading, 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rest Day")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("Take a rest, stretch a bit and get ready for the next day.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                        
                        Spacer()
                    }
                    .background(Color.white)
                    .cornerRadius(12, corners: [.topRight, .bottomRight])
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            }
        }
    }
}


// Custom corner radius for my showcurrentdayplanview card
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        self.clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}



struct ShowCurrentDayPlanView_Previews: PreviewProvider {
    static var previews: some View {
        // Create dummy daily plans for preview:
        let dummyRunPlan = DailyPlan(
            day: "Wednesday",
            date: Date(), // Assume today
            distance: 7.5,
            runType: "Tempo",
            estimatedDuration: "35:00",
            workoutDetails: nil,
            isCompleted: false
        )
        
        let dummyRestPlan = DailyPlan(
            day: "Wednesday",
            date: Date(), // Assume today
            distance: 0.0,
            runType: nil,
            estimatedDuration: nil,
            workoutDetails: nil,
            isCompleted: false
        )
        
        // For preview, create a view model instance and set the override.
        let viewModel = NewRunningProgramViewModel()
        // Uncomment one of the lines below to preview a run day or a rest day.
        viewModel.todaysDailyPlanOverride = dummyRunPlan   // Run day preview.
        // viewModel.todaysDailyPlanOverride = dummyRestPlan  // Rest day preview.
        
        return ShowCurrentDayPlanView()
            .environmentObject(viewModel)
            .previewLayout(.sizeThatFits)
    }
}
