//
//  ImportFightsView.swift
//  r2rscorecards
//
//  Browse and import fights from Boxing Data API
//

import SwiftUI
import SwiftData

struct ImportFightsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = BoxingAPIService()
    
    @State private var upcomingFights: [BoxingFight] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var importedFights: Set<String> = []
    
    var body: some View {
        NavigationStack {
            Group {
                if apiService.isLoading {
                    loadingView
                } else if upcomingFights.isEmpty {
                    emptyStateView
                } else {
                    fightsList
                }
            }
            .navigationTitle("Import Fights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await loadFights()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(apiService.isLoading)
                }
            }
            .task {
                await loadFights()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading upcoming fights...")
                .foregroundStyle(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Fights Available", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("Unable to load fights at this time. You can create fights manually from the main screen.")
        } actions: {
            Button("Try Again") {
                Task {
                    await loadFights()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var fightsList: some View {
        List {
            ForEach(upcomingFights) { fight in
                FightRow(
                    fight: fight,
                    isImported: importedFights.contains(fight.id),
                    onImport: {
                        importFight(fight)
                    }
                )
            }
        }
    }
    
    private func loadFights() async {
        do {
            upcomingFights = try await apiService.fetchUpcomingFights()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            
            // For demo purposes, load mock data if API fails
            #if DEBUG
            print("⚠️ API Error: \(error.localizedDescription)")
            print("📝 Loading mock data for preview...")
            upcomingFights = BoxingAPIService.mockFights()
            #endif
        }
    }
    
    private func importFight(_ boxingFight: BoxingFight) {
        // Check if already exists by API ID or title
        let descriptor = FetchDescriptor<Fight>()
        let existingFights = (try? context.fetch(descriptor)) ?? []
        
        // Don't import if we already have this fight (check by API ID first, then title)
        if existingFights.contains(where: { $0.apiSourceID == boxingFight.id || $0.title == boxingFight.displayTitle }) {
            return
        }
        
        // Create new fight from API data with API ID for global tracking
        let fight = Fight(
            title: boxingFight.displayTitle,
            date: boxingFight.date,
            scheduledRounds: boxingFight.rounds ?? 12,
            statusRaw: "upcoming",
            apiSourceID: boxingFight.id // Store API ID for global statistics
        )
        
        context.insert(fight)
        
        do {
            try context.save()
            importedFights.insert(boxingFight.id)
        } catch {
            errorMessage = "Failed to import fight: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Fight Row

private struct FightRow: View {
    let fight: BoxingFight
    let isImported: Bool
    let onImport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date
            Text(fight.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Fighters
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let f1 = fight.fighter1 {
                        Text(f1.name)
                            .font(.headline)
                        if let record = f1.record {
                            Text(record.displayString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Text("vs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let f2 = fight.fighter2 {
                        Text(f2.name)
                            .font(.headline)
                        if let record = f2.record {
                            Text(record.displayString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Details
            HStack {
                if let weightClass = fight.weightClass {
                    Label(weightClass, systemImage: "figure.boxing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let rounds = fight.rounds {
                    Label("\(rounds) rounds", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let location = fight.location {
                Label(location, systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Import button
            if isImported {
                Label("Imported", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button(action: onImport) {
                    Label("Import Fight", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Import Fights") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fight.self, configurations: config)
    
    ImportFightsView()
        .modelContainer(container)
}

#Preview("Fight Row") {
    let fight = BoxingAPIService.mockFights()[0]
    
    List {
        FightRow(fight: fight, isImported: false, onImport: {})
        FightRow(fight: fight, isImported: true, onImport: {})
    }
}
