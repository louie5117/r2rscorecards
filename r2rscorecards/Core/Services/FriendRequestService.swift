//
//  FriendRequestService.swift
//  r2rscorecards
//
//  Manage friend requests and invitations
//

import Foundation
import Combine
import Supabase

@MainActor
final class FriendRequestService: ObservableObject {
    
    @Published var pendingRequests: [SBFriendRequestWithProfiles] = []
    @Published var sentRequests: [SBFriendRequestWithProfiles] = []
    @Published var friends: [SBProfile] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MARK: - Send Friend Request
    
    /// Send a friend request to another user
    func sendFriendRequest(
        from fromUserId: UUID,
        to toUserId: UUID,
        groupId: UUID? = nil,
        message: String? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Check if request already exists
        let existing: [SBFriendRequest] = try await supabase
            .from("friend_requests")
            .select()
            .eq("from_user_id", value: fromUserId.uuidString)
            .eq("to_user_id", value: toUserId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        
        if !existing.isEmpty {
            throw FriendRequestError.requestAlreadyExists
        }
        
        // Check if already friends
        let friendship: [SBFriendship] = try await supabase
            .from("friendships")
            .select()
            .or("and(user_id.eq.\(fromUserId.uuidString),friend_id.eq.\(toUserId.uuidString)),and(user_id.eq.\(toUserId.uuidString),friend_id.eq.\(fromUserId.uuidString))")
            .execute()
            .value
        
        if !friendship.isEmpty {
            throw FriendRequestError.alreadyFriends
        }
        
        // Create the friend request
        let insert = SBFriendRequestInsert(
            fromUserId: fromUserId,
            toUserId: toUserId,
            groupId: groupId,
            message: message
        )
        
        try await supabase
            .from("friend_requests")
            .insert(insert)
            .execute()
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch pending friend requests received by the user
    func fetchPendingRequests(userId: UUID) async throws -> [SBFriendRequestWithProfiles] {
        isLoading = true
        defer { isLoading = false }
        
        // Note: This requires a database view or manual join
        // For now, fetch requests and profiles separately
        let requests: [SBFriendRequest] = try await supabase
            .from("friend_requests")
            .select()
            .eq("to_user_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Fetch sender profiles
        let senderIds = requests.map { $0.fromUserId }
        guard !senderIds.isEmpty else {
            pendingRequests = []
            return []
        }
        
        let profiles: [SBProfile] = try await supabase
            .from("profiles")
            .select()
            .in("id", values: senderIds.map { $0.uuidString })
            .execute()
            .value
        
        // Map profiles to requests
        let profileDict = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
        
        let requestsWithProfiles = requests.map { request in
            SBFriendRequestWithProfiles(
                id: request.id,
                fromUserId: request.fromUserId,
                toUserId: request.toUserId,
                status: request.status,
                groupId: request.groupId,
                message: request.message,
                createdAt: request.createdAt,
                respondedAt: request.respondedAt,
                fromUserProfile: profileDict[request.fromUserId],
                toUserProfile: nil
            )
        }
        
        pendingRequests = requestsWithProfiles
        return requestsWithProfiles
    }
    
    /// Fetch friend requests sent by the user
    func fetchSentRequests(userId: UUID) async throws -> [SBFriendRequestWithProfiles] {
        isLoading = true
        defer { isLoading = false }
        
        let requests: [SBFriendRequest] = try await supabase
            .from("friend_requests")
            .select()
            .eq("from_user_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Fetch recipient profiles
        let recipientIds = requests.map { $0.toUserId }
        guard !recipientIds.isEmpty else {
            sentRequests = []
            return []
        }
        
        let profiles: [SBProfile] = try await supabase
            .from("profiles")
            .select()
            .in("id", values: recipientIds.map { $0.uuidString })
            .execute()
            .value
        
        let profileDict = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
        
        let requestsWithProfiles = requests.map { request in
            SBFriendRequestWithProfiles(
                id: request.id,
                fromUserId: request.fromUserId,
                toUserId: request.toUserId,
                status: request.status,
                groupId: request.groupId,
                message: request.message,
                createdAt: request.createdAt,
                respondedAt: request.respondedAt,
                fromUserProfile: nil,
                toUserProfile: profileDict[request.toUserId]
            )
        }
        
        sentRequests = requestsWithProfiles
        return requestsWithProfiles
    }
    
    // MARK: - Respond to Request
    
    /// Accept a friend request
    func acceptRequest(_ requestId: UUID, fromUserId: UUID, toUserId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Update request status
        try await supabase
            .from("friend_requests")
            .update([
                "status": "accepted",
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: requestId.uuidString)
            .execute()
        
        // Create bidirectional friendship
        struct FriendshipInsert: Codable {
            let user_id: String
            let friend_id: String
        }
        
        // Add both directions
        let friendships = [
            FriendshipInsert(user_id: fromUserId.uuidString, friend_id: toUserId.uuidString),
            FriendshipInsert(user_id: toUserId.uuidString, friend_id: fromUserId.uuidString)
        ]
        
        try await supabase
            .from("friendships")
            .insert(friendships)
            .execute()
        
        // Refresh pending requests
        try await fetchPendingRequests(userId: toUserId)
    }
    
    /// Reject a friend request
    func rejectRequest(_ requestId: UUID, userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase
            .from("friend_requests")
            .update([
                "status": "rejected",
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: requestId.uuidString)
            .execute()
        
        // Refresh pending requests
        try await fetchPendingRequests(userId: userId)
    }
    
    /// Cancel a sent friend request
    func cancelRequest(_ requestId: UUID, userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase
            .from("friend_requests")
            .delete()
            .eq("id", value: requestId.uuidString)
            .execute()
        
        // Refresh sent requests
        try await fetchSentRequests(userId: userId)
    }
    
    // MARK: - Friends List
    
    /// Fetch all friends for a user
    func fetchFriends(userId: UUID) async throws -> [SBProfile] {
        isLoading = true
        defer { isLoading = false }
        
        // Get friend IDs
        let friendships: [SBFriendship] = try await supabase
            .from("friendships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let friendIds = friendships.map { $0.friendId }
        guard !friendIds.isEmpty else {
            friends = []
            return []
        }
        
        // Fetch friend profiles
        let profiles: [SBProfile] = try await supabase
            .from("profiles")
            .select()
            .in("id", values: friendIds.map { $0.uuidString })
            .order("display_name", ascending: true)
            .execute()
            .value
        
        friends = profiles
        return profiles
    }
    
    /// Remove a friend
    func removeFriend(userId: UUID, friendId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Remove both directions
        try await supabase
            .from("friendships")
            .delete()
            .or("and(user_id.eq.\(userId.uuidString),friend_id.eq.\(friendId.uuidString)),and(user_id.eq.\(friendId.uuidString),friend_id.eq.\(userId.uuidString))")
            .execute()
        
        // Refresh friends list
        try await fetchFriends(userId: userId)
    }
    
    /// Check if two users are friends
    func areFriends(userId: UUID, friendId: UUID) async throws -> Bool {
        let friendships: [SBFriendship] = try await supabase
            .from("friendships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("friend_id", value: friendId.uuidString)
            .execute()
            .value
        
        return !friendships.isEmpty
    }
}

// MARK: - Errors

enum FriendRequestError: LocalizedError {
    case requestAlreadyExists
    case alreadyFriends
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .requestAlreadyExists: return "Friend request already sent"
        case .alreadyFriends: return "You're already friends with this user"
        case .userNotFound: return "User not found"
        }
    }
}
