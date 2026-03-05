//
//  SettingsView.swift
//  r2rscorecards
//
//  User settings and account management
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @EnvironmentObject private var syncStatus: SyncStatus
    
    @State private var showChangePassword = false
    @State private var showSignOut = false
    @State private var showDeleteAccount = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    // Current User Info
                    if let displayName = authManager.displayName {
                        HStack {
                            Label(displayName, systemImage: "person.circle.fill")
                            #if DEBUG
                            if authManager.isDevBypass {
                                Spacer()
                                Image(systemName: "hammer.fill")
                                    .foregroundStyle(.orange)
                                Text("Dev Mode")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            #endif
                        }
                    }
                    
                    // Supabase Account Info
                    if supabaseAuth.isAuthenticated, let profile = supabaseAuth.currentProfile {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Supabase Account")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(profile.displayName)
                                .font(.body)
                        }
                    }
                    
                    // Change Password (Supabase users only)
                    if supabaseAuth.isAuthenticated {
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            Label("Change Password", systemImage: "key.fill")
                        }
                    }
                    
                    // Sign Out
                    Button(role: .destructive) {
                        showSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                // Social Section (Supabase users only)
                if supabaseAuth.isAuthenticated {
                    Section("Social") {
                        NavigationLink {
                            FriendRequestsView()
                        } label: {
                            Label("Friend Requests & Friends", systemImage: "person.2.fill")
                        }
                        
                        NavigationLink {
                            UserSearchView()
                        } label: {
                            Label("Find Users", systemImage: "magnifyingglass")
                        }
                    }
                }
                
                // Sync Status Section
                Section("Data Sync") {
                    HStack {
                        Label(syncStatus.title, systemImage: syncStatus.iconName)
                        Spacer()
                    }
                    
                    Text(syncStatus.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Text("Last check: \(syncStatus.lastSyncAttempt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    if let lastError = syncStatus.lastError, !lastError.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last error:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(lastError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    NavigationLink {
                        PrivacyFAQView()
                    } label: {
                        Label("Privacy & FAQ", systemImage: "hand.raised")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                #if DEBUG
                // Developer Section
                Section("Developer") {
                    if authManager.isDevBypass {
                        Label("Dev Bypass Active", systemImage: "hammer.fill")
                            .foregroundStyle(.orange)
                    }
                    
                    Button(role: .destructive) {
                        resetLocalData()
                    } label: {
                        Label("Reset Local Data", systemImage: "trash")
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOut) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
        }
    }
    
    // MARK: - Actions
    
    private func signOut() {
        // Sign out from Supabase if authenticated
        if supabaseAuth.isAuthenticated {
            Task {
                await supabaseAuth.signOut()
            }
        }
        
        // Sign out from local auth
        authManager.signOut()
        
        dismiss()
    }
    
    #if DEBUG
    private func resetLocalData() {
        // Delete all local data
        do {
            try context.delete(model: Fight.self)
            try context.delete(model: User.self)
            try context.delete(model: FriendGroup.self)
            try context.delete(model: Scorecard.self)
            try context.delete(model: RoundScore.self)
            try context.save()
        } catch {
            print("Failed to reset local data: \(error)")
        }
    }
    #endif
}

#Preview {
    let container = try! ModelContainer(
        for: Fight.self,
        User.self,
        FriendGroup.self,
        Scorecard.self,
        RoundScore.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseAuthService())
        .environmentObject(SyncStatus(mode: .cloudKit, detail: "Data is syncing with CloudKit."))
        .modelContainer(container)
}
