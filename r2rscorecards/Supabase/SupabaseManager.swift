// SupabaseManager.swift
// Shared SupabaseClient instance. All services pull from this singleton.
//
// SETUP: Replace the placeholder values below with your project's
// URL and anon key from: Supabase Dashboard → Project Settings → API

import Foundation
import Supabase

enum SupabaseConfig {
    /// Your Supabase project URL.
    /// Example: "https://abcdefghijklmnop.supabase.co"
    static let url = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!

    /// Your project's anon (public) key. Safe to ship in the app —
    /// Row Level Security policies enforce who can read/write data.
    static let anonKey = "YOUR_ANON_KEY"
}

// MARK: - Shared Client

/// Single shared SupabaseClient. Import this anywhere you need DB, auth, or realtime access.
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)

// MARK: - Date Decoding

extension JSONDecoder {
    /// Pre-configured decoder for Supabase responses.
    /// Handles ISO8601 timestamps with fractional seconds.
    static var supabase: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = formatter.date(from: string) { return date }
            // Fallback: without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(string)")
        }
        return decoder
    }
}
