// FightService.swift
// CRUD operations for the `fights` table.

import Foundation
import Supabase

@MainActor
final class FightService: ObservableObject {

    @Published var fights: [SBFight] = []
    @Published var isLoading = false
    @Published var lastError: String?

    // MARK: - Fetch

    func fetchUpcomingFights() async throws -> [SBFight] {
        isLoading = true
        defer { isLoading = false }

        let results: [SBFight] = try await supabase
            .from("fights")
            .select()
            .eq("status", value: "upcoming")
            .order("date", ascending: true)
            .execute()
            .value

        fights = results
        return results
    }

    func fetchFight(id: UUID) async throws -> SBFight {
        try await supabase
            .from("fights")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    /// Fetches all fights (any status), most recent first.
    func fetchAllFights() async throws -> [SBFight] {
        isLoading = true
        defer { isLoading = false }

        let results: [SBFight] = try await supabase
            .from("fights")
            .select()
            .order("date", ascending: false)
            .execute()
            .value

        fights = results
        return results
    }

    // MARK: - Insert

    /// Imports a fight from the external boxing API into Supabase.
    /// Uses `api_source_id` to deduplicate — safe to call multiple times.
    func importFight(from boxingFight: BoxingFight) async throws -> SBFight {
        let insert = SBFightInsert(
            title: boxingFight.displayTitle,
            date: boxingFight.date,
            scheduledRounds: boxingFight.rounds ?? 12,
            status: "upcoming",
            apiSourceId: boxingFight.id
        )

        // Upsert on api_source_id so duplicate imports are idempotent.
        let result: SBFight = try await supabase
            .from("fights")
            .upsert(insert, onConflict: "api_source_id")
            .select()
            .single()
            .execute()
            .value

        return result
    }

    // MARK: - Update Status

    func updateStatus(_ status: String, for fightId: UUID) async throws {
        try await supabase
            .from("fights")
            .update(["status": status])
            .eq("id", value: fightId.uuidString)
            .execute()
    }

    // MARK: - Analytics

    func fetchCrowdScore(fightId: UUID) async throws -> SBFightCrowdScore {
        try await supabase
            .from("fight_crowd_scores")
            .select()
            .eq("fight_id", value: fightId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchDemographicScores(fightId: UUID, dimension: String? = nil) async throws -> [SBDemographicScore] {
        var query = supabase
            .from("fight_demographic_scores")
            .select()
            .eq("fight_id", value: fightId.uuidString)

        if let dimension {
            query = query.eq("dimension", value: dimension)
        }

        return try await query.execute().value
    }
}
