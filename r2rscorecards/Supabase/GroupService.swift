// GroupService.swift
// Operations for `friend_groups` and `group_members` tables.
// Invite codes are generated server-side by the `generate_invite_code()` SQL function.

import Foundation
import Supabase

@MainActor
final class GroupService: ObservableObject {

    @Published var currentGroup: SBFriendGroup?
    @Published var groupMembers: [SBProfile] = []
    @Published var isLoading = false
    @Published var lastError: String?

    // MARK: - Create Group

    /// Creates a new group for a fight. The invite code is generated server-side.
    @discardableResult
    func createGroup(name: String, fightId: UUID, createdBy: UUID) async throws -> SBFriendGroup {
        isLoading = true
        defer { isLoading = false }

        // Call the SQL function to get a unique invite code, then insert.
        // The `generate_invite_code()` function is defined in schema.sql.
        let inviteCode: String = try await supabase
            .rpc("generate_invite_code")
            .execute()
            .value

        struct GroupInsert: Encodable {
            let name: String
            let invite_code: String
            let fight_id: String
            let created_by: String
        }

        let insert = GroupInsert(
            name: name,
            invite_code: inviteCode,
            fight_id: fightId.uuidString,
            created_by: createdBy.uuidString
        )

        let group: SBFriendGroup = try await supabase
            .from("friend_groups")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Auto-join the creator
        try await joinGroup(id: group.id, userId: createdBy)

        currentGroup = group
        return group
    }

    // MARK: - Join via Invite Code

    /// Looks up a group by invite code and adds the user as a member.
    @discardableResult
    func joinGroup(inviteCode: String, userId: UUID) async throws -> SBFriendGroup {
        isLoading = true
        defer { isLoading = false }

        let results: [SBFriendGroup] = try await supabase
            .from("friend_groups")
            .select()
            .eq("invite_code", value: inviteCode.uppercased())
            .limit(1)
            .execute()
            .value

        guard let group = results.first else {
            throw GroupError.invalidInviteCode
        }

        try await joinGroup(id: group.id, userId: userId)
        currentGroup = group
        return group
    }

    // MARK: - Fetch Group

    func fetchGroup(id: UUID) async throws -> SBFriendGroup {
        let group: SBFriendGroup = try await supabase
            .from("friend_groups")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        currentGroup = group
        return group
    }

    func fetchGroups(for fightId: UUID, userId: UUID) async throws -> [SBFriendGroup] {
        // Groups the current user belongs to for this fight
        let memberGroupIds: [SBGroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let ids = memberGroupIds.map { $0.groupId.uuidString }
        guard !ids.isEmpty else { return [] }

        let groups: [SBFriendGroup] = try await supabase
            .from("friend_groups")
            .select()
            .eq("fight_id", value: fightId.uuidString)
            .in("id", values: ids)
            .execute()
            .value

        return groups
    }

    // MARK: - Members

    func fetchMembers(groupId: UUID) async throws -> [SBProfile] {
        // Join group_members → profiles via a Supabase foreign-table select
        struct MemberRow: Decodable {
            let profiles: SBProfile
        }

        let rows: [MemberRow] = try await supabase
            .from("group_members")
            .select("profiles(*)")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value

        groupMembers = rows.map(\.profiles)
        return groupMembers
    }

    // MARK: - Leave Group

    func leaveGroup(groupId: UUID, userId: UUID) async throws {
        try await supabase
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()

        if currentGroup?.id == groupId {
            currentGroup = nil
            groupMembers = []
        }
    }

    // MARK: - Private Helpers

    private func joinGroup(id: UUID, userId: UUID) async throws {
        struct MemberInsert: Encodable {
            let group_id: String
            let user_id: String
        }

        try await supabase
            .from("group_members")
            .upsert(
                MemberInsert(group_id: id.uuidString, user_id: userId.uuidString),
                onConflict: "group_id,user_id"
            )
            .execute()
    }
}

// MARK: - Errors

enum GroupError: LocalizedError {
    case invalidInviteCode

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode: return "No group found with that invite code."
        }
    }
}
