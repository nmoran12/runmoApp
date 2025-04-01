//
//  UserSearchListView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct UserSearchListView: View {
    @ObservedObject var viewModel: ExploreViewModel
    
    var body: some View {
        Group {
            if !viewModel.filteredUsers.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.filteredUsers) { user in
                            NavigationLink(destination: ProfileView(user: .constant(user))) {
                                HStack {
                                    AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle().fill(Color.gray)
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    Text(user.username)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                .frame(maxHeight: 200) // Limit height
            } else {
                EmptyView()
            }
        }
        // Retain the swipe gesture to clear search text
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Check for a right swipe (translation.width > 100 can be adjusted)
                    if value.translation.width > 100 {
                        withAnimation {
                            viewModel.searchText = ""
                        }
                    }
                }
        )
    }
}

#Preview {
    UserSearchListView(viewModel: ExploreViewModel())
}

