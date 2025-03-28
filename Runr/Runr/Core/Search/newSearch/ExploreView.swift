//
//  ExploreView.swift
//  Runr
//
//  Created by Noah Moran on 24/3/2025.
//

import SwiftUI

// MARK: - Data Models

struct RunningProgram123: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageUrl: String
}

struct Blog123: Identifiable {
    let id = UUID()
    let title: String
    let snippet: String
    let imageUrl: String
}

// Sample data
let sampleRunningPrograms = [
    RunningProgram123(title: "Morning Run", description: "Kickstart your day with an energizing run.", imageUrl: "https://www.letsdothis.com/blog/article/6-top-5k-training-tips"),
    RunningProgram123(title: "Evening Sprint", description: "Boost your speed and endurance.", imageUrl: "https://www.letsdothis.com/blog/article/6-top-5k-training-tips")
]

let sampleBlogs = [
    Blog123(title: "Running Tips for Beginners", snippet: "Learn the basics of running and get started on the right foot.", imageUrl: "https://via.placeholder.com/400x200"),
    Blog123(title: "How to Stay Motivated", snippet: "Discover techniques to keep yourself motivated during your training.", imageUrl: "https://via.placeholder.com/400x200")
]

// MARK: - Card Views

/// Card for Running Programs (horizontal carousel).
struct RunningProgramCard: View {
    let program: RunningProgram123
    var onSave: (() async -> Void)? = nil
    
    // Adjust these constants to your preference
    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 220
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: program.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: cardWidth, height: cardHeight)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cardWidth, height: cardHeight)
                                    .clipped()
                            case .failure:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: cardWidth, height: cardHeight)
                            @unknown default:
                                EmptyView()
                            }
                        }
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.2),  // instead of 0.0
                    Color.black.opacity(0.8)   // instead of 0.6 or 0.7
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: cardWidth, height: cardHeight)
            
            // Text Overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(program.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(program.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding()
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 3)
        // Add a context menu so a long press shows the Save option
                .contextMenu {
                    if let onSave = onSave {
                        Button("Save") {
                            Task {
                                await onSave()
                            }
                        }
                    }
                }
    }
}


// MARK: - Main Explore Screen

struct ExploreView: View {
    @StateObject var viewModel = ExploreViewModel()
    @State private var showUploadView = false
    @State private var programs: [RunningProgram] = []
    @State private var showUploadSheet = false
    
    var runningPrograms: [ExploreFeedItem] {
        viewModel.exploreFeedItems.filter { $0.category == "runningProgram" }
    }
    
    var blogItems: [ExploreFeedItem] {
        viewModel.exploreFeedItems.filter { $0.category == "Blog" }
    }

    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        searchBar
                        
                        if !viewModel.searchText.isEmpty {
                            UserSearchListView(viewModel: viewModel)
                        } else {
                            runningProgramsSection
                            blogsSection
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Explore")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                    }
                }
                
                // Floating Upload Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showUploadView.toggle()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            // Present the upload view as a modal sheet
            .sheet(isPresented: $showUploadView, onDismiss: {
                Task {
                    await viewModel.fetchBlogs()
                    await viewModel.fetchRunningPrograms()
                }
            }) {
                ExploreUploadView()
            }

    }
}
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var runningProgramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Running Programs")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(runningPrograms, id: \.exploreFeedId) { item in
                        NavigationLink(destination: RunningProgramContentView(program: RunningProgram(from: item))) {
                            RunningProgramCard(program: convertToRunningProgram123(from: item)) {
                                do {
                                    try await AuthService.shared.saveItem(item)
                                    print("Running program saved successfully!")
                                } catch {
                                    print("Error saving running program: \(error.localizedDescription)")
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var blogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blogs")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(blogItems, id: \.exploreFeedId) { item in
                        NavigationLink(destination: BlogContentView(blog: item)) {
                            BlogCard(blog: convertToBlog123(from: item)) {
                                do {
                                    try await AuthService.shared.saveItem(item)
                                    print("Blog saved successfully!")
                                } catch {
                                    print("Error saving blog: \(error.localizedDescription)")
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }

}

func convertToRunningProgram123(from item: ExploreFeedItem) -> RunningProgram123 {
    return RunningProgram123(
        title: item.title,
        description: item.content,
        imageUrl: item.imageUrl
    )
}

func convertToBlog123(from item: ExploreFeedItem) -> Blog123 {
    Blog123(
        title: item.title,
        snippet: item.content,
        imageUrl: item.imageUrl
    )
}




// MARK: - Preview

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}


