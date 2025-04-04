//
//  SplitsView.swift
//  Runr
//
//  Created by Noah Moran on 25/3/2025.
//

import SwiftUI

struct SplitsView: View {
    let splits: [Split]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Splits")
                .font(.title2)
                .padding(.bottom, 4)
            
            ForEach(splits, id: \.splitNumber) { split in
                HStack {
                    Text("KM \(split.splitNumber)")
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    // Format the pace as min:sec per km
                    let minutes = Int(split.pace) / 60
                    let seconds = Int(split.pace) % 60
                    Text("\(minutes):\(String(format: "%02d", seconds)) / km")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
    }
}


#Preview {
    SplitsView(splits: [
        Split(splitNumber: 1, distanceMeters: 1000, splitTime: 300),
        Split(splitNumber: 2, distanceMeters: 1000, splitTime: 320)
    ])
}

