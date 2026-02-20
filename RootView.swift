import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var showSignIn = false

    var body: some View {
        Group {
            if auth.currentUserIdentifier == nil {
                VStack(spacing: 20) {
                    Image(systemName: "list.number.rectangle.fill")
                        .font(.system(size: 64))
                    Text("R2R Scorecards")
                        .font(.largeTitle.bold())
                    Text("Track rounds, compare scorecards, and share with your group.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Sign in to Continue") { showSignIn = true }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                NavigationStack {
                    FightListView()
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack { SignInView(isPresented: $showSignIn) }
                .environmentObject(auth)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Fight.self,
        User.self,
        FriendGroup.self,
        Scorecard.self,
        RoundScore.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    RootView()
        .environmentObject(AuthManager())
        .environmentObject(SyncStatus(mode: .cloudKit, detail: "Data is syncing with CloudKit."))
        .modelContainer(container)
}
