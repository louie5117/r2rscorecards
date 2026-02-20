import Foundation
import AuthenticationServices
import SwiftData
import Combine
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published var currentUserIdentifier: String? // Apple ID credential user identifier
    @Published var displayName: String?

    private var continuation: CheckedContinuation<(String, String?), Error>?

    func startSignIn() async throws -> (String, String?) {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(String, String?), Error>) in
            self.continuation = cont
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            let userID = credential.user
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            self.currentUserIdentifier = userID
            self.displayName = name.isEmpty ? nil : name
            continuation?.resume(returning: (userID, self.displayName))
        default:
            continuation?.resume(throwing: NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown credential"]))
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let foregroundScene = scenes.first(where: { $0.activationState == .foregroundActive }),
           let window = foregroundScene.windows.first(where: \.isKeyWindow) ?? foregroundScene.windows.first {
            return window
        }

        if let window = scenes.flatMap(\.windows).first {
            return window
        }

        // Preview/canvas hosts may not provide a normal scene; return a detached anchor.
        return UIWindow()
    }
}
