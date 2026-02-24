//
//  AppErrors.swift
//  r2rscorecards
//
//  Created by Paul Lewis on 23/02/2026.
//

import Foundation

/// Centralized error types for the R2R Scorecards app
enum AppError: LocalizedError {
    case authenticationFailed(String)
    case dataStoreFailed(String)
    case invalidInput(String)
    case networkUnavailable
    case cloudKitUnavailable
    case scorecardValidation(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .dataStoreFailed(let message):
            return "Data store error: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkUnavailable:
            return "Network unavailable. Some features may not work."
        case .cloudKitUnavailable:
            return "Cloud sync unavailable. Data will be stored locally."
        case .scorecardValidation(let message):
            return "Scorecard validation failed: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try signing in again."
        case .dataStoreFailed:
            return "Try restarting the app. If the problem persists, contact support."
        case .invalidInput:
            return "Please check your input and try again."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .cloudKitUnavailable:
            return "Your data will sync when cloud services are available."
        case .scorecardValidation:
            return "Please complete all required fields."
        }
    }
}

// MARK: - Convenience Extensions

extension AppError {
    /// Create an error from a SwiftData context save failure
    static func fromSaveError(_ error: Error) -> AppError {
        .dataStoreFailed(error.localizedDescription)
    }
    
    /// Create an error from an authentication failure
    static func fromAuthError(_ error: Error) -> AppError {
        .authenticationFailed(error.localizedDescription)
    }
}
