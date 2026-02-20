import Foundation
import SwiftData

@Model
final class RoundScore {
    var id: UUID
    var round: Int
    var redScore: Int
    var blueScore: Int

    // Parent links
    @Relationship(inverse: \Fight.rounds)
    var fight: Fight?

    @Relationship(inverse: \Scorecard.rounds)
    var scorecard: Scorecard?

    init(id: UUID = UUID(), round: Int, redScore: Int, blueScore: Int, fight: Fight? = nil, scorecard: Scorecard? = nil) {
        self.id = id
        self.round = round
        self.redScore = redScore
        self.blueScore = blueScore
        self.fight = fight
        self.scorecard = scorecard
    }
}
