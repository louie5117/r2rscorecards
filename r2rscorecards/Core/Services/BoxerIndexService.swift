//
//  BoxerIndexService.swift
//  r2rscorecards
//
//  Fetches boxer profiles and fight history from TheSportsDB (free tier).
//  TheSportsDB v1 is free, no API key required for public data.
//  Docs: https://www.thesportsdb.com/api.php
//

import Foundation
import Combine

// MARK: - TheSportsDB API Models

private struct TSDBSearchResponse: Decodable {
    let players: [TSDBPlayer]?
}

private struct TSDBEventsResponse: Decodable {
    let results: [TSDBEvent]?
    let events: [TSDBEvent]?

    var allEvents: [TSDBEvent] {
        (results ?? []) + (events ?? [])
    }
}

private struct TSDBPlayer: Decodable {
    let idPlayer: String?
    let strPlayer: String?           // Full name
    let strNationality: String?
    let dateBorn: String?
    let strBirthLocation: String?
    let strDescriptionEN: String?
    let strThumb: String?
    let strCutout: String?
    let strHeight: String?           // e.g. "6'1\" (185 cm)"
    let strWeight: String?           // e.g. "240 lbs (109 kg)"
    let intLoved: String?
}

private struct TSDBEvent: Decodable {
    let idEvent: String?
    let strEvent: String?            // "Fury vs Usyk"
    let dateEvent: String?           // "2024-05-18"
    let strTime: String?             // "21:00:00"
    let strVenue: String?
    let strCity: String?
    let strCountry: String?
    let intRound: String?            // rounds
    let strResult: String?           // "Usyk wins by Split Decision"
    let strHomeTeam: String?         // Red corner fighter
    let strAwayTeam: String?         // Blue corner fighter
    let intHomeScore: String?        // Red corner result code
    let intAwayScore: String?
    let strSeason: String?
    let strThumb: String?
    let strBanner: String?
    let strStatus: String?           // "Match Finished" | upcoming
    let strPostponed: String?
    let strDescriptionEN: String?
}

// MARK: - Public-facing models returned by this service

/// Boxer profile fetched from an external source
struct BoxerProfile: Identifiable {
    let id: String                   // sportsDbID
    let name: String
    let nationality: String?
    let dateOfBirth: Date?
    let photoURL: String?
    let description: String?
}

/// Historical or planned fight from an external source
struct IndexedFight: Identifiable {
    let id: String                   // sportsDbID or api_source_id
    let title: String
    let date: Date?
    let venue: String?
    let city: String?
    let country: String?
    let redFighterName: String?
    let blueFighterName: String?
    let result: String?
    let method: String?
    let scheduledRounds: Int
    let status: FightStatus
    let posterURL: String?

    enum FightStatus { case upcoming, completed, unknown }

    /// Parses "result" field from TheSportsDB into a human-readable method string.
    static func parseMethod(from result: String?) -> String? {
        guard let r = result?.lowercased() else { return nil }
        if r.contains("knockout") || r.contains(" ko") { return "KO" }
        if r.contains("technical") || r.contains("tko") { return "TKO" }
        if r.contains("unanimous") { return "UD" }
        if r.contains("split") { return "SD" }
        if r.contains("majority") { return "MD" }
        if r.contains("disqualif") { return "DQ" }
        if r.contains("no contest") { return "NC" }
        if r.contains("retired") || r.contains("corner") { return "RTD" }
        return nil
    }
}

// MARK: - Service

