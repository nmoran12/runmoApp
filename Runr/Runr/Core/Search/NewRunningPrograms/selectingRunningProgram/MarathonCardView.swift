//
//  MarathonCardView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI

struct MarathonCardView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .shadow(radius: 4)
            HStack {
                Image(systemName: "figure.run")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .padding()
                Text("Marathon Running Program")
                    .font(.headline)
                    .padding()
                Spacer()
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        // Add an invisible background to force hit-testing:
        .background(Color.clear)
        // This ensures the entire area is tappable:
        .contentShape(Rectangle())
    }
}

struct MarathonCardView_Previews: PreviewProvider {
    static var previews: some View {
        MarathonCardView()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
