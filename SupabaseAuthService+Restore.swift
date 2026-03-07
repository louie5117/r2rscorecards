import Foundation

extension SupabaseAuthService {
    @MainActor
    func restoreSessionIfPossible() {
        // If your Supabase client provides session restoration, call it here.
        // For now, this is a safe no-op that can be expanded later.
        if self.isAuthenticated {
            return
        }
        // TODO: Implement real session restoration via Supabase SDK
    }
}
