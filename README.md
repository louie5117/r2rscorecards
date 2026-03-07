# R2R Scorecards

[![Build iOS](https://github.com/louie5117/r2rscorecards/actions/workflows/build-ios.yml/badge.svg)](https://github.com/louie5117/r2rscorecards/actions/workflows/build-ios.yml)

[![Tests](https://github.com/louie5117/r2rscorecards/actions/workflows/build-ios.yml/badge.svg)](https://github.com/louie5117/r2rscorecards/actions/workflows/build-ios.yml)

iPhone app for scoring boxing rounds and aggregating scores—solo or in groups. Built with SwiftUI and SwiftData. Optional CloudKit sync; Supabase for auth and social features.

## Requirements

- Xcode 16+ (project format 77)
- iOS 18.0+
- Apple Developer account for iCloud/CloudKit (optional)

## Running the app

1. Clone the repo and open `r2rscorecards.xcodeproj` in Xcode.
2. Select the r2rscorecards scheme and a simulator or device.
3. Build and run (Cmd+R).

SPM will fetch Supabase and other dependencies on first build.

## Development

- **Local data:** In Debug, use **Developer > Reset Local Store** and **Developer > Seed Sample Data** from the Fight list view if the store gets out of sync after schema or code changes.
- **Schema:** SwiftData schema is still evolving. Resetting the local store is the usual approach during development; proper migrations can be added later for production.
- **CloudKit (optional):** In Signing & Capabilities, enable iCloud and CloudKit, and set the container to `iCloud.PSL.r2rscorecards`. If CloudKit isn’t set up, the app runs with local-only storage.
- **Docs:** See the `docs/` folder for setup guides, API notes, and troubleshooting.

## CI

The **Build iOS** workflow runs on push/PR to `main` or `master`: a **build** job compiles the app (macOS, Xcode 16.2, no signing), then a **test** job runs unit tests using that build. Both badges link to the same workflow run; the **Tests** badge reflects whether the test job passed. Check the Actions tab for details.
