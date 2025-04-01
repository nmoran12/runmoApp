//
//  LeaderboardsView.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI

// if you ever want to add more leaderboards you have to add it to this list
enum LeaderboardType: String, CaseIterable, Identifiable {
    case totalDistance = "Total Distance"
    case fastest5k = "Fastest 5K"
    case fastest10k = "Fastest 10K"
    case fastestHalfMarathon = "Fastest Half-Marathon"
    case fastestMarathon = "Fastest Marathon"

    
    
    var id: String { self.rawValue }
    
    /// Returns the target distance (in meters) for fastest leaderboards.
    var targetDistance: Double? {
        switch self {
        case .fastest5k:
            return 5000.0
        case .fastest10k:
            return 10_000.0
        case .fastestHalfMarathon:
            return 21_097.5
        case .fastestMarathon:
            return 42_195.0
        default:
            return nil
        }
    }
}



struct LeaderboardsView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var selectedLeaderboardType: LeaderboardType = .fastest5k
    @State private var selectedScope: LeaderboardScope = .global
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme

    
    // Update the leaderboard based on the current type and timeframe.
    // you must update this as well if you add more leaderboards
        private func updateLeaderboard() {
            if let targetDistance = selectedLeaderboardType.targetDistance {
                viewModel.fetchFastestLeaderboard(for: selectedPeriod, targetDistance: targetDistance, scope: selectedScope)
            } else {
                viewModel.fetchLeaderboard(for: selectedPeriod, scope: selectedScope)
            }
        }
    
    // Helper: Return display label for a given scope.
    private func scopeDisplayLabel(for scope: LeaderboardScope) -> String {
        if let user = authService.currentUser {
            switch scope {
            case .local:
                if let city = user.city, !city.isEmpty {
                    print("DEBUG: currentUser city: \(city)")
                    return city
                } else {
                    print("DEBUG: currentUser has no city; defaulting to 'Local'")
                    return "Local"
                }
            case .national:
                if let country = user.country, !country.isEmpty {
                    print("DEBUG: currentUser country: \(country)")
                    return country
                } else {
                    print("DEBUG: currentUser has no country; defaulting to 'National'")
                    return "National"
                }
            case .global:
                return "Global"
            }
        } else {
            print("DEBUG: authService.currentUser is nil; using defaults")
            switch scope {
            case .local:
                return "Local"
            case .national:
                return "National"
            case .global:
                return "Global"
            }
        }
    }


        
        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header Section with Title and Picker Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(selectedLeaderboardType.rawValue) Leaderboard")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Picker Bar: Leaderboard Type (Dropdown) & Period (Segmented)
                        HStack {
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
                    //.background(Color.primary)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // NEW: Segmented control for location scope, using dynamic labels.
                                    HStack {
                                        Picker("Scope", selection: $selectedScope) {
                                            ForEach(LeaderboardScope.allCases) { scope in
                                                Text(scopeDisplayLabel(for: scope))
                                                    .tag(scope)
                                            }
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .onChange(of: selectedScope) { _ in
                                            updateLeaderboard()
                                        }
                                        .padding(.horizontal, 16)
                                    }
                    
                    // Top 3 Users Section
                    if !viewModel.users.isEmpty {
                        VStack {
                            HStack(spacing: 20) {
                                if viewModel.users.count > 1 {
                                    LeaderboardTopUser(user: viewModel.users[1],
                                                       rank: 2,
                                                       leaderboardType: selectedLeaderboardType)
                                }
                                if viewModel.users.count > 0 {
                                    LeaderboardTopUser(user: viewModel.users[0],
                                                       rank: 1,
                                                       isFirst: true,
                                                       leaderboardType: selectedLeaderboardType)
                                }
                                if viewModel.users.count > 2 {
                                    LeaderboardTopUser(user: viewModel.users[2],
                                                       rank: 3,
                                                       leaderboardType: selectedLeaderboardType)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1),
                                radius: colorScheme == .dark ? 6 : 4, x: 0, y: 3)

                        // black.opacity = 0.05 4 0 2
                        .padding(.horizontal)
                    }
                    
                    // Remaining Leaderboard List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.users.indices, id: \.self) { index in
                                if index >= 3 {
                                    ZStack(alignment: .leading) {
                                        // Use a card-like background color that adapts
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.secondarySystemBackground))
                                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1),
                                                    radius: colorScheme == .dark ? 4 : 2, x: 0, y: 2)

                                        LeaderboardsCell(user: viewModel.users[index],
                                                         rank: index + 1,
                                                         leaderboardType: selectedLeaderboardType)
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
        .preferredColorScheme(.dark)
}
