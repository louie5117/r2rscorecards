import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var supabaseAuth: SupabaseAuthService
    @EnvironmentObject private var authUI: AuthUIState

    private var isAuthenticated: Bool {
        auth.currentUserIdentifier != nil || supabaseAuth.isAuthenticated
    }

    var body: some View {
        NavigationStack {
            HomeViewEnhanced()
        }
        .fullScreenCover(isPresented: .constant(!isAuthenticated)) {
            SignInView(isPresented: .constant(true), onSuccess: {
                // On success, auth state flips to authenticated elsewhere, which will auto-dismiss the cover
            })
            .interactiveDismissDisabled(true)
        }
        .task {
            supabaseAuth.restoreSessionIfPossible()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseAuthService())
        .environmentObject(AuthUIState())
}
