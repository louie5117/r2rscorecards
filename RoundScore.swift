import Foundation
import SwiftData

/// Individual round score for red and blue corners
/// Belongs to both a fight and a specific scorecard
@Model
final class RoundScore {
    var id: UUID = UUID()
    /// Round number (1-based)
    var round: Int = 1
    /// Points awarded to red corner (typically 8-10)
    var redScore: Int = 10
    /// Points awarded to blue corner (typically 8-10)
    var blueScore: Int = 10

    // Relationships
    /// The fight this round belongs to
    var fight: Fight?

    /// The scorecard this round score is part of
    var scorecard: Scorecard?

    init(id: UUID = UUID(), round: Int, redScore: Int = 10, blueScore: Int = 10, fight: Fight? = nil, scorecard: Scorecard? = nil) {
        self.id = id
        self.round = round
        self.redScore = redScore
        self.blueScore = blueScore
        self.fight = fight
        self.scorecard = scorecard
    }
    
    /// Validates the score according to boxing rules
    var isValidScore: Bool {
        BoxingRules.isValidRoundScore(red: redScore, blue: blueScore)
    }
    
    /// Returns a description of what this score means
    var scoreDescription: String {
        BoxingRules.scoreDescription(red: redScore, blue: blueScore)
    }
    
    /// Returns true if this round has been scored (not 0-0)
    var isScored: Bool {
        redScore > 0 || blueScore > 0
    }
}

