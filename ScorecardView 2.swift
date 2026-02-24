//
//  ScorecardView.swift
//  r2rscorecards
//
//  Created by Paul Lewis on 23/02/2026.
//

import SwiftUI
import SwiftData

struct ScorecardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var scorecard: Scorecard
    
    @State private var showSubmitConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section("Fight Details") {
                HStack {
                    Text("Fight")
                    Spacer()
                    Text(scorecard.fight?.title ?? "Unknown")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Group")
                    Spacer()
                    Text(scorecard.group?.name ?? "No Group")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Status")
                    Spacer()
                    if scorecard.isSubmitted {
                        Label("Submitted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Draft", systemImage: "pencil.circle")
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Section("Current Score") {
                HStack {
                    Text("Red Corner")
                        .font(.headline)
                    Spacer()
                    Text("\(scorecard.totalRed)")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                }
                HStack {
                    Text("Blue Corner")
                        .font(.headline)
                    Spacer()
                    Text("\(scorecard.totalBlue)")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                }
            }
            
            Section("Round Scores") {
                let sortedRounds = (scorecard.rounds ?? []).sorted { $0.round < $1.round }
                if sortedRounds.isEmpty {
                    Text("No rounds yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedRounds) { round in
                        RoundScoreRow(round: round, isEditable: !scorecard.isSubmitted)
                    }
                }
            }
            
            if !scorecard.isSubmitted {
                Section {
                    Button {
                        showSubmitConfirmation = true
                    } label: {
                        Label("Submit Scorecard", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    
                    if let message = validationMessage {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            } else if let submittedAt = scorecard.submittedAt {
                Section("Submission Info") {
                    HStack {
                        Text("Submitted")
                        Spacer()
                        Text(submittedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    Text("This scorecard is locked and cannot be edited.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(scorecard.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Submit Scorecard", isPresented: $showSubmitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Submit") {
                submitScorecard()
            }
        } message: {
            Text("Once submitted, you won't be able to edit this scorecard. Your scores will be included in group results.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        // Check that all rounds have been scored and are valid
        let sortedRounds = (scorecard.rounds ?? []).sorted { $0.round < $1.round }
        guard !sortedRounds.isEmpty else { return false }
        
        // Verify we have the expected number of rounds
        guard let fight = scorecard.fight else { return false }
        guard sortedRounds.count == fight.scheduledRounds else { return false }
        
        // Check that each round has been scored AND follows boxing rules
        for round in sortedRounds {
            // Must be scored (not 0-0)
            if !round.isScored {
                return false
            }
            // Must follow boxing rules (10-point must system)
            if !round.isValidScore {
                return false
            }
        }
        
        return true
    }
    
    private var validationMessage: String? {
        let sortedRounds = (scorecard.rounds ?? []).sorted { $0.round < $1.round }
        
        guard let fight = scorecard.fight else {
            return "No fight associated"
        }
        
        if sortedRounds.isEmpty {
            return "No rounds to score"
        }
        
        if sortedRounds.count != fight.scheduledRounds {
            return "Expected \(fight.scheduledRounds) rounds, found \(sortedRounds.count)"
        }
        
        // Check for unscored rounds
        let unscoredRounds = sortedRounds.filter { !$0.isScored }
        if !unscoredRounds.isEmpty {
            let roundNumbers = unscoredRounds.map { String($0.round) }.joined(separator: ", ")
            return "Unscored rounds: \(roundNumbers)"
        }
        
        // Check for invalid scores
        let invalidRounds = sortedRounds.filter { !$0.isValidScore }
        if !invalidRounds.isEmpty {
            let roundNumbers = invalidRounds.map { String($0.round) }.joined(separator: ", ")
            return "Invalid scores in rounds: \(roundNumbers)"
        }
        
        return nil
    }
    
    private func submitScorecard() {
        scorecard.submittedAt = Date()
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to submit scorecard: \(error.localizedDescription)"
            showError = true
            scorecard.submittedAt = nil
        }
    }
}

private struct RoundScoreRow: View {
    @Bindable var round: RoundScore
    let isEditable: Bool
    
    var body: some View {
        if isEditable {
            RoundScoringView(round: round)
        } else {
            // Read-only display
            VStack(spacing: 8) {
                HStack {
                    Text("Round \(round.round)")
                        .font(.headline)
                    Spacer()
                    if !round.isValidScore {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                HStack {
                    Label("\(round.redScore)", systemImage: "figure.boxing")
                        .foregroundStyle(.red)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                    
                    Text("—")
                        .foregroundStyle(.secondary)
                    
                    Label("\(round.blueScore)", systemImage: "figure.boxing")
                        .foregroundStyle(.blue)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                }
                
                if round.isValidScore {
                    Text(round.scoreDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Invalid score combination", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

private enum ScorecardPreviewData {
    @MainActor
    static var containerAndScorecard: (ModelContainer, Scorecard) {
        let container = try! ModelContainer(
            for: Fight.self,
            User.self,
            FriendGroup.self,
            Scorecard.self,
            RoundScore.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        
        let fight = Fight(title: "Championship Bout", date: .now, scheduledRounds: 12)
        let user = User(displayName: "Preview User", region: "US", gender: "unspecified", ageGroup: "25-34")
        let group = FriendGroup(name: "Test Group", fight: fight, members: [user])
        let scorecard = Scorecard(title: "Preview Scorecard", user: user, fight: fight, group: group)
        
        context.insert(fight)
        context.insert(user)
        context.insert(group)
        context.insert(scorecard)
        
        // Add some sample rounds with valid boxing scores
        for i in 1...12 {
            // Generate valid boxing scores for first 3 rounds
            let scores: [(Int, Int)] = [
                (10, 9),  // Red wins
                (9, 10),  // Blue wins
                (10, 10), // Even
                (10, 8),  // Red dominant
                (8, 10),  // Blue dominant
            ]
            let validScore = i <= 3 ? scores.randomElement()! : (10, 10)
            
            let round = RoundScore(
                round: i,
                redScore: i <= 3 ? validScore.0 : 10,
                blueScore: i <= 3 ? validScore.1 : 10,
                fight: fight,
                scorecard: scorecard
            )
            context.insert(round)
            if scorecard.rounds == nil {
                scorecard.rounds = []
            }
            scorecard.rounds?.append(round)
        }
        
        return (container, scorecard)
    }
}

#Preview("Draft Scorecard") {
    DraftScorecardPreview()
}

#Preview("Submitted Scorecard") {
    SubmittedScorecardPreview()
}

private struct DraftScorecardPreview: View {
    let previewData = ScorecardPreviewData.containerAndScorecard
    
    var body: some View {
        NavigationStack {
            ScorecardView(scorecard: previewData.1)
        }
        .modelContainer(previewData.0)
    }
}

private struct SubmittedScorecardPreview: View {
    let previewData: (ModelContainer, Scorecard) = {
        let data = ScorecardPreviewData.containerAndScorecard
        data.1.submittedAt = Date()
        // Complete all rounds for submitted state with valid boxing scores
        let validScores: [(Int, Int)] = [(10, 9), (9, 10), (10, 10), (10, 8), (8, 10)]
        for round in (data.1.rounds ?? []) {
            let score = validScores.randomElement()!
            round.redScore = score.0
            round.blueScore = score.1
        }
        return data
    }()
    
    var body: some View {
        NavigationStack {
            ScorecardView(scorecard: previewData.1)
        }
        .modelContainer(previewData.0)
    }
}
