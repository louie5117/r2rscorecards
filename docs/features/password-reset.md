# Password Reset

## Current behavior

Password recovery is implemented via Supabase Auth and includes:

- Forgot password flow for signed-out users.
- Change password flow for authenticated users.
- Integrated entry points from Supabase sign-in and settings flows.

## User flows

### Forgot password

1. User chooses email sign-in path.
2. User taps Forgot Password.
3. App sends reset request through Supabase.
4. User completes reset through emailed secure link.

### Change password

1. Authenticated user opens settings/account.
2. User enters and confirms new password.
3. App updates password via Supabase.

## Implementation anchors

- Auth service: `r2rscorecards/Supabase/SupabaseAuthService.swift`
- Forgot password view: `r2rscorecards/Supabase/ForgotPasswordView.swift`
- Change password view: `r2rscorecards/Supabase/ChangePasswordView.swift`
- Sign-in flow: `r2rscorecards/Supabase/SupabaseSignInView.swift`

## Security notes

- Reset tokens, expiry, and credential storage are managed by Supabase.
- App code should avoid local password handling outside provider-supported APIs.

Historical implementation logs are archived in `docs/archive/ai-sessions/`.
