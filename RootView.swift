import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @State private var showSignIn = false
    @State private var showAuthChoice = false

    var body: some View {
        Group {
            if auth.currentUserIdentifier == nil && !supabaseAuth.isAuthenticated {
                // Not signed in
                VStack(spacing: 20) {
                    Image(systemName: "list.number.rectangle.fill")
                        .font(.system(size: 64))
                    Text("R2R Scorecards")
                        .font(.largeTitle.bold())
                    Text("Track rounds, compare scorecards, and share with your group.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        // Primary: Supabase Sign In (recommended)
                        Button {
                            showAuthChoice = true
                        } label: {
                            Label("Sign In", systemImage: "person.crop.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // Secondary: Legacy Sign In
                        Button {
                            showSignIn = true
                        } label: {
                            Text("Sign In (Legacy)")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            } else {
                // Signed in
                NavigationStack {
                    FightListView()
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack { SignInView(isPresented: $showSignIn) }
                .environmentObject(auth)
        }
        .sheet(isPresented: $showAuthChoice) {
            SupabaseSignInView()
                .environmentObject(supabaseAuth)
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
        .environmentObject(SupabaseAuthService())
        .environmentObject(SyncStatus(mode: .cloudKit, detail: "Data is syncing with CloudKit."))
        .modelContainer(container)
}
