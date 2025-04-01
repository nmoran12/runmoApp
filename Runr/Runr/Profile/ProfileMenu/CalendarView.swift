//
//  CalendarView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

// MARK: - Date Identifiable Extension
extension Date: Identifiable {
    public var id: TimeInterval { self.timeIntervalSince1970 }
}

// Helper to check if two dates are in the same month.
extension Calendar {
    func isDate(_ date1: Date, inSameMonthAs date2: Date) -> Bool {
        return self.component(.year, from: date1) == self.component(.year, from: date2) &&
            self.component(.month, from: date1) == self.component(.month, from: date2)
    }
}

struct CalendarView: View {
    @Environment(\.dismiss) var dismiss
    let runs: [RunData] // Your run data array
    let calendar = Calendar.current
    @State private var selectedDate: Date? = nil
    @State private var currentMonth: Date = Date() // Tracks the displayed month
    @State private var monthlyGoal: Int = 15 // User's goal for days to run per month
    
    // Compute distinct days (using startOfDay) when runs occurred in the current month.
    var distinctRunDaysCount: Int {
        let runsThisMonth = runs.filter { calendar.isDate($0.date, inSameMonthAs: currentMonth) }
        let distinctDays = Set(runsThisMonth.map { calendar.startOfDay(for: $0.date) })
        return distinctDays.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and a close button.
            HStack {
                Text("Running Calendar")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Month Navigation Header
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding()
                }
                Spacer()
                Text(currentMonthString)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Days of the week header.
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(generateDays(), id: \.self) { date in
                    DayCell(date: date, hasRun: hasRun(on: date))
                        .onTapGesture {
                            if date != Date.distantPast {
                                selectedDate = date
                            }
                        }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Summary Card with goal display and a Stepper.
            VStack(spacing: 8) {
                Text("Total Runs This Month")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(distinctRunDaysCount) days / \(monthlyGoal) days")
                    .font(.title)
                    .fontWeight(.bold)
                Stepper("Set Monthly Goal", value: $monthlyGoal, in: 1...31)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Spacer()
        }
        .padding()
        // Present either a direct run detail view if there's only one run, or a list view.
        .sheet(item: $selectedDate) { date in
            let runsForDate = runs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            if runsForDate.count == 1, let singleRun = runsForDate.first {
                RunDetailView(run: singleRun, userId: "CURRENT_USER_ID")
            } else {
                RunDetailsForDateView(date: date, runs: runsForDate)
            }
        }
    }
    
    // MARK: - Helpers
    
    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth)
    }
    
    // Generate an array of Dates for the current month grid.
    func generateDays() -> [Date] {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        var dates: [Date] = []
        
        // Add placeholder dates for alignment.
        for _ in 1..<firstWeekday {
            dates.append(Date.distantPast)
        }
        
        // Add each day of the month.
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // Check if there's a run on a given date.
    func hasRun(on date: Date) -> Bool {
        if date == Date.distantPast { return false }
        return runs.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// A view representing each day cell in the calendar.
struct DayCell: View {
    let date: Date
    let hasRun: Bool
    let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            if date == Date.distantPast {
                Text("")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("\(calendar.component(.day, from: date))")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                Circle()
                    .fill(hasRun ? Color.blue : Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(4)
    }
}

struct RunDetailsForDateView: View {
    let date: Date
    let runs: [RunData]
    let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            List {
                if runs.isEmpty {
                    Text("No runs on \(formattedDate(date))")
                        .foregroundColor(.gray)
                } else {
                    ForEach(runs) { run in
                        NavigationLink(destination: RunDetailView(run: run, userId: "CURRENT_USER_ID")) {
                            VStack(alignment: .leading) {
                                Text("Run at \(formattedTime(run.date))")
                                    .font(.headline)
                                Text("\(String(format: "%.2f km", run.distance / 1000)) in \(Int(run.elapsedTime) / 60) min")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .navigationTitle(formattedDate(date))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    // For preview purposes, passing an empty array.
    CalendarView(runs: [])
}






#Preview {
    RunDetailsForDateView(date: Date(), runs: [])
}

