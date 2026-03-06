//
//  BoxingRules.swift
//  r2rscorecards
//
//  Boxing scoring rules validation and helpers
//

import Foundation

/// Enforces Queensberry Rules 10-Point Must System
enum BoxingRules {
    
    /// Validates a round score according to boxing rules
    /// - Parameters:
    ///   - redScore: Red corner score
    ///   - blueScore: Blue corner score
    /// - Returns: true if the score combination is valid
    static func isValidRoundScore(red: Int, blue: Int) -> Bool {
        // Both scores must be between 6 and 10
        guard (6...10).contains(red) && (6...10).contains(blue) else {
            return false
        }
        
        // Calculate the difference
        let diff = abs(red - blue)
        
        // Valid scenarios:
        // - 10-10 (even round)
        // - 10-9 (clear winner)
        // - 10-8 (dominant or knockdown)
        // - 10-7 (multiple knockdowns)
        // - 10-6 (extremely rare, multiple knockdowns)
        // - 9-9 (even round with point deductions to both)
        // - 9-8, 8-7, etc. (winner with deduction)
        
        // The winner should have at most 10 points
        let maxScore = max(red, blue)
        guard maxScore <= 10 else { return false }
        
        // The difference shouldn't be more than 4 points (extremely rare but possible)
        guard diff <= 4 else { return false }
        
        // If it's not 10-10 or 9-9, one fighter must have a higher score
        if red == blue && red != 10 && red != 9 {
            return false // 8-8, 7-7, 6-6 are not valid
        }
        
        return true
    }
    
    /// Common valid score combinations for quick selection
    static let commonScores: [(red: Int, blue: Int, description: String)] = [
        (10, 10, "Even Round"),
        (10, 9, "Red Wins Round"),
        (9, 10, "Blue Wins Round"),
        (10, 8, "Red Dominant/Knockdown"),
        (8, 10, "Blue Dominant/Knockdown"),
        (10, 7, "Red - Multiple Knockdowns"),
        (7, 10, "Blue - Multiple Knockdowns"),
        (9, 9, "Even Round (Both Deductions)"),
        (9, 8, "Red Wins (Deduction)"),
        (8, 9, "Blue Wins (Deduction)"),
    ]
    
    /// Returns a suggested default score when one fighter clearly won
    static func defaultScore(winner: Corner) -> (red: Int, blue: Int) {
        switch winner {
        case .red:
            return (10, 9)
        case .blue:
            return (9, 10)
        case .even:
            return (10, 10)
        }
    }
    
    /// Applies a point deduction to a score
    /// - Parameters:
    ///   - currentRed: Current red corner score
    ///   - currentBlue: Current blue corner score
    ///   - deductFrom: Which corner to deduct from
    ///   - points: Number of points to deduct (1 or 2)
    /// - Returns: New valid score after deduction
    static func applyDeduction(
        currentRed: Int,
        currentBlue: Int,
        deductFrom corner: Corner,
        points: Int = 1
    ) -> (red: Int, blue: Int) {
        var newRed = currentRed
        var newBlue = currentBlue
        
        switch corner {
        case .red:
            newRed = max(6, currentRed - points)
        case .blue:
            newBlue = max(6, currentBlue - points)
        case .even:
            // Deduct from both
            newRed = max(6, currentRed - points)
            newBlue = max(6, currentBlue - points)
        }
        
        return (newRed, newBlue)
    }
    
    /// Gets a description of what a score means
    static func scoreDescription(red: Int, blue: Int) -> String {
        if !isValidRoundScore(red: red, blue: blue) {
            return "Invalid score combination"
        }
        
        let diff = red - blue
        
        if diff == 0 {
            if red == 10 {
                return "Even round"
            } else if red == 9 {
                return "Even round with point deductions to both fighters"
            } else {
                return "Even round with multiple deductions"
            }
        } else if abs(diff) == 1 {
            let winner = diff > 0 ? "Red" : "Blue"
            if max(red, blue) == 10 {
                return "\(winner) wins round clearly"
            } else {
                return "\(winner) wins round (with deduction)"
            }
        } else if abs(diff) == 2 {
            let winner = diff > 0 ? "Red" : "Blue"
            return "\(winner) dominant round or knockdown"
        } else if abs(diff) == 3 {
            let winner = diff > 0 ? "Red" : "Blue"
            return "\(winner) - multiple knockdowns"
        } else {
            let winner = diff > 0 ? "Red" : "Blue"
            return "\(winner) - extremely dominant"
        }
    }
}

enum Corner {
    case red
    case blue
    case even
}
