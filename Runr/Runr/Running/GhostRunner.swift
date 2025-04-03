//
//  GhostRunner.swift
//  Runr
//
//  Created by Noah Moran on 1/4/2025.
//

// MARK: - GhostRunner.swift
// This file defines the GhostRunner model and manager

import Foundation
import CoreLocation
import SwiftUI
import Firebase

// Main model for a ghost runner
struct GhostRunner: Identifiable, Hashable {
    let id: String
    let name: String
    let runData: RunData
    let type: GhostRunnerType
    var color: Color
    var profileImageUrl: String?
    
    // Used for tracking progress during a live run
    var currentIndex: Int = 0
    var isActive: Bool = true
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GhostRunner, rhs: GhostRunner) -> Bool {
        lhs.id == rhs.id
    }
}

// Different types of ghost runners
enum GhostRunnerType: String, CaseIterable {
    case previousRun = "Your Previous Run"
    case friend = "Friend's Run"
    case personal = "Personal Best"
    case famous = "Famous Runner"
    
    var icon: String {
        switch self {
        case .previousRun: return "clock.arrow.circlepath"
        case .friend: return "person.2"
        case .personal: return "trophy"
        case .famous: return "star"
        }
    }
}

// Color options for ghost runners
extension Color {
    static let ghostRunnerColors: [Color] = [
        .blue, .green, .red, .orange, .purple, .pink, .yellow, .mint
    ]
}

// Manager class to handle ghost runners
class GhostRunnerManager: ObservableObject {
    @Published var selectedGhostRunners: [GhostRunner] = []
    @Published var availableGhostRunners: [GhostRunner] = []
    @Published var isShowingSelection = false
    
    // Famous runners data - could be expanded or fetched from a database
    let famousRunners = [
        (name: "Eliud Kipchoge", pace: 170.0, distance: 42195.0),
        (name: "Mo Farah", pace: 225.0, distance: 10000.0),
        (name: "Usain Bolt", pace: 100.0, distance: 1000.0)
    ]
    
    private var db = Firestore.firestore()
    
    // Load available ghost runners
    func loadAvailableGhostRunners() async {
        await loadPreviousRuns()
        await loadFriendsRuns()
        await loadPersonalBests()   // new
        loadFamousRuns()
    }
    
    /// Call this function periodically with the current elapsed time.
    func updateSelectedGhostRunnerPositions(elapsedTime: TimeInterval) {
        for index in selectedGhostRunners.indices {
            var ghost = selectedGhostRunners[index]
            let totalPoints = ghost.runData.routeCoordinates.count
            // Calculate progress percentage (clamped to 1.0)
            let progressPercentage = min(elapsedTime / ghost.runData.elapsedTime, 1.0)
            // Compute new index
            let targetIndex = Int(Double(totalPoints - 1) * progressPercentage)
            ghost.currentIndex = min(targetIndex, totalPoints - 1)
            // Mark as finished if needed
            if targetIndex >= totalPoints - 1 {
                ghost.isActive = false
            }
            // Reassign updated ghost back into the array so the @Published property is updated.
            selectedGhostRunners[index] = ghost
        }
    }

    
    func loadPersonalBests() async {
        guard let currentUserId = AuthService.shared.userSession?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserId)
        
