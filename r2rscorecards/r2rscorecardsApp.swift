//
//  r2rscorecardsApp.swift
//  r2rscorecards
//
//  Created by Paul Lewis on 19/02/2026.
//

import SwiftUI
import SwiftData
import os
import Combine

enum PersistenceSyncMode {
    case cloudKit
    case localFallback
    case inMemoryRecovery
}

@MainActor
final class SyncStatus: ObservableObject {
    @Published var mode: PersistenceSyncMode
    @Published var detail: String
    @Published var lastSyncAttempt: Date
    @Published var lastError: String?

    init(mode: PersistenceSyncMode, detail: String, lastSyncAttempt: Date = .now, lastError: String? = nil) {
        self.mode = mode
        self.detail = detail
        self.lastSyncAttempt = lastSyncAttempt
        self.lastError = lastError
    }

    var title: String {
        switch mode {
        case .cloudKit: return "Cloud Sync Enabled"
        case .localFallback: return "Local-Only Mode"
        case .inMemoryRecovery: return "Recovery Mode"
        }
    }

    var iconName: String {
        switch mode {
        case .cloudKit: return "icloud"
        case .localFallback: return "externaldrive"
        case .inMemoryRecovery: return "exclamationmark.triangle"
        }
    }
}

@main
struct r2rscorecardsApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var syncStatus: SyncStatus
    private static let logger = Logger(subsystem: "PSL.r2rscorecards", category: "Persistence")
    let sharedModelContainer: ModelContainer
    let persistenceReady: Bool
    let startupErrorMessage: String?

    init() {
        let setup = Self.makeModelContainer()
        if let container = setup.container {
            self.sharedModelContainer = container
            self.persistenceReady = true
        } else {
            self.sharedModelContainer = Self.makeEmergencyContainer()
            self.persistenceReady = false
        }
        self.startupErrorMessage = setup.lastError
        _syncStatus = StateObject(
            wrappedValue: SyncStatus(
                mode: setup.mode,
                detail: setup.detail,
                lastSyncAttempt: setup.lastSyncAttempt,
                lastError: setup.lastError
            )
        )
    }

    private static func makeModelContainer() -> (container: ModelContainer?, mode: PersistenceSyncMode, detail: String, lastSyncAttempt: Date, lastError: String?) {
        let schema = Schema([
            Fight.self,
            User.self,
            FriendGroup.self,
            Scorecard.self,
            RoundScore.self,
        ])
        let attemptedAt = Date()

#if targetEnvironment(simulator)
        do {
            let simulatorConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [simulatorConfiguration])
            logger.info("SwiftData configured for simulator local storage.")
            return (container, .localFallback, "Simulator mode: using local device storage.", attemptedAt, nil)
        } catch {
            logger.error("Simulator local store failed: \(String(describing: error)). Falling back to in-memory mode.")
            do {
                let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
                return (container, .inMemoryRecovery, "Simulator recovery mode: temporary in-memory storage.", attemptedAt, String(describing: error))
            } catch {
                let finalError = "Simulator local store error: \(error)"
                logger.fault("Could not create simulator ModelContainer: \(finalError)")
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
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: Item.self, configurations: configuration)
        } catch {
            fatalError("Emergency container creation failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if persistenceReady {
                RootView()
                    .environmentObject(authManager)
                    .environmentObject(syncStatus)
            } else {
                StartupFailureView(errorMessage: startupErrorMessage ?? "Unknown error")
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct StartupFailureView: View {
    let errorMessage: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Startup Error")
                        .font(.title.bold())
                    Text("The app could not create a local data store, so it cannot continue safely.")
                        .foregroundStyle(.secondary)
                    Text("Details:")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("r2rscorecards")
        }
    }
}
