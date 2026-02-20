# R2R Scorecards MVP Checklist

## Product Flow
- [x] Auth gate at launch (`RootView`)
- [x] Fight list and fight detail navigation
- [x] Group join/create in fight detail
- [x] Start/continue scorecard scoped to signed-in user + selected group
- [x] Round-by-round scoring UI
- [x] Submit scorecard and lock edits

## Data Model
- [x] `User` includes auth user id mapping (`authUserID`)
- [x] `Fight` has `friendGroups`
- [x] `FriendGroup` has `inviteCode`, `fight`, `members`
- [x] `Scorecard` has `group` and `submittedAt`
- [x] App schema includes all models (`Fight`, `User`, `FriendGroup`, `Scorecard`, `RoundScore`)

## What To Build Next
- [ ] Replace local-only auth mapping with backend identity sync
- [ ] Add proper invite link/share flow (not just manual code entry)
- [ ] Add fight-level permissions (who can join/submit)
- [ ] Add “My Scorecards” and “Group Results” screens
- [ ] Add conflict handling for concurrent edits
- [ ] Add tests for scoring totals and submission lock behavior
- [ ] Add TestFlight-ready error logging and analytics
