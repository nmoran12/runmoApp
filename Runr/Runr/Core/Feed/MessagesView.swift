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
            ($0.lastMessage?.timestamp ?? Date.distantPast) > ($1.lastMessage?.timestamp ?? Date.distantPast)
        }

        if searchText.isEmpty {
            return sortedConversations
        } else {
            return sortedConversations.filter { conversation in
                conversation.otherUserName?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // Conversations List
                List(filteredConversations) { conversation in
                    NavigationLink(destination: ChatView(conversationId: conversation.id, userId: conversation.otherUserId ?? "")) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(conversation.otherUserName ?? "Unknown User")
                                    .font(.headline)
                                Text(conversation.lastMessage?.text ?? "No messages yet")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if let timestamp = conversation.lastMessage?.timestamp {
                                Text(timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("No timestamp")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                                Text("Messages")
                                    .fontWeight(.semibold)
                                    .font(.system(size: 24))
                        Spacer()
                    }
                }
            }
            .navigationBarItems(trailing:
                Button(action: {
                    isShowingNewMessageView.toggle()
                }) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                        .font(.title2)
                }
            )
            .sheet(isPresented: $isShowingNewMessageView) {
                NewMessageView(isPresented: $isShowingNewMessageView)
            }
            .onAppear {
                viewModel.fetchConversations()
            }
        }
    }
}

#Preview {
    MessagesView()
}
