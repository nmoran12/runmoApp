//
//  ChatView.swift
//  Runr
//
//  Created by Noah Moran on 11/2/2025.
//

//  This file displays a chat conversation using data from ChatViewModel.
//  It loads messages and the chat partner's profile, and provides an input
//  field to send messages. Custom navigation items display the partner's info.

import SwiftUI

struct ChatView: View {
    let conversationId: String
    let userId: String    // This is the chat partner's user ID
    @State private var messageText: String = ""
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable messages
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(
                                message: message,
                                currentUserId: viewModel.currentUserId,
                                viewModel: viewModel
                            )
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
            
            // Input bar
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    // Custom Back Button with left padding
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .padding(.leading, 8)
                    }
                    
                    if let partner = viewModel.userProfile {
                        // Display chat partner's profile picture and info
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(partner.username)
                                    .font(.headline)
                                Text(partner.realName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            viewModel.loadMessages(conversationId: conversationId)
            viewModel.loadUserProfile(userId: userId)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // Scrolls to the last message in the chat
    func scrollToLastMessage(_ scrollViewProxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    // Sends a new message and resets the input field
    func sendMessage() {
        viewModel.sendMessage(conversationId: conversationId, text: messageText)
        messageText = ""
    }
}

#Preview {
    ChatView(conversationId: "testConversationId", userId: "partnerUserId")
}



