//
//  BoxingAPIService.swift
//  r2rscorecards
//
//  Integration with Boxing Data API via RapidAPI
//  Query upcoming and past boxing fights
//

import Foundation
import Combine

/// Feature flag to gate RapidAPI usage while migrating away
let USE_RAPID_API: Bool = false

@available(*, deprecated, message: "Deprecated: Replaced by ESPNFightService via FightSource. Remove RapidAPI usage.")
@MainActor
final class BoxingAPIService: ObservableObject {
    
    @Published var isLoading = false
    @Published var error: String?
    
    // Boxing Data API via RapidAPI
    // Endpoint: boxing-data-api.p.rapidapi.com
    private let apiKey = "3d5426fa8cmsh7b7d6c420f60a9ep10f275jsn0fbe2602da5f"
    private let baseURL = "https://boxing-data-api.p.rapidapi.com"
    
    // MARK: - API Endpoints
    
    /// Fetch upcoming boxing events
    func fetchUpcomingFights() async throws -> [BoxingFight] {
        // Boxing Data API - get upcoming fights
        // Using 7 days (default for free tier) with 12 hours past
        let endpoint = "/v1/events/schedule?days=7&past_hours=12&date_sort=ASC&page_num=1&page_size=25"
        
        do {
            // API returns an array directly, not wrapped in an object
            let response: [BoxingDataFight] = try await makeRequest(endpoint: endpoint)
            
            print("✅ API returned \(response.count) fights")
            
            // Don't filter by date - show all fights from the API
            // (The API already filters based on days and past_hours parameters)
            let fights = response.compactMap { convertToBoxingFight($0) }
            
            print("✅ Converted \(fights.count) fights")
            
            if fights.isEmpty {
                print("⚠️ No fights found, using mock data")
                return Self.mockFights()
            }
            
            // Log fight dates for debugging
            for fight in fights.prefix(3) {
                print("📅 Fight: \(fight.title) on \(fight.date)")
            }
            
            return fights
        } catch {
            print("❌ Boxing Data API Error: \(error)")
            print("📝 Falling back to mock data")
            return Self.mockFights()
        }
    }
    
    /// Fetch past boxing events
    func fetchPastFights() async throws -> [BoxingFight] {
        // Get fights from past 12 hours (free tier limit)
        let endpoint = "/v1/events/schedule?days=0&past_hours=12&date_sort=DESC&page_num=1&page_size=25"
        
        do {
            let response: [BoxingDataFight] = try await makeRequest(endpoint: endpoint)
            
            let now = Date()
            let pastFights = response.filter { fight in
                if let fightDate = parseFightDate(fight.date) {
                    return fightDate < now
                }
                return false
            }
            
            return pastFights.compactMap { convertToBoxingFight($0) }
        } catch {
            print("❌ Error fetching past fights: \(error)")
            return []
        }
    }
    
    /// Search for specific fighter or event
    func searchEvent(query: String) async throws -> [BoxingFight] {
        // Get all available fights within subscription limits
        let endpoint = "/v1/events/schedule?days=7&past_hours=12&date_sort=ASC&page_num=1&page_size=25"
        let response: [BoxingDataFight] = try await makeRequest(endpoint: endpoint)
        
        let queryLower = query.lowercased()
        let filtered = response.filter { fight in
            let title = fight.title ?? ""
            return title.lowercased().contains(queryLower)
        }
        
        return filtered.compactMap { convertToBoxingFight($0) }
    }
    
    private func parseFightDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Try ISO8601 first
        let iso8601 = ISO8601DateFormatter()
        if let date = iso8601.date(from: dateString) {
            return date
        }
        
        // Try common formats
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    // MARK: - Network Request
    
    private func makeRequest<T: Decodable>(endpoint: String) async throws -> T {
        // If running in preview mode, skip API calls
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            print("📝 Running in preview mode - skipping API call")
            throw APIError.previewMode
        }
        #endif
        
