//
//  CalendarButtonView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

struct CalendarButtonView: View {
    var action: () -> Void
    

    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .bold)) // Smaller icon
                .foregroundColor(.primary)              // Black icon
                .frame(width: 40, height: 40)            // Smaller frame
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: Color.primary.opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }
}

#Preview {
    CalendarButtonView {
        print("Calendar tapped")
    }
}




