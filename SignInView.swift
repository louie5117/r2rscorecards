import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager
    @Binding var isPresented: Bool
    @State private var showDemographicsPrompt = false
    @State private var createdUser: User?
    var onUserCreated: ((User) -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign in to save your scoring and join crowd insights.")
                .multilineTextAlignment(.center)
            SignInWithAppleButton(.signIn, onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            }, onCompletion: { result in
                switch result {
                case .success(let authResult):
                    handle(authResult)
                case .failure(let error):
                    print("Sign in failed: \(error)")
                }
            })
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)

            Button("Cancel") { isPresented = false }
        }
        .padding()
        .sheet(isPresented: $showDemographicsPrompt) {
            if let user = createdUser {
                DemographicsPromptView(user: user, isPresented: $showDemographicsPrompt)
                    .onDisappear {
                        if let user = createdUser { onUserCreated?(user) }
                        isPresented = false
                    }
            } else {
                NavigationStack {
                    VStack(spacing: 16) {
                        Text("Profile setup was interrupted.")
                            .font(.headline)
                        Text("Please try signing in again.")
                            .foregroundStyle(.secondary)
                        Button("Close") {
                            showDemographicsPrompt = false
                            isPresented = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("Profile")
                }
            }
        }
    }

    private func handle(_ authResult: ASAuthorization) {
        guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else { return }
        let userID = credential.user
        let displayName = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        auth.currentUserIdentifier = userID
        auth.displayName = displayName.isEmpty ? nil : displayName

        // Find or create local User by Apple credential user id.
        let users = (try? context.fetch(FetchDescriptor<User>())) ?? []
        if let existing = users.first(where: { $0.authUserID == userID }) {
            createdUser = existing
        } else {
            let fallbackName = displayName.isEmpty ? "User" : displayName
            let user = User(authUserID: userID, displayName: fallbackName, region: "", gender: Gender.unspecified.rawValue, ageGroup: "")
            context.insert(user)
            do { try context.save() } catch { print("Save user error: \(error)") }
            createdUser = user
        }
        showDemographicsPrompt = true
    }
}

struct DemographicsPromptView: View {
    @Environment(\.modelContext) private var context
    @Bindable var user: User
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Optional Demographics") {
                    TextField("Region", text: $user.region)
                    Picker("Gender", selection: Binding(get: { user.genderEnum }, set: { user.genderEnum = $0 })) {
                        ForEach(Gender.allCases) { g in Text(g.rawValue.capitalized).tag(g) }
                    }
                    Picker("Age Group", selection: Binding(get: { user.ageGroupEnum }, set: { user.ageGroupEnum = $0 })) {
                        Text("Unspecified").tag(Optional<AgeGroup>.none)
                        ForEach(AgeGroup.allCases) { ag in Text(ag.rawValue).tag(Optional(ag)) }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        do { try context.save() } catch { print("Save error: \(error)") }
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: User.self)
    let auth = AuthManager()
    SignInView(isPresented: .constant(true))
        .environmentObject(auth)
        .modelContainer(container)
}