        do {
            let userDoc = try await userRef.getDocument()
            guard let data = userDoc.data(),
                  let personalBests = data["personalBests"] as? [String: Any] else {
                return
            }
            
            var bestGhostRunners: [GhostRunner] = []
            
            // For each key in personalBests, parse into a RunData
            for (key, value) in personalBests {
                guard let bestData = value as? [String: Any],
                      let distance = bestData["distance"] as? Double,
                      let elapsedTime = bestData["elapsedTime"] as? Double,
                      let date = bestData["date"] as? Timestamp,
                      let coords = bestData["routeCoordinates"] as? [[String: Double]] else {
                    continue
                }
                
                let route = coords.map {
                    CLLocationCoordinate2D(latitude: $0["latitude"] ?? 0.0,
                                           longitude: $0["longitude"] ?? 0.0)
                }
                
                // Create a RunData
                let runData = RunData(
                    date: date.dateValue(),
                    distance: distance,
                    elapsedTime: elapsedTime,
                    routeCoordinates: route
                )
                
                // Convert the key into a nice display name if desired:
                let displayName = displayNameForPBKey(key)
                
                // Create a ghost runner
                let ghostRunner = GhostRunner(
                    id: "personal-\(key)",
                    name: displayName,
                    runData: runData,
                    type: .personal,
                    color: .yellow
                )
                
                bestGhostRunners.append(ghostRunner)
            }
            
            // Add them to availableGhostRunners
            DispatchQueue.main.async {
                self.availableGhostRunners += bestGhostRunners
            }
        } catch {
            print("DEBUG: Error loading personalBests: \(error.localizedDescription)")
        }
    }

    // Helper function to map your PB keys to a user-friendly name
    private func displayNameForPBKey(_ key: String) -> String {
        switch key {
        case "fastest5k": return "Fastest 5K"
        case "fastest10k": return "Fastest 10K"
        case "fastestHalf": return "Fastest Half Marathon"
        case "fastestMarathon": return "Fastest Marathon"
        case "fastestPace": return "Fastest Pace"
        case "longestRun": return "Longest Run"
        default: return "Your Personal Best"
        }
    }

    
    // Load the user's previous runs
    private func loadPreviousRuns() async {
        do {
            let runs = try await AuthService.shared.fetchUserRuns()
            // Sort by date descending, so most recent first
            let sortedRuns = runs.sorted { $0.date > $1.date }
            
            var previousGhosts: [GhostRunner] = []
            
            for run in sortedRuns {
                // Convert each run into a GhostRunner of type .previousRun
                let ghostRunner = GhostRunner(
                    id: "previous-\(run.id)",
                    name: formatRunName(distance: run.distance, date: run.date),
                    runData: run,
                    type: .previousRun,
                    color: Color.ghostRunnerColors.randomElement() ?? .blue
                )
                
                previousGhosts.append(ghostRunner)
            }
            
            DispatchQueue.main.async {
                self.availableGhostRunners += previousGhosts
            }
        } catch {
            print("DEBUG: Failed to load previous runs: \(error.localizedDescription)")
        }
    }

    
    // Load runs from friends (users the current user follows)
    private func loadFriendsRuns() async {
        guard let currentUserId = AuthService.shared.userSession?.uid else { return }
        
        do {
            let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
            guard let following = currentUserDoc.data()?["following"] as? [String] else { return }
            
            var friendGhostRunners: [GhostRunner] = []
            
            for friendId in following.prefix(5) {
                let user = try await AuthService.shared.fetchUser(for: friendId)
                let runs = try await AuthService.shared.fetchUserRuns(for: friendId)
                
                if let latestRun = runs.max(by: { $0.date < $1.date }) {
                    let ghostRunner = GhostRunner(
                        id: "friend-\(friendId)-\(latestRun.id)",
                        name: "\(user.username)'s Run",
                        runData: latestRun,
                        type: .friend,
                        color: Color.ghostRunnerColors.randomElement() ?? .green,
                        profileImageUrl: user.profileImageUrl
                    )
                    
                    friendGhostRunners.append(ghostRunner)
                }
            }
            
            DispatchQueue.main.async {
                self.availableGhostRunners += friendGhostRunners
            }
        } catch {
            print("DEBUG: Failed to load friends' runs: \(error.localizedDescription)")
        }
    }
    
    // Load simulated famous runners data
    private func loadFamousRuns() {
        var famousGhostRunners: [GhostRunner] = []
        
        for (index, runner) in famousRunners.enumerated() {
            let startCoord = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
            let endCoord = CLLocationCoordinate2D(latitude: 40.7128 + 0.01 * Double(index + 1),
                                                 longitude: -74.0060 + 0.01 * Double(index + 1))
            
            let numPoints = 100
            var coordinates: [CLLocationCoordinate2D] = []
            
            for i in 0..<numPoints {
                let fraction = Double(i) / Double(numPoints - 1)
                let lat = startCoord.latitude + fraction * (endCoord.latitude - startCoord.latitude)
                let lon = startCoord.longitude + fraction * (endCoord.longitude - startCoord.longitude)
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            
            let runData = RunData(
                date: Date(),
                distance: runner.distance,
                elapsedTime: runner.distance / runner.pace,
                routeCoordinates: coordinates
            )
            
            let ghostRunner = GhostRunner(
                id: "famous-\(index)",
                name: runner.name,
                runData: runData,
                type: .famous,
                color: Color.ghostRunnerColors[index % Color.ghostRunnerColors.count]
            )
            
            famousGhostRunners.append(ghostRunner)
        }
        
        DispatchQueue.main.async {
            self.availableGhostRunners += famousGhostRunners
        }
    }
    
    private func formatRunName(distance: Double, date: Date) -> String {
        let distanceKm = distance / 1000
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return String(format: "%.1f km - %@", distanceKm, formatter.string(from: date))
    }
    
    func toggleGhostRunner(_ runner: GhostRunner) {
        if selectedGhostRunners.contains(where: { $0.id == runner.id }) {
            selectedGhostRunners.removeAll { $0.id == runner.id }
        } else {
            if selectedGhostRunners.count < 3 {
                selectedGhostRunners.append(runner)
            }
        }
    }
    
    func resetForNewRun() {
        for i in 0..<selectedGhostRunners.count {
            selectedGhostRunners[i].currentIndex = 0
            selectedGhostRunners[i].isActive = true
        }
    }
    
    func clearSelections() {
        selectedGhostRunners.removeAll()
    }
}

