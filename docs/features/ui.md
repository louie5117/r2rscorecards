# UI

## Current UI direction

The app uses SwiftUI and is centered on a fight list -> fight detail -> scorecard flow, with optional enhanced onboarding, settings, and theming components.

## Key experience areas

- Core navigation and auth gating in `RootView`.
- Fight browsing and creation in `FightListView`.
- Round-by-round scoring in scorecard and round scoring views.
- Optional enhanced screens (`HomeViewEnhanced`, `SettingsViewEnhanced`, `OnboardingFlow`) layered on top of core flows.

## Theme and personalization

- Theme state is managed by `ThemeManager`.
- User preferences are persisted through app storage/state patterns used in enhanced settings and onboarding components.

## Design principles

- Keep scoring actions fast and obvious.
- Prioritize readability of round and total scores.
- Keep onboarding and settings additive (do not block core scoring workflows).

## Implementation anchors

- App root: `r2rscorecards/r2rscorecardsApp.swift`
- Core views: `r2rscorecards/Views/`
- Theme support: `r2rscorecards/Managers/ThemeManager.swift`

Detailed incremental implementation logs are archived under `docs/archive/ai-sessions/`.
