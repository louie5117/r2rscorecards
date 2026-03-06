//
//  BoxerSearchView.swift
//  r2rscorecards
//
//  Browse and search boxers + their fight history via TheSportsDB.
//

import SwiftUI

// MARK: - Boxer Search / Browse

struct BoxerSearchView: View {
    @StateObject private var service = BoxerIndexService()
    @State private var query = ""
    @State private var boxers: [BoxerProfile] = []
    @State private var upcomingFights: [IndexedFight] = []
    @State private var recentFights: [IndexedFight] = []
    @State private var selectedTab: Tab = .upcoming

    enum Tab: String, CaseIterable {
        case upcoming = "Upcoming"
        case results  = "Results"
        case boxers   = "Boxers"
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

                if selectedTab == .boxers {
                    searchBar
                }

                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = service.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle",
                                          description: Text(err))
                } else {
                    tabContent
                }
            }
            .navigationTitle("Boxing Index")
            .task { await loadInitialData() }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .upcoming:
            fightList(upcomingFights, emptyMessage: "No upcoming fights found")
        case .results:
            fightList(recentFights, emptyMessage: "No recent results found")
        case .boxers:
            boxerList
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search boxer name…", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { Task { await runBoxerSearch() } }
            if !query.isEmpty {
                Button { query = ""; boxers = [] } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private var boxerList: some View {
        Group {
            if boxers.isEmpty && query.isEmpty {
                ContentUnavailableView("Search Boxers",
                                       systemImage: "person.crop.circle.badge.magnifyingglass",
                                       description: Text("Type a name above to search for a boxer"))
            } else if boxers.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(boxers) { boxer in
                    NavigationLink(destination: BoxerDetailView(profile: boxer)) {
                        BoxerRowView(boxer: boxer)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func fightList(_ fights: [IndexedFight], emptyMessage: String) -> some View {
        Group {
            if fights.isEmpty {
                ContentUnavailableView(emptyMessage, systemImage: "calendar.badge.exclamationmark")
            } else {
                List(fights) { fight in
                    IndexedFightRowView(fight: fight)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Data loading

    private func loadInitialData() async {
        async let upcoming = service.fetchUpcomingSchedule()
        async let recent   = service.fetchRecentResults()
        let (u, r) = await (upcoming, recent)
        upcomingFights = u
        recentFights   = r
    }

    private func runBoxerSearch() async {
        guard !query.isEmpty else { boxers = []; return }
        boxers = await service.searchBoxers(query: query)
    }
}

// MARK: - Boxer Row

struct BoxerRowView: View {
    let boxer: BoxerProfile

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: boxer.photoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(boxer.name).font(.headline)
                if let nat = boxer.nationality {
                    Text(nat).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Indexed Fight Row

struct IndexedFightRowView: View {
    let fight: IndexedFight

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
                if let venue = fight.venue ?? fight.city {
                    Label(venue, systemImage: "mappin")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let method = fight.method {
                HStack {
                    Text(fight.status == .completed ? "Result:" : "Scheduled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(method)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor(method).opacity(0.15),
                                    in: Capsule())
                        .foregroundStyle(methodColor(method))
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

// MARK: - Boxer Detail View

struct BoxerDetailView: View {
    let profile: BoxerProfile
    @StateObject private var service = BoxerIndexService()
    @State private var fights: [IndexedFight] = []

    var body: some View {
        List {
            // Header
            Section {
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: profile.photoURL ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name).font(.title2.bold())
                        if let nat = profile.nationality {
                            Text(nat).foregroundStyle(.secondary)
                        }
                        if let dob = profile.dateOfBirth {
                            Text("Born \(dob.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                if let desc = profile.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }

            // Fight history
            let upcoming = fights.filter { $0.status == .upcoming }
            let past     = fights.filter { $0.status != .upcoming }

            if !upcoming.isEmpty {
                Section("Upcoming") {
                    ForEach(upcoming) { fight in
                        IndexedFightRowView(fight: fight)
                    }
                }
            }

            if !past.isEmpty {
                Section("Fight History (\(past.count))") {
                    ForEach(past) { fight in
                        IndexedFightRowView(fight: fight)
                    }
                }
            }

            if fights.isEmpty && !service.isLoading {
                Section {
                    ContentUnavailableView("No Fight History",
                                           systemImage: "list.bullet.rectangle",
                                           description: Text("No recorded fights found for this boxer"))
                }
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if service.isLoading { ProgressView() }
        }
        .task {
            fights = await service.fetchFightHistory(sportsDbID: profile.id)
        }
    }
}

// MARK: - Preview

#Preview {
    BoxerSearchView()
}
