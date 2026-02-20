# R2R Scorecards

A SwiftUI + SwiftData app for creating fights, scoring rounds, and aggregating crowd scores. Supports demographic grouping by region, gender, and age group via a `User` model.

## Development notes

### Schema changes (SwiftData)
This project is under active development and the SwiftData schema evolves. Recent changes include adding a `User` model and a `user` relationship on `Scorecard` (while temporarily keeping `userId`). If you encounter issues running after pulling changes, reset the local SwiftData store.

### Resetting local data
In Debug builds, open the app and use:
- Developer > Reset Local Store
- Developer > Seed Sample Data

These options are available in the Fight list view. Reset clears all local objects. Seed creates a sample fight, two users, and scorecards with random round scores.

### Notes on migration
- During active development, it’s common to reset the local store instead of performing migrations.
- Once the schema stabilizes, we can remove `userId` from `Scorecard` and rely solely on the `User` relationship.
- For production, consider adopting SwiftData migration strategies before shipping.

## Cloud sync (SwiftData + CloudKit)

This app now prefers a CloudKit-backed SwiftData store and falls back to local-only storage if CloudKit setup is unavailable.

### Required Xcode/Apple Developer setup
- In Signing & Capabilities, ensure `iCloud` is enabled for the app target.
- Ensure `CloudKit` is enabled under iCloud services.
- Ensure the container `iCloud.PSL.r2rscorecards` exists in your Apple Developer account and is selected for the target.

### Behavior
- If CloudKit is configured correctly, data syncs across devices for the same Apple ID.
- If not configured, the app keeps working with local persistence only.
