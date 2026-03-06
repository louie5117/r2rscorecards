import Foundation
import SwiftData

/// Represents a user profile with optional demographic information
/// Links to Sign in with Apple via authUserID
@Model
final class User {
    var id: UUID = UUID()
    /// Apple Sign In user identifier (app-scoped)
    var authUserID: String?
    var displayName: String = ""
    /// ISO country/region code or freeform text
    var region: String = ""
    /// Gender identity (see Gender enum)
    var gender: String = "unspecified"
    /// Age range (see AgeGroup enum)
    var ageGroup: String = ""
    
    // Email/Password authentication fields
    /// User's email address (for email/password auth)
    var email: String?
    /// Hashed password (for email/password auth)
    var passwordHash: String?

    // Relationships
    /// All scorecards created by this user
    @Relationship(deleteRule: .nullify, inverse: \Scorecard.user)
    var scorecards: [Scorecard]? = []
    
    /// Friend groups this user belongs to
    @Relationship(inverse: \FriendGroup.members)
    var friendGroups: [FriendGroup]? = []

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
