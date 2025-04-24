//
//  FeedView.swift
//  Runmo
//
//  Created by Noah Moran on 6/1/2025.
//
//

import SwiftUI

@MainActor
struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var navigateToMessages = false

    // search toggle + VM
    @State private var isSearchActive = false
    @StateObject private var searchVM = ExploreViewModel()
    @Namespace    private var searchAnim

    init(viewModel: FeedViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? FeedViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isSearchActive {
                    VStack(spacing: 0) {
                        // Empty view to ensure proper spacing below navigation bar
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                        
                        // User search results with no spacing
                        UserSearchListView(viewModel: searchVM)
                            .padding(.top, 0)
                    }
                } else {
                    ScrollView {
                        PostListView(
                            posts: viewModel.posts,
                            isFetching: viewModel.isFetching,
                            noMorePosts: viewModel.noMorePosts
                        ) {
                            Task { await viewModel.fetchPosts() }
                        }
                        .padding(.top, 8)
                    }
                }

                NavigationLink(destination: MessagesView(),
                               isActive: $navigateToMessages) { EmptyView() }
            }
            .gesture(DragGesture(minimumDistance: 20).onEnded {
                if $0.translation.width > 100 && abs($0.translation.height) < 50 {
                    navigateToMessages = true
                }
            })
            .onAppear {
                if viewModel.posts.isEmpty {
                    Task { await viewModel.fetchPosts(initial: true) }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Always show the Runmo title
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Runmo")
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if isSearchActive {
                            // Search text field with the search icon on the left and Cancel button on the right
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .matchedGeometryEffect(id: "searchIcon", in: searchAnim)
                                TextField("Search users…", text: $searchVM.searchText)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                
                                Button("Cancel") {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isSearchActive = false
                                        searchVM.searchText = ""
                                    }
                                }
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .matchedGeometryEffect(id: "searchBar", in: searchAnim)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        } else {
                            Spacer()
                                .frame(width: 0)
                                .matchedGeometryEffect(id: "searchBar", in: searchAnim)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isSearchActive = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .matchedGeometryEffect(id: "searchIcon", in: searchAnim)
                            }
                        }
                        
                        // always show the messages icon
                        NavigationLink(destination: MessagesView()) {
                            Image(systemName: "paperplane")
                        }
                    }
                }
            }
            // This modifier ensures the content extends directly under the navigation bar
            .ignoresSafeArea(edges: isSearchActive ? .top : [])
        }
    }
}

// PostListView unchanged...
struct PostListView: View {
    let posts: [Post]
    let isFetching: Bool
    let noMorePosts: Bool
    let fetchMoreAction: () -> Void

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(posts.indices, id: \.self) { i in
                NavigationLink(destination: RunDetailView(post: posts[i])) {
                    FeedCell(post: posts[i])
                }
                .buttonStyle(.plain)
                .onAppear {
                    if i == posts.count - 1, !isFetching, !noMorePosts {
                        fetchMoreAction()
                    }
                }
            }

            if isFetching {
                ProgressView("Loading more posts…")
                    .padding(.vertical, 16)
            } else if noMorePosts {
                Text("Follow some people to see posts!")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 16)
            }
        }
    }
}
