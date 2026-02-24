# R2R Scorecards Developer Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Data Model](#data-model)
3. [Key Components](#key-components)
4. [Common Tasks](#common-tasks)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Tech Stack
- **SwiftUI** - UI framework
- **SwiftData** - Data persistence and modeling
- **CloudKit** - Cloud synchronization (with local fallback)
- **AuthenticationServices** - Sign in with Apple

### Project Structure
```
r2rscorecards/
├── Models/
│   ├── Fight.swift          # Fight event model
│   ├── User.swift           # User profile model
│   ├── Scorecard.swift      # Individual scoring record
│   ├── RoundScore.swift     # Individual round scores
│   └── FriendGroup.swift    # Group collaboration model
├── Views/
│   ├── RootView.swift       # Entry point, auth gate
│   ├── FightListView.swift  # Main fight list
│   ├── FightDetailView.swift # Fight details & management
│   ├── ScorecardView.swift  # Scorecard creation/editing
│   ├── SignInView.swift     # Authentication flow
│   └── UsersListView.swift  # User management
├── Managers/
│   └── AuthManager.swift    # Authentication logic
└── r2rscorecardsApp.swift   # App entry point
```

---

## Data Model

### Entity Relationships

```
Fight (1) ──→ (many) Scorecard
Fight (1) ──→ (many) RoundScore
Fight (1) ──→ (many) FriendGroup

User (1) ──→ (many) Scorecard
User (many) ←→ (many) FriendGroup

Scorecard (1) ──→ (many) RoundScore
Scorecard (many) ──→ (1) FriendGroup

FriendGroup (1) ──→ (1) Fight
```

### Key Model Properties

#### Fight
- `scheduledRounds`: Number of rounds (1-15)
- `statusRaw`: "upcoming" | "inProgress" | "complete"
- Computed: crowd averages, demographic breakdowns

#### Scorecard
- `totalRed` / `totalBlue`: **Computed** from round scores
- `submittedAt`: `nil` = draft, `Date` = locked
- Always computes totals from rounds (no stored totals)

#### User
- `authUserID`: Apple Sign In identifier (app-scoped)
- `region`, `gender`, `ageGroup`: Optional demographics
- Used for crowd analytics

#### FriendGroup
- `inviteCode`: Unique 6-char code for joining
- `members`: Users in this group
- Tied to a specific `Fight`

---

## Key Components

### AuthManager
**Purpose:** Handles Sign in with Apple integration

**Key Methods:**
- `startSignIn()` - Initiates auth flow (async/await)
- `signOut()` - Clears user state
- Uses `CheckedContinuation` for async bridging

**Usage Example:**
```swift
do {
    let (userID, displayName) = try await auth.startSignIn()
    // Handle successful sign-in
} catch {
    // Show error to user
}
```

### SyncStatus
**Purpose:** Tracks CloudKit sync state

**States:**
- `.cloudKit` - Successfully syncing
- `.localFallback` - CloudKit unavailable, local only
- `.inMemoryRecovery` - Emergency mode (data not persisted)

### Persistence Setup
**Location:** `r2rscorecardsApp.makeModelContainer()`

**Logic:**
1. Try CloudKit (device) or local (simulator)
2. Fallback to in-memory if all else fails
3. Log all attempts with `os.Logger`

---

## Common Tasks

### Adding a New Model Property

1. **Add property to model:**
```swift
@Model
final class Fight {
    var newProperty: String = ""
    // ...
}
```

2. **Update schema array in app:**
```swift
let schema = Schema([
    Fight.self,
    // ... other models
])
```

3. **Reset data store in DEBUG:**
   - Run app → Developer → Reset Local Store

### Creating a New View

1. **Create view file:**
```swift
import SwiftUI
import SwiftData

struct MyNewView: View {
    @Environment(\.modelContext) private var context
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        // Your UI
    }
}

#Preview {
    // Always include preview
    MyNewView()
        .modelContainer(for: Fight.self, inMemory: true)
}
```

2. **Add navigation:**
```swift
NavigationLink(destination: MyNewView()) {
    Text("Navigate")
}
```

### Adding Error Handling

**Pattern to follow:**
```swift
do {
    try context.save()
} catch {
    errorMessage = "Failed to save: \(error.localizedDescription)"
    showError = true
}
```

**In view body:**
```swift
.alert("Error", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage)
}
```

### Working with Computed Properties

**✅ DO:**
```swift
var totalRed: Int {
    rounds.reduce(0) { $0 + $1.redScore }
}
```

**❌ DON'T:**
```swift
var totalRed: Int = 0  // Stored - can become stale!

func updateTotal() {
    totalRed = rounds.reduce(0) { $0 + $1.redScore }
}
```

### Adding Demographics Filtering

**Example from FightDetailView:**
```swift
func demographicAverages() -> [String: (red: Int, blue: Int, count: Int)] {
    let cards = fight.scorecards
    var buckets: [String: (sumR: Int, sumB: Int, n: Int)] = [:]
    
    for card in cards {
        guard let user = card.user else { continue }
        let key = user.region // or gender, ageGroup
        var bucket = buckets[key] ?? (0, 0, 0)
        bucket.sumR += card.totalRed
        bucket.sumB += card.totalBlue
        bucket.n += 1
        buckets[key] = bucket
    }
    
    // Convert to averages
    return buckets.mapValues { v in
        (
            red: Int(round(Double(v.sumR) / Double(v.n))),
            blue: Int(round(Double(v.sumB) / Double(v.n))),
            count: v.n
        )
    }
}
```

---

## Testing

### Unit Testing with Swift Testing

**Example test:**
```swift
import Testing
import SwiftData
@testable import r2rscorecards

@Suite("Scorecard Tests")
struct ScorecardTests {
    
    @Test("Totals compute correctly")
    func computeTotals() async throws {
        let container = try ModelContainer(
            for: Scorecard.self, RoundScore.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        
        let scorecard = Scorecard(title: "Test")
        context.insert(scorecard)
        
        let round1 = RoundScore(round: 1, redScore: 10, blueScore: 9, scorecard: scorecard)
        let round2 = RoundScore(round: 2, redScore: 9, blueScore: 10, scorecard: scorecard)
        context.insert(round1)
        context.insert(round2)
        scorecard.rounds = [round1, round2]
        
        #expect(scorecard.totalRed == 19)
        #expect(scorecard.totalBlue == 19)
    }
}
```

### Manual Testing Checklist

**Authentication Flow:**
- [ ] Sign in with Apple works
- [ ] Error shown if sign-in fails
- [ ] User profile created/loaded correctly
- [ ] Demographics prompt appears
- [ ] Sign out works correctly

**Fight Management:**
- [ ] Can create new fight
- [ ] Can edit fight details
- [ ] Status updates correctly
- [ ] Fights sorted by date

**Scorecard Flow:**
- [ ] Can create scorecard (requires sign-in)
- [ ] Can enter round scores (0-10 range)
- [ ] Totals update in real-time
- [ ] Cannot submit incomplete scorecard
- [ ] Submitted scorecard becomes read-only
- [ ] Can view submitted scorecard

**Friend Groups:**
- [ ] Can create group
- [ ] Invite code is generated
- [ ] Can join group by code
- [ ] Error shown for invalid code
- [ ] Group members shown correctly

**Analytics:**
- [ ] Crowd averages compute correctly
- [ ] Demographics filtering works
- [ ] Per-round averages accurate
- [ ] Submitted vs draft distinction

**CloudKit Sync:**
- [ ] Data appears on second device
- [ ] Conflicts resolve reasonably
- [ ] Offline mode works (local storage)
- [ ] Sync status shown correctly

---

## Troubleshooting

### "Schema mismatch" or "Cannot load data"

**Cause:** Model changes require migration

**Fix (Development):**
1. Run app in DEBUG mode
2. Developer → Reset Local Store
3. Developer → Seed Sample Data (optional)

**Fix (Production):**
- Implement SwiftData migration strategy
- See Apple docs on `VersionedSchema`

### CloudKit not working

**Check:**
1. Signing & Capabilities → iCloud enabled
2. CloudKit container `iCloud.PSL.r2rscorecards` selected
3. Logged into iCloud on device
4. Network connection available
5. Check `SyncStatus` display in app

**Simulator Note:**
- Simulator uses local storage by design
- Test CloudKit on real device

### Sign in with Apple fails

**Check:**
1. Capabilities → Sign in with Apple enabled
2. Correct bundle ID in Developer Portal
3. Simulator/device logged into Apple ID
4. Not in Private Relay blocking state

**Common Error:**
- "Invalid_client" = Bundle ID mismatch
- "Cancelled" = User cancelled (not an error)

### Computed properties showing 0

**Likely Cause:** Rounds not yet loaded

**Fix:**
```swift
// Make sure relationships are loaded
let _ = scorecard.rounds.count  // Force evaluation

// Or use explicit fetch
let descriptor = FetchDescriptor<RoundScore>(
    predicate: #Predicate { $0.scorecard?.id == scorecard.id }
)
let rounds = try? context.fetch(descriptor)
```

### Preview not working

**Check:**
1. Preview container uses `isStoredInMemoryOnly: true`
2. All required models in container schema
3. Sample data properly inserted
4. Environment objects provided

**Example:**
```swift
#Preview {
    let container = try! ModelContainer(
        for: Fight.self, User.self, Scorecard.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        MyView()
    }
    .modelContainer(container)
    .environmentObject(AuthManager())
}
```

### Xcode build errors after pulling changes

1. Clean Build Folder (Cmd+Shift+K)
2. Delete Derived Data
3. Restart Xcode
4. Check for missing files in project

---

## Best Practices

### ✅ DO

- Use `@Bindable` for direct model editing
- Use computed properties for derived data
- Always handle errors with user-facing alerts
- Provide previews for all views
- Document complex logic
- Test on real devices for CloudKit

### ❌ DON'T

- Store computed values (use computed properties)
- Use `print()` for error handling
- Forget to save context after changes
- Test CloudKit only in simulator
- Skip error handling
- Commit with TODO/FIXME comments

---

## Useful Resources

### Apple Documentation
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Best Practices](https://developer.apple.com/documentation/cloudkit)
- [Sign in with Apple](https://developer.apple.com/documentation/sign_in_with_apple)
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)

### Project-Specific
- `README.md` - Setup and deployment notes
- `CHANGES_APPLIED.md` - Recent improvements
- `AppErrors.swift` - Centralized error types

---

## Questions?

For project-specific questions:
1. Check this guide first
2. Review the inline documentation in model files
3. Look at similar implemented features
4. Check the preview code for examples

For Apple framework questions:
1. Check Apple's official documentation
2. Search for WWDC sessions
3. Look at sample code projects

---

**Last Updated:** February 23, 2026
**Xcode Version:** 16.0+
**iOS Deployment Target:** iOS 18.0+
