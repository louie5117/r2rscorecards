//
//  FriendRequestsView.swift
//  r2rscorecards
//
//  View and manage friend requests
//

import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @StateObject private var friendRequestService = FriendRequestService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Tab = .received
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum Tab: String, CaseIterable {
        case received = "Received"
        case sent = "Sent"
        case friends = "Friends"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                Group {
                    switch selectedTab {
                    case .received:
                        receivedRequestsList
                    case .sent:
                        sentRequestsList
                    case .friends:
                        friendsList
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .alert("Friend Request", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Received Requests
    
    private var receivedRequestsList: some View {
        Group {
            if friendRequestService.isLoading {
                ProgressView()
                    .padding()
            } else if friendRequestService.pendingRequests.isEmpty {
                ContentUnavailableView(
                    "No Pending Requests",
                    systemImage: "tray",
                    description: Text("You don't have any pending friend requests")
                )
            } else {
                List(friendRequestService.pendingRequests) { request in
                    ReceivedRequestRow(request: request) { action in
                        await handleReceivedRequest(request, action: action)
                    }
                }
            }
        }
    }
    
    // MARK: - Sent Requests
    
    private var sentRequestsList: some View {
        Group {
            if friendRequestService.isLoading {
                ProgressView()
                    .padding()
            } else if friendRequestService.sentRequests.isEmpty {
                ContentUnavailableView(
                    "No Sent Requests",
                    systemImage: "paperplane",
                    description: Text("You haven't sent any friend requests yet")
                )
            } else {
                List(friendRequestService.sentRequests) { request in
                    SentRequestRow(request: request) {
                        await cancelRequest(request)
                    }
                }
            }
        }
    }
    
    // MARK: - Friends List
    
    private var friendsList: some View {
        Group {
            if friendRequestService.isLoading {
                ProgressView()
                    .padding()
            } else if friendRequestService.friends.isEmpty {
                ContentUnavailableView(
                    "No Friends Yet",
                    systemImage: "person.2.slash",
                    description: Text("Send friend requests to connect with other users")
                )
            } else {
                List(friendRequestService.friends) { friend in
                    FriendRow(friend: friend) {
                        await removeFriend(friend)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadData() async {
        guard let userId = supabaseAuth.currentUserId else { return }
        
        do {
            async let received = friendRequestService.fetchPendingRequests(userId: userId)
            async let sent = friendRequestService.fetchSentRequests(userId: userId)
            async let friends = friendRequestService.fetchFriends(userId: userId)
            
            _ = try await (received, sent, friends)
        } catch {
            alertMessage = "Failed to load data: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func handleReceivedRequest(_ request: SBFriendRequestWithProfiles, action: RequestAction) async {
        guard let userId = supabaseAuth.currentUserId else { return }
        
        do {
            switch action {
            case .accept:
                try await friendRequestService.acceptRequest(
                    request.id,
                    fromUserId: request.fromUserId,
                    toUserId: userId
                )
                alertMessage = "Friend request accepted!"
                showAlert = true
                
            case .reject:
                try await friendRequestService.rejectRequest(request.id, userId: userId)
                alertMessage = "Friend request declined"
                showAlert = true
            }
        } catch {
            alertMessage = "Failed: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func cancelRequest(_ request: SBFriendRequestWithProfiles) async {
        guard let userId = supabaseAuth.currentUserId else { return }
        
        do {
            try await friendRequestService.cancelRequest(request.id, userId: userId)
        } catch {
            alertMessage = "Failed to cancel request: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func removeFriend(_ friend: SBProfile) async {
        guard let userId = supabaseAuth.currentUserId else { return }
        
        do {
            try await friendRequestService.removeFriend(userId: userId, friendId: friend.id)
            alertMessage = "Removed \(friend.displayName) from friends"
            showAlert = true
        } catch {
            alertMessage = "Failed to remove friend: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Request Action

enum RequestAction {
    case accept
    case reject
}

// MARK: - Received Request Row

struct ReceivedRequestRow: View {
    let request: SBFriendRequestWithProfiles
    let onAction: (RequestAction) async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text((request.fromUserProfile?.displayName ?? "?").prefix(1).uppercased())
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUserProfile?.displayName ?? "Unknown User")
                        .font(.headline)
                    
                    Text(request.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Message
            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button {
                    Task {
                        await onAction(.accept)
                    }
                } label: {
                    Label("Accept", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    Task {
                        await onAction(.reject)
                    }
                } label: {
                    Label("Decline", systemImage: "xmark.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Sent Request Row

struct SentRequestRow: View {
    let request: SBFriendRequestWithProfiles
    let onCancel: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text((request.toUserProfile?.displayName ?? "?").prefix(1).uppercased())
                        .font(.headline.bold())
                        .foregroundStyle(.gray)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.toUserProfile?.displayName ?? "Unknown User")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Pending • \(request.createdAt, style: .relative)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Cancel Button
            Button(role: .destructive) {
                Task {
                    await onCancel()
                }
            } label: {
                Text("Cancel")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend: SBProfile
    let onRemove: () async -> Void
    
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                if let email = friend.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !friend.region.isEmpty {
                    Label(friend.region, systemImage: "globe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(role: .destructive) {
                showRemoveConfirmation = true
            } label: {
                Image(systemName: "person.fill.xmark")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task {
                    await onRemove()
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .confirmationDialog("Remove Friend", isPresented: $showRemoveConfirmation) {
            Button("Remove \(friend.displayName)", role: .destructive) {
                Task {
                    await onRemove()
                }
            }
        } message: {
            Text("Are you sure you want to remove \(friend.displayName) from your friends?")
        }
    }
}

#Preview {
    FriendRequestsView()
        .environmentObject(SupabaseAuthService())
}
