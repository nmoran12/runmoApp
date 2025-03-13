//
//  MessagesView.swift
//  Runr
//
//  Created by Noah Moran on 11/2/2025.
//

import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var searchText = ""
    @State private var isShowingNewMessageView = false
    
    var filteredConversations: [Conversation] {
        let sortedConversations = viewModel.conversations.sorted {
            ($0.lastMessage?.timestamp ?? Date.distantPast) >
            ($1.lastMessage?.timestamp ?? Date.distantPast)
        }
        if searchText.isEmpty {
            return sortedConversations
        } else {
            return sortedConversations.filter { conversation in
                conversation.otherUserName?.lowercased()
                    .contains(searchText.lowercased()) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                TextField("Search", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Conversations List
                List {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(
                            destination: ChatView(
                                conversationId: conversation.id,
                                userId: conversation.otherUserId ?? ""
                            )
                        ) {
                            conversationRow(conversation)
                        }
                        .padding(.vertical, 6)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
            // Navigation Title (inline style)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            // Trailing button for new message
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingNewMessageView.toggle()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isShowingNewMessageView) {
                NewMessageView(isPresented: $isShowingNewMessageView)
            }
            .onAppear {
                viewModel.fetchConversations()
            }
        }
    }
    
    // MARK: - Conversation Row (optional layout)
    @ViewBuilder
    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            // Placeholder profile image
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUserName ?? "Unknown User")
                    .font(.system(size: 15, weight: .semibold))
                
                Text(conversation.lastMessage?.text ?? "No messages yet")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let timestamp = conversation.lastMessage?.timestamp {
                Text(timeAgoString(from: timestamp)) // e.g. "10m", "2h", etc.
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
    }
}

// Example time-ago function (optional)
fileprivate func timeAgoString(from date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    let minutes = Int(interval / 60)
    if minutes < 1 {
        return "Now"
    } else if minutes < 60 {
        return "\(minutes)m"
    } else if minutes < 1440 {
        let hours = minutes / 60
        return "\(hours)h"
    } else {
        let days = minutes / 1440
        return "\(days)d"
    }
}

#Preview {
    MessagesView()
}

