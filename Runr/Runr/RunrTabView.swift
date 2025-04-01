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
            
            
            ExploreView()
                .onAppear{
                    print("Search clicked")
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
