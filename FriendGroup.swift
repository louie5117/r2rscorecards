import Foundation
import SwiftData

/// A group of users who can score fights together and compare results
/// Groups are joined via unique invite codes
@Model
final class FriendGroup {
    var id: UUID = UUID()
    /// Unique 6-character invite code for joining this group
    var inviteCode: String = String(UUID().uuidString.prefix(6)).uppercased()
    var name: String = ""
    
    // Relationships
    /// The fight this group is scoring
    var fight: Fight?
    
    /// Users who are members of this group
    var members: [User]? = []
    
    /// Scorecards associated with this group
    @Relationship(deleteRule: .cascade, inverse: \Scorecard.group)
    var scorecards: [Scorecard]? = []

    init(id: UUID = UUID(), name: String, inviteCode: String = String(UUID().uuidString.prefix(6)).uppercased(), fight: Fight? = nil, members: [User] = [], scorecards: [Scorecard] = []) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.fight = fight
        self.members = members
        self.scorecards = scorecards
    }
}
