//
//  BestEffortsBadgesView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct BestEffortsBadgesView: View {
    let efforts: [BestEffortsViewModel.BestEffort]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(efforts) { effort in
                VStack(spacing: 4) {
                    // Badge view with animations added
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.8))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.run")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    // Adding similar animations from TagsView:
                    .modifier(EdgeShineModifier())
                    .modifier(GlossyShineModifier())
                    .modifier(FloatingModifier(isRare: false))
                    // Optionally, if you want a shimmering effect:
                    .shinyEffect(isRare: false)
                }
            }
        }
    }
}

struct BestEffortsBadgesView_Previews: PreviewProvider {
    static var previews: some View {
        BestEffortsBadgesView(efforts: [
            BestEffortsViewModel.BestEffort(distance: "5K", time: 1500, date: Date()),
            BestEffortsViewModel.BestEffort(distance: "10K", time: 3200, date: Date()),
            BestEffortsViewModel.BestEffort(distance: "Half Marathon", time: 7500, date: Date())
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

