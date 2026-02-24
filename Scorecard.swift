import Foundation
import SwiftData

/// A user's scoring record for a specific fight
/// Tracks individual round scores and provides computed totals
@Model
final class Scorecard {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date?

    // Relationships
    /// The user who created this scorecard
    var user: User?

    /// The fight this scorecard is scoring
    var fight: Fight?

    /// The friend group this scorecard belongs to
    var group: FriendGroup?

    /// When this scorecard was submitted (nil = draft)
    var submittedAt: Date?

    /// Individual round scores for this scorecard
    @Relationship(deleteRule: .cascade, inverse: \RoundScore.scorecard)
    var rounds: [RoundScore]? = []

    init(id: UUID = UUID(), title: String, createdAt: Date = .now, user: User? = nil, fight: Fight? = nil, group: FriendGroup? = nil, submittedAt: Date? = nil, rounds: [RoundScore] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.user = user
        self.fight = fight
        self.group = group
        self.submittedAt = submittedAt
        self.rounds = rounds
    }

    /// Total red corner score computed from all rounds
    var totalRed: Int {
        rounds?.reduce(0) { $0 + $1.redScore } ?? 0
    }

    /// Total blue corner score computed from all rounds
    var totalBlue: Int {
        rounds?.reduce(0) { $0 + $1.blueScore } ?? 0
    }

    /// Whether this scorecard has been submitted
    var isSubmitted: Bool {
        submittedAt != nil
    }
}
