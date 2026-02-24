# 🔐 TODO: Password Reset / Forgot Password Feature

## Current Status
✅ Email/password authentication implemented  
✅ Account registration with demographics  
✅ Secure password hashing (SHA256)  
❌ **Password reset/recovery NOT YET IMPLEMENTED**

## What You Need to Add

### For Local/Testing (Simple Approach)
If you're just testing locally without a backend, you could add:

1. **Simple reset with security question** (not recommended for production)
2. **Admin override** (debug builds only)
3. **Manual password change** (requires knowing old password)

### For Production (Recommended Approach)
You'll need a backend service to handle email delivery. Options:

#### Option 1: Firebase Authentication
- ✅ Built-in email verification
- ✅ Built-in password reset emails
- ✅ Easy integration with iOS
- ✅ Free tier available

#### Option 2: Custom Backend + Email Service
- Use SendGrid, Mailgun, or AWS SES for emails
- Create API endpoints for:
  - `/forgot-password` - Generate reset token
  - `/reset-password` - Verify token and update password
  - `/verify-email` - Email verification on signup

#### Option 3: Supabase
- ✅ Built-in auth with email reset
- ✅ Real-time database
- ✅ Easy Swift integration
- ✅ Free tier available

## Implementation Steps (When Ready)

### 1. Add "Forgot Password" UI
```swift
// In EmailAuthView.swift - Login Form
Button("Forgot Password?") {
    showForgotPassword = true
}
.font(.caption)
.foregroundStyle(.blue)
```

### 2. Create ForgotPasswordView
```swift
struct ForgotPasswordView: View {
    @State private var email = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            Button("Send Reset Link") {
                // TODO: Send email with reset token
            }
        }
    }
}
```

### 3. Backend Requirements
- **Database table** to store reset tokens with expiration
- **Email service** to send reset links
- **API endpoint** to generate tokens
- **API endpoint** to verify tokens and update password

### 4. Reset Flow
1. User enters email address
2. System generates unique token (UUID)
3. Token stored in database with expiration (e.g., 1 hour)
4. Email sent with link: `yourapp://reset?token=ABC123`
5. User clicks link, app opens to reset screen
6. User enters new password
7. App validates token and updates password
8. Token is invalidated

## Quick Alternative: Password Change (Requires Current Password)

You can implement a "Change Password" feature that doesn't require email:

```swift
struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Verify current password, then update to new password
}
```

Add this to a Settings/Profile screen where users are already logged in.

## Security Considerations

### Current Implementation (Local Only)
- ⚠️ SHA256 for password hashing (better than plain text, but not ideal)
- ⚠️ No rate limiting on login attempts
- ⚠️ No account lockout after failed attempts
- ⚠️ No email verification

### Production Requirements
- ✅ Use bcrypt or Argon2 for password hashing
- ✅ Rate limit login attempts (e.g., max 5 per minute)
- ✅ Lock account after 10 failed attempts
- ✅ Require email verification before first login
- ✅ Use HTTPS for all communication
- ✅ Store sensitive data encrypted
- ✅ Implement 2FA (optional but recommended)

## Next Steps

**When you're ready to add password reset:**

1. **Choose your approach:**
   - Firebase (easiest, production-ready)
   - Custom backend (most flexible)
   - Just add "Change Password" (requires current password)

2. **Let me know which option you prefer**, and I'll help you implement it!

3. **For now**, users who forget passwords will need to:
   - Create a new account with different email
   - OR you can manually reset in the database (debug only)

## Files to Modify (When Implementing)

- `EmailAuthView.swift` - Add "Forgot Password" button
- Create `ForgotPasswordView.swift` - Password reset UI
- Create `PasswordResetService.swift` - Backend communication
- Update `User.swift` - Add reset token fields (if storing locally)
- Update `AuthManager.swift` - Add reset methods

---

**REMINDER**: This is currently NOT implemented. Users cannot reset forgotten passwords yet!
