// AppAuthState.swift
// Single facade for auth state used by views. Aggregates AuthManager (legacy) and
// SupabaseAuthService so views depend on one object and one interface (DRY, DIP, ISP).

import Foundation
import Combine

@MainActor
final class AppAuthState: ObservableObject {

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var displayName: String?

    private let legacy: AuthManager
    private let supabase: SupabaseAuthService
    private var cancellables = Set<AnyCancellable>()

    init(legacy: AuthManager, supabase: SupabaseAuthService) {
        self.legacy = legacy
        self.supabase = supabase
        updateFromSources()
        legacy.$currentUserIdentifier
            .sink { [weak self] _ in self?.updateFromSources() }
            .store(in: &cancellables)
        legacy.$displayName
            .sink { [weak self] _ in self?.updateFromSources() }
            .store(in: &cancellables)
        supabase.$isAuthenticated
            .sink { [weak self] _ in self?.updateFromSources() }
            .store(in: &cancellables)
        supabase.$currentUserId
            .sink { [weak self] _ in self?.updateFromSources() }
            .store(in: &cancellables)
        supabase.$currentProfile
            .sink { [weak self] _ in self?.updateFromSources() }
            .store(in: &cancellables)
    }

    private func updateFromSources() {
        let legacyId = legacy.currentUserIdentifier
        let supabaseAuthenticated = supabase.isAuthenticated
        isAuthenticated = (legacyId != nil) || supabaseAuthenticated
        currentUserId = legacyId ?? supabase.currentUserId?.uuidString
        displayName = legacy.displayName
            ?? supabase.currentProfile?.displayName
            ?? supabase.currentProfile?.email
    }
}
