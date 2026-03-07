import Foundation

// Abstraction over external fight data providers (e.g., ESPN)
protocol FightSource {
    func fetchUpcomingFights() async throws -> [BoxingFight]
    func fetchPastFights() async throws -> [BoxingFight]
    func searchEvent(query: String) async throws -> [BoxingFight]
}

// MARK: - Default no-op implementation for previews/tests

extension FightSource {
    func fetchUpcomingFights() async throws -> [BoxingFight] { [] }
    func fetchPastFights() async throws -> [BoxingFight] { [] }
    func searchEvent(query: String) async throws -> [BoxingFight] { [] }
}
