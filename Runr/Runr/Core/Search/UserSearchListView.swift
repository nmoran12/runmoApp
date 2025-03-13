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
        if !viewModel.filteredUsers.isEmpty {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.filteredUsers) { user in
                        NavigationLink(destination: ProfileView(user: .constant(user))) { // 🔹 Navigate to ProfileView
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
        }
    }
}



// 🔹 Fixed PreviewProvider
#Preview {
    UserSearchListView(viewModel: ExploreViewModel()) // 🔹 Provide sample viewModel
}

