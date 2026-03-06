//
//  ImprovedScoringFlow.swift
//  r2rscorecards
//
//  Created by PSL on 06/03/2026
//  Makes groups OPTIONAL - score solo or with friends!
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Fight Detail View

struct ImprovedFightDetailView: View {
    let fight: Fight
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @Query private var groups: [FriendGroup]
    @Query private var scorecards: [Scorecard]
    
    @State private var showScoringOptions = false
    @State private var showGroupCreation = false
    @State private var selectedGroup: FriendGroup?
    
    private var isAuthenticated: Bool {
        auth.currentUserIdentifier != nil || supabaseAuth.isAuthenticated
    }
    
    private var myGroups: [FriendGroup] {
        groups.filter { $0.fight?.id == fight.id }
    }
    
    private var myScorecards: [Scorecard] {
        guard let userId = auth.currentUserIdentifier ?? supabaseAuth.currentUserId?.uuidString else {
            return []
        }
        return scorecards.filter { 
            $0.fight?.id == fight.id && $0.user?.authUserID == userId
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Fight Info Header
                fightInfoSection
                
                // Scoring Options
                scoringOptionsSection
                
                // Your Scorecards
                if !myScorecards.isEmpty {
                    yourScorecardsSection
                }
                
                // Groups Section
                if !myGroups.isEmpty {
                    groupsSection
                }
            }
            .padding()
        }
        .navigationTitle(fight.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showScoringOptions) {
            ScoringOptionsSheet(fight: fight, selectedGroup: $selectedGroup)
        }
        .sheet(isPresented: $showGroupCreation) {
            GroupCreationView(fight: fight)
        }
    }
    
    // MARK: - Sections
    
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
    
    private var scoringOptionsSection: some View {
        VStack(spacing: 12) {
            // ✨ PRIMARY: Score Solo
            Button {
                startSoloScoring()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Score Solo", systemImage: "person.fill")
                            .font(.headline)
                        Text("Score individually, no group needed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            // ✨ OPTIONAL: Score with Group
            Button {
                showScoringOptions = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Score with Friends", systemImage: "person.3.fill")
                            .font(.headline)
                        Text("Join or create a group to compare")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var yourScorecardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Scorecards")
                .font(.headline)
            
            ForEach(myScorecards) { scorecard in
                NavigationLink(value: scorecard) {
                    ScorecardRowView(scorecard: scorecard)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Groups")
                    .font(.headline)
                Spacer()
                Button {
                    showGroupCreation = true
                } label: {
                    Label("New Group", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            ForEach(myGroups) { group in
                NavigationLink(value: group) {
                    GroupRowView(group: group)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startSoloScoring() {
        guard isAuthenticated else {
            // Show sign in prompt
            return
        }
        
        // Create solo scorecard (no group!)
        let scorecard = Scorecard(
            title: "\(fight.title) - Solo",
            fight: fight,
            group: nil // ✨ NIL = Solo scoring!
        )
        
        // TODO: Navigate to scoring view with this scorecard
        context.insert(scorecard)
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

// MARK: - Scoring Options Sheet

struct ScoringOptionsSheet: View {
    let fight: Fight
    @Binding var selectedGroup: FriendGroup?
    @Environment(\.dismiss) private var dismiss
    @Query private var groups: [FriendGroup]
    
    @State private var showGroupCreation = false
    
    private var fightGroups: [FriendGroup] {
        groups.filter { $0.fight?.id == fight.id }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(fightGroups) { group in
                        Button {
                            selectedGroup = group
                            // TODO: Navigate to scoring with this group
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.name)
                                        .font(.headline)
                                    Text("\(group.members?.count ?? 0) members")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Your Groups")
                } footer: {
                    Text("Score with an existing group")
                }
                
                Section {
                    Button {
                        showGroupCreation = true
                    } label: {
                        Label("Create New Group", systemImage: "plus.circle.fill")
                    }
                } footer: {
                    Text("Create a group to compare scorecards with friends")
                }
            }
            .navigationTitle("Score with Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGroupCreation) {
                GroupCreationView(fight: fight)
            }
        }
    }
}

// MARK: - Group Creation View

struct GroupCreationView: View {
    let fight: Fight
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager
    
    @State private var groupName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group Name", text: $groupName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Group Details")
                } footer: {
                    Text("Choose a name for your scoring group")
                }
                
                Section {
                    Text("Fight: \(fight.title)")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("For Fight")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Invite friends with a code")
                        Text("• Compare scorecards in real-time")
                        Text("• See crowd statistics")
                        Text("• Debate the decision!")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("What are groups?")
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createGroup() {
        guard !groupName.isEmpty else { return }
        
        // Create the group
        let group = FriendGroup(
            name: groupName,
            inviteCode: generateInviteCode(),
            fight: fight,
            createdBy: auth.displayName ?? "You"
        )
        
        context.insert(group)
        
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func generateInviteCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Avoid confusing chars
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// MARK: - Supporting Views

struct ScorecardRowView: View {
    let scorecard: Scorecard
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scorecard.title)
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 12) {
                    Text("R: \(scorecard.totalRed)")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Text("B: \(scorecard.totalBlue)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    if scorecard.isSubmitted {
                        Label("Submitted", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Label("Draft", systemImage: "pencil.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            if let group = scorecard.group {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                    Text(group.name)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            } else {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct GroupRowView: View {
    let group: FriendGroup
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 8) {
                    Text("\(group.members?.count ?? 0) members")
                        .font(.caption)
                    
                    Text("•")
                        .font(.caption)
                    
                    Text("Code: \(group.inviteCode)")
                        .font(.caption.monospaced())
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
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
    
    let fight = Fight(title: "Fury vs Usyk III", date: .now, scheduledRounds: 12, statusRaw: "upcoming")
    context.insert(fight)
    
    return NavigationStack {
        ImprovedFightDetailView(fight: fight)
    }
    .environmentObject(AuthManager())
    .environmentObject(SupabaseAuthService())
    .modelContainer(container)
}
