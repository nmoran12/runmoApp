//
//  RunrSearchView.swift
//  Runr
//
//  Created by Noah Moran on 7/1/2025.
//

import SwiftUI

struct RunrSearchView: View {
    @StateObject var viewModel = ExploreViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredUsers) { user in
                        NavigationLink(destination: ProfileView(user: user)) {
                            HStack {
                                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle().fill(Color.gray)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(user.username)
                                        .fontWeight(.semibold)

                                    if let displayName = user.realName ?? user.fullname {
                                        Text(displayName)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .font(.footnote)
                                
                                Spacer()
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search...")
        }
    }
}

struct RunrSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RunrSearchView()
    }
}

