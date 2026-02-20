import Foundation
import SwiftData

@Model
final class FriendGroup {
    var id: UUID
    var inviteCode: String
    var name: String
    @Relationship(inverse: \Fight.friendGroups)
    var fight: Fight?
    var members: [User]

    init(id: UUID = UUID(), name: String, inviteCode: String = String(UUID().uuidString.prefix(6)).uppercased(), fight: Fight? = nil, members: [User] = []) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.fight = fight
        self.members = members
    }
}
