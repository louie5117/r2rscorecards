//
//  ImportFightsView.swift
//  r2rscorecards
//
//  Browse and import fights from TheSportsDB (free, no API key required).
//

import SwiftUI
import SwiftData

struct ImportFightsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = BoxerIndexService()

    @State private var upcomingFights: [IndexedFight] = []
    @State private var recentFights: [IndexedFight] = []
    @State private var selectedTab: Tab = .upcoming
    @State private var importedFights: Set<String> = []

    enum Tab: String, CaseIterable {
        case upcoming = "Upcoming"
        case results  = "Results"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Group {
                    if service.isLoading {
                        ProgressView("Loading fights…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let err = service.errorMessage {
                        ContentUnavailableView {
                            Label("Error", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(err)
                        } actions: {
                            Button("Try Again") { Task { await loadFights() } }
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        fightsList
                    }
                }
            }
            .navigationTitle("Import Fights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { Task { await loadFights() } } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(service.isLoading)
                }
            }
            .task { await loadFights() }
        }
    }

    // MARK: - Fight list

    @ViewBuilder
    private var fightsList: some View {
        let fights = selectedTab == .upcoming ? upcomingFights : recentFights
        if fights.isEmpty {
            ContentUnavailableView(
                selectedTab == .upcoming ? "No Upcoming Fights" : "No Recent Results",
                systemImage: "calendar.badge.exclamationmark"
            )
        } else {
            List(fights) { fight in
                FightImportRow(
                    fight: fight,
                    isImported: importedFights.contains(fight.id),
                    onImport: { importFight(fight) }
                )
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Data loading

    private func loadFights() async {
        async let upcoming = service.fetchUpcomingSchedule()
        async let recent   = service.fetchRecentResults()
        let (u, r) = await (upcoming, recent)
        upcomingFights = u
        recentFights   = r
    }

    // MARK: - Import

    private func importFight(_ indexed: IndexedFight) {
        let descriptor = FetchDescriptor<Fight>()
        let existing = (try? context.fetch(descriptor)) ?? []

        guard !existing.contains(where: {
            $0.apiSourceID == indexed.id || $0.title == indexed.title
        }) else { return }

        let fight = Fight(
            title: indexed.title,
            date: indexed.date ?? Date(),
            scheduledRounds: indexed.scheduledRounds,
            statusRaw: indexed.status == .completed ? "complete" : "upcoming",
            apiSourceID: indexed.id
        )

        context.insert(fight)
        try? context.save()
        importedFights.insert(indexed.id)
    }
}

// MARK: - Row

private struct FightImportRow: View {
    let fight: IndexedFight
    let isImported: Bool
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fight.title)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 12) {
                if let date = fight.date {
                    Label(date.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                }
                if let place = fight.venue ?? fight.city {
                    Label(place, systemImage: "mappin")
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label("\(fight.scheduledRounds) rounds", systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let method = fight.method {
                    Text(method)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor(method).opacity(0.15), in: Capsule())
                        .foregroundStyle(methodColor(method))
                }

                Spacer()

                if isImported {
                    Label("Imported", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Button(action: onImport) {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "KO", "TKO": return .red
        case "UD", "SD", "MD": return .blue
        default: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fight.self, configurations: config)
    ImportFightsView()
        .modelContainer(container)
}
