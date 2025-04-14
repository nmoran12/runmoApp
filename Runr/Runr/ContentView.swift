//
//  ContentView.swift
//  Runr
//
//  Created by Noah Moran on 6/1/2025.
//

import SwiftUI

struct ContentView: View {
    
    
    var body: some View {
        VStack {
            FeedView(viewModel: FeedViewModel())
        }

    }
}

#Preview {
    ContentView()
}
