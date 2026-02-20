import Foundation
import SwiftData

@Model
final class Scorecard {
    var id: UUID
    var title: String
    var createdAt: Date
    var totalRed: Int
    var totalBlue: Int

    // Link to User
    @Relationship(inverse: \User.scorecards)
    var user: User?

    // Parent relationship to Fight (inverse handled on this side)
    @Relationship(inverse: \Fight.scorecards)
    var fight: Fight?

    @Relationship
    var group: FriendGroup?

    var submittedAt: Date?

    // Child relationship to RoundScore (let RoundScore declare inverse back to Scorecard)
    var rounds: [RoundScore]

    init(id: UUID = UUID(), title: String, createdAt: Date = .now, totalRed: Int = 0, totalBlue: Int = 0, user: User? = nil, fight: Fight? = nil, group: FriendGroup? = nil, submittedAt: Date? = nil, rounds: [RoundScore] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.totalRed = totalRed
        self.totalBlue = totalBlue
        self.user = user
        self.fight = fight
        self.group = group
        self.submittedAt = submittedAt
        self.rounds = rounds
    }

    var computedRedTotal: Int {
        rounds.reduce(0) { $0 + $1.redScore }
    }

    var computedBlueTotal: Int {
        rounds.reduce(0) { $0 + $1.blueScore }
    }

    var isSubmitted: Bool {
        submittedAt != nil
    }
}
