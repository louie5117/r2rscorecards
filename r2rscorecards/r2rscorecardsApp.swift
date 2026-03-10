//
//  r2rscorecardsApp.swift
//  r2rscorecards
//
//  Created by Paul Lewis on 19/02/2026.
//

import SwiftUI
import SwiftData
import os

@main
struct r2rscorecardsApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var supabaseAuth = SupabaseAuthService()
    @StateObject private var syncStatus: SyncStatus
    @StateObject private var themeManager = ThemeManager() // ✨ THEME MANAGER ACTIVATED
    private static let logger = Logger(subsystem: "PSL.r2rscorecards", category: "Persistence")
    let sharedModelContainer: ModelContainer
    let persistenceReady: Bool
    let startupErrorMessage: String?

    init() {
        print("🚀 r2rscorecardsApp init() starting...")
        let setup = Self.makeModelContainer()
        print("📦 Container setup complete - mode: \(setup.mode), has container: \(setup.container != nil)")
        
        if let container = setup.container {
            self.sharedModelContainer = container
            self.persistenceReady = true
            print("✅ Using normal container, persistence ready")
        } else {
            print("⚠️ No container created, using emergency container")
            self.sharedModelContainer = Self.makeEmergencyContainer()
            self.persistenceReady = false
            print("❌ Persistence NOT ready")
        }
        
        self.startupErrorMessage = setup.lastError
        if let error = setup.lastError {
            print("🔴 Startup error: \(error)")
        }
        
        _syncStatus = StateObject(
            wrappedValue: SyncStatus(
                mode: setup.mode,
                detail: setup.detail,
                lastSyncAttempt: setup.lastSyncAttempt,
                lastError: setup.lastError
            )
        )
        print("🏁 r2rscorecardsApp init() complete")
    }

    private static func makeModelContainer() -> (container: ModelContainer?, mode: PersistenceSyncMode, detail: String, lastSyncAttempt: Date, lastError: String?) {
        print("📋 Creating schema with 5 model types...")
        let schema = Schema([
            Fight.self,
            User.self,
            FriendGroup.self,
            Scorecard.self,
            RoundScore.self,
        ])
        print("✅ Schema created successfully")
        let attemptedAt = Date()

#if targetEnvironment(simulator)
        print("🔧 Running in SIMULATOR mode")
        do {
            print("📝 Attempting simulator local storage configuration...")
            let simulatorConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [simulatorConfiguration])
            logger.info("SwiftData configured for simulator local storage.")
            print("✅ Simulator local storage SUCCESS")
            return (container, .localFallback, "Simulator mode: using local device storage.", attemptedAt, nil)
        } catch {
            logger.error("Simulator local store failed: \(String(describing: error)). Falling back to in-memory mode.")
            print("❌ Simulator local storage FAILED: \(error)")
            print("🔄 Attempting in-memory fallback...")
            do {
                let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
                print("⚠️ In-memory container created (data will NOT persist)")
                return (container, .inMemoryRecovery, "Simulator recovery mode: temporary in-memory storage.", attemptedAt, String(describing: error))
            } catch {
                let finalError = "Simulator local store error: \(error)"
                logger.fault("Could not create simulator ModelContainer: \(finalError)")
                print("💥 FATAL: Could not create ANY container: \(error)")
                return (nil, .inMemoryRecovery, "Failed to open any data store. App is running without persistence.", attemptedAt, finalError)
            }
        }
#else
        do {
            let cloudConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: schema, configurations: [cloudConfiguration])
            logger.info("SwiftData configured with CloudKit sync.")
            return (container, .cloudKit, "Data is syncing with CloudKit.", attemptedAt, nil)
        } catch {
            logger.error("CloudKit setup failed: \(String(describing: error)). Falling back to local-only store.")
            let cloudError = error
            do {
                let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [localConfiguration])
                return (container, .localFallback, "CloudKit unavailable. Using local storage on this device.", attemptedAt, String(describing: error))
            } catch {
                let localError = error
                logger.error("Local store load failed: \(String(describing: localError)). Falling back to in-memory recovery mode.")
                do {
                    let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
                    let detail = "Could not open CloudKit or local database. Running in temporary in-memory mode."
                    let combinedError = "CloudKit: \(cloudError). Local: \(localError)"
                    return (container, .inMemoryRecovery, detail, attemptedAt, combinedError)
                } catch {
                    let finalError = "CloudKit: \(cloudError). Local: \(localError). In-memory: \(error)"
                    logger.fault("Could not create any ModelContainer: \(finalError)")
                    return (nil, .inMemoryRecovery, "Failed to open any data store. App is running without persistence.", attemptedAt, finalError)
                }
            }
        }
#endif
    }

    private static func makeEmergencyContainer() -> ModelContainer {
        do {
            let schema = Schema([
                Fight.self,
                User.self,
                FriendGroup.self,
                Scorecard.self,
                RoundScore.self,
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Emergency container creation failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if persistenceReady {
                AuthStateProvider(authManager: authManager, supabaseAuth: supabaseAuth) {
                    RootView()
                        .environmentObject(authManager)
                        .environmentObject(supabaseAuth)
                        .environmentObject(syncStatus)
                        .environmentObject(themeManager) // ✨ THEME AVAILABLE EVERYWHERE
                        .environmentObject(AuthUIState())
                        .preferredColorScheme(themeManager.currentTheme.colorScheme) // ✨ APPLY THEME
                }
            } else {
                StartupFailureView(errorMessage: startupErrorMessage ?? "Unknown error")
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Auth state provider

/// Provides a single auth-state facade to the hierarchy; created once from the two auth services.
private struct AuthStateProvider<Content: View>: View {
    @StateObject private var appAuthState: AppAuthState
    let content: () -> Content

    init(authManager: AuthManager, supabaseAuth: SupabaseAuthService, @ViewBuilder content: @escaping () -> Content) {
        _appAuthState = StateObject(wrappedValue: AppAuthState(legacy: authManager, supabase: supabaseAuth))
        self.content = content
    }

    var body: some View {
        content()
            .environmentObject(appAuthState)
    }
}
