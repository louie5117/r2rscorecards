//
//  HomeViewEnhanced.swift
//  Clean implementation - NO CONFLICTS
//

import SwiftUI
import SwiftData

struct HomeViewEnhanced: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Fight.date, order: .forward)]) private var fights: [Fight]
    @Query(sort: [SortDescriptor(\Scorecard.createdAt, order: .reverse)]) private var allScorecards: [Scorecard]
    
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var syncStatus: SyncStatus
    @EnvironmentObject private var themeManager: ThemeManager // ✨ THEME MANAGER
    @State private var showSignIn = false
    @State private var showSettings = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showImportFights = false
    
    var body: some View {
        ZStack {
            // ✨ THEMED BACKGROUND
            LinearGradient(
                colors: themeManager.currentTheme.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    quickStatsCard
                    upcomingFightsSection
                    recentScorecardsSection
                    completedFightsSection
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.boxing")
                        .font(.title2)
                        .foregroundStyle(.red)
                    Text("R2R")
                        .font(.title2.bold())
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showImportFights = true }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title3)
                    }
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                    
                    Button(action: { showSignIn = true }) {
                        if let name = auth.displayName, !name.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title3)
                                Text(name)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(20)
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack { SignInView(isPresented: $showSignIn) }
                .environmentObject(auth)
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewEnhanced()
        }
        .sheet(isPresented: $showImportFights) {
            ImportFightsView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingMessage)
                .font(.title.bold())
            
            if let name = auth.displayName, !name.isEmpty {
                Text("Ready to score some fights, \(name)?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Track every punch, every round")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    private var quickStatsCard: some View {
        HStack(spacing: 20) {
            StatBadgeView(
                icon: "checklist",
                value: "\(userScorecardCount)",
                label: "Scorecards",
                color: .blue
            )
            
            StatBadgeView(
                icon: "calendar",
                value: "\(upcomingFights.count)",
                label: "Upcoming",
                color: .green
            )
            
            StatBadgeView(
                icon: "chart.bar.fill",
                value: "\(completedFights.count)",
                label: "Completed",
                color: .orange
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var upcomingFightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Upcoming Fights", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                Spacer()
                if !upcomingFights.isEmpty {
                    NavigationLink(destination: FightListView()) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if upcomingFights.isEmpty {
                EmptyStateCard(
                    icon: "calendar.badge.plus",
                    message: "No upcoming fights",
                    actionLabel: "Add Fight"
                ) {
                    addSampleFight()
                }
            } else {
                ForEach(Array(upcomingFights.prefix(3).enumerated()), id: \.element.id) { index, fight in
                    NavigationLink(value: fight) {
                        FightCardDisplay(fight: fight)
                    }
                    .buttonStyle(.plain)
                    .animatedCard(delay: Double(index) * 0.1)
                }
            }
        }
        .navigationDestination(for: Fight.self) { fight in
            FightDetailView(fight: fight)
        }
    }
    
    private var recentScorecardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your Recent Scorecards", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
            }
            
            if auth.currentUserIdentifier == nil {
                EmptyStateCard(
                    icon: "person.crop.circle.badge.questionmark",
                    message: "Sign in to track your scorecards",
                    actionLabel: "Sign In"
                ) {
                    showSignIn = true
                }
            } else if userScorecardCount == 0 {
                EmptyStateCard(
                    icon: "checklist",
                    message: "Score your first fight!",
                    actionLabel: nil,
                    action: nil
                )
            } else {
                ForEach(Array(recentScorecards.prefix(3))) { scorecard in
                    NavigationLink(value: scorecard) {
                        ScorecardCardDisplay(scorecard: scorecard)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Scorecard.self) { scorecard in
            ScorecardView(scorecard: scorecard)
        }
    }
    
    private var completedFightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Past Fights", systemImage: "clock.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
            }
            
            if completedFights.isEmpty {
                EmptyStateCard(
                    icon: "archivebox",
                    message: "No completed fights yet",
                    actionLabel: nil,
                    action: nil
                )
            } else {
                ForEach(completedFights.prefix(2)) { fight in
                    NavigationLink(value: fight) {
                        FightCardDisplay(fight: fight, isCompleted: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var upcomingFights: [Fight] {
        fights.filter { $0.statusRaw == "upcoming" || $0.statusRaw == "inProgress" }
    }
    
    private var completedFights: [Fight] {
        let completed = fights.filter { $0.statusRaw == "complete" }
        return completed.sorted { fight1, fight2 in
            let date1 = fight1.date ?? .distantPast
            let date2 = fight2.date ?? .distantPast
            return date1 > date2
        }
    }
    
    private var userScorecardCount: Int {
        guard let authID = auth.currentUserIdentifier else { return 0 }
        return allScorecards.filter { $0.user?.authUserID == authID }.count
    }
    
    private var recentScorecards: [Scorecard] {
        guard let authID = auth.currentUserIdentifier else { return [] }
        let userCards = allScorecards.filter { $0.user?.authUserID == authID }
        return userCards.sorted { card1, card2 in
            let date1 = card1.submittedAt ?? card1.createdAt ?? .distantPast
            let date2 = card2.submittedAt ?? card2.createdAt ?? .distantPast
            return date1 > date2
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    // MARK: - Actions
    
    private func addSampleFight() {
        let fight = Fight(
            title: "Championship Bout",
            date: .now.addingTimeInterval(86400 * 7),
            scheduledRounds: 12,
            statusRaw: "upcoming"
        )
        context.insert(fight)
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to save fight: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Component Views

struct EmptyStateCard: View {
    let icon: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct StatBadgeView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FightCardDisplay: View {
    let fight: Fight
    var isCompleted: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.purple.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "flame.fill")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .purple : .red)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(fight.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let date = fight.date {
                        Label(
                            date.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    Label("\(fight.scheduledRounds) rounds", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(isCompleted ? "Tap to view results" : "Tap to score")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ScorecardCardDisplay: View {
    let scorecard: Scorecard
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scorecard.fight?.title ?? "Unknown Fight")
                    .font(.subheadline.weight(.medium))
                
                Text("Red \(scorecard.totalRed) – Blue \(scorecard.totalBlue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let date = scorecard.submittedAt ?? scorecard.createdAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Fight.self, User.self, FriendGroup.self, Scorecard.self, RoundScore.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    
    let fight1 = Fight(title: "Fury vs Usyk III", date: .now.addingTimeInterval(86400 * 7), scheduledRounds: 12, statusRaw: "upcoming")
    let fight2 = Fight(title: "Canelo vs Benavidez", date: .now.addingTimeInterval(86400 * 14), scheduledRounds: 12, statusRaw: "upcoming")
    let fight3 = Fight(title: "Crawford vs Spence", date: .now.addingTimeInterval(-86400 * 30), scheduledRounds: 12, statusRaw: "complete")
    context.insert(fight1)
    context.insert(fight2)
    context.insert(fight3)
    
    return NavigationStack {
        HomeViewEnhanced()
    }
    .environmentObject(AuthManager())
    .environmentObject(SyncStatus(mode: .cloudKit, detail: "Synced"))
    .environmentObject(ThemeManager()) // ✨ THEME MANAGER
    .modelContainer(container)
}
