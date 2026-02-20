import SwiftUI
import SwiftData

struct ScorecardView: View {
    @Environment(\.modelContext) private var context
    @Bindable var scorecard: Scorecard

    var body: some View {
        List {
            Section("Rounds") {
                ForEach(scorecard.rounds.sorted(by: { $0.round < $1.round })) { rs in
                    HStack {
                        Text("Round \(rs.round)").frame(width: 80, alignment: .leading)
                        Stepper("Red: \(rs.redScore)", value: binding(for: rs, keyPath: \.redScore), in: 0...10)
                            .disabled(scorecard.isSubmitted)
                        Stepper("Blue: \(rs.blueScore)", value: binding(for: rs, keyPath: \.blueScore), in: 0...10)
                            .disabled(scorecard.isSubmitted)
                    }
                }
            }
            Section("Totals") {
                HStack {
                    Text("Computed Totals")
                    Spacer()
                    Text("R \(scorecard.computedRedTotal) – B \(scorecard.computedBlueTotal)")
                }
                HStack {
                    Text("Stored Totals")
                    Spacer()
                    Text("R \(scorecard.totalRed) – B \(scorecard.totalBlue)")
                }
                Button("Update Stored Totals from Computed") {
                    scorecard.totalRed = scorecard.computedRedTotal
                    scorecard.totalBlue = scorecard.computedBlueTotal
                    do { try context.save() } catch { print("Save error: \(error)") }
                }
                .disabled(scorecard.isSubmitted)
            }
            Section("Submission") {
                if let submittedAt = scorecard.submittedAt {
                    Text("Submitted \(submittedAt.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                } else {
                    Button("Submit Scorecard") {
                        scorecard.totalRed = scorecard.computedRedTotal
                        scorecard.totalBlue = scorecard.computedBlueTotal
                        scorecard.submittedAt = .now
                        do { try context.save() } catch { print("Submit error: \(error)") }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(scorecard.title)
    }

    private func binding<T>(for rs: RoundScore, keyPath: ReferenceWritableKeyPath<RoundScore, T>) -> Binding<T> {
        Binding(get: { rs[keyPath: keyPath] }, set: { newValue in
            guard !scorecard.isSubmitted else { return }
            rs[keyPath: keyPath] = newValue
            do { try context.save() } catch { print("Save error: \(error)") }
        })
    }
}

private enum ScorecardPreviewData {
    @MainActor
    static var containerAndCard: (ModelContainer, Scorecard) {
        let container = try! ModelContainer(
            for: Fight.self,
            User.self,
            FriendGroup.self,
            Scorecard.self,
            RoundScore.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let fight = Fight(title: "Preview Fight", date: .now, scheduledRounds: 12)
        let card = Scorecard(title: "Me", fight: fight)
        context.insert(fight)
        context.insert(card)
        for round in 1...3 {
            let score = RoundScore(round: round, redScore: 0, blueScore: 0, fight: fight, scorecard: card)
            context.insert(score)
            card.rounds.append(score)
            fight.rounds.append(score)
        }
        return (container, card)
    }
}

#Preview {
    let previewData = ScorecardPreviewData.containerAndCard
    NavigationStack { ScorecardView(scorecard: previewData.1) }
        .modelContainer(previewData.0)
}
