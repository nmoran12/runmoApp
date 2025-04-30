//
//  BestEffortsCardView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct BestEffortsCardView: View {
    @StateObject private var viewModel = BestEffortsViewModel()
    
    // Show only the top 3 efforts (if available)
    private var topEfforts: [BestEffortsViewModel.BestEffort] {
        Array(viewModel.bestEfforts.prefix(3))
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 16) {
                // Title and subtext
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Bests")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("See your personal records and trends over time.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Display the top 3 best efforts using BestEffortRow
                if topEfforts.isEmpty {
                    Text("No best efforts yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
                    ForEach(topEfforts) { effort in
                        BestEffortRow(effort: effort)
                    }
                }
                
                // Bottom-right link to full Best Efforts view
                HStack {
                    Spacer()
                    NavigationLink(destination: BestEffortsView()) {
                        Text("View all your Best Efforts")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            
        }
        .onAppear {
            viewModel.loadPersonalBests()
        }
    }
}

struct BestEffortsCardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BestEffortsCardView()
                .padding()
                .background(Color(.systemGroupedBackground))
        }
    }
}
