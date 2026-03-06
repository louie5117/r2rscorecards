import SwiftUI
import SwiftUI
import SwiftData

struct FightDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager

    @Bindable var fight: Fight

    init(fight: Fight) {
        self._fight = Bindable(wrappedValue: fight)
    }

    @Query(sort: [SortDescriptor(\User.displayName)]) private var users: [User]
    @Query(sort: [SortDescriptor(\FriendGroup.name)]) private var allGroups: [FriendGroup]
    @State private var selectedUser: User?
    @State private var selectedGroup: FriendGroup?
    @State private var groupInviteCode: String = ""
    @State private var newGroupName: String = ""

    @State private var showSignIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToScorecard: Scorecard?

    enum Grouping: String, CaseIterable, Identifiable { case overall, region, gender, ageGroup; var id: String { rawValue } }
    @State private var grouping: Grouping = .overall

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Text("Signed in as")
                    Spacer()
                    if let displayName = auth.displayName {
                        VStack(alignment: .trailing) {
                            Text(displayName)
                                .foregroundStyle(.primary)
                            #if DEBUG
                            if auth.isDevBypass {
                                Text("(Dev Mode)")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            #endif
                        }
                    } else {
                        Text("Not signed in")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if selectedUser == nil && auth.currentUserIdentifier != nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("User profile not found. Try signing out and back in.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Button(role: .destructive) {
                    auth.signOut()
                    selectedUser = nil
                    selectedGroup = nil
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .disabled(auth.displayName == nil)
            }

            Section("Details") {
                TextField("Title", text: $fight.title)
                DatePicker("Date", selection: Binding(
                    get: { fight.date ?? .now },
                    set: { fight.date = $0 }
                ))
                Stepper("Scheduled Rounds: \(fight.scheduledRounds)", value: $fight.scheduledRounds, in: 1...15)
                Picker("Status", selection: $fight.statusRaw) {
                    Text("Upcoming").tag("upcoming")
                    Text("In Progress").tag("inProgress")
                    Text("Complete").tag("complete")
                }
            }

            Section("Scorecards") {
                if selectedUser == nil {
                    Text("Sign in to join a group and score this fight.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Your Group", selection: $selectedGroup) {
                        Text("None").tag(Optional<FriendGroup>.none)
                        ForEach(groupsForFight) { group in
                            Text(group.name).tag(Optional(group))
                        }
                    }
                    HStack {
                        TextField("Invite Code", text: $groupInviteCode)
                            .textInputAutocapitalization(.characters)
                        Button("Join") { joinGroupByCode() }
                            .disabled(groupInviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    HStack {
                        TextField("New Group Name", text: $newGroupName)
                        Button("Create") { createGroup() }
                            .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                ForEach(fight.scorecards ?? []) { card in
                    NavigationLink(value: card) {
                        HStack {
                            Text(card.title)
                            Spacer()
                            Text("R \(card.totalRed) – B \(card.totalBlue)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteScorecards)

                Button(action: {
                    if auth.currentUserIdentifier == nil {
                        showSignIn = true
                    } else {
                        startOrContinueScoring()
                    }
                }) {
                    if let user = selectedUser, let group = selectedGroup {
                        Text("Start/Continue for \(user.displayName) in \(group.name)")
                    } else if auth.currentUserIdentifier == nil {
                        Text("Sign in to start")
                    } else {
                        Text("Join or create a group to start")
                    }
                }
                .disabled(!canStartScoring)

                NavigationLink(destination: GroupResultsView(fight: fight)) {
                    Label("View Group Results", systemImage: "chart.bar.xaxis")
                }
            }

            Section("Crowd Average Totals") {
                let totals = crowdTotals()
                let avgRed = totals.avgRed
                let avgBlue = totals.avgBlue
                let count = totals.count
                VStack(alignment: .leading) {
                    HStack {
                        Text("Average Totals")
                        Spacer()
                        Text("R \(avgRed) – B \(avgBlue)")
                    }
                    .font(.headline)
                    if count > 0 {
                        Text("Based on \(count) scorecard(s)").foregroundStyle(.secondary)
                    } else {
                        Text("No scorecards yet").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Demographics Averages") {
                Picker("Group by", selection: $grouping) {
                    ForEach(Grouping.allCases) { g in Text(g.rawValue.capitalized).tag(g) }
                }
                let groups: [String: (red: Int, blue: Int, count: Int)] = demographicAverages()
                if groups.isEmpty {
                    Text("No data yet").foregroundStyle(.secondary)
                } else {
                    let sortedGroups: [(String, (Int, Int, Int))] = groups.sorted { $0.key < $1.key }.map { ($0.key, ($0.value.red, $0.value.blue, $0.value.count)) }
                    ForEach(sortedGroups, id: \.0) { entry in
                        let key: String = entry.0
                        let red: Int = entry.1.0
                        let blue: Int = entry.1.1
                        let n: Int = entry.1.2
                        HStack {
                            Text(key.isEmpty ? "Unspecified" : key)
                            Spacer()
                            Text("R \(red) – B \(blue) (n=\(n))")
                        }
                    }
                }
            }

            Section("Per-Round Crowd Averages") {
                let averages: [Int: (red: Int, blue: Int, count: Int)] = perRoundAverages()
                if averages.isEmpty {
                    Text("No round data yet").foregroundStyle(.secondary)
                } else {
                    let sortedRounds: [(Int, (Int, Int, Int))] = averages.sorted { $0.key < $1.key }.map { ($0.key, ($0.value.red, $0.value.blue, $0.value.count)) }
                    ForEach(sortedRounds, id: \.0) { entry in
                        let round: Int = entry.0
                        let red: Int = entry.1.0
                        let blue: Int = entry.1.1
                        let n: Int = entry.1.2
                        HStack {
                            Text("Round \(round)")
                            Spacer()
                            Text("R \(red) – B \(blue) (n=\(n))")
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Scorecard.self) { card in
            ScorecardView(scorecard: card)
        }
        .navigationDestination(item: $navigateToScorecard) { card in
            ScorecardView(scorecard: card)
        }
        .navigationTitle(fight.title)
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInView(isPresented: $showSignIn, onUserCreated: { user in
                    selectedUser = user
                })
            }
        }
        .onAppear { syncSignedInUser() }
        .onChange(of: auth.currentUserIdentifier) { oldValue, newValue in
            syncSignedInUser()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    UsersListView()
                } label: {
                    Label("Users", systemImage: "person.3")
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func startOrContinueScoring() {
        guard let user = selectedUser, let group = selectedGroup else { return }
        
        // Check if scorecard already exists - if so, navigate to it
        if let existingCard = (fight.scorecards ?? []).first(where: { $0.user?.id == user.id && $0.group?.id == group.id }) {
            navigateToScorecard = existingCard
            return
        }
        
        // Create new scorecard with valid default scores (10-10 for all rounds)
        let card = Scorecard(title: "Scorecard (\(user.displayName))", user: user, fight: fight, group: group)
        for r in 1...fight.scheduledRounds {
            // Initialize with 10-10 (valid even round score) instead of 0-0
            let rs = RoundScore(round: r, redScore: 10, blueScore: 10, fight: fight, scorecard: card)
            context.insert(rs)
            if card.rounds == nil { card.rounds = [] }
            card.rounds?.append(rs)
            if fight.rounds == nil { fight.rounds = [] }
            fight.rounds?.append(rs)
        }
        context.insert(card)
        do {
            try context.save()
            // Navigate to the new scorecard
            navigateToScorecard = card
        } catch {
            errorMessage = "Failed to create scorecard: \(error.localizedDescription)"
            showError = true
        }
    }

    private func deleteScorecards(at offsets: IndexSet) {
        let scorecards = fight.scorecards ?? []
        for index in offsets { context.delete(scorecards[index]) }
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to delete scorecard: \(error.localizedDescription)"
            showError = true
        }
    }

    private func crowdTotals() -> (avgRed: Int, avgBlue: Int, count: Int) {
        let cards = fight.scorecards ?? []
        let count = cards.count
        guard count > 0 else { return (0, 0, 0) }
        let sumRed = cards.reduce(0) { $0 + $1.totalRed }
        let sumBlue = cards.reduce(0) { $0 + $1.totalBlue }
        let avgRed = Int(round(Double(sumRed) / Double(count)))
        let avgBlue = Int(round(Double(sumBlue) / Double(count)))
        return (avgRed, avgBlue, count)
    }

    private var groupsForFight: [FriendGroup] {
        allGroups.filter { $0.fight?.id == fight.id }
    }

    private var canStartScoring: Bool {
        selectedUser != nil && selectedGroup != nil
    }

    private func syncSignedInUser() {
        guard let authID = auth.currentUserIdentifier else {
            selectedUser = nil
            return
        }
        
        // Try to find existing user in the query results first
        // Check both authUserID and UUID string (for email auth)
        if let user = users.first(where: { 
            $0.authUserID == authID || $0.id.uuidString == authID
        }) {
            selectedUser = user
            return
        }
        
        // If not found, try to fetch again (in case it was just created)
        do {
            let descriptor = FetchDescriptor<User>()
            let allUsers = try context.fetch(descriptor)
            if let user = allUsers.first(where: { 
                $0.authUserID == authID || $0.id.uuidString == authID
            }) {
                selectedUser = user
                print("✅ Found user via manual fetch: \(user.displayName)")
            } else {
                print("❌ User not found with authID: \(authID)")
            }
        } catch {
            print("❌ Error fetching user: \(error)")
        }
    }

    private func joinGroupByCode() {
        guard let user = selectedUser else { return }
        let code = groupInviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let group = groupsForFight.first(where: { $0.inviteCode.uppercased() == code }) else {
            errorMessage = "No group found with invite code '\(code)'"
            showError = true
            return
        }
        if !(group.members ?? []).contains(where: { $0.id == user.id }) {
            if group.members == nil { group.members = [] }
            group.members?.append(user)
        }
        selectedGroup = group
        groupInviteCode = ""
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to join group: \(error.localizedDescription)"
            showError = true
        }
    }

    private func createGroup() {
        guard let user = selectedUser else { return }
        let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
        while allGroups.contains(where: { $0.inviteCode.uppercased() == inviteCode }) {
            inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
        }
        let group = FriendGroup(name: trimmed, inviteCode: inviteCode, fight: fight, members: [user])
        context.insert(group)
        if fight.friendGroups == nil { fight.friendGroups = [] }
        fight.friendGroups?.append(group)
        selectedGroup = group
        newGroupName = ""
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
            showError = true
        }
    }

    private func demographicAverages() -> [String: (red: Int, blue: Int, count: Int)] {
        let cards = fight.scorecards ?? []
        guard !cards.isEmpty else { return [:] }
        func key(for card: Scorecard) -> String {
            guard let u = card.user else { return "" }
            switch grouping {
            case .overall: return "Overall"
            case .region: return u.region
            case .gender: return u.gender
            case .ageGroup: return u.ageGroup
            }
        }
        var buckets: [String: (sumR: Int, sumB: Int, n: Int)] = [:]
        for c in cards {
            let k = key(for: c)
            var b = buckets[k] ?? (0, 0, 0)
            b.sumR += c.totalRed
            b.sumB += c.totalBlue
            b.n += 1
            buckets[k] = b
        }
        var result: [String: (red: Int, blue: Int, count: Int)] = [:]
        for (k, v) in buckets {
            let avgR = Int(round(Double(v.sumR) / Double(v.n)))
            let avgB = Int(round(Double(v.sumB) / Double(v.n)))
            result[k] = (avgR, avgB, v.n)
        }
        return result
    }

    private func perRoundAverages() -> [Int: (red: Int, blue: Int, count: Int)] {
        var buckets: [Int: (sumR: Int, sumB: Int, n: Int)] = [:]
        for c in (fight.scorecards ?? []) {
            for rs in (c.rounds ?? []) {
                var b = buckets[rs.round] ?? (0,0,0)
                b.sumR += rs.redScore
                b.sumB += rs.blueScore
                b.n += 1
                buckets[rs.round] = b
            }
        }
        var result: [Int: (red: Int, blue: Int, count: Int)] = [:]
        for (roundNumber, v) in buckets {
            let avgR = Int(round(Double(v.sumR) / Double(v.n)))
            let avgB = Int(round(Double(v.sumB) / Double(v.n)))
            result[roundNumber] = (avgR, avgB, v.n)
        }
        return result
    }
}

private struct GroupResultsView: View {
    @Bindable var fight: Fight
    @State private var selectedGroup: FriendGroup?

    var body: some View {
        Form {
            Section("Filter") {
                Picker("Group", selection: $selectedGroup) {
                    Text("All Groups").tag(Optional<FriendGroup>.none)
                    ForEach(groupsForFight) { group in
                        Text(group.name).tag(Optional(group))
                    }
                }
            }

            Section("Summary") {
                let cards = filteredSubmittedCards
                if cards.isEmpty {
                    Text("No submitted scorecards yet.")
                        .foregroundStyle(.secondary)
                } else {
                    let totals = averageTotals(for: cards)
                    HStack {
                        Text("Submitted Cards")
                        Spacer()
                        Text("\(cards.count)")
                    }
                    HStack {
                        Text("Average Totals")
                        Spacer()
                        Text("R \(totals.red) – B \(totals.blue)")
                    }
                }
            }

            Section("Submitted Scorecards") {
                let cards = filteredSubmittedCards
                if cards.isEmpty {
                    Text("Nothing submitted yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(cards) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(card.user?.displayName ?? "Unknown User")
                                Spacer()
                                Text(card.group?.name ?? "No Group")
                                    .foregroundStyle(.secondary)
                            }
                            Text("R \(card.totalRed) – B \(card.totalBlue)")
                                .font(.subheadline)
                            if let submittedAt = card.submittedAt {
                                Text("Submitted \(submittedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Per-Round Averages") {
                let averages = perRoundAverages(for: filteredSubmittedCards)
                if averages.isEmpty {
                    Text("No round data from submitted scorecards.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(averages, id: \.round) { row in
                        HStack {
                            Text("Round \(row.round)")
                            Spacer()
                            Text("R \(row.red) – B \(row.blue) (n=\(row.count))")
                        }
                    }
                }
            }
        }
        .navigationTitle("Group Results")
    }

    private var groupsForFight: [FriendGroup] {
        (fight.friendGroups ?? []).sorted { $0.name < $1.name }
    }

    private var filteredSubmittedCards: [Scorecard] {
        let submitted = (fight.scorecards ?? []).filter { $0.isSubmitted }
        let filtered: [Scorecard]
        if let selectedGroup {
            filtered = submitted.filter { $0.group?.id == selectedGroup.id }
        } else {
            filtered = submitted
        }
        return filtered.sorted { ($0.submittedAt ?? .distantPast) > ($1.submittedAt ?? .distantPast) }
    }

    private func averageTotals(for cards: [Scorecard]) -> (red: Int, blue: Int) {
        guard !cards.isEmpty else { return (0, 0) }
        let sumRed = cards.reduce(0) { $0 + $1.totalRed }
        let sumBlue = cards.reduce(0) { $0 + $1.totalBlue }
        return (Int(round(Double(sumRed) / Double(cards.count))), Int(round(Double(sumBlue) / Double(cards.count))))
    }

    private func perRoundAverages(for cards: [Scorecard]) -> [(round: Int, red: Int, blue: Int, count: Int)] {
        var buckets: [Int: (sumRed: Int, sumBlue: Int, count: Int)] = [:]
        for card in cards {
            for round in (card.rounds ?? []) {
                var bucket = buckets[round.round] ?? (0, 0, 0)
                bucket.sumRed += round.redScore
                bucket.sumBlue += round.blueScore
                bucket.count += 1
                buckets[round.round] = bucket
            }
        }
        return buckets
            .map { key, value in
                (
                    round: key,
                    red: Int(round(Double(value.sumRed) / Double(value.count))),
                    blue: Int(round(Double(value.sumBlue) / Double(value.count))),
                    count: value.count
                )
            }
            .sorted { $0.round < $1.round }
    }
}

private enum FightDetailPreviewData {
    @MainActor
    static var containerFightAndAuth: (ModelContainer, Fight, AuthManager) {
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
        let user = User(authUserID: "preview-user", displayName: "Preview User", region: "US", gender: "unspecified", ageGroup: "")
        context.insert(fight)
        context.insert(user)
        let group = FriendGroup(name: "Friends", fight: fight, members: [user])
        context.insert(group)
        if fight.friendGroups == nil { fight.friendGroups = [] }
        fight.friendGroups?.append(group)
        let auth = AuthManager()
        auth.currentUserIdentifier = user.authUserID
        auth.displayName = user.displayName
        return (container, fight, auth)
    }
}

#Preview {
    FightDetailPreview()
}

private struct FightDetailPreview: View {
    let previewData = FightDetailPreviewData.containerFightAndAuth
    
    var body: some View {
        NavigationStack { 
            FightDetailView(fight: previewData.1) 
        }
        .environmentObject(previewData.2)
        .modelContainer(previewData.0)
    }
}
