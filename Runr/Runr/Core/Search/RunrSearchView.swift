//
//  RunrSearchView.swift
//  Runr
//
//  Created by Noah Moran on 7/1/2025.
//

import SwiftUI

struct RunrSearchView: View {
    @StateObject var viewModel = ExploreViewModel()
    @State private var isShowingUploadView = false // 🔹 Control modal visibility

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) { // 🔹 Ensure button stays in the same place
                VStack {
                    // 🔹 Search Bar
                    TextField("Search...", text: $viewModel.searchText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // 🔹 Show Users
                    UserSearchListView(viewModel: viewModel)

                    // 🔹 Show ExploreFeedItems
                    ExploreFeedListView(viewModel: viewModel)
                }
                
                // 🔹 Floating Add Button
                Button(action: {
                    isShowingUploadView.toggle() // 🔹 Open upload screen
                }) {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(20) // 🔹 Keep button in bottom-right corner
                .sheet(isPresented: $isShowingUploadView) { // 🔹 Show upload view
                    ExploreUploadView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Explore")
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                }
            }
        }
    }
}



struct RunrSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RunrSearchView()
    }
}



