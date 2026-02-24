//
//  EmailAuthView.swift
//  r2rscorecards
//
//  Email/Password authentication views
//

import SwiftUI
import SwiftData
import CryptoKit

struct EmailAuthView: View {
    enum Mode {
        case login
        case register
    }
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var auth: AuthManager
    @Binding var isPresented: Bool
    
    let initialMode: Mode
    
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    
    // Demographic fields
    @State private var region = ""
    @State private var selectedGender: Gender = .unspecified
    @State private var selectedAgeGroup: AgeGroup?
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var onUserCreated: ((User) -> Void)? = nil
    
    init(isPresented: Binding<Bool>, initialMode: Mode = .login, onUserCreated: ((User) -> Void)? = nil) {
        self._isPresented = isPresented
        self.initialMode = initialMode
        self.onUserCreated = onUserCreated
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Toggle between Login and Register
            Picker("", selection: $isRegistering) {
                Text("Sign In").tag(false)
                Text("Register").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if isRegistering {
                registrationForm
            } else {
                loginForm
            }
            
            Button("Cancel") {
                isPresented = false
            }
            .padding(.top)
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            isRegistering = (initialMode == .register)
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            Text("Sign in with Email")
                .font(.headline)
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
            
            Button(action: handleLogin) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(email.isEmpty || password.isEmpty)
        }
    }
    
    private var registrationForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Create Account")
                    .font(.headline)
                
                // Account Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account Information")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                    
                    if !password.isEmpty && password.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Demographics (Optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Demographics")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    GeographicPicker(regionString: $region)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gender")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Gender", selection: $selectedGender) {
                            ForEach(Gender.allCases) { gender in
                                Text(gender.rawValue.capitalized).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Age Group")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Age Group", selection: $selectedAgeGroup) {
                            Text("Prefer not to say").tag(Optional<AgeGroup>.none)
                            ForEach(AgeGroup.allCases) { ageGroup in
                                Text(ageGroup.rawValue).tag(Optional(ageGroup))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Text("Demographics help provide insights on scoring patterns across different groups.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                
                Button(action: handleRegistration) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .disabled(!isValidRegistration)
            }
            .padding()
        }
    }
    
    private var isValidRegistration: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        do {
            // Fetch all users and find by email
            let descriptor = FetchDescriptor<User>()
            let users = try context.fetch(descriptor)
            
            guard let user = users.first(where: { $0.email == email.lowercased() }) else {
                errorMessage = "No account found with this email"
                showError = true
                return
            }
            
            // Verify password
            guard let storedPasswordHash = user.passwordHash else {
                errorMessage = "This account uses a different sign-in method"
                showError = true
                return
            }
            
            let passwordHash = hashPassword(password)
            guard passwordHash == storedPasswordHash else {
                errorMessage = "Incorrect password"
                showError = true
                return
            }
            
            // Success! Sign in
            auth.signInWithEmail(userID: user.id.uuidString, displayName: user.displayName)
            onUserCreated?(user)
            isPresented = false
            
        } catch {
            errorMessage = "Failed to sign in: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func handleRegistration() {
        guard isValidRegistration else { return }
        
        do {
            // Check if email already exists
            let descriptor = FetchDescriptor<User>()
            let users = try context.fetch(descriptor)
            
            if users.contains(where: { $0.email == email.lowercased() }) {
                errorMessage = "An account with this email already exists"
                showError = true
                return
            }
            
            // Create new user with demographics
            let passwordHash = hashPassword(password)
            let user = User(
                authUserID: "email-\(UUID().uuidString)",
                displayName: displayName,
                region: region,
                gender: selectedGender.rawValue,
                ageGroup: selectedAgeGroup?.rawValue ?? ""
            )
            user.email = email.lowercased()
            user.passwordHash = passwordHash
            user.passwordHash = passwordHash
            
            context.insert(user)
            try context.save()
            
            // Sign in
            auth.signInWithEmail(userID: user.id.uuidString, displayName: user.displayName)
            onUserCreated?(user)
            isPresented = false
            
        } catch {
            errorMessage = "Failed to create account: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview("Login") {
    do {
        let container = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let auth = AuthManager()
        
        return NavigationStack {
            EmailAuthView(isPresented: .constant(true), initialMode: .login)
                .environmentObject(auth)
                .modelContainer(container)
                .navigationTitle("Email Sign In")
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

#Preview("Register") {
    do {
        let container = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let auth = AuthManager()
        
        return NavigationStack {
            EmailAuthView(isPresented: .constant(true), initialMode: .register)
                .environmentObject(auth)
                .modelContainer(container)
                .navigationTitle("Register")
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
