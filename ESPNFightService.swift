import Foundation

@MainActor
final class ESPNFightService: FightSource {

    // TODO: Wire to ESPN endpoints and map to BoxingFight

    func fetchUpcomingFights() async throws -> [BoxingFight] {
        // TODO: Implement ESPN upcoming fights fetch
        return []
    }

    func fetchPastFights() async throws -> [BoxingFight] {
        // TODO: Implement ESPN past fights fetch
        return []
    }

    func searchEvent(query: String) async throws -> [BoxingFight] {
        // TODO: Implement ESPN search
        return []
    }
}
