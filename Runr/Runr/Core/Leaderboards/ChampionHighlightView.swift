//
//  ChampionHighlightView.swift
//  Runr
//
//  Created by Noah Moran on 1/4/2025.
//

import SwiftUI

struct ChampionHighlightView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // A subtle circular background with an edge shine, similar to your TagsView
            Circle()
                .fill(Color.yellow.opacity(0.2))
                .frame(width: 120, height: 120)
            
            // The main user content, gently floating with a subtle shimmer overlay
            content
                .clipShape(Circle())
        }
    }

    
    private func randomColor() -> Color {
        let colors: [Color] = [.yellow, .orange, .pink, .blue, .green, .purple]
        return colors.randomElement() ?? .white
    }
}
