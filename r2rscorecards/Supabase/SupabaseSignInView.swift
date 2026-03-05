//
//  SupabaseSignInView.swift
//  r2rscorecards
//
//  Sign in with Supabase (Apple ID, Email/Password)
//

import SwiftUI
import AuthenticationServices

struct SupabaseSignInView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEmailAuth = false
    @State private var showForgotPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Sign In")
                        .font(.title.bold())
                    
                    Text("Save your scorecards and join the crowd!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Sign In Options
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    
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
                    .padding(.vertical, 8)
                    
                    // Email/Password button
                    Button {
                        showEmailAuth = true
                    } label: {
                        Label("Continue with Email", systemImage: "envelope.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Cancel button
                Button("Maybe Later") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showEmailAuth) {
                SupabaseEmailAuthView(showForgotPassword: $showForgotPassword)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    // MARK: - Apple Sign In Handler
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            switch result {
            case .success:
                await authService.signInWithApple()
                if authService.isAuthenticated {
                    dismiss()
                } else if let error = authService.lastError {
                    errorMessage = error
                    showError = true
                }
                
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Email Auth View for Supabase

struct SupabaseEmailAuthView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    @Binding var showForgotPassword: Bool
    
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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
                
                Spacer()
            }
            .padding()
            .navigationTitle(isRegistering ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
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
    
    // MARK: - Login Form
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
            
            // Forgot Password Link
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    dismiss()
                    showForgotPassword = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            Button {
                Task {
                    await handleLogin()
                }
            } label: {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(email.isEmpty || password.isEmpty ? Color.gray : Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(10)
            .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
        }
    }
    
    // MARK: - Registration Form
    
    private var registrationForm: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                
                // Validation Messages
                VStack(alignment: .leading, spacing: 4) {
                    if !password.isEmpty && password.count < 6 {
                        Label("Password must be at least 6 characters", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Label("Passwords don't match", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    if isValidRegistration {
                        Label("Ready to create account", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    Task {
                        await handleRegistration()
                    }
                } label: {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(isValidRegistration ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(10)
                .disabled(!isValidRegistration || authService.isLoading)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValidRegistration: Bool {
        !displayName.isEmpty &&
        isValidEmail(email) &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Actions
    
    private func handleLogin() async {
        await authService.signIn(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password)
        
        if authService.isAuthenticated {
            dismiss()
        } else if let error = authService.lastError {
            errorMessage = error
            showError = true
        }
    }
    
    private func handleRegistration() async {
        await authService.signUp(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password, displayName: displayName)
        
        if authService.isAuthenticated {
            dismiss()
        } else if let error = authService.lastError {
            errorMessage = error
            showError = true
        }
    }
}

#Preview("Sign In") {
    SupabaseSignInView()
        .environmentObject(SupabaseAuthService())
}

#Preview("Email Auth") {
    SupabaseEmailAuthView(showForgotPassword: .constant(false))
        .environmentObject(SupabaseAuthService())
}
