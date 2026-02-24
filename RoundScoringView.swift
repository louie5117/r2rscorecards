//
//  RoundScoringView.swift
//  r2rscorecards
//
//  Interactive round scoring with boxing rules validation
//

import SwiftUI
import SwiftData

struct RoundScoringView: View {
    @Bindable var round: RoundScore
    @State private var showingCustomScore = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Round \(round.round)")
                    .font(.headline)
                Spacer()
                if !round.isValidScore {
                    Label("Invalid", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            // Quick selection buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                QuickScoreButton(
                    title: "Red Wins",
                    subtitle: "10-9",
                    color: .red,
                    isSelected: round.redScore == 10 && round.blueScore == 9
                ) {
                    round.redScore = 10
                    round.blueScore = 9
                }
                
                QuickScoreButton(
                    title: "Blue Wins",
                    subtitle: "9-10",
                    color: .blue,
                    isSelected: round.redScore == 9 && round.blueScore == 10
                ) {
                    round.redScore = 9
                    round.blueScore = 10
                }
                
                QuickScoreButton(
                    title: "Even Round",
                    subtitle: "10-10",
                    color: .gray,
                    isSelected: round.redScore == 10 && round.blueScore == 10
                ) {
                    round.redScore = 10
                    round.blueScore = 10
                }
                
                QuickScoreButton(
                    title: "More Options",
                    subtitle: "Knockdowns, etc.",
                    color: .gray,
                    isSelected: showingCustomScore
                ) {
                    showingCustomScore.toggle()
                }
            }
            
            // Current score display
            HStack(spacing: 20) {
                VStack {
                    Text("Red")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(round.redScore)")
                        .font(.title.bold())
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
                
                Text("—")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                VStack {
                    Text("Blue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(round.blueScore)")
                        .font(.title.bold())
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Score description
            if round.isValidScore {
                Text(round.scoreDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Expanded custom scoring options
            if showingCustomScore {
                Divider()
                
                VStack(spacing: 12) {
                    Text("Advanced Scoring")
                        .font(.headline)
                    
                    ForEach(BoxingRules.commonScores.filter { 
                        // Filter out the basic ones already shown
                        !($0.red == 10 && $0.blue == 9) &&
                        !($0.red == 9 && $0.blue == 10) &&
                        !($0.red == 10 && $0.blue == 10)
                    }, id: \.description) { score in
                        Button {
                            round.redScore = score.red
                            round.blueScore = score.blue
                        } label: {
                            HStack {
                                Text(score.description)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(score.red)-\(score.blue)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                round.redScore == score.red && round.blueScore == score.blue 
                                ? Color.accentColor.opacity(0.2) 
                                : Color.clear
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Manual adjustment
                    Divider()
                    
                    VStack(spacing: 8) {
                        Text("Manual Adjustment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("Red")
                                    .font(.caption)
                                Stepper(
                                    "\(round.redScore)",
                                    value: $round.redScore,
                                    in: 6...10
                                )
                                .labelsHidden()
                            }
                            
                            VStack {
                                Text("Blue")
                                    .font(.caption)
                                Stepper(
                                    "\(round.blueScore)",
                                    value: $round.blueScore,
                                    in: 6...10
                                )
                                .labelsHidden()
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .animation(.easeInOut, value: showingCustomScore)
    }
}

private struct QuickScoreButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Round Scoring") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RoundScore.self, configurations: config)
    
    let round = RoundScore(round: 1, redScore: 10, blueScore: 10)
    container.mainContext.insert(round)
    
    return NavigationStack {
        ScrollView {
            RoundScoringView(round: round)
                .padding()
        }
        .navigationTitle("Score Round 1")
    }
    .modelContainer(container)
}
