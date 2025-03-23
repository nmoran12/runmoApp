//
//  ChatView.swift
//  Runr
//
//  Created by Noah Moran on 11/2/2025.
//

import SwiftUI

struct ChatView: View {
    let conversationId: String
    let userId: String
    @State private var messageText: String = ""
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 1) Scrollable messages
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message, currentUserId: viewModel.currentUserId)
                                .id(message.id)
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        scrollToLastMessage(scrollViewProxy)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToLastMessage(scrollViewProxy)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The scroll view expands to fill available space
            
            // 2) The input bar, pinned at bottom
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Chat")
        .onAppear {
            viewModel.loadMessages(conversationId: conversationId)
            viewModel.loadUserProfile(userId: userId)
        }
        // 3) Allow the keyboard to cover the bottom safe area if needed
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    func scrollToLastMessage(_ scrollViewProxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    func sendMessage() {
        viewModel.sendMessage(conversationId: conversationId, text: messageText)
        messageText = ""
    }
}




#Preview {
    ChatView(conversationId: "testConversationId", userId: "testUserId")
}


