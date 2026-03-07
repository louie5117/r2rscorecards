// RealtimeService.swift
// Supabase Realtime subscriptions for live collaborative scoring.
//
// Subscribe to a fight+group channel to receive round score updates
// from all group members in real time as they score each round.

import Foundation
import Combine
import Supabase

@MainActor
final class RealtimeService: ObservableObject {

    // MARK: - Published State

    /// Latest round scores keyed by userId string, then by round number.
    /// Populated and updated as Realtime events arrive.
    @Published var liveScores: [String: [Int: SBLiveRoundScore]] = [:]

    /// Fires when a group member submits (locks) their scorecard.
    @Published var submittedUserIds: Set<String> = []

    // MARK: - Private

    private var activeChannel: RealtimeChannelV2?

    // MARK: - Subscribe

    /// Subscribes to live round score updates for a fight within a group.
    /// Call this when the user opens a group scoring session.
    ///
    /// - Parameters:
    ///   - fightId:  The fight being scored.
    ///   - groupId:  The group whose members' scores to observe.
    func subscribe(fightId: UUID, groupId: UUID) async {
        // Clean up any existing subscription first
        await unsubscribe()

        let channelName = "fight-\(fightId.uuidString)-group-\(groupId.uuidString)"
        let channel = supabase.channel(channelName)

        // Listen for INSERT and UPDATE on round_scores for this fight
        let roundScoreChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "round_scores",
            filter: "fight_id=eq.\(fightId.uuidString)"
        )

        // Listen for scorecard submissions (submitted_at set → not null)
        let scorecardChanges = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "scorecards",
            filter: "fight_id=eq.\(fightId.uuidString)"
        )

        await channel.subscribe()
        activeChannel = channel

        // Load initial state from the live view before streaming starts
        await loadInitialScores(fightId: fightId, groupId: groupId)

        // Stream round score changes
        Task {
            for await change in roundScoreChanges {
                await handleRoundScoreChange(change, fightId: fightId, groupId: groupId)
            }
        }

        // Stream scorecard submission events
        Task {
            for await update in scorecardChanges {
                handleScorecardUpdate(update)
            }
        }
    }

    // MARK: - Unsubscribe

    func unsubscribe() async {
        if let channel = activeChannel {
            await supabase.removeChannel(channel)
            activeChannel = nil
        }
        liveScores = [:]
        submittedUserIds = []
    }

    // MARK: - Private Helpers

    private func loadInitialScores(fightId: UUID, groupId: UUID) async {
        do {
            let scores: [SBLiveRoundScore] = try await supabase
                .from("live_group_round_scores")
                .select()
                .eq("fight_id", value: fightId.uuidString)
                .eq("group_id", value: groupId.uuidString)
                .execute()
                .value

            for score in scores {
                let userId = score.userId.uuidString
                if liveScores[userId] == nil { liveScores[userId] = [:] }
                liveScores[userId]?[score.round] = score

                if score.submittedAt != nil {
                    submittedUserIds.insert(userId)
                }
            }
        } catch {
            // Non-fatal: stream will still populate scores as events arrive
        }
    }

    private func handleRoundScoreChange(_ change: AnyAction, fightId: UUID, groupId: UUID) async {
        // Refetch from the live view to get the full row (including display_name)
        // This is simpler than parsing the raw Realtime payload.
        do {
            let scores: [SBLiveRoundScore] = try await supabase
                .from("live_group_round_scores")
                .select()
                .eq("fight_id", value: fightId.uuidString)
                .eq("group_id", value: groupId.uuidString)
                .execute()
                .value

            var updated: [String: [Int: SBLiveRoundScore]] = [:]
            for score in scores {
                let userId = score.userId.uuidString
                if updated[userId] == nil { updated[userId] = [:] }
                updated[userId]?[score.round] = score
            }
            liveScores = updated
        } catch {
            // Ignore fetch errors — next event will retry
        }
    }

    private func handleScorecardUpdate(_ update: UpdateAction) {
        // Check if submitted_at changed to a non-null value
        if let submittedAt = update.record["submitted_at"],
           case .string = submittedAt,
           let userIdValue = update.record["user_id"],
           case .string(let userId) = userIdValue {
            submittedUserIds.insert(userId)
        }
    }
}

// MARK: - SwiftUI Usage Example
//
// @StateObject private var realtime = RealtimeService()
//
// .task {
//     await realtime.subscribe(fightId: fight.id, groupId: group.id)
// }
// .onDisappear {
//     Task { await realtime.unsubscribe() }
// }
//
// // In the view body:
// ForEach(Array(realtime.liveScores.keys), id: \.self) { userId in
//     let roundScores = realtime.liveScores[userId]?.values.sorted { $0.round < $1.round }
//     // render each member's scores
// }
