//
//  ChatBubbleView.swift
//  Runr
//
//  Created by Noah Moran on 23/3/2025.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: Message
    let currentUserId: String
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        HStack {
            if message.senderId == viewModel.currentUserId {
                Spacer()
                VStack(alignment: .trailing, spacing: 4){
                    Text(message.text)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    // Timestamp
                    Text(message.timestamp, style: .time) // or .date, .relative, etc.
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                    .id(message.id) // Assign ID for scrolling
            } else {
                VStack(alignment: .leading, spacing: 4) {
                                // Message text
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(20)
                                
                                // Timestamp
                                Text(message.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .id(message.id)
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}


#Preview {
    let sampleMessage = Message(
        id: "1",
        senderId: "testUserId",
        text: "Hello world",
        timestamp: Date()
    )
    
    return ChatBubbleView(
        message: sampleMessage,
        currentUserId: "testUserId"
    )
}

