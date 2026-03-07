//
//  ImprovedFightDetailView.swift
//  r2rscorecards
//
//  Created by PSL on 06/03/2026
//  Makes groups OPTIONAL - score solo or with friends!
//

import SwiftUI
import SwiftData

struct ImprovedFightDetailView: View {
    let fight: Fight
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var authState: AppAuthState

    @State private var showScoringOptions = false
    @State private var navigateToScorecard: Scorecard?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Fight Info Header
                fightInfoSection
                
                // Scoring Options - SOLO IS PRIMARY!
                scoringOptionsSection
            }
            .padding()
        }
        .navigationTitle(fight.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $navigateToScorecard) { scorecard in
            ScorecardView(scorecard: scorecard)
        }
    }
    
    // MARK: - Fight Info Section
    
    private var fightInfoSection: some View {
        VStack(spacing: 16) {
            // Fight icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "figure.boxing")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            
            Text(fight.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            if let date = fight.date {
                HStack(spacing: 16) {
                    Label(
                        date.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "calendar"
                    )
                    .font(.subheadline)
                    
                    Label("\(fight.scheduledRounds) Rounds", systemImage: "clock")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            
            // Status badge
            Text(fight.statusRaw.uppercased())
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
    
    // MARK: - Scoring Options Section
    
    private var scoringOptionsSection: some View {
        VStack(spacing: 12) {
            // ✨ PRIMARY: Score Solo
            Button {
                startSoloScoring()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.title3)
                            Text("Score Solo")
                                .font(.headline)
                        }
                        Text("Score individually, no group needed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            
            // Info text
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("Groups are optional! Score solo or create a group later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Actions
    
    private func startSoloScoring() {
        guard authState.isAuthenticated else {
            // TODO: Show sign in prompt
            return
        }
        
        guard let userId = authState.currentUserId else { return }
        
        // Find or create user in SwiftData
        let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { user in
            user.authUserID == userId
        })
        
        let existingUsers = (try? context.fetch(fetchDescriptor)) ?? []
        let user = existingUsers.first ?? {
            let newUser = User(
                displayName: authState.displayName ?? "You",
                region: "Unknown",
                gender: "Unknown",
                ageGroup: "Unknown"
            )
            newUser.authUserID = userId
            context.insert(newUser)
            return newUser
        }()
        
        // Create solo scorecard (no group!)
        let scorecard = Scorecard(
            title: "\(fight.title) - Solo",
            user: user,
            fight: fight,
            group: nil // ✨ NIL = Solo scoring!
        )
        
        // Create round scores
        for roundNum in 1...fight.scheduledRounds {
            let roundScore = RoundScore(
                round: roundNum,
                redScore: 10,
                blueScore: 10,
                fight: fight,
                scorecard: scorecard
            )
            context.insert(roundScore)
            if scorecard.rounds == nil {
                scorecard.rounds = []
            }
            scorecard.rounds?.append(roundScore)
        }
        
        context.insert(scorecard)
        
        // Save and navigate
        do {
            try context.save()
            navigateToScorecard = scorecard
        } catch {
            print("Error creating solo scorecard: \(error)")
        }
    }
    
    private var statusColor: Color {
        switch fight.statusRaw {
        case "upcoming": return .blue
        case "inProgress": return .orange
        case "complete": return .green
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Fight.self, User.self, FriendGroup.self, Scorecard.self, RoundScore.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let fight = Fight(title: "Fury vs Usyk III", date: .now, scheduledRounds: 12, statusRaw: "upcoming")
    context.insert(fight)
    let auth = AuthManager()
    let supabase = SupabaseAuthService()
    return NavigationStack {
        ImprovedFightDetailView(fight: fight)
    }
    .environmentObject(auth)
    .environmentObject(supabase)
    .environmentObject(AppAuthState(legacy: auth, supabase: supabase))
    .modelContainer(container)
}
