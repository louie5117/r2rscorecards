import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @EnvironmentObject private var authState: AppAuthState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false // ✨ ONBOARDING CHECK
    @State private var showSignIn = false
    @State private var showAuthChoice = false

    var body: some View {
        Group {
            // ✨ ONBOARDING FLOW - Shows on first launch
            if !hasCompletedOnboarding {
                OnboardingFlow(showAuthChoice: $showAuthChoice)
                    .environmentObject(supabaseAuth)
            } else if !authState.isAuthenticated {
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
                // Signed in - show new enhanced home
                NavigationStack {
                    HomeViewEnhanced()
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
    let auth = AuthManager()
    let supabase = SupabaseAuthService()
    return RootView()
        .environmentObject(auth)
        .environmentObject(supabase)
        .environmentObject(AppAuthState(legacy: auth, supabase: supabase))
        .environmentObject(SyncStatus(mode: .cloudKit, detail: "Data is syncing with CloudKit."))
        .modelContainer(container)
}
