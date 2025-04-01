//
//  TagsView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

extension String: Identifiable {
    public var id: String { self }
}

// MARK: - GradientTagColor

struct GradientTagColor {
    let startColor: Color
    let endColor: Color
    
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - EdgeShineModifier

struct EdgeShineModifier: ViewModifier {
    @State private var position = false

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geometry in
                // Instead of building a Path manually, use RoundedRectangle
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.3), location: position ? 1 : 0),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
                position.toggle()
            }
        }
    }
}




// MARK: - TagsView

struct TagsView: View {
    let tags: [String]
    
    let tagGradientColors: [String: GradientTagColor] = [
        "Ultra Legend": GradientTagColor(
            startColor: Color(#colorLiteral(red: 1, green: 0.84, blue: 0, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.85, green: 0.65, blue: 0.00, alpha: 1))
        ),
        "Elite Marathoner": GradientTagColor(
            startColor: Color(#colorLiteral(red: 1, green: 0.84, blue: 0, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.85, green: 0.65, blue: 0.00, alpha: 1))
        ),
        "10K Runner": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.42, green: 0.11, blue: 0.60, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.32, green: 0.08, blue: 0.45, alpha: 1))
        ),
        "Veteran Runner": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.42, green: 0.11, blue: 0.60, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.32, green: 0.08, blue: 0.45, alpha: 1))
        ),
        "Marathon Runner": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.1, green: 0.45, blue: 0.7, alpha: 1))
        ),
        "5K Speed Demon": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.1, green: 0.45, blue: 0.7, alpha: 1))
        ),
        "Pace Setter": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.13, green: 0.59, blue: 0.95, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.1, green: 0.45, blue: 0.7, alpha: 1))
        ),
        "Consistent Runner": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.30, green: 0.69, blue: 0.31, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.22, green: 0.5, blue: 0.23, alpha: 1))
        ),
        "Distance Dominator": GradientTagColor(
            startColor: Color(#colorLiteral(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)),
            endColor: Color(#colorLiteral(red: 0.47, green: 0.47, blue: 0.47, alpha: 1))
        )
    ]
    
    let tagIcons: [String: String] = [
        "Ultra Legend": "crown.fill",
        "Elite Marathoner": "trophy.fill",
        "10K Runner": "figure.run.circle.fill",
        "Veteran Runner": "star.fill",
        "Marathon Runner": "flag.checkered",
        "5K Speed Demon": "bolt.fill",
        "Pace Setter": "speedometer",
        "Consistent Runner": "calendar.badge.clock",
        "Distance Dominator": "ruler.fill"
    ]
    
    let rarityOrder: [String: Int] = [
        "Ultra Legend": 1,
        "Elite Marathoner": 1,
        "10K Runner": 2,
        "Veteran Runner": 2,
        "Marathon Runner": 3,
        "5K Speed Demon": 3,
        "Pace Setter": 3,
        "Consistent Runner": 4,
        "Distance Dominator": 5
    ]
    
    @State private var selectedTag: String? = nil
    @State private var longPressTag: String? = nil
    @State private var showingTooltip = false
    
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        let sortedTags = tags.sorted { (tag1, tag2) -> Bool in
            (rarityOrder[tag1] ?? Int.max) < (rarityOrder[tag2] ?? Int.max)
        }
        
        FlexibleView(data: sortedTags, spacing: 4, maxRows: 2) { tag in
            TagButton(
                tag: tag,
                rarity: rarityOrder[tag] ?? 5,
                iconName: tagIcons[tag],
                isSelected: selectedTag == tag,
                background: tagGradientColors[tag]?.gradient ?? LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                feedback: feedback
            ) {
                selectedTag = tag
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                longPressTag = tag
                showingTooltip = true
                feedback.impactOccurred(intensity: 0.7)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showingTooltip = false
                    }
                }
            }
        }
        .frame(minHeight: 30)
        .padding(.vertical, 8)
        .sheet(item: $selectedTag) { tag in
            AllTagDetailsView(selectedTag: tag, tagGradientColors: tagGradientColors)
                .transition(.move(edge: .bottom))
        }

    }
    
    private func tagDescription(for tag: String) -> String {
        switch tag {
        case "Marathon Runner":
            return "Earned by completing at least one run of 42,195 meters."
        case "5K Speed Demon":
            return "Earned by achieving an equivalent 5K time under 15 minutes."
        case "10K Runner":
            return "Earned by achieving an equivalent 10K time under 40 minutes."
        case "Elite Marathoner":
            return "Earned by completing a marathon in under 2 hours 30 minutes."
        case "Ultra Legend":
            return "Earned by completing a 100 km run in under 12 hours."
        case "Pace Setter":
            return "Earned by maintaining an overall average pace under 5 minutes per km (with at least 10 runs)."
        case "Distance Dominator":
            return "Earned by accumulating at least 1,000 km total distance."
        case "Veteran Runner":
            return "Earned by completing 50 or more runs."
        case "Consistent Runner":
            return "Earned by running on 7 or more distinct days."
        default:
            return "No description available."
        }
    }
}

