// ScorecardService.swift
// CRUD operations for `scorecards` and `round_scores` tables.
// A scorecard is a draft until submitScorecard() is called, which locks it.

import Foundation
import Combine
import Supabase

@MainActor
final class ScorecardService: ObservableObject {

    @Published var currentScorecard: SBScorecard?
    @Published var currentRoundScores: [SBRoundScore] = []
    @Published var isLoading = false
    @Published var lastError: String?

    // MARK: - Scorecard Fetch

    /// Returns the user's existing scorecard for this fight/group combo, or nil if none exists.
    func fetchScorecard(fightId: UUID, userId: UUID, groupId: UUID?) async throws -> SBScorecard? {
        var query = supabase
            .from("scorecards")
            .select()
            .eq("fight_id", value: fightId.uuidString)
            .eq("user_id", value: userId.uuidString)

        if let groupId {
            query = query.eq("group_id", value: groupId.uuidString)
        } else {
            // Filter for NULL group_id (personal scorecards not tied to any group)
            query = query.filter("group_id", operator: "is", value: "null")
        }

        let results: [SBScorecard] = try await query.execute().value
        return results.first
    }

    /// Fetches all submitted scorecards for a fight (for analytics display).
    func fetchSubmittedScorecards(fightId: UUID) async throws -> [SBScorecard] {
        try await supabase
            .from("scorecards")
            .select()
            .eq("fight_id", value: fightId.uuidString)
            .not("submitted_at", operator: .is, value: "null")
            .execute()
            .value
    }

    // MARK: - Scorecard Create

    /// Creates a fresh draft scorecard. Errors if one already exists (use fetchScorecard first).
    @discardableResult
    func createScorecard(title: String, fightId: UUID, userId: UUID, groupId: UUID?) async throws -> SBScorecard {
        let insert = SBScorecardInsert(
            title: title,
            userId: userId,
            fightId: fightId,
            groupId: groupId
        )

        let scorecard: SBScorecard = try await supabase
            .from("scorecards")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        currentScorecard = scorecard
        return scorecard
    }

    // MARK: - Round Scores

    func fetchRoundScores(scorecardId: UUID) async throws -> [SBRoundScore] {
        let scores: [SBRoundScore] = try await supabase
            .from("round_scores")
            .select()
            .eq("scorecard_id", value: scorecardId.uuidString)
            .order("round", ascending: true)
            .execute()
            .value

        currentRoundScores = scores
        return scores
    }

    /// Insert or update a single round's scores.
    /// Only works while the parent scorecard is a draft (enforced by RLS).
    func upsertRoundScore(
        scorecardId: UUID,
        fightId: UUID,
        round: Int,
        redScore: Int,
        blueScore: Int
    ) async throws {
        let upsert = SBRoundScoreUpsert(
            scorecardId: scorecardId,
            fightId: fightId,
            round: round,
            redScore: redScore,
            blueScore: blueScore
        )

        try await supabase
            .from("round_scores")
            .upsert(upsert, onConflict: "scorecard_id,round")
            .execute()

        // Keep local state in sync
        if currentRoundScores.contains(where: { $0.round == round }) {
            // Replace in-place — refetch to get server-assigned id/scoredAt
            let updated = try await fetchRoundScores(scorecardId: scorecardId)
            currentRoundScores = updated
        }
    }

    // MARK: - Submit (Lock)

    /// Sets submitted_at to now, locking the scorecard against further edits.
    /// This is enforced server-side by the RLS `scorecards_update_own_draft` policy.
    func submitScorecard(id: UUID) async throws {
        try await supabase
            .from("scorecards")
            .update(["submitted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()

        if currentScorecard?.id == id {
            // Refresh to get the authoritative submitted_at from the server
            let updated: SBScorecard = try await supabase
                .from("scorecards")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            currentScorecard = updated
        }
    }
}
