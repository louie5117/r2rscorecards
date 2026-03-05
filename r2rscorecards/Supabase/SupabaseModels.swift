// SupabaseModels.swift
// Codable structs that mirror the Supabase PostgreSQL schema.
// These are the wire types used for encoding/decoding API responses.
// They are separate from the SwiftData @Model classes so both can
// coexist during the CloudKit → Supabase migration.

import Foundation

// MARK: - Profile

struct SBProfile: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let email: String?
    let region: String
    let gender: String
    let ageGroup: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName  = "display_name"
        case email
        case region
        case gender
        case ageGroup     = "age_group"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }
}

struct SBProfileUpdate: Codable {
    var displayName: String?
    var region: String?
    var gender: String?
    var ageGroup: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case region
        case gender
        case ageGroup    = "age_group"
    }
}

// MARK: - Fight

struct SBFight: Codable, Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let scheduledRounds: Int
    let status: String          // "upcoming" | "inProgress" | "complete"
    let apiSourceId: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case scheduledRounds = "scheduled_rounds"
        case status
        case apiSourceId     = "api_source_id"
        case createdBy       = "created_by"
        case createdAt       = "created_at"
        case updatedAt       = "updated_at"
    }
}

struct SBFightInsert: Codable {
    let title: String
    let date: Date
    let scheduledRounds: Int
    let status: String
    let apiSourceId: String?

    enum CodingKeys: String, CodingKey {
        case title
        case date
        case scheduledRounds = "scheduled_rounds"
        case status
        case apiSourceId     = "api_source_id"
    }
}

// MARK: - Friend Group

struct SBFriendGroup: Codable, Identifiable {
    let id: UUID
    let name: String
    let inviteCode: String
    let fightId: UUID
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode  = "invite_code"
        case fightId     = "fight_id"
        case createdBy   = "created_by"
        case createdAt   = "created_at"
    }
}

struct SBGroupMember: Codable {
    let groupId: UUID
    let userId: UUID
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case groupId   = "group_id"
        case userId    = "user_id"
        case joinedAt  = "joined_at"
    }
}

// MARK: - Scorecard

struct SBScorecard: Codable, Identifiable {
    let id: UUID
    let title: String
    let userId: UUID
    let fightId: UUID
    let groupId: UUID?
    let submittedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case userId      = "user_id"
        case fightId     = "fight_id"
        case groupId     = "group_id"
        case submittedAt = "submitted_at"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    var isSubmitted: Bool { submittedAt != nil }
}

struct SBScorecardInsert: Codable {
    let title: String
    let userId: UUID
    let fightId: UUID
    let groupId: UUID?

    enum CodingKeys: String, CodingKey {
        case title
        case userId  = "user_id"
        case fightId = "fight_id"
        case groupId = "group_id"
    }
}

// MARK: - Round Score

struct SBRoundScore: Codable, Identifiable {
    let id: UUID
    let scorecardId: UUID
    let fightId: UUID
    let round: Int
    let redScore: Int
    let blueScore: Int
    let scoredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case scorecardId = "scorecard_id"
        case fightId     = "fight_id"
        case round
        case redScore    = "red_score"
        case blueScore   = "blue_score"
        case scoredAt    = "scored_at"
    }
}

struct SBRoundScoreUpsert: Codable {
    let scorecardId: UUID
    let fightId: UUID
    let round: Int
    let redScore: Int
    let blueScore: Int

    enum CodingKeys: String, CodingKey {
        case scorecardId = "scorecard_id"
        case fightId     = "fight_id"
        case round
        case redScore    = "red_score"
        case blueScore   = "blue_score"
    }
}

// MARK: - Analytics

/// Maps to the `fight_crowd_scores` view.
struct SBFightCrowdScore: Codable {
    let fightId: UUID
    let scorecardCount: Int
    let avgScoreMargin: Double   // positive = red leads
    let totalRed: Int
    let totalBlue: Int
    let redRoundsWon: Int
    let blueRoundsWon: Int
    let evenRounds: Int

    enum CodingKeys: String, CodingKey {
        case fightId        = "fight_id"
        case scorecardCount = "scorecard_count"
        case avgScoreMargin = "avg_score_margin"
        case totalRed       = "total_red"
        case totalBlue      = "total_blue"
        case redRoundsWon   = "red_rounds_won"
        case blueRoundsWon  = "blue_rounds_won"
        case evenRounds     = "even_rounds"
    }
}

/// Maps to the `fight_demographic_scores` view.
struct SBDemographicScore: Codable {
    let fightId: UUID
    let dimension: String   // "region" | "gender" | "age_group"
    let segment: String
    let scorecardCount: Int
    let avgScoreMargin: Double
    let totalRed: Int
    let totalBlue: Int

    enum CodingKeys: String, CodingKey {
        case fightId        = "fight_id"
        case dimension
        case segment
        case scorecardCount = "scorecard_count"
        case avgScoreMargin = "avg_score_margin"
        case totalRed       = "total_red"
        case totalBlue      = "total_blue"
    }
}

/// Maps to the `live_group_round_scores` view.
struct SBLiveRoundScore: Codable {
    let groupId: UUID
    let fightId: UUID
    let userId: UUID
    let displayName: String
    let round: Int
    let redScore: Int
    let blueScore: Int
    let scoredAt: Date
    let submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case groupId     = "group_id"
        case fightId     = "fight_id"
        case userId      = "user_id"
        case displayName = "display_name"
        case round
        case redScore    = "red_score"
        case blueScore   = "blue_score"
        case scoredAt    = "scored_at"
        case submittedAt = "submitted_at"
    }
}