// MARK: - TagButton

struct TagButton: View {
    let tag: String
    let rarity: Int
    let iconName: String?
    let isSelected: Bool
    let background: LinearGradient
    let feedback: UIImpactFeedbackGenerator
    let action: () -> Void

    // Build the base content of the button.
    private var baseContent: some View {
        HStack(spacing: 4) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.system(size: 10))
            }
            Text(tag)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(background)
        .foregroundColor(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(isSelected ? 0.95 : 1.0)
    }
    
    // Apply extra animations based on rarity.
    private var animatedContent: some View {
        switch rarity {
        case 1:
            // Rarity 1: Floating, Glossy, Edge and Shiny animations.
            return AnyView(baseContent
                .modifier(FloatingModifier(isRare: true))
                .modifier(GlossyShineModifier())
                .modifier(EdgeShineModifier())
                .shinyEffect(isRare: true))
        case 2:
            // Rarity 2: Glossy, Edge and Shiny animations.
            return AnyView(baseContent
                .modifier(GlossyShineModifier())
                .modifier(EdgeShineModifier())
                .shinyEffect(isRare: true))
        case 3:
            // Rarity 3: Edge and Shiny animations.
            return AnyView(baseContent
                .modifier(EdgeShineModifier())
                .shinyEffect(isRare: true))
        case 4:
            // Rarity 4: Shiny animation only.
            return AnyView(baseContent
                .shinyEffect(isRare: true))
        default:
            // Other rarities: no extra animations.
            return AnyView(baseContent)
        }
    }
    
    var body: some View {
        Button(action: {
            feedback.impactOccurred()
            action()
        }) {
            animatedContent
        }
    }
}


@ViewBuilder
private func sparkleOverlay(for tag: String) -> some View {
    if tag == "Ultra Legend" {
        SparkleView()
    } else {
        EmptyView()
    }
}

// MARK: - FloatingModifier

struct FloatingModifier: ViewModifier {
    let isRare: Bool
    @State private var offsetY: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .onAppear {
                let floatAmount: CGFloat = isRare ? -2.5 : -1.5
                withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    offsetY = floatAmount
                }
            }
    }
}

struct GlossyShineModifier: ViewModifier {
    @State private var animate = false

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geometry in
                let size = geometry.size
                // A rectangle with a gradient that will slide over the view
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    // The width is a bit larger than the view so the shine can smoothly slide in and out.
                    .frame(width: size.width * 1.5, height: size.height)
                    .offset(x: animate ? size.width : -size.width, y: 0)
                    .animation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false), value: animate)
                    .onAppear {
                        animate = true
                    }
            }
            .clipped()
        )
    }
}

extension View {
    func glossyShine() -> some View {
        self.modifier(GlossyShineModifier())
    }
}


// MARK: - ShimmerView and ShinyEffect

struct ShimmerView: View {
    @State private var shimmerOffset: CGFloat = -0.25
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                Color.white.opacity(0.2)
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: shimmerOffset - 0.25),
                                        .init(color: .white.opacity(0.9), location: shimmerOffset),
                                        .init(color: .clear, location: shimmerOffset + 0.25)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .rotationEffect(.degrees(30))
                            .scaleEffect(3)
                    )
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.25
                }
            }
        }
    }
}

struct ShinyEffect: ViewModifier {
    let isRare: Bool
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            // your shimmer overlays, etc.
            .onAppear {
                if isRare {
                    withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                }
            }
    }
}

// This extension is crucial
extension View {
    func shinyEffect(isRare: Bool = false) -> some View {
        self.modifier(ShinyEffect(isRare: isRare))
    }
}


// MARK: - SparkleView

struct SparkleView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 7))
                    .foregroundColor(.white)
                    .offset(x: CGFloat.random(in: -15...15),
                            y: CGFloat.random(in: -15...15))
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .delay(Double.random(in: 0.3...1.2))
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Conditional Modifier Extension

extension View {
    @ViewBuilder func conditionalModifier<M: ViewModifier>(
        _ condition: Bool,
        modifier: M
    ) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }
}

// MARK: - TagDetailView

struct TagDetailView: View {
    let tag: String
    let description: String
    let iconName: String
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                    .padding(.top, 20)
                
                Text(tag)
                    .font(.title)
                    .fontWeight(.bold)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("About this achievement")
                        .font(.headline)
                    
                    Text(description)
                        .font(.body)
                        .padding(.bottom, 10)
                    
                    if tag == "Ultra Legend" || tag == "Elite Marathoner" {
                        Text("Rare achievement! Only a small percentage of runners have earned this badge.")
                            .font(.callout)
                            .foregroundColor(.orange)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 200)
                .background(Color.accentColor)
                .cornerRadius(10)
                .padding(.bottom, 20)
            }
            .navigationTitle("Tag Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView(tags: [
            "5K Speed Demon", "Marathon Runner", "Elite Marathoner", "Ultra Legend",
            "Pace Setter", "Distance Dominator", "Veteran Runner", "Consistent Runner"
        ])
    }
}

