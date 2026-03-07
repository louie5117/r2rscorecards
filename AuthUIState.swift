import Foundation
import Combine

@MainActor
final class AuthUIState: ObservableObject {
    @Published var showAuth: Bool = false
}
