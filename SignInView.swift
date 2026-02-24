import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager
    @Binding var isPresented: Bool
    @State private var showDemographicsPrompt = false
    @State private var createdUser: User?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEmailAuth = false
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
                    errorMessage = error.localizedDescription
                    showError = true
                }
            })
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Email/Password button
            Button {
                showEmailAuth = true
            } label: {
                Label("Sign in with Email", systemImage: "envelope.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            
            #if DEBUG
            Button {
                handleDevBypass()
            } label: {
                Label("Skip Sign In (Dev Only)", systemImage: "hammer.fill")
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            #endif

            Button("Cancel") { isPresented = false }
        }
        .padding()
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showEmailAuth) {
            NavigationStack {
                EmailAuthView(isPresented: $showEmailAuth, onUserCreated: onUserCreated)
                    .navigationTitle("Email Sign In")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .environmentObject(auth)
        }
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
        guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid credential type received"
            showError = true
            return
        }
        let userID = credential.user
        let displayName = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        auth.currentUserIdentifier = userID
        auth.displayName = displayName.isEmpty ? nil : displayName

        // Find or create local User by Apple credential user id.
        do {
            let users = try context.fetch(FetchDescriptor<User>())
            if let existing = users.first(where: { $0.authUserID == userID }) {
                createdUser = existing
            } else {
                let fallbackName = displayName.isEmpty ? "User" : displayName
                let user = User(authUserID: userID, displayName: fallbackName, region: "", gender: Gender.unspecified.rawValue, ageGroup: "")
                context.insert(user)
                try context.save()
                createdUser = user
            }
            showDemographicsPrompt = true
        } catch {
            errorMessage = "Failed to save user profile: \(error.localizedDescription)"
            showError = true
        }
    }
    
    #if DEBUG
    private func handleDevBypass() {
        // This sets currentUserIdentifier to "dev-bypass-test-user"
        auth.devBypassSignIn(name: "Dev Tester")
        
        // Create or find the dev user in the database
        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.authUserID == "dev-bypass-test-user" }
            )
            let users = try context.fetch(descriptor)
            
            if let existing = users.first {
                // Reuse existing dev user
                createdUser = existing
            } else {
                // Create new dev user
                let user = User(
                    authUserID: "dev-bypass-test-user",
                    displayName: "Dev Tester",
                    region: "US",
                    gender: Gender.unspecified.rawValue,
                    ageGroup: AgeGroup.a25_34.rawValue
                )
                context.insert(user)
                try context.save()
                createdUser = user
            }
            // Skip demographics prompt for dev bypass
            isPresented = false
        } catch {
            errorMessage = "Failed to create dev user: \(error.localizedDescription)"
            showError = true
        }
    }
    #endif
}

struct DemographicsPromptView: View {
    @Environment(\.modelContext) private var context
    @Bindable var user: User
    @Binding var isPresented: Bool
    @State private var showError = false
    @State private var errorMessage = ""

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
                        do {
                            try context.save()
                            isPresented = false
                        } catch {
                            errorMessage = "Failed to save profile: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
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
