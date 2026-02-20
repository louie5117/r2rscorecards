import SwiftUI
import SwiftData

struct FightListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Fight.date, order: .forward)]) private var fights: [Fight]
    
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var syncStatus: SyncStatus
    @State private var showSignIn = false

    init() {}

    var body: some View {
        List {
            Section("Sync") {
                HStack {
                    Label(syncStatus.title, systemImage: syncStatus.iconName)
                    Spacer()
                    Text(syncStatus.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                Text("Last check: \(syncStatus.lastSyncAttempt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let lastError = syncStatus.lastError, !lastError.isEmpty {
                    Text("Last error: \(lastError)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            Section("Upcoming") {
                ForEach(fights.filter { $0.statusRaw == "upcoming" || $0.statusRaw == "inProgress" }) { fight in
                    NavigationLink(value: fight) {
                        VStack(alignment: .leading) {
                            Text(fight.title).font(.headline)
                            Text("\(fight.date, format: .dateTime) • Rounds: \(fight.scheduledRounds)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Completed") {
                ForEach(fights.filter { $0.statusRaw == "complete" }) { fight in
                    NavigationLink(value: fight) {
                        VStack(alignment: .leading) {
                            Text(fight.title).font(.headline)
                            Text("\(fight.date, format: .dateTime) • Rounds: \(fight.scheduledRounds)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
#if DEBUG
            Section("Developer") {
                Button(role: .destructive) { resetStore() } label: { Text("Reset Local Store") }
                Button { seedSampleData() } label: { Text("Seed Sample Data") }
            }
#endif
        }
        .navigationDestination(for: Fight.self) { fight in
            FightDetailView(fight: fight)
        }
        .navigationTitle("Fights")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: UsersListView()) { Label("Users", systemImage: "person.3") }
            }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: MyScorecardsView()) { Label("My Cards", systemImage: "checklist") }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { addSampleFight() } label: { Label("Add Fight", systemImage: "plus") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: PrivacyFAQView()) { Label("Privacy", systemImage: "hand.raised") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSignIn = true } label: {
                    if let name = auth.displayName, !name.isEmpty {
                        Label(name, systemImage: "person.crop.circle")
                    } else {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack { SignInView(isPresented: $showSignIn) }
                .environmentObject(auth)
        }
    }

    private func addSampleFight() {
        let fight = Fight(title: "Sample Fight", date: .now.addingTimeInterval(86400), scheduledRounds: 12, statusRaw: "upcoming")
        context.insert(fight)
        do { try context.save() } catch { print("Failed to save: \(error)") }
    }

#if DEBUG
    private func resetStore() {
        // Delete all objects in the local context
        let allFights = fights
        for f in allFights { context.delete(f) }
        // Also fetch and delete users, scorecards, and rounds
        let descriptor = FetchDescriptor<User>()
        if let fetchedUsers = try? context.fetch(descriptor) {
            for u in fetchedUsers { context.delete(u) }
        }
        let scDesc = FetchDescriptor<Scorecard>()
        if let fetchedSCs = try? context.fetch(scDesc) {
            for sc in fetchedSCs { context.delete(sc) }
        }
        let rsDesc = FetchDescriptor<RoundScore>()
        if let fetchedRS = try? context.fetch(rsDesc) {
            for rs in fetchedRS { context.delete(rs) }
        }
        do { try context.save() } catch { print("Reset error: \(error)") }
    }

    private func seedSampleData() {
        // Create users
        let alice = User(displayName: "Alice", region: "US", gender: "female", ageGroup: "25-34")
        let bob = User(displayName: "Bob", region: "UK", gender: "male", ageGroup: "35-44")
        context.insert(alice); context.insert(bob)
        // Create a fight
        let fight = Fight(title: "Championship Bout", date: .now.addingTimeInterval(3600*24), scheduledRounds: 12, statusRaw: "upcoming")
        context.insert(fight)
        // Create scorecards and rounds
        let aliceCard = Scorecard(title: "Alice Card", user: alice, fight: fight)
        let bobCard = Scorecard(title: "Bob Card", user: bob, fight: fight)
        context.insert(aliceCard); context.insert(bobCard)
        for r in 1...fight.scheduledRounds {
            let a = RoundScore(round: r, redScore: Int.random(in: 8...10), blueScore: Int.random(in: 8...10), fight: fight, scorecard: aliceCard)
            let b = RoundScore(round: r, redScore: Int.random(in: 8...10), blueScore: Int.random(in: 8...10), fight: fight, scorecard: bobCard)
            context.insert(a); context.insert(b)
            aliceCard.rounds.append(a); bobCard.rounds.append(b)
            fight.rounds.append(a); fight.rounds.append(b)
        }
        do { try context.save() } catch { print("Seed error: \(error)") }
    }
#endif
}

private enum FightListPreviewData {
    @MainActor
    static var container: ModelContainer {
        let container = try! ModelContainer(
            for: Fight.self,
            User.self,
            FriendGroup.self,
            Scorecard.self,
            RoundScore.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(Fight(title: "Championship Bout", date: .now.addingTimeInterval(3600 * 24), scheduledRounds: 12, statusRaw: "upcoming"))
        context.insert(Fight(title: "Main Event Replay", date: .now.addingTimeInterval(-3600 * 24), scheduledRounds: 10, statusRaw: "complete"))
        return container
    }
}

#Preview {
    NavigationStack {
        FightListView()
    }
    .environmentObject(AuthManager())
    .environmentObject(SyncStatus(mode: .cloudKit, detail: "Data is syncing with CloudKit."))
    .modelContainer(FightListPreviewData.container)
}

private struct MyScorecardsView: View {
    @EnvironmentObject private var auth: AuthManager
    @Query(sort: [SortDescriptor(\Scorecard.submittedAt, order: .reverse), SortDescriptor(\Scorecard.createdAt, order: .reverse)])
    private var scorecards: [Scorecard]

    var body: some View {
        List {
            if auth.currentUserIdentifier == nil {
                Text("Sign in to view your scorecards.")
                    .foregroundStyle(.secondary)
            } else if myCards.isEmpty {
                Text("No scorecards yet.")
                    .foregroundStyle(.secondary)
            } else {
                Section("Submitted") {
                    let submitted = myCards.filter { $0.isSubmitted }
                    if submitted.isEmpty {
                        Text("No submitted scorecards yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(submitted) { card in
                            NavigationLink(destination: ScorecardView(scorecard: card)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.fight?.title ?? "Unknown Fight")
                                        .font(.headline)
                                    Text("R \(card.totalRed) – B \(card.totalBlue)")
                                    if let submittedAt = card.submittedAt {
                                        Text("Submitted \(submittedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Drafts") {
                    let drafts = myCards.filter { !$0.isSubmitted }
                    if drafts.isEmpty {
                        Text("No drafts.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(drafts) { card in
                            NavigationLink(destination: ScorecardView(scorecard: card)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.fight?.title ?? "Unknown Fight")
                                        .font(.headline)
                                    Text("Draft: R \(card.computedRedTotal) – B \(card.computedBlueTotal)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("My Scorecards")
    }

    private var myCards: [Scorecard] {
        guard let authID = auth.currentUserIdentifier else { return [] }
        return scorecards.filter { $0.user?.authUserID == authID }
    }
}

struct PrivacyFAQView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy & Demographics").font(.largeTitle).bold()
                Text("We use optional demographics to show crowd insights by region, gender, and age group. You can edit or remove your info at any time.")
                Text("We do not access your Apple ID profile. If you sign in with Apple, we receive an app-scoped identifier and an optional name.")
                Text("Your data is stored locally and can be removed by deleting the app or using in-app reset tools in Debug builds.")
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
}
