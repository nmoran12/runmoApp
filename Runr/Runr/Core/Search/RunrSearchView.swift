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
            ZStack(alignment: .bottomTrailing) { //  Ensure button stays in the same place
                VStack {
                    //  Search Bar
                    TextField("Search...", text: $viewModel.searchText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    //  Show Users
                    UserSearchListView(viewModel: viewModel)
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
}



struct RunrSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RunrSearchView()
    }
}



