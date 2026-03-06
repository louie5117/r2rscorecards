import Foundation
import AuthenticationServices
import SwiftData
import Combine
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published var currentUserIdentifier: String? // Apple ID credential user identifier
    @Published var displayName: String?
    @Published var lastError: String?
    @Published var isDevBypass: Bool = false // For development testing

    private var continuation: CheckedContinuation<(String, String?), Error>?

    func startSignIn() async throws -> (String, String?) {
        guard continuation == nil else {
            throw NSError(domain: "Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sign-in already in progress"])
        }
        
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(String, String?), Error>) in
            self.continuation = cont
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    #if DEBUG
    /// Development-only bypass for testing without Sign in with Apple
    func devBypassSignIn(name: String = "Dev User") {
        // Use a consistent dev user ID so we can reuse it
        self.currentUserIdentifier = "dev-bypass-test-user"
        self.displayName = name
        self.isDevBypass = true
        self.lastError = nil
    }
    #endif
    
    /// Sign in with email/password
    func signInWithEmail(userID: String, displayName: String) {
        self.currentUserIdentifier = userID
        self.displayName = displayName
        self.isDevBypass = false
        self.lastError = nil
    }
    
    func signOut() {
        currentUserIdentifier = nil
        displayName = nil
        lastError = nil
        isDevBypass = false
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
            self.lastError = nil
            continuation?.resume(returning: (userID, self.displayName))
        default:
            let error = NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown credential type"])
            self.lastError = error.localizedDescription
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.lastError = error.localizedDescription
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
