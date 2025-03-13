//
//  FootwearButtonView.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI

struct FootwearButtonView: View {
    @Binding var selectedFootwear: String
    @State private var showFootwearMenu = false // Controls visibility of the pop-down menu
    @State private var footwearOptions: [String] = ["Adidas", "Nike Superfly"] // Initial list of options
    @State private var searchQuery = "" // Stores the search query

    var body: some View {
        VStack {
            // Button to toggle the footwear menu
            HStack(spacing: -3) {
                Button(action: {
                    withAnimation {
                        showFootwearMenu.toggle()
                    }
                }) {
                    HStack {
                        Text(selectedFootwear)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(10)
                        
                        Image(systemName: "shoe")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                            .padding(10)
                    }
                }
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(.black)
            }

            if showFootwearMenu {
                VStack {
                    // Search bar
                    TextField("Search or add new footwear...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    // Dropdown list with filtered footwear options
                    ScrollView {
                        ForEach(filteredFootwearOptions(), id: \.self) { option in
                            Button(action: {
                                selectedFootwear = option
                                showFootwearMenu = false
                            }) {
                                Text(option)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color.white)
                            .cornerRadius(5)
                        }
                    }
                    .frame(maxHeight: 200) // Limit the height of the dropdown menu
                    
                    // Button to add new footwear if it's not in the list
                    if !searchQuery.isEmpty && !footwearOptions.contains(searchQuery) {
                        Button("Add '\(searchQuery)' to Footwear") {
                            footwearOptions.append(searchQuery) // Add new footwear to the list
                            selectedFootwear = searchQuery // Set new footwear as selected
                            searchQuery = "" // Clear the search bar
                            showFootwearMenu = false // Hide the menu
                        }
                        .padding()
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.top, 5)
            }
        }
        .padding()
    }

    // Filter options based on search query
    private func filteredFootwearOptions() -> [String] {
        if searchQuery.isEmpty {
            return footwearOptions
        } else {
            return footwearOptions.filter { $0.lowercased().contains(searchQuery.lowercased()) }
        }
    }
}

#Preview {
    @State var previewFootwear = "Select Footwear"
    FootwearButtonView(selectedFootwear: $previewFootwear)
}
