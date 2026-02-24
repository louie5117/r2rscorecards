import Foundation
import SwiftData

/// Represents a combat sports fight event (boxing, MMA, etc.)
/// Contains fight metadata and relationships to scorecards, rounds, and friend groups
@Model
final class Fight {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date?
    var scheduledRounds: Int = 12
    var statusRaw: String = "upcoming" // "upcoming", "inProgress", or "complete"
    
    /// ID from external API (e.g., API-Sports fight ID)
    /// Used to aggregate global statistics across all users for the same fight
    var apiSourceID: String?

    // Relationships
    /// All scorecards created for this fight
    @Relationship(deleteRule: .cascade, inverse: \Scorecard.fight)
    var scorecards: [Scorecard]? = []
    
    /// All round scores across all scorecards for this fight
    @Relationship(deleteRule: .cascade, inverse: \RoundScore.fight)
    var rounds: [RoundScore]? = []
    
    /// Friend groups participating in this fight
    @Relationship(deleteRule: .cascade, inverse: \FriendGroup.fight)
    var friendGroups: [FriendGroup]? = []

    init(id: UUID = UUID(), title: String, date: Date = .now, scheduledRounds: Int, statusRaw: String = "upcoming", apiSourceID: String? = nil, scorecards: [Scorecard] = [], rounds: [RoundScore] = [], friendGroups: [FriendGroup] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.scheduledRounds = scheduledRounds
        self.statusRaw = statusRaw
        self.apiSourceID = apiSourceID
        self.scorecards = scorecards
        self.rounds = rounds
        self.friendGroups = friendGroups
    }
}
