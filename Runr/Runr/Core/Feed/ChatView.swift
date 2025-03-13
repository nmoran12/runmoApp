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
        VStack {
            ScrollViewReader { scrollViewProxy in // Define scrollViewProxy
                ScrollView {
                    VStack {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.senderId == viewModel.currentUserId {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .id(message.id) // Assign ID for scrolling
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(20)
                                        .id(message.id) // Assign ID for scrolling
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom) // Auto-scroll to bottom
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom) // Scroll on view appear
                            }
                        }
                    }
                }
            }
            
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
    }

    func sendMessage() {
        viewModel.sendMessage(conversationId: conversationId, text: messageText)
        messageText = ""
    }
}



#Preview {
    ChatView(conversationId: "testConversationId", userId: "testUserId")
}


