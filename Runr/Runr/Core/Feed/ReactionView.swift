//
//  ReactionView.swift
//  Runr
//
//  Created by Noah Moran on 3/4/2025.
//

import SwiftUI

struct ReactionView: View {
    // List of reactions you want to support
    private let reactions = ["❤️", "👍", "😂", "😮", "😢", "👏"]
    var onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(reactions, id: \.self) { reaction in
                Text(reaction)
                    .font(.system(size: 24))
                    .onTapGesture {
                        onSelect(reaction)
                    }
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}


#Preview {
    ReactionView { reaction in
        print("User selected reaction: \(reaction)")
    }
}

