//
//  Boxer.swift
//  r2rscorecards
//
//  SwiftData model for a boxer profile with career statistics.
//

import Foundation
import SwiftData

/// Professional boxer profile with career record and metadata.
@Model
final class Boxer {
    var id: UUID = UUID()

    // MARK: - Identity
    var name: String = ""
    var nickname: String?
    var nationality: String?
    var dateOfBirth: Date?
    var birthCity: String?
    var birthCountry: String?

    // MARK: - Physical
    /// "orthodox" | "southpaw" | "switch"
    var stance: String?
    var heightCm: Double?
    var reachCm: Double?
    /// Canonical weight class string matching the DB enum
    var weightClass: String?

    // MARK: - Career Record (denormalised for fast display)
    var wins: Int = 0
    var losses: Int = 0
    var draws: Int = 0
    var noContests: Int = 0
    var kos: Int = 0   // KO wins
    var tkos: Int = 0  // TKO wins

    // MARK: - Status
    var isActive: Bool = true
    var proDebut: Date?

    // MARK: - External IDs
    var boxrecID: String?
    var espnID: String?
    var sportsDbID: String?
    var wikidataID: String?

    // MARK: - Media
    var photoURL: String?

    // MARK: - Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        nickname: String? = nil,
        nationality: String? = nil,
        dateOfBirth: Date? = nil,
        stance: String? = nil,
        heightCm: Double? = nil,
        reachCm: Double? = nil,
        weightClass: String? = nil,
        wins: Int = 0,
        losses: Int = 0,
        draws: Int = 0,
        noContests: Int = 0,
        kos: Int = 0,
        tkos: Int = 0,
        isActive: Bool = true,
        espnID: String? = nil,
        sportsDbID: String? = nil,
        photoURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.nationality = nationality
        self.dateOfBirth = dateOfBirth
        self.stance = stance
        self.heightCm = heightCm
        self.reachCm = reachCm
        self.weightClass = weightClass
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.noContests = noContests
        self.kos = kos
        self.tkos = tkos
        self.isActive = isActive
        self.espnID = espnID
        self.sportsDbID = sportsDbID
        self.photoURL = photoURL
    }

    // MARK: - Computed

    /// "33-0-1" style record string
    var recordString: String { "\(wins)-\(losses)-\(draws)" }

    /// KO percentage of wins
    var koPercentage: Double {
        guard wins > 0 else { return 0 }
        return Double(kos + tkos) / Double(wins) * 100
    }

    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}
