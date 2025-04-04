//
//  BestEffortsView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct BestEffortsView: View {
    @StateObject private var viewModel = BestEffortsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.bestEfforts) { effort in
                BestEffortRow(effort: effort)
            }
        }
        .navigationTitle("Personal Bests")
        .onAppear {
            viewModel.loadPersonalBests()
        }
    }
}

struct BestEffortsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BestEffortsView()
        }
    }
}

