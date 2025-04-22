//
//  MarathonCardView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI

struct MarathonCardView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("marathon-image")
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.3))
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Personalise it for you")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text("Marathon Running Program")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        // Maintain a height = width * 0.45
        .aspectRatio(1 / 0.45, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}


struct MarathonCardView_Previews: PreviewProvider {
    static var previews: some View {
        MarathonCardView()
            .padding()
            .previewLayout(.sizeThatFits)
            .background(Color(.systemBackground))
    }
}
