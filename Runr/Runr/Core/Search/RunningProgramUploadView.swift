//
//  RunningProgramUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct RunningProgramUploadView: View {
    @State private var numberOfWeeks: Int = 6
    @State private var programData: [[String]] = Array(repeating: Array(repeating: "", count: 7), count: 6)
    
    let daysOfWeek = ["Mon", "Tues", "Wed", "Thurs", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationView {
            VStack(spacing: 10) { // Reduce spacing between sections
                
                // Title Input
                TextField("Enter Program Title", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Week Selection
                HStack {
                    Text("Number of Weeks:")
                    Picker("Weeks", selection: $numberOfWeeks) {
                        ForEach(1...12, id: \.self) { week in
                            Text("\(week) Weeks").tag(week)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)

                // Editable Program Table (Now Takes Up More Space)
                ScrollView {
                    VStack {
                        // Header Row
                        HStack {
                            Text("Week").bold().frame(width: 50)
                            ForEach(daysOfWeek, id: \.self) { day in
                                Text(day).bold()
                                    .frame(maxWidth: .infinity)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // Editable Rows
                        ForEach(0..<numberOfWeeks, id: \.self) { week in
                            HStack {
                                Text("\(week + 1)").bold().frame(width: 50)
                                ForEach(0..<7, id: \.self) { day in
                                    TextField("Enter", text: $programData[week][day])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                }
                .frame(maxHeight: .infinity) // Expands to fill available space

                // Spacer to push buttons to the bottom
                Spacer()

                // Save and Close Buttons
                HStack {
                    Button("Cancel") {
                        // Handle cancel
                    }
                    .foregroundColor(.red)

                    Spacer()

                    Button("Save Program") {
                        // Handle save action
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                //.padding(.bottom) // Add padding at the bottom
            }
        }
    }
}

#Preview {
    RunningProgramUploadView()
}
