// SyncStatus.swift
// Persistence/sync state for SwiftData + CloudKit. Used by the app root and by views that show sync status.

import Foundation

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
