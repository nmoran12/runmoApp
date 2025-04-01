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
            // Subtle pulsing glow ring
            Circle()
                .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 4)
                .shadow(color: Color.yellow.opacity(0.4), radius: 6, x: 0, y: 2)
                .scaleEffect(1.0)
                .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: 1)
            
            // User content with a subtle shimmer overlay
            content
                .overlay(
                    SubtleShimmerView()
                        .clipShape(Circle())
                )
        }
    }
}

// A more subtle shimmer effect than the confetti
struct SubtleShimmerView: View {
    @State private var shimmerOffset: CGFloat = -0.2

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(30))
                .frame(width: size.width * 1.5, height: size.height)
                .offset(x: shimmerOffset * size.width)
                .onAppear {
                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1.2
                    }
                }
        }
    }
}

// MARK: - PulsingRingView
struct PulsingRingView: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .strokeBorder(Color.yellow.opacity(0.7), lineWidth: 8)
            .scaleEffect(scale)
            .opacity(Double(2 - scale)) // fade out as it expands
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    scale = 2.0
                }
            }
    }
}

// MARK: - ConfettiView (simplified)
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<15) { i in
                    Circle()
                        .fill(randomColor())
                        .frame(width: 6, height: 6)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: animate
                              ? CGFloat.random(in: 0...geo.size.height)
                              : -20
                        )
                        .animation(
                            .interpolatingSpring(stiffness: 30, damping: 10)
                                .delay(Double(i) * 0.1),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
        .clipped()
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [.yellow, .orange, .pink, .blue, .green, .purple]
        return colors.randomElement() ?? .white
    }
}
