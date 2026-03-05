//
//  UserSearchService.swift
//  r2rscorecards
//
//  Search for users by email or display name
//

import Foundation
import Combine
import Supabase

@MainActor
final class UserSearchService: ObservableObject {
    
    @Published var searchResults: [SBProfile] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MARK: - Search Users
    
    /// Search for users by display name or email
    /// Returns matching profiles (excluding the current user)
    func searchUsers(query: String, excludeUserId: UUID? = nil) async throws -> [SBProfile] {
        guard !query.isEmpty else {
            searchResults = []
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Search by display name OR email (case-insensitive)
        let results: [SBProfile] = try await supabase
            .from("profiles")
            .select()
            .or("display_name.ilike.%\(query)%,email.ilike.%\(query)%")
            .limit(50)
            .execute()
            .value
        
        // Filter out current user if provided
        let filtered: [SBProfile]
        if let excludeUserId {
            filtered = results.filter { $0.id != excludeUserId }
        } else {
            filtered = results
        }
        
        searchResults = filtered
        return filtered
    }
    
    /// Get a user profile by exact email
    func getUserByEmail(_ email: String) async throws -> SBProfile? {
        let results: [SBProfile] = try await supabase
            .from("profiles")
            .select()
            .eq("email", value: email.lowercased())
            .limit(1)
            .execute()
            .value
        
        return results.first
    }
    
    /// Get a user profile by ID
    func getUserById(_ userId: UUID) async throws -> SBProfile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }
    
    /// Get multiple user profiles by IDs
    func getUsersByIds(_ userIds: [UUID]) async throws -> [SBProfile] {
        guard !userIds.isEmpty else { return [] }
        
        let ids = userIds.map { $0.uuidString }
        return try await supabase
            .from("profiles")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }
}
