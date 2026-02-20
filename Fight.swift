import Foundation
import SwiftData

@Model
final class Fight {
    var id: UUID
    var title: String
    var date: Date
    var scheduledRounds: Int
    var statusRaw: String

    // Relationships
    var scorecards: [Scorecard]
    var rounds: [RoundScore]
    var friendGroups: [FriendGroup]

    init(id: UUID = UUID(), title: String, date: Date = .now, scheduledRounds: Int, statusRaw: String = "upcoming", scorecards: [Scorecard] = [], rounds: [RoundScore] = [], friendGroups: [FriendGroup] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.scheduledRounds = scheduledRounds
        self.statusRaw = statusRaw
        self.scorecards = scorecards
        self.rounds = rounds
        self.friendGroups = friendGroups
    }
}
