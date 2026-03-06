# Unit Test TODO Backlog

This document tracks unit test coverage work that is intentionally deferred for now.

## Current Status

- No unit test files are currently present.
- No dedicated unit test target is currently configured.
- This is a planning/backlog artifact only (no runnable tests yet).

## Framework Decision (Placeholder)

Choose one before implementation starts:

- Option A: Swift Testing (`import Testing`, `@Suite`, `@Test`)
- Option B: XCTest (`XCTestCase`)

Decision: `TBD`
Owner: `TBD`
Decision date: `TBD`

## Phased Roadmap

### Phase 1: Core Risk Coverage (Start Here)

Target modules:
- `SupabaseAuthService`
- `ScorecardService`
- `RealtimeService`
- `FriendRequestService`
- `GroupService`

Placeholder test files and sample test names:
- `SupabaseAuthServiceTests.swift`
  - `testRestoreSession_WhenSessionExists_SetsAuthenticatedState()`
  - `testSignOut_ClearsCurrentUserAndProfile()`
- `ScorecardServiceTests.swift`
  - `testUpsertRoundScore_WhenRoundExists_RefreshesCurrentRoundScores()`
  - `testSubmitScorecard_WhenCurrentScorecardMatches_RefreshesSubmittedState()`
- `RealtimeServiceTests.swift`
  - `testSubscribe_InitialLoad_PopulatesLiveScoresByUserAndRound()`
  - `testUnsubscribe_ClearsLiveScoresAndSubmittedUsers()`
- `FriendRequestServiceTests.swift`
  - `testSendFriendRequest_WhenPendingRequestExists_ThrowsRequestAlreadyExists()`
  - `testAcceptRequest_CreatesBidirectionalFriendships()`
- `GroupServiceTests.swift`
  - `testJoinGroup_WhenInviteCodeInvalid_ThrowsInvalidInviteCode()`
  - `testCreateGroup_AutoJoinsCreator()`

### Phase 2: Data and API Reliability

Target modules:
- `FightService`
- `BoxingAPIService`
- `BoxerIndexService`

Placeholder test files and sample test names:
- `FightServiceTests.swift`
  - `testImportFight_UsesApiSourceIdForIdempotentUpsert()`
  - `testFetchUpcomingFights_SortsByAscendingDate()`
- `BoxingAPIServiceTests.swift`
  - `testParseFightersFromTitle_WithVsSeparator_ReturnsTwoFighters()`
  - `testParseFightDate_WithMultipleFormats_ParsesCorrectly()`
- `BoxerIndexServiceTests.swift`
  - `testParseMethod_WhenResultContainsSplitDecision_ReturnsSD()`
  - `testFetchFightHistory_SortsMostRecentFirst()`

### Phase 3: Domain Rules and Model Invariants

Target modules:
- `BoxingRules`
- Core models (`Scorecard`, `RoundScore`, `Boxer`, `User`)

Placeholder test files and sample test names:
- `BoxingRulesTests.swift`
  - `testIsValidRoundScore_RejectsOutOfRangeScores()`
  - `testApplyDeduction_DoesNotDropBelowSix()`
- `DomainModelsTests.swift`
  - `testScorecardTotals_SumAllRoundScores()`
  - `testRoundScoreIsValidScore_UsesBoxingRulesValidation()`
  - `testBoxerKoPercentage_WhenWinsZero_ReturnsZero()`

## Suggested Placeholder Directory Layout

The following is the expected target layout when implementation begins:

- `r2rscorecardsTests/`
  - `Services/`
  - `Supabase/`
  - `Support/`
  - `Models/`

## Definition of Done for Initial Baseline

- Test framework choice is finalized and documented.
- Test target is created and builds successfully.
- At least one passing unit test file exists per Phase 1 module.
- Basic negative-path coverage exists for auth, score submission, and group join flows.
- CI includes a test run step for the unit test target.

## Out of Scope for This TODO

- Snapshot/UI tests
- End-to-end integration tests
- Performance benchmarks
