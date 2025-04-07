//
//  RunrTabView.swift
//  Runr
//
//  Created by Noah Moran on 7/1/2025.
//

import SwiftUI

struct RunrTabView: View {
    @State private var selectedIndex = 0
    @EnvironmentObject var runTracker: RunTracker
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        
        
        TabView(selection: $selectedIndex){
            FeedView()
                .onAppear{
                    selectedIndex = 0
                }
                .tabItem{
                    Image(systemName: "house")
                        .foregroundColor(.primary)
                }.tag(0)
            
            
            NewRunningProgramContentView(
                plan: NewRunningProgram(
                    title: "Sample Running Program",
                    raceName: "Boston Marathon 2025",
                    subtitle: "A new running challenge",
                    finishDate: Date(),
                    imageUrl: "https://via.placeholder.com/300",
                    totalDistance: 500,
                    planOverview: "This is a sample overview of the running program. It details the plan and what you can expect.",
                    experienceLevel: "Beginner",
                    weeklyPlan: sampleWeeklyPlans
                )
            )
            .onAppear {
                print("Running Program clicked!")
                selectedIndex = 1
            }

                .tabItem{
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.primary)
                }.tag(1)
            
            
            // Start run button on tab bar
            RunningView()
                .onAppear{
                    print("Run view appeared")
                    selectedIndex = 2
                }
                .tabItem{
                    Image(systemName: "figure.run")
                        .foregroundColor(.primary)
                }.tag(2)
            
            
            // View Leaderboards
            LeaderboardsView()
                .onAppear{
                    selectedIndex = 3
                }
                .tabItem{
                    Image(systemName: "flag.2.crossed.fill")
                        .foregroundColor(.primary)
                }.tag(3)
                .environmentObject(authService)
            
            CurrentUserProfileView()
                .onAppear{
                    selectedIndex = 4
                }
                .environmentObject(authService)
                .tabItem{
                    Image(systemName: "person")
                        .foregroundColor(.primary)
                }.tag(4)
        }
        .accentColor(.primary)
    }
}

#Preview {
    RunrTabView()
}