// MARK: - GhostRunButtonView
// Advanced ghost runner button with active indicator

struct GhostRunButtonView: View {
    var action: () -> Void
    @Binding var hasActiveGhostRunners: Bool

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.primary.opacity(0.3), radius: 3, x: 0, y: 1)
                
                if hasActiveGhostRunners {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .offset(x: 12, y: -12)
                }
            }
        }
    }
}

// MARK: - GhostRunnerSelectionView.swift
// View for selecting ghost runners

import SwiftUI

struct GhostRunnerSelectionView: View {
    @ObservedObject var ghostRunnerManager: GhostRunnerManager
    @State private var selectedType: GhostRunnerType? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with types of ghost runners
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(GhostRunnerType.allCases, id: \.self) { type in
                            GhostTypeButton(
                                type: type,
                                isSelected: selectedType == type
                            )
                            .onTapGesture {
                                withAnimation {
                                    if selectedType == type {
                                        selectedType = nil
                                    } else {
                                        selectedType = type
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading Ghost Runners...")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    // List of ghost runners
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if ghostRunnerManager.availableGhostRunners.isEmpty {
                                Text("No ghost runners available")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(filteredGhostRunners) { runner in
                                    GhostRunnerCard(
                                        ghostRunner: runner,
                                        isSelected: ghostRunnerManager.selectedGhostRunners.contains(where: { $0.id == runner.id }),
                                        onSelect: {
                                            ghostRunnerManager.toggleGhostRunner(runner)
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Selected ghost runners
                    VStack(alignment: .leading) {
                        Text("Selected Ghost Runners (\(ghostRunnerManager.selectedGhostRunners.count)/3)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ghostRunnerManager.selectedGhostRunners) { runner in
                                    VStack {
                                        Circle()
                                            .fill(runner.color)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "figure.run")
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(runner.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .frame(width: 80)
                                    }
                                    .onTapGesture {
                                        ghostRunnerManager.toggleGhostRunner(runner)
                                    }
                                }
                                
                                if ghostRunnerManager.selectedGhostRunners.isEmpty {
                                    Text("No ghost runners selected")
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 80)
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
            .navigationTitle("Ghost Runners")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
            .task {
                await ghostRunnerManager.loadAvailableGhostRunners()
                isLoading = false
            }
        }
    }
    
    // Filter ghost runners by selected type
    private var filteredGhostRunners: [GhostRunner] {
        guard let selectedType = selectedType else {
            return ghostRunnerManager.availableGhostRunners
        }
        
        return ghostRunnerManager.availableGhostRunners.filter { $0.type == selectedType }
    }
}

// Type selection button
struct GhostTypeButton: View {
    let type: GhostRunnerType
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
                .clipShape(Circle())
            
            Text(type.rawValue)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .primary)
        }
    }
}

// Individual ghost runner card
struct GhostRunnerCard: View {
    let ghostRunner: GhostRunner
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Runner icon/image
            ZStack {
                if let profileImageUrl = ghostRunner.profileImageUrl, !profileImageUrl.isEmpty {
                    AsyncImage(url: URL(string: profileImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(ghostRunner.color, lineWidth: 2)
                    )
                } else {
                    Circle()
                        .fill(ghostRunner.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "figure.run")
                                .font(.system(size: 24))
                                .foregroundColor(ghostRunner.color)
                        )
                }
            }
            
            // Runner details
            VStack(alignment: .leading, spacing: 4) {
                Text(ghostRunner.name)
                    .font(.headline)
                
                HStack {
                    // Distance
                    Label(
                        String(format: "%.1f km", ghostRunner.runData.distance / 1000),
                        systemImage: "ruler"
                    )
                    .font(.caption)
                    
                    Spacer()
                    
                    // Pace
                    let paceInSeconds = ghostRunner.runData.elapsedTime / (ghostRunner.runData.distance / 1000)
                    let paceMinutes = Int(paceInSeconds) / 60
                    let paceSeconds = Int(paceInSeconds) % 60
                    
                    Label(
                        String(format: "%d:%02d /km", paceMinutes, paceSeconds),
                        systemImage: "speedometer"
                    )
                    .font(.caption)
                }
                
                // Time
                let hours = Int(ghostRunner.runData.elapsedTime) / 3600
                let minutes = (Int(ghostRunner.runData.elapsedTime) % 3600) / 60
                let seconds = Int(ghostRunner.runData.elapsedTime) % 60
                
                if hours > 0 {
                    Text(String(format: "Time: %d:%02d:%02d", hours, minutes, seconds))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(String(format: "Time: %d:%02d", minutes, seconds))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? ghostRunner.color : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - RunTracker Extensions
// Adding ghost runner functionality to your RunTracker class

import SwiftUI
import MapKit

extension RunTracker {
    // Update ghost runners based on current user progress during a run
    func updateGhostRunnerPositions(elapsedTime: TimeInterval, ghostRunners: inout [GhostRunner]) {
        for i in 0..<ghostRunners.count {
            guard ghostRunners[i].isActive else { continue }
            
            let ghostRun = ghostRunners[i].runData
            let ghostTotalTime = ghostRun.elapsedTime
            
            // Calculate where the ghost runner should be based on elapsed time
            let ghostProgressPercentage = min(elapsedTime / ghostTotalTime, 1.0)
            let totalGhostPoints = ghostRun.routeCoordinates.count
            let targetIndex = Int(Double(totalGhostPoints - 1) * ghostProgressPercentage)
            
            // Update the ghost runner's position
            ghostRunners[i].currentIndex = min(targetIndex, totalGhostPoints - 1)
            
            // Mark as finished if at the end
            if targetIndex >= totalGhostPoints - 1 {
                ghostRunners[i].isActive = false
            }
        }
    }
    
    // Get current position of a ghost runner
    func getCurrentGhostPosition(for ghostRunner: GhostRunner) -> CLLocationCoordinate2D? {
        guard ghostRunner.isActive,
              ghostRunner.currentIndex < ghostRunner.runData.routeCoordinates.count else {
            return nil
        }
        
        return ghostRunner.runData.routeCoordinates[ghostRunner.currentIndex]
    }
}

// Custom map view that displays ghost runners
struct GhostRunnerMapView: View {
    @Binding var region: MKCoordinateRegion
    var ghostRunners: [GhostRunner]
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .ignoresSafeArea()
            .overlay(
                ZStack {
                    // Add overlays for each ghost runner
                    ForEach(ghostRunners) { runner in
                        if let position = getGhostRunnerPosition(runner) {
                            GhostRunnerMarker(color: runner.color, name: runner.name)
                                .position(
                                    x: longitudeToX(position.longitude),
                                    y: latitudeToY(position.latitude)
                                )
                        }
                    }
                }
            )
    }
    
    // Helper to get the current position of a ghost runner
    private func getGhostRunnerPosition(_ runner: GhostRunner) -> CLLocationCoordinate2D? {
        guard runner.isActive,
              runner.currentIndex < runner.runData.routeCoordinates.count else {
            return nil
        }
        
        return runner.runData.routeCoordinates[runner.currentIndex]
    }
    
    // Coordinate conversion helpers
    private func longitudeToX(_ longitude: Double) -> CGFloat {
        let spanHalf = region.span.longitudeDelta / 2.0
        let leftLon = region.center.longitude - spanHalf
        let rightLon = region.center.longitude + spanHalf
        
        let percentage = (longitude - leftLon) / (rightLon - leftLon)
        return CGFloat(percentage) * UIScreen.main.bounds.width
    }
    
    private func latitudeToY(_ latitude: Double) -> CGFloat {
        let spanHalf = region.span.latitudeDelta / 2.0
        let bottomLat = region.center.latitude - spanHalf
        let topLat = region.center.latitude + spanHalf
        
        let percentage = (topLat - latitude) / (topLat - bottomLat)
        return CGFloat(percentage) * UIScreen.main.bounds.height
    }
}

// Custom marker for ghost runners
struct GhostRunnerMarker: View {
    var color: Color
    var name: String
    
    var body: some View {
        VStack(spacing: 2) {
            // Runner icon
            Image(systemName: "figure.run")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(8)
                .background(color)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            // Name label
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .padding(4)
                .background(Color(UIColor.systemBackground).opacity(0.8))
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }
}

// MARK: - Ghost Runner Status View
// Shows the status of ghost runners during a run

struct GhostRunnerStatusView: View {
    var ghostRunners: [GhostRunner]
    var userDistance: Double

    var body: some View {
        // Use the first ghost runner for the status card
        if let ghost = ghostRunners.first, ghost.runData.routeCoordinates.count > 1 {
            let totalPoints = ghost.runData.routeCoordinates.count
            let ghostDistance = ghost.runData.distance * (Double(ghost.currentIndex) / Double(totalPoints - 1))
            let difference = ghostDistance - userDistance
            let tolerance = 0.1  // km tolerance
            
            let paceStatus: String
            if abs(difference) < tolerance {
                paceStatus = "On pace"
            } else if difference > 0 {
                paceStatus = String(format: "Off pace by %.2f km", difference)
            } else {
                paceStatus = String(format: "Ahead by %.2f km", abs(difference))
            }
            
            return AnyView(
                HStack {
                    // Left icon matching leaderboard card style
                    Circle()
                        .fill(ghost.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "figure.run")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(ghost.color)
                        )
                        .padding(.leading, 5)
                    
                    // Main text area
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(ghost.name) ghost run")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                        Text(paceStatus)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                    
                    // Chevron for consistency (optional)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 10)
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray6).opacity(0.6))
                .cornerRadius(8)
                .padding(.horizontal, 10)
                .padding(.top, 15)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // Get the current distance traveled by a ghost runner
    private func getGhostDistance(_ runner: GhostRunner) -> Double {
        guard runner.isActive else { return runner.runData.distance }
        let totalPoints = runner.runData.routeCoordinates.count
        let percentage = Double(runner.currentIndex) / Double(totalPoints - 1)
        return runner.runData.distance * percentage
    }
}

