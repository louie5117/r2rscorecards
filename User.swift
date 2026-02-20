import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var authUserID: String?
    var displayName: String
    var region: String // e.g., ISO country/region code or freeform
    var gender: String // e.g., "male", "female", "nonbinary", "unspecified"
    var ageGroup: String // e.g., "18-24", "25-34", etc.

    // Inverse relationship from Scorecard.user
    var scorecards: [Scorecard]
    @Relationship(inverse: \FriendGroup.members)
    var friendGroups: [FriendGroup]

    init(id: UUID = UUID(), authUserID: String? = nil, displayName: String, region: String, gender: String, ageGroup: String, scorecards: [Scorecard] = [], friendGroups: [FriendGroup] = []) {
        self.id = id
        self.authUserID = authUserID
        self.displayName = displayName
        self.region = region
        self.gender = gender
        self.ageGroup = ageGroup
        self.scorecards = scorecards
        self.friendGroups = friendGroups
    }
}
enum Gender: String, CaseIterable, Identifiable { 
    case male, female, nonbinary, unspecified
    var id: String { rawValue } 
}

enum AgeGroup: String, CaseIterable, Identifiable {
    case under18 = "<18"
    case a18_24 = "18-24"
    case a25_34 = "25-34"
    case a35_44 = "35-44"
    case a45_54 = "45-54"
    case a55_64 = "55-64"
    case a65plus = "65+"
    var id: String { rawValue }
}

extension User {
    var genderEnum: Gender {
        get { Gender(rawValue: gender) ?? .unspecified }
        set { gender = newValue.rawValue }
    }
    var ageGroupEnum: AgeGroup? {
        get { AgeGroup(rawValue: ageGroup) }
        set { ageGroup = newValue?.rawValue ?? "" }
    }
}
