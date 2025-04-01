//
//  FeedView.swift
//  Runr
//
//  Created by Noah Moran on 6/1/2025.
//

import SwiftUI

struct FeedView: View {
    @ObservedObject var viewModel = FeedViewModel()
    @State private var navigateToMessages = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Feed content
                ScrollView {
                    // Use the subview for listing posts
                    PostListView(
                        posts: viewModel.posts,
                        isFetching: viewModel.isFetching,
                        noMorePosts: viewModel.noMorePosts
                    ) {
                        Task {
                            await viewModel.fetchPosts()
                        }
                    }
                    .padding(.top, 8)
                }
                // Hidden NavigationLink triggered by a swipe gesture.
                NavigationLink(destination: MessagesView(), isActive: $navigateToMessages) {
                    EmptyView()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        // Check if the swipe is predominantly to the right.
                        if value.translation.width > 100 && abs(value.translation.height) < 50 {
                            navigateToMessages = true
                        }
                    }
            )
            .onAppear {
                Task {
                    // Fetch initial batch of posts
                    await viewModel.fetchPosts(initial: true)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Runmo")
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: MessagesView()) {
                        Image(systemName: "paperplane")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// This subview handles displaying the list of posts in a LazyVStack
// and triggers `fetchMoreAction` when the user scrolls to the last post.
struct PostListView: View {
    let posts: [Post]
    let isFetching: Bool
    let noMorePosts: Bool
    let fetchMoreAction: () -> Void
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(posts.indices, id: \.self) { index in
                NavigationLink(destination: RunDetailView(post: posts[index])) {
                    FeedCell(post: posts[index])
                }
                .buttonStyle(PlainButtonStyle())
                .onAppear {
                    // If we're at the last post, and not currently fetching,
                    // and we still have more posts, fetch more
                    if index == posts.count - 1, !isFetching, !noMorePosts {
                        fetchMoreAction()
                    }
                }
            }
            // Loading Indicator or "No More Posts"
            if isFetching {
                ProgressView("Loading more posts...")
                    .padding(.vertical, 16)
            } else if noMorePosts {
                Text("No More Posts to Display")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    FeedView()
}








