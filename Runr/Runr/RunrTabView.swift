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
                }.tag(0)
            
            RunrSearchView()
                .onAppear{
                    print("Search clicked")
                    selectedIndex = 1
                }
                .tabItem{
                    Image(systemName: "magnifyingglass")
                }.tag(1)
            
            
            // Start run button on tab bar
            RunView()
                .onAppear{
                    print("Run view appeared")
                    selectedIndex = 2
                }
                .tabItem{
                    Image(systemName: "figure.run")
                }.tag(2)
            
            
            // View Leaderboards
            LeaderboardsView()
                .onAppear{
                    selectedIndex = 3
                }
                .tabItem{
                    Image(systemName: "flag.2.crossed.fill")
                }.tag(3)
            
            CurrentUserProfileView()
                .onAppear{
                    selectedIndex = 4
                }
                .environmentObject(authService)
                .tabItem{
                    Image(systemName: "person")
                }.tag(4)
        }
        .accentColor(.black)
    }
}

#Preview {
    RunrTabView()
}
