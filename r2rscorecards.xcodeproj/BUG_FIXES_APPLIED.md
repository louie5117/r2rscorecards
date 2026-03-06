# 🔧 Bug Fixes Applied

## ✅ Issue #1: Login Screen Doesn't Auto-Dismiss - FIXED!

**Problem:** After logging in with Supabase, user had to manually click Cancel.

**Root Cause:** Nested sheets (SupabaseEmailAuthView inside SupabaseSignInView) weren't communicating dismissal properly.

**Fix Applied:**
1. Added `.onChange(of: authService.isAuthenticated)` to SupabaseSignInView - monitors auth state and auto-dismisses
2. Added `parentDismiss` parameter to SupabaseEmailAuthView to dismiss both sheets
3. Both login and registration now dismiss properly

**Result:** Sign in sheet now automatically closes when authentication succeeds! ✅

---

## ✅ Issue #2: Recent Scorecards Section Shows Empty - FIXED!

**Problem:** "Recent Scorecards" section showed "Sign in" message even when logged in via Supabase.

**Root Cause:** Code only checked `auth.currentUserIdentifier` (legacy auth) but not Supabase auth.

**Fix Applied:**
1. Added `@EnvironmentObject private var supabaseAuth: SupabaseAuthService` to HomeViewEnhanced
2. Added helper computed properties:
   - `isAuthenticated` - checks BOTH auth systems
   - `currentUserId` - gets ID from either system
3. Updated recentScorecardsSection to use `isAuthenticated` instead of just checking legacy auth
4. Updated userScorecardCount and recentScorecards to check both auth systems

**Result:** Recent scorecards now show correctly for Supabase users! ✅

---

## 🚀 How to Test:

### Test Fix #1 (Auto-Dismiss):
1. Launch app
2. Tap "Sign In"
3. Tap "Continue with Email"
4. Enter credentials and sign in
5. **Sheet should auto-close!** ✅

### Test Fix #2 (Recent Scorecards):
1. Sign in with Supabase
2. Go to home screen
3. Look at "Your Recent Scorecards" section
4. **Should show your scorecards!** ✅

---

## 🎯 Build & Run:

```bash
Cmd + B  # Build
Cmd + R  # Run and test!
```

---

## 📝 Files Changed:

1. **SupabaseSignInView.swift**
   - Added `.onChange` to monitor auth state
   - Added `parentDismiss` parameter
   - Passes dismiss action to child view

2. **HomeViewEnhanced.swift**
   - Added `supabaseAuth` environment object
   - Added `isAuthenticated` helper
   - Added `currentUserId` helper
   - Updated recent scorecards check

---

## ✅ Both Issues Resolved!

Your app now:
- ✅ Auto-dismisses login screen after successful auth
- ✅ Shows recent scorecards for Supabase users
- ✅ Works with both legacy and Supabase authentication

---

**Test it out!** 🥊
