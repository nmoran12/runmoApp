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
    @Environment(\.dismiss) private var dismiss  // For dismissing the view

    var filteredConversations: [Conversation] {
      let sorted = viewModel.conversations.sorted {
        ($0.lastMessage?.timestamp ?? .distantPast) >
        ($1.lastMessage?.timestamp ?? .distantPast)
      }
      let bySearch = searchText.isEmpty
        ? sorted
        : sorted.filter { $0.otherUserName?.lowercased().contains(searchText.lowercased()) == true }
      // drop any with no “other user”
      return bySearch.filter { $0.otherUserId != nil }
    }

    
    var body: some View {
        NavigationStack {
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
                  // only keep ones with a valid otherUserId
                  ForEach(filteredConversations.filter { $0.otherUserId != nil }) { convo in
                    NavigationLink(
                      destination: ChatView(
                        conversationId: convo.id,
                        // force‐unwrap is safe now because we filtered out nil
                        userId: convo.otherUserId!
                      )
                    ) {
                      conversationRow(convo)
                    }
                    .padding(.vertical, 6)
                    .listRowSeparator(.hidden)
                  }
                }
                .listStyle(PlainListStyle())

            }
            // Custom toolbar for a back button style nav bar
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Messages")
                        }
                        .font(.system(size: 20, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
    // Add a drag gesture to the entire NavigationStack to dismiss on a right swipe.
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        // Check if swipe is predominantly rightward (translation.width > 100)
                        // and vertical movement is minimal.
                        if value.translation.width > 100 && abs(value.translation.height) < 50 {
                            dismiss()
                        }
                    }
            )
        }
    }
    
    // MARK: - Conversation Row
    @ViewBuilder
    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            // Profile Image
            if let urlString = conversation.otherUserProfileUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }
            
            // Conversation info
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
                Text(timeAgoString(from: timestamp))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
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

