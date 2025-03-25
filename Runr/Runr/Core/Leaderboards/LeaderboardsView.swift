//
//  LeaderboardsView.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI

enum LeaderboardType: String, CaseIterable, Identifiable {
    case totalDistance = "Total Distance"
    case fastest5k = "Fastest 5K"
    
    var id: String { self.rawValue }
}

struct LeaderboardsView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var selectedLeaderboardType: LeaderboardType = .fastest5k
    
    // Update the leaderboard based on the current type and timeframe.
    private func updateLeaderboard() {
        switch selectedLeaderboardType {
        case .totalDistance:
            viewModel.fetchLeaderboard(for: selectedPeriod)
        case .fastest5k:
            viewModel.fetchFastest5kLeaderboard(for: selectedPeriod)
        }
    }
    
    var body: some View {
        ZStack {
            // Subtle background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                // Header / Title
                VStack(spacing: 8) {
                    HStack {
                        Text("\(selectedLeaderboardType.rawValue) Leaderboard")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Picker row
                    HStack {
                        // Drop-down menu for Leaderboard Type
                        Picker("Leaderboard Type", selection: $selectedLeaderboardType) {
                            ForEach(LeaderboardType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedLeaderboardType) { _ in
                            updateLeaderboard()
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        // Segmented picker for timeframe
                        Picker("Period", selection: $selectedPeriod) {
                            Text("Weekly").tag(LeaderboardPeriod.weekly)
                            Text("Monthly").tag(LeaderboardPeriod.monthly)
                            Text("Yearly").tag(LeaderboardPeriod.yearly)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedPeriod) { _ in
                            updateLeaderboard()
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.bottom, 10)
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                
                // Top 3 Users Section
                if !viewModel.users.isEmpty {
                    VStack {
                        HStack(spacing: 20) {
                            // 2nd place
                            if viewModel.users.count > 1 {
                                LeaderboardTopUser(user: viewModel.users[1], rank: 2)
                            }
                            // 1st place
                            if viewModel.users.count > 0 {
                                LeaderboardTopUser(user: viewModel.users[0], rank: 1, isFirst: true)
                            }
                            // 3rd place
                            if viewModel.users.count > 2 {
                                LeaderboardTopUser(user: viewModel.users[2], rank: 3)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // Remaining leaderboard
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.users.indices, id: \.self) { index in
                            // If you’re already showing top 3 separately, skip them here
                            if index >= 3 {
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    LeaderboardsCell(user: viewModel.users[index], rank: index + 1)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                }
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: viewModel.users)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
            }
            .padding(.top, 8)
        }
        .onAppear {
            selectedPeriod = .weekly
            updateLeaderboard()
        }
    }
}



#Preview {
    LeaderboardsView()
}