/// Fetches boxer and fight index data from TheSportsDB (free, no API key).
@MainActor
final class BoxerIndexService: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    // TheSportsDB free v1 endpoint — no key required
    private let baseURL = "https://www.thesportsdb.com/api/v1/json/3"

    // MARK: - Boxer Search

    /// Search for boxers by name. Returns up to 25 results.
    func searchBoxers(query: String) async -> [BoxerProfile] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "/searchplayers.php?p=\(encoded)&s=Boxing"
        guard let response: TSDBSearchResponse = await fetch(endpoint: endpoint) else { return [] }
        return (response.players ?? []).compactMap { parseBoxerProfile($0) }
    }

    /// Fetch detailed profile for a single boxer by TheSportsDB player ID.
    func fetchBoxer(sportsDbID: String) async -> BoxerProfile? {
        let endpoint = "/lookupplayer.php?id=\(sportsDbID)"
        guard let response: TSDBSearchResponse = await fetch(endpoint: endpoint) else { return nil }
        return response.players?.first.flatMap { parseBoxerProfile($0) }
    }

    // MARK: - Fight History / Schedule

    /// Fetch past fights for a boxer by their TheSportsDB player ID.
    /// Returns up to 25 results, most recent first.
    func fetchFightHistory(sportsDbID: String) async -> [IndexedFight] {
        let endpoint = "/searchevents.php?p=\(sportsDbID)&s=Boxing"
        guard let response: TSDBEventsResponse = await fetch(endpoint: endpoint) else { return [] }
        return response.allEvents.compactMap { parseEvent($0) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    /// Search fights by event name (e.g. "Fury vs Usyk").
    func searchFights(query: String) async -> [IndexedFight] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "/searchevents.php?e=\(encoded)&s=Boxing"
        guard let response: TSDBEventsResponse = await fetch(endpoint: endpoint) else { return [] }
        return response.allEvents.compactMap { parseEvent($0) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    /// Fetch upcoming boxing events from TheSportsDB league schedule.
    /// League ID 4424 = Boxing (Professional)
    func fetchUpcomingSchedule() async -> [IndexedFight] {
        let endpoint = "/eventsnextleague.php?id=4424"
        guard let response: TSDBEventsResponse = await fetch(endpoint: endpoint) else { return [] }
        return response.allEvents.compactMap { parseEvent($0) }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }

    /// Fetch recently completed boxing events.
    func fetchRecentResults() async -> [IndexedFight] {
        let endpoint = "/eventspastleague.php?id=4424"
        guard let response: TSDBEventsResponse = await fetch(endpoint: endpoint) else { return [] }
        return response.allEvents.compactMap { parseEvent($0) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    // MARK: - Import Helpers

    /// Converts an IndexedFight into a Boxer-linked Fight suitable for local SwiftData.
    /// Pass in the two Boxer objects if already resolved; otherwise title-only.
    func toLocalFight(_ indexed: IndexedFight) -> Fight {
        let fight = Fight(
            title: indexed.title,
            date: indexed.date ?? Date(),
            scheduledRounds: indexed.scheduledRounds,
            statusRaw: indexed.status == .completed ? "complete" : "upcoming",
            apiSourceID: indexed.id
        )
        return fight
    }

    // MARK: - Private helpers

    private func fetch<T: Decodable>(endpoint: String) async -> T? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: baseURL + endpoint) else {
            errorMessage = "Invalid URL"
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                errorMessage = "Server error"
                return nil
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func parseBoxerProfile(_ p: TSDBPlayer) -> BoxerProfile? {
        guard let id = p.idPlayer, let name = p.strPlayer else { return nil }
        return BoxerProfile(
            id: id,
            name: name,
            nationality: p.strNationality,
            dateOfBirth: parseDate(p.dateBorn),
            photoURL: p.strThumb ?? p.strCutout,
            description: p.strDescriptionEN
        )
    }

    private func parseEvent(_ e: TSDBEvent) -> IndexedFight? {
        guard let id = e.idEvent else { return nil }

        let title = e.strEvent ?? [e.strHomeTeam, e.strAwayTeam]
            .compactMap { $0 }
            .joined(separator: " vs ")

        guard !title.isEmpty else { return nil }

        let fightDate = parseEventDate(date: e.dateEvent, time: e.strTime)

        let status: IndexedFight.FightStatus
        if let s = e.strStatus?.lowercased(), s.contains("finished") || s.contains("complete") {
            status = .completed
        } else if let d = fightDate, d > Date() {
            status = .upcoming
        } else if fightDate != nil {
            status = .completed
        } else {
            status = .unknown
        }

        let rounds = Int(e.intRound ?? "") ?? 12

        return IndexedFight(
            id: id,
            title: title,
            date: fightDate,
            venue: e.strVenue,
            city: e.strCity,
            country: e.strCountry,
            redFighterName: e.strHomeTeam,
            blueFighterName: e.strAwayTeam,
            result: e.strResult,
            method: IndexedFight.parseMethod(from: e.strResult),
            scheduledRounds: rounds,
            status: status,
            posterURL: e.strThumb ?? e.strBanner
        )
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let s = string else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private func parseEventDate(date: String?, time: String?) -> Date? {
        guard let d = date else { return nil }
        let combined = time.map { "\(d) \($0)" } ?? d
        let formatters = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"]
        for fmt in formatters {
            let f = DateFormatter()
            f.dateFormat = fmt
            f.timeZone = TimeZone(identifier: "UTC")
            if let parsed = f.date(from: combined) { return parsed }
        }
        return nil
    }
}

// MARK: - Preview helpers

#if DEBUG
extension BoxerIndexService {
    static let preview: BoxerIndexService = BoxerIndexService()

    static func mockBoxers() -> [BoxerProfile] {
        [
            BoxerProfile(id: "34147", name: "Tyson Fury", nationality: "British",
                         dateOfBirth: nil, photoURL: nil, description: "The Gypsy King"),
            BoxerProfile(id: "34148", name: "Oleksandr Usyk", nationality: "Ukrainian",
                         dateOfBirth: nil, photoURL: nil, description: "The Cat"),
            BoxerProfile(id: "34149", name: "Canelo Alvarez", nationality: "Mexican",
                         dateOfBirth: nil, photoURL: nil, description: nil)
        ]
    }

    static func mockFights() -> [IndexedFight] {
        [
            IndexedFight(id: "e1", title: "Fury vs Usyk II", date: Date().addingTimeInterval(86400 * 30),
                         venue: "Kingdom Arena", city: "Riyadh", country: "Saudi Arabia",
                         redFighterName: "Tyson Fury", blueFighterName: "Oleksandr Usyk",
                         result: nil, method: nil, scheduledRounds: 12,
                         status: .upcoming, posterURL: nil),
            IndexedFight(id: "e2", title: "Fury vs Usyk", date: Date().addingTimeInterval(-86400 * 90),
                         venue: "Kingdom Arena", city: "Riyadh", country: "Saudi Arabia",
                         redFighterName: "Tyson Fury", blueFighterName: "Oleksandr Usyk",
                         result: "Usyk wins by Split Decision", method: "SD",
                         scheduledRounds: 12, status: .completed, posterURL: nil)
        ]
    }
}
#endif

