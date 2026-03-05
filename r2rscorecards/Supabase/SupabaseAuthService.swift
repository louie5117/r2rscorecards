// SupabaseAuthService.swift
// Wraps Supabase Auth for sign-in with Apple and email/password.
// Intended to replace the local-only AuthManager once Supabase is configured.
//
// Usage: add as a @StateObject in r2rscorecardsApp and pass via .environmentObject()

import Foundation
import Combine
import AuthenticationServices
import Supabase

@MainActor
final class SupabaseAuthService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var currentUserId: UUID?
    @Published var currentProfile: SBProfile?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    // MARK: - Apple Sign-In Continuation

    private var appleSignInContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    // MARK: - Lifecycle

    override init() {
        super.init()
        Task { await restoreSession() }
    }

    // MARK: - Session Restoration

    /// Called on app launch to restore an existing session.
    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = UUID(uuidString: session.user.id.uuidString)
            isAuthenticated = true
            await fetchProfile()
        } catch {
            // No active session — user needs to sign in.
            isAuthenticated = false
        }
    }

    // MARK: - Sign In with Apple

    /// Triggers the native Apple Sign In sheet, then signs into Supabase via OIDC.
    func signInWithApple() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let credential = try await requestAppleCredential()
            guard let identityTokenData = credential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8) else {
                throw AuthError.missingIdentityToken
            }

            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken
                )
            )

            let session = try await supabase.auth.session
            currentUserId = UUID(uuidString: session.user.id.uuidString)
            isAuthenticated = true

            // Update display name on first sign in if Apple provided one
            if !displayName.isEmpty {
                try await upsertProfile(displayName: displayName)
            }

            await fetchProfile()

        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Email / Password

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(displayName)]
            )

            let user = response.user
            currentUserId = UUID(uuidString: user.id.uuidString)
            isAuthenticated = true
            await fetchProfile()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            currentUserId = UUID(uuidString: session.user.id.uuidString)
            isAuthenticated = true
            await fetchProfile()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            lastError = error.localizedDescription
        }
        currentUserId = nil
        currentProfile = nil
        isAuthenticated = false
    }

    // MARK: - Profile

    func fetchProfile() async {
        guard let userId = currentUserId else { return }
        do {
            let profile: SBProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentProfile = profile
        } catch {
            // Profile may not exist yet (trigger may still be running)
            lastError = error.localizedDescription
        }
    }

    func updateProfile(_ update: SBProfileUpdate) async throws {
        guard let userId = currentUserId else { return }
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
        await fetchProfile()
    }

    // MARK: - Helpers

    private func upsertProfile(displayName: String) async throws {
        guard let userId = currentUserId else { return }
        let update = SBProfileUpdate(displayName: displayName, region: nil, gender: nil, ageGroup: nil)
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    private func requestAppleCredential() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

// MARK: - Apple Sign-In Delegate

extension SupabaseAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            appleSignInContinuation?.resume(throwing: AuthError.unknownCredentialType)
            appleSignInContinuation = nil
            return
        }
        appleSignInContinuation?.resume(returning: credential)
        appleSignInContinuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

extension SupabaseAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first(where: \.isKeyWindow) ?? UIWindow()
    }
}

// MARK: - Errors

private enum AuthError: LocalizedError {
    case missingIdentityToken
    case unknownCredentialType

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken:   return "Apple did not return an identity token."
        case .unknownCredentialType:  return "Unrecognised Apple credential type."
        }
    }
}
