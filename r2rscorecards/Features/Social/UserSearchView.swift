//
//  UserSearchView.swift
//  r2rscorecards
//
//  Search for users and send friend requests
//

import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @StateObject private var searchService = UserSearchService()
    @StateObject private var friendRequestService = FriendRequestService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedUser: SBProfile?
    @State private var showSendRequest = false
    @State private var requestMessage = ""
    
    var groupId: UUID? = nil // Optional: for group invites
    
    var body: some View {
        if !(supabaseAuth.isAuthenticated) {
            ContentUnavailableView(
                "Sign-in required",
                systemImage: "person.crop.circle.badge.exclam",
                description: Text("Please sign in to use this feature.")
            )
        } else {
            NavigationStack {
                VStack {
                    // Search Results
                    if searchService.isLoading {
                        ProgressView("Searching...")
                            .padding()
                    } else if searchQuery.isEmpty {
                        ContentUnavailableView(
                            "Search for Users",
                            systemImage: "magnifyingglass",
                            description: Text("Enter a name or email address to find users")
                        )
                    } else if searchService.searchResults.isEmpty {
                        ContentUnavailableView(
                            "No Users Found",
                            systemImage: "person.slash",
                            description: Text("Try a different search term")
                        )
                    } else {
                        List(searchService.searchResults) { user in
                            UserSearchRow(user: user) {
                                selectedUser = user
                                showSendRequest = true
                            }
                        }
                    }
                }
                .searchable(text: $searchQuery, prompt: "Search by name or email")
                .onChange(of: searchQuery) { _, newValue in
                    Task { await performSearch(newValue) }
                }
                .navigationTitle("Find Users")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                }
                .alert("Send Friend Request", isPresented: $showSendRequest) {
                    TextField("Message (optional)", text: $requestMessage)
                    Button("Cancel", role: .cancel) { requestMessage = "" }
                    Button("Send") { Task { await sendFriendRequest() } }
                } message: { if let user = selectedUser { Text("Send a friend request to \(user.displayName)?") } }
                .alert("Friend Request", isPresented: $showAlert) { Button("OK") { } } message: { Text(alertMessage) }
            }
        }
    }
    
    // MARK: - Actions
    
    private func performSearch(_ query: String) async {
        guard let currentUserId = supabaseAuth.currentUserId else { return }
        
        do {
            _ = try await searchService.searchUsers(query: query, excludeUserId: currentUserId)
        } catch {
            alertMessage = "Search failed: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func sendFriendRequest() async {
        guard let currentUserId = supabaseAuth.currentUserId,
              let toUser = selectedUser else { return }
        
        do {
            try await friendRequestService.sendFriendRequest(
                from: currentUserId,
                to: toUser.id,
                groupId: groupId,
                message: requestMessage.isEmpty ? nil : requestMessage
            )
            
            alertMessage = "Friend request sent to \(toUser.displayName)!"
            showAlert = true
            requestMessage = ""
            selectedUser = nil
            
        } catch let error as FriendRequestError {
            alertMessage = error.localizedDescription
            showAlert = true
        } catch {
            alertMessage = "Failed to send request: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - User Search Row

struct UserSearchRow: View {
    let user: SBProfile
    let onSendRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.displayName.prefix(1).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                if let email = user.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 8) {
                    if !user.region.isEmpty {
                        Label(user.region, systemImage: "globe")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !user.gender.isEmpty && user.gender != "unspecified" {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(user.gender.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Send Request Button
            Button {
                onSendRequest()
            } label: {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    UserSearchView()
        .environmentObject(SupabaseAuthService())
}
