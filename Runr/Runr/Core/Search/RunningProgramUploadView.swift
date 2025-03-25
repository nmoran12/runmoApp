//
//  RunningProgramUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI
import FirebaseFirestore

struct WeeklyPlanInput: Identifiable {
    let id = UUID()
    var title: String = ""
    var shortDescription: String = ""
    var planDetails: String = ""
    var extraNotes: String = ""
}

struct RunningProgramUploadView: View {
    // MARK: - State Properties
    @State private var programTitle: String = ""
    @State private var programSubtitle: String = ""
    @State private var imageUrl: String = ""
    @State private var planOverview: String = ""
    @State private var experienceLevel: String = ""
    @Environment(\.dismiss) private var dismiss // this is used to get rid of the upload screen when i click upload
    
    var onProgramCreated: (() -> Void)?

    
    @State private var numberOfWeeks: Int = 6 {
        didSet {
            weeklyPlanInputs = Array(repeating: WeeklyPlanInput(), count: numberOfWeeks)
        }
    }
    @State private var weeklyPlanInputs: [WeeklyPlanInput] = Array(repeating: WeeklyPlanInput(), count: 6)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Hero Image
                    ZStack {
                        if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                            // Show the image if the URL is valid
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 240)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 240)
                                        .clipped()
                                case .failure:
                                    Color.red
                                        .frame(height: 240)
                                        .overlay(
                                            Text("Image failed to load")
                                                .foregroundColor(.white)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            // Placeholder image area
                            Color.gray.opacity(0.2)
                                .frame(height: 240)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        Text("Tap to Enter Image URL")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        // Let user paste a URL, open an image picker, etc.
                    }
                    
                    // MARK: - Program Title & Subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Program Title", text: $programTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .textFieldStyle(.plain)     // No border
                        
                        TextField("Subtitle (e.g., Up to 5 runs a week, 8 weeks total)", text: $programSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textFieldStyle(.plain)
                    }
                    
                    // MARK: - Plan Overview
                    Text("Plan Overview")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ZStack(alignment: .topLeading) {
                        // Simple placeholder for the TextEditor
                        if planOverview.isEmpty {
                            Text("Write your plan overview here...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $planOverview)
                            .frame(minHeight: 100)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, -4) // Align text with the heading
                    }
                    
                    // MARK: - Experience Level
                    Text("Experience Level")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    TextField("Beginner, Intermediate, etc.", text: $experienceLevel)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, -4)  // Align with heading text
                        .foregroundColor(.primary)
                    
                    // MARK: - Number of Weeks
                    HStack {
                        Text("Number of Weeks")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Picker("Weeks", selection: $numberOfWeeks) {
                            ForEach(1...12, id: \.self) { week in
                                Text("\(week)").tag(week)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // MARK: - Weekly Plans
                    ForEach(0..<numberOfWeeks, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 12) {
                            // Week heading
                            HStack {
                                Text("Week \(i + 1)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            // Title
                            TextField("Title (e.g., Welcome to the Starting Line)",
                                      text: $weeklyPlanInputs[i].title)
                            .textFieldStyle(.plain)
                            .font(.headline)
                            
                            // Short Description
                            ZStack(alignment: .topLeading) {
                                if weeklyPlanInputs[i].shortDescription.isEmpty {
                                    Text("Short Description...")
                                        .foregroundColor(.gray)
                                        .padding(.top, 8)
                                        .padding(.leading, 2)
                                }
                                TextEditor(text: $weeklyPlanInputs[i].shortDescription)
                                    .frame(minHeight: 60)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, -4)
                            }
                            
                            // Plan Details
                            ZStack(alignment: .topLeading) {
                                if weeklyPlanInputs[i].planDetails.isEmpty {
                                    Text("Plan Details (e.g., 2 Recovery/Easy Runs...)")
                                        .foregroundColor(.gray)
                                        .padding(.top, 8)
                                        .padding(.leading, 2)
                                }
                                TextEditor(text: $weeklyPlanInputs[i].planDetails)
                                    .frame(minHeight: 80)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, -4)
                            }
                            
                            // Extra Notes
                            ZStack(alignment: .topLeading) {
                                if weeklyPlanInputs[i].extraNotes.isEmpty {
                                    Text("Additional Notes...")
                                        .foregroundColor(.gray)
                                        .padding(.top, 8)
                                        .padding(.leading, 2)
                                }
                                TextEditor(text: $weeklyPlanInputs[i].extraNotes)
                                    .frame(minHeight: 50)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, -4)
                            }
                        }
                    }
                    
                    // MARK: - Save / Cancel Buttons
                    HStack {
                        Button("Cancel") {
                            // Dismiss or pop
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Save Program") {
                            uploadRunningProgram()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Create Running Program")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Initialize weekly plan inputs
            weeklyPlanInputs = Array(repeating: WeeklyPlanInput(), count: numberOfWeeks)
        }
    }
    
    // MARK: - Firebase Upload
    func uploadRunningProgram() {
        var weeklyPlans: [[String: Any]] = []
        for (index, input) in weeklyPlanInputs.enumerated() {
            let weekDict: [String: Any] = [
                "weekNumber": index + 1,
                "title": input.title,
                "shortDescription": input.shortDescription,
                "planDetails": input.planDetails,
                "extraNotes": input.extraNotes
            ]
            weeklyPlans.append(weekDict)
        }
        
        let data: [String: Any] = [
            "title": programTitle,
            "subtitle": programSubtitle,
            "imageUrl": imageUrl,
            "planOverview": planOverview,
            "experienceLevel": experienceLevel,
            "weeklyPlans": weeklyPlans,
            "category": "runningProgram",
            "createdAt": Timestamp(date: Date())
        ]
        
        let db = Firestore.firestore()
                db.collection("exploreFeedItems")
                    .document("runningPrograms")
                    .collection("programs")
                    .addDocument(data: data) { error in
                        if let error = error {
                            print("Error uploading running program: \(error.localizedDescription)")
                        } else {
                            print("Running program successfully uploaded!")
                            
                            // INSTEAD OF calling `dismiss()` here, just call the callback:
                            DispatchQueue.main.async {
                                onProgramCreated?()  // Tell the parent "we're done"
                            }
                        }
                    }
            }
        }

#Preview {
    RunningProgramUploadView()
}



