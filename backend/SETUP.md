# Backend Setup Guide

Step-by-step instructions for wiring up the Supabase backend to the iOS app.

---

## Part 1 — Create the Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in (or create an account).
2. Click **New project**.
3. Fill in:
   - **Name:** r2rscorecards
   - **Database password:** choose a strong password and save it
   - **Region:** pick the region closest to your users (e.g. EU West for UK)
4. Wait ~2 minutes for the project to be provisioned.

---

## Part 2 — Run the SQL Files

Open the **SQL Editor** in the Supabase dashboard (left sidebar → SQL Editor).

Run the files **in this exact order** — each one depends on the previous:

### Step 1 — Core Schema
Copy and paste `backend/schema.sql`, then click **Run**.

This creates:
- `profiles`, `fights`, `friend_groups`, `group_members`, `scorecards`, `round_scores` tables
- Triggers for `updated_at` and auto-profile creation on sign-up
- The `generate_invite_code()` function

### Step 2 — Row Level Security
Copy and paste `backend/rls_policies.sql`, then click **Run**.

This enables RLS on all tables and defines who can read and write each row.

### Step 3 — Analytics Views
Copy and paste `backend/analytics_views.sql`, then click **Run**.

This creates views for crowd stats, demographic breakdowns, and the live scoring feed.

---

## Part 3 — Get Your API Credentials

In the Supabase dashboard: **Project Settings → API**

Copy two values:
| Key | Where to find it |
|-----|-----------------|
| **Project URL** | "Project URL" — looks like `https://abcdefgh.supabase.co` |
| **Anon (public) key** | Under "Project API keys" → `anon public` |

The anon key is safe to ship in the app. All access is gated by the RLS policies you just ran.

Open `r2rscorecards/Supabase/SupabaseManager.swift` and replace the placeholders:

```swift
enum SupabaseConfig {
    static let url     = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    static let anonKey = "YOUR_ANON_KEY"
}
```

---

## Part 4 — Add the Supabase Swift SDK in Xcode

1. Open `r2rscorecards.xcodeproj` in Xcode.
2. **File → Add Package Dependencies…**
3. In the search bar, paste:
   ```
   https://github.com/supabase/supabase-swift
   ```
4. Set the version rule to **Up to Next Major** from `2.0.0`.
5. Click **Add Package**.
6. When prompted to choose products, select **Supabase** and add it to the `r2rscorecards` target.

---

## Part 5 — Add the New Swift Files to the Xcode Target

The files in `r2rscorecards/Supabase/` exist on disk but are not yet part of the Xcode target.

1. In Xcode's Project Navigator, right-click on the `r2rscorecards` group folder.
2. Choose **Add Files to "r2rscorecards"…**
3. Navigate to `r2rscorecards/Supabase/` and select all seven files:
   - `SupabaseManager.swift`
   - `SupabaseModels.swift`
   - `SupabaseAuthService.swift`
   - `FightService.swift`
   - `ScorecardService.swift`
   - `GroupService.swift`
   - `RealtimeService.swift`
4. Make sure **"Add to target: r2rscorecards"** is checked.
5. Click **Add**.

---

## Part 6 — Enable Apple Sign In in Supabase

1. In the Supabase dashboard: **Authentication → Providers → Apple**
2. Toggle Apple on.
3. Follow the [Supabase Apple OAuth guide](https://supabase.com/docs/guides/auth/social-login/auth-apple) to configure your Apple Services ID and private key.
   - You'll need an Apple Developer account.
   - Create a **Services ID** (for web redirect, even for native apps).
   - Create a **private key** with the Sign in with Apple capability.

---

## Part 7 — Wire Up SupabaseAuthService in the App

Replace the `AuthManager` environment object in `r2rscorecardsApp.swift` with `SupabaseAuthService`:

```swift
@StateObject private var authService = SupabaseAuthService()

// In the body:
RootView()
    .environmentObject(authService)
```

Update `SignInView` (and any other view that calls `AuthManager`) to call `authService.signInWithApple()` and `authService.signIn(email:password:)` instead.

---

## Part 8 — Build and Test

```
Product → Build  (⌘B)
```

If everything is configured correctly the project should compile without errors.

**Smoke test checklist:**
- [ ] App launches and `SupabaseAuthService.restoreSession()` runs without crashing
- [ ] Sign in with Apple completes and creates a `profiles` row (check Supabase Table Editor)
- [ ] `FightService.fetchUpcomingFights()` returns data (or empty array — not a crash)
- [ ] Creating a scorecard appears in the `scorecards` table
- [ ] Saving a round score appears in `round_scores`
- [ ] Submitting a scorecard sets `submitted_at` and the row becomes uneditable

---

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| Build error: `No such module 'Supabase'` | Package not added yet (Part 4) |
| Build error: `Cannot find type 'SBFight'` | Files not added to target (Part 5) |
| Auth error on Apple sign in | Apple provider not configured in Supabase (Part 6) |
| Empty fights list | SQL not run, or RLS blocking reads — check Supabase logs |
| `profiles` row missing after sign up | `on_auth_user_created` trigger didn't fire — re-run `schema.sql` |
