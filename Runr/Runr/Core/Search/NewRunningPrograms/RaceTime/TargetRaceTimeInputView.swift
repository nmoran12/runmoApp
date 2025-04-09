//
//  TargetRaceTimeInputView.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import SwiftUI

struct TargetRaceTimeInputView: View {
    // Input fields for hours and minutes for the desired marathon time.
    @State private var hours: String = ""
    @State private var minutes: String = ""
    
    // Calculated pace strings (min/km)
    @State private var marathonPace: String = "Not set"
    @State private var easyPace: String = "Not set"
    @State private var tempoPace: String = "Not set"
    @State private var longRunPace: String = "Not set"
    @State private var intervalsPace: String = "Not set"
    
    // Inject your view model that holds targetTimeSeconds.
    @EnvironmentObject var programVM: NewRunningProgramViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Desired Marathon Finish Time")) {
                    HStack {
                        TextField("Hours", text: $hours)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            // Update paces every time 'hours' changes.
                            .onChange(of: hours) { _ in
                                updatePaces()
                            }
                        Text(":")
                        TextField("Minutes", text: $minutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            // Update paces every time 'minutes' changes.
                            .onChange(of: minutes) { _ in
                                updatePaces()
                            }
                    }
                }
                
                // (Optional) You can remove this button if you want a fully live update.
                Section {
                    Button(action: updatePaces) {
                        Text("Set Target Race Time")
                    }
                }
                
                Section(header: Text("Calculated Paces (min/km)")) {
                    HStack {
                        Text("Marathon Pace:")
                        Spacer()
                        Text(marathonPace)
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Text("Easy Pace:")
                        Spacer()
                        Text(easyPace)
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Tempo Pace:")
                        Spacer()
                        Text(tempoPace)
                            .foregroundColor(.orange)
                    }
                    HStack {
                        Text("Long Run Pace:")
                        Spacer()
                        Text(longRunPace)
                            .foregroundColor(.purple)
                    }
                    HStack {
                        Text("Intervals Pace:")
                        Spacer()
                        Text(intervalsPace)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Workout Adjustments")) {
                    Text("Your running program’s workouts can now use these pace zones. For example, if your calculated Marathon Pace is 5:30 min/km, an Easy Run might target 6:00–6:30 min/km, a Tempo run might target 5:10–5:20 min/km, a Long Run might target 5:50–6:00 min/km and Intervals might target 5:00–5:10 min/km.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Target Race Time")
        }
    }
    
    /// This function is called whenever the hour or minute input changes.
    /// It validates the input and updates the view model’s targetTimeSeconds along with recalculating the pace values.
    private func updatePaces() {
        // Check that both hours and minutes convert to a valid number.
        guard let h = Double(hours), let m = Double(minutes) else {
            marathonPace = "Invalid input"
            easyPace = "Invalid input"
            tempoPace = "Invalid input"
            longRunPace = "Invalid input"
            intervalsPace = "Invalid input"
            return
        }
        
        // Convert the input to seconds.
        let newTargetTimeSeconds = h * 3600 + m * 60
        
        // Update the view model's property (if needed for in-app calculations)
        programVM.targetTimeSeconds = newTargetTimeSeconds
        
        // Calculate and update pace strings as before…
        let marathonDistance = 42.195
        let marathonPaceSec = newTargetTimeSeconds / marathonDistance
        marathonPace = formatPace(secondsPerKm: marathonPaceSec)
        easyPace     = PaceCalculator.formattedRecommendedPace(for: .easyRun, targetTimeSeconds: newTargetTimeSeconds)
        tempoPace    = PaceCalculator.formattedRecommendedPace(for: .tempo, targetTimeSeconds: newTargetTimeSeconds)
        longRunPace  = PaceCalculator.formattedRecommendedPace(for: .longRun, targetTimeSeconds: newTargetTimeSeconds)
        intervalsPace = PaceCalculator.formattedRecommendedPace(for: .intervals, targetTimeSeconds: newTargetTimeSeconds)
        
        print("Updated Target Time (seconds): \(programVM.targetTimeSeconds)")
        print("Calculated Marathon Pace (sec/km): \(marathonPaceSec)")
        
        // Now update Firestore with the new target race time.
        Task {
            await programVM.updateUserTargetTime(newTargetTime: newTargetTimeSeconds)
        }
    }

    
    /// Converts seconds per km into a "minutes:seconds" formatted string.
    private func formatPace(secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    TargetRaceTimeInputView()
        .environmentObject(NewRunningProgramViewModel())
}