        let fullURL = baseURL + endpoint
        print("🌐 Making request to: \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("boxing-data-api.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📡 Response code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response body: \(responseString.prefix(500))")
                }
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // Try to decode
            let decoder = JSONDecoder()
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response")
                return decoded
            } catch {
                print("❌ Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response JSON: \(responseString.prefix(1000))")
                }
                throw APIError.decodingError
            }
            
        } catch let error as APIError {
            self.error = error.localizedDescription
            throw error
        } catch {
            print("❌ Network error: \(error)")
            self.error = error.localizedDescription
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertToBoxingFight(_ fight: BoxingDataFight) -> BoxingFight? {
        // Parse date
        let fightDate = parseFightDate(fight.date) ?? Date()
        
        // Extract fighters from title or use provided names
        var fighters: [BoxingFighter] = []
        
        if let f1 = fight.fighter1, let f2 = fight.fighter2 {
            // If API provides fighter names directly
            fighters.append(BoxingFighter(id: "f1", name: f1, nickname: nil, record: nil))
            fighters.append(BoxingFighter(id: "f2", name: f2, nickname: nil, record: nil))
        } else if let title = fight.title {
            // Parse fighters from title (e.g., "Cooper vs. Ursu: Under the Lights")
            let parsedFighters = parseFightersFromTitle(title)
            fighters = parsedFighters
        }
        
        // Use title as-is
        let title = fight.title ?? "Boxing Event"
        
        return BoxingFight(
            id: fight.id,
            date: fightDate,
            venue: fight.venue,
            location: fight.location,
            title: title,
            fighters: fighters,
            rounds: 12, // Default
            weightClass: fight.weight_class
        )
    }
    
    private func parseFightersFromTitle(_ title: String) -> [BoxingFighter] {
        // Split by common separators: " vs. ", " vs ", " v. ", " v "
        let separators = [" vs. ", " vs ", " v. ", " v ", " VS. ", " VS "]
        
        for separator in separators {
            if title.contains(separator) {
                let parts = title.components(separatedBy: separator)
                if parts.count >= 2 {
                    // Take only the fighter names (before any colon or subtitle)
                    let fighter1 = parts[0].components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? parts[0].trimmingCharacters(in: .whitespaces)
                    let fighter2 = parts[1].components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? parts[1].trimmingCharacters(in: .whitespaces)
                    
                    return [
                        BoxingFighter(id: "f1", name: fighter1, nickname: nil, record: nil),
                        BoxingFighter(id: "f2", name: fighter2, nickname: nil, record: nil)
                    ]
                }
            }
        }
        
        return []
    }
}

// MARK: - Boxing Data API Models

struct BoxingDataFight: Codable {
    let id: String
    let title: String?
    let date: String?
    let venue: String?
    let location: String?
    let poster_image_url: String?
    let updated_at: String?
    
    // Optional fields that might be in detailed responses
    let fighter1: String?
    let fighter2: String?
    let weight_class: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, venue, location
        case poster_image_url, updated_at
        case fighter1, fighter2, weight_class
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try? container.decode(String.self, forKey: .title)
        date = try? container.decode(String.self, forKey: .date)
        venue = try? container.decode(String.self, forKey: .venue)
        location = try? container.decode(String.self, forKey: .location)
        poster_image_url = try? container.decode(String.self, forKey: .poster_image_url)
        updated_at = try? container.decode(String.self, forKey: .updated_at)
        fighter1 = try? container.decode(String.self, forKey: .fighter1)
        fighter2 = try? container.decode(String.self, forKey: .fighter2)
        weight_class = try? container.decode(String.self, forKey: .weight_class)
    }
}

// MARK: - Models

struct BoxingFight: Codable, Identifiable {
    let id: String
    let date: Date
    let venue: String?
    let location: String?
    let title: String?
    let fighters: [BoxingFighter]
    let rounds: Int?
    let weightClass: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case venue
        case location
        case title
        case fighters
        case rounds
        case weightClass = "weight_class"
    }
    
    var fighter1: BoxingFighter? {
        fighters.first
    }
    
    var fighter2: BoxingFighter? {
        fighters.count > 1 ? fighters[1] : nil
    }
    
    var displayTitle: String {
        if let f1 = fighter1, let f2 = fighter2 {
            return "\(f1.name) vs \(f2.name)"
        } else if let title = title {
            return title
        } else {
            return "Boxing Match"
        }
    }
}

