# Boxing API

## Current behavior

The app supports importing fight cards from an external boxing feed through `BoxingAPIService` and `ImportFightsView`.

- Import is user-initiated from the fights screen.
- Imported fights are converted into local `Fight` records.
- Error states are surfaced in UI and mock/debug fallbacks are supported for development workflows.

## Scope

- Focus is upcoming and recently relevant boxing events.
- Imported fields include event title, date, venue/location (when available), and default rounds.
- API payload is normalized into existing app models so scoring flows remain unchanged.

## Reliability approach

- Treat the external API as non-authoritative.
- Keep manual fight creation as a first-class path.
- Keep import optional and resilient to upstream failures.

## Implementation anchors

- Service: `r2rscorecards/Services/BoxingAPIService.swift`
- Boxer index service: `r2rscorecards/Services/BoxerIndexService.swift`
- Import UI: `r2rscorecards/Views/ImportFightsView.swift`
- Fight list entry point: `r2rscorecards/Views/FightListView.swift`

## Endpoint contract

- Swagger/OpenAPI source of truth: `docs/architecture/api-openapi.yaml`
- This repository currently consumes external APIs (RapidAPI Boxing Data, TheSportsDB, and Supabase endpoints via SDK) and does not expose app-owned backend routes.

## Notes

Historical API migration/session logs are retained in `docs/archive/ai-sessions/` for audit history, but are not canonical.
