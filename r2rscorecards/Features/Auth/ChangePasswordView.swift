//
//  ChangePasswordView.swift
//  r2rscorecards
//
//  Allows authenticated users to change their password
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Change Password")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        if !newPassword.isEmpty && newPassword.count < 6 {
                            Label("Password must be at least 6 characters", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if !confirmPassword.isEmpty && newPassword != confirmPassword {
                            Label("Passwords don't match", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        
                        if isValidPassword {
                            Label("Password is valid", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await updatePassword()
                        }
                    } label: {
                        if authService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Update Password")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValidPassword || authService.isLoading)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been successfully updated.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValidPassword: Bool {
        newPassword.count >= 6 &&
        newPassword == confirmPassword &&
        !newPassword.isEmpty
    }
    
    // MARK: - Actions
    
    private func updatePassword() async {
        guard isValidPassword else { return }
        
        let success = await authService.updatePassword(newPassword: newPassword)
        
        if success {
            showSuccess = true
        } else {
            errorMessage = authService.lastError ?? "Failed to update password. Please try again."
            showError = true
        }
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(SupabaseAuthService())
}