struct BoxingFighter: Codable, Identifiable {
    let id: String
    let name: String
    let nickname: String?
    let record: FighterRecord?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case record
    }
}

struct FighterRecord: Codable {
    let wins: Int
    let losses: Int
    let draws: Int
    let knockouts: Int?
    
    var displayString: String {
        "\(wins)-\(losses)-\(draws)"
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case previewMode
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case networkError(Error)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .previewMode:
            return "Running in preview mode - API calls disabled"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server returned error code: \(code)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode response data"
        }
    }
}

// MARK: - Preview Mock Data

#if DEBUG
extension BoxingAPIService {
    static let preview: BoxingAPIService = {
        let service = BoxingAPIService()
        return service
    }()
    
    static func mockFights() -> [BoxingFight] {
        [
            BoxingFight(
                id: "mock-1",
                date: Date().addingTimeInterval(86400 * 7), // 1 week from now
                venue: "Madison Square Garden",
                location: "New York, NY",
                title: "Heavyweight Championship Unification",
                fighters: [
                    BoxingFighter(
                        id: "f1",
                        name: "Tyson Fury",
                        nickname: "The Gypsy King",
                        record: FighterRecord(wins: 33, losses: 0, draws: 1, knockouts: 24)
                    ),
                    BoxingFighter(
                        id: "f2",
                        name: "Oleksandr Usyk",
                        nickname: "The Cat",
                        record: FighterRecord(wins: 21, losses: 0, draws: 0, knockouts: 14)
                    )
                ],
                rounds: 12,
                weightClass: "Heavyweight"
            ),
            BoxingFight(
                id: "mock-2",
                date: Date().addingTimeInterval(86400 * 14), // 2 weeks from now
                venue: "T-Mobile Arena",
                location: "Las Vegas, NV",
                title: "Welterweight Showdown",
                fighters: [
                    BoxingFighter(
                        id: "f3",
                        name: "Terence Crawford",
                        nickname: "Bud",
                        record: FighterRecord(wins: 40, losses: 0, draws: 0, knockouts: 31)
                    ),
                    BoxingFighter(
                        id: "f4",
                        name: "Errol Spence Jr",
                        nickname: "The Truth",
                        record: FighterRecord(wins: 28, losses: 1, draws: 0, knockouts: 22)
                    )
                ],
                rounds: 12,
                weightClass: "Welterweight"
            ),
            BoxingFight(
                id: "mock-3",
                date: Date().addingTimeInterval(86400 * 21), // 3 weeks from now
                venue: "Wembley Stadium",
                location: "London, UK",
                title: "Super Middleweight Championship",
                fighters: [
                    BoxingFighter(
                        id: "f5",
                        name: "Canelo Alvarez",
                        nickname: nil,
                        record: FighterRecord(wins: 60, losses: 2, draws: 2, knockouts: 39)
                    ),
                    BoxingFighter(
                        id: "f6",
                        name: "David Benavidez",
                        nickname: "El Bandera Roja",
                        record: FighterRecord(wins: 28, losses: 0, draws: 0, knockouts: 24)
                    )
                ],
                rounds: 12,
                weightClass: "Super Middleweight"
            ),
            BoxingFight(
                id: "mock-4",
                date: Date().addingTimeInterval(86400 * 28), // 4 weeks from now
                venue: "Crypto.com Arena",
                location: "Los Angeles, CA",
                title: "Lightweight Championship",
                fighters: [
                    BoxingFighter(
                        id: "f7",
                        name: "Gervonta Davis",
                        nickname: "Tank",
                        record: FighterRecord(wins: 29, losses: 0, draws: 0, knockouts: 27)
                    ),
                    BoxingFighter(
                        id: "f8",
                        name: "Ryan Garcia",
                        nickname: "KingRy",
                        record: FighterRecord(wins: 24, losses: 1, draws: 0, knockouts: 20)
                    )
                ],
                rounds: 12,
                weightClass: "Lightweight"
            )
        ]
    }
}
#endif

