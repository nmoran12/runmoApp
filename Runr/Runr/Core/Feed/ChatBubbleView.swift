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
    @ObservedObject var viewModel: ChatViewModel
    @State private var showReactions = false
    
    // A helper view that displays reaction badges in a horizontal stack
    private func reactionBadges(for alignment: Alignment) -> some View {
        // Get the reactions (if any) sorted by key (or you can sort as needed)
        let reactions = message.reactions ?? [:]
        return HStack(spacing: 4) {
            ForEach(Array(reactions.keys), id: \.self) { userId in
                if let reaction = reactions[userId] {
                    Text(reaction)
                        .font(.system(size: 16))
                        .padding(6)
                        .background(Circle().fill(Color.white))
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(radius: 2)
                }
            }
        }
        // Adjust the alignment by adding padding and offset
        .padding(.top, 4)
        .padding(alignment == .topTrailing ? .trailing : .leading, 4)
    }
    
    var body: some View {
        HStack {
            if message.senderId == currentUserId {
                // Right-aligned bubble for current user
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Text(message.text)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .onLongPressGesture {
                                showReactions = true
                            }
                        
                        // Show all reactions in the top-right corner
                        if let reactions = message.reactions, !reactions.isEmpty {
                            reactionBadges(for: .topTrailing)
                                .offset(x: 10, y: -10)
                        }
                    }
                    
                    // Timestamp
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .id(message.id)
            } else {
                // Left-aligned bubble for other user
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        Text(message.text)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .onLongPressGesture {
                                showReactions = true
                            }
                        
                        if let reactions = message.reactions, !reactions.isEmpty {
                            reactionBadges(for: .topLeading)
                                .offset(x: -10, y: -10)
                        }
                    }
                    
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
        .overlay(
            // Reaction picker appears on long press
            Group {
                if showReactions {
                    ReactionView { selectedReaction in
                        viewModel.addReaction(to: message, reaction: selectedReaction)
                        showReactions = false
                    }
                    .offset(y: -60)
                }
            }
        )
    }
}

#Preview {
    // For preview purposes, simulate a message with multiple reactions:
    let sampleMessage = Message(
        id: "1",
        senderId: "testUserId",
        text: "Hello world",
        timestamp: Date(),
        reactions: ["user1": "❤️", "user2": "😂"]
    )
    
    let sharedViewModel = ChatViewModel()
    sharedViewModel.conversationId = "testConversationId"
    
    return ChatBubbleView(message: sampleMessage, currentUserId: "testUserId", viewModel: sharedViewModel)
}

