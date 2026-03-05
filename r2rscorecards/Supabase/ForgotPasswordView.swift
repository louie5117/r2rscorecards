//
//  ForgotPasswordView.swift
//  r2rscorecards
//
//  Password reset flow using Supabase Auth
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                // Instructions
                VStack(spacing: 12) {
                    Text("Reset Your Password")
                        .font(.title2.bold())
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if !email.isEmpty && !isValidEmail(email) {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                
                // Send Reset Link Button
                Button {
                    Task {
                        await sendResetLink()
                    }
                } label: {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Send Reset Link")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(isValidEmail(email) ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(!isValidEmail(email) || authService.isLoading)
                
                Spacer()
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Check Your Email", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("If an account exists with \(email), you will receive a password reset link shortly.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendResetLink() async {
        guard isValidEmail(email) else { return }
        
        let success = await authService.sendPasswordReset(email: email.lowercased().trimmingCharacters(in: .whitespaces))
        
        if success {
            showSuccess = true
        } else {
            errorMessage = authService.lastError ?? "Failed to send reset email. Please try again."
            showError = true
        }
    }
    
    // MARK: - Validation
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(SupabaseAuthService())
}
