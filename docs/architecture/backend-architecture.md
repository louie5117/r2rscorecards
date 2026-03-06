# R2R Scorecards — Backend Architecture

## Overview

The backend is built on **Supabase**, an open-source Firebase alternative that provides:

- **PostgreSQL** — relational database with full SQL support
- **Supabase Auth** — centralized identity (email/password, Apple Sign In, Google)
- **Supabase Realtime** — WebSocket subscriptions on Postgres table changes
- **Auto-generated REST API** — works immediately for iOS, web, and Android
- **Row Level Security (RLS)** — access control enforced at the database level
- **Edge Functions** — Deno-based serverless functions for custom logic

---

## Why Supabase Over CloudKit

| Feature                          | CloudKit (current)   | Supabase             |
|----------------------------------|----------------------|----------------------|
| Cross-user queries / analytics   | ✗ Not possible       | ✓ Full SQL           |
| Android / web clients            | ✗ Apple only         | ✓ REST + WebSocket   |
| Demographic breakdowns           | ✗                    | ✓ via SQL views      |
| Real-time collaborative scoring  | Limited              | ✓ Realtime channels  |
| Custom server logic              | ✗                    | ✓ Edge Functions     |
| Open source / self-hostable      | ✗                    | ✓                    |

---

## File Structure

```
backend/
├── schema.sql                   # Core tables, indexes, triggers
├── rls_policies.sql             # Row Level Security policies
├── analytics_views.sql          # Pre-built views for analytics and realtime
├── boxing_index_migration.sql   # Boxer profiles, fight extensions, rankings
├── boxing_index_views.sql       # Computed stats, fight history, head-to-head views
└── ARCHITECTURE.md              # This document
```

Run files in this order when initializing a new Supabase project:
1. `schema.sql`
2. `rls_policies.sql`
3. `analytics_views.sql`
4. `boxing_index_migration.sql`
5. `boxing_index_views.sql`

---

## Data Model

```
auth.users (Supabase managed)
    │
    ▼
profiles            ← region, gender, age_group, display_name
    │
    ├──▶ scorecards ──▶ round_scores
    │        │
    │        └──▶ friend_groups ──▶ group_members (many-to-many with profiles)
    │
    └──▶ fights ◀── scorecards         ◀── boxers (red_boxer_id / blue_boxer_id)
                ◀── friend_groups      ◀── boxer_rankings


boxers              ← name, nationality, record (wins/losses/draws/kos), weight_class
    │
    ├──▶ fights (as red_boxer or blue_boxer)
    └──▶ boxer_rankings ← organization, weight_class, rank, as_of_date
```

### Boxing Index Tables (boxing_index_migration.sql)

| Table              | Purpose                                              |
|--------------------|------------------------------------------------------|
| `boxers`           | Fighter profiles, physical attributes, career record |
| `boxer_rankings`   | Snapshot rankings per org/weight class/date          |

### Extended Fights Columns

| Column             | Type                  | Notes                                |
|--------------------|-----------------------|--------------------------------------|
| `red_boxer_id`     | UUID → boxers         | Red corner fighter                   |
| `blue_boxer_id`    | UUID → boxers         | Blue corner fighter                  |
| `weight_class`     | weight_class enum     | Fight weight class                   |
| `belts_at_stake`   | TEXT[]                | e.g. `{'WBC','WBA'}`                 |
| `venue`            | TEXT                  | Arena name                           |
| `city` / `country` | TEXT                  | Location                             |
| `result`           | fight_result enum     | red_win/blue_win/draw/no_contest     |
| `method`           | fight_method enum     | KO/TKO/UD/SD/MD/RTD/DQ              |
| `method_round`     | INT                   | Round fight ended                    |
| `broadcast`        | TEXT[]                | e.g. `{'ESPN+','DAZN'}`              |

### Boxing Index Views (boxing_index_views.sql)

| View                       | Purpose                                              |
|----------------------------|------------------------------------------------------|
| `boxer_fight_history`      | All fights for any boxer with opponent details       |
| `boxer_computed_stats`     | Win/loss/KO record derived from fight outcomes       |
| `head_to_head`             | All fights between two specific boxers               |
| `upcoming_fights_detail`   | Upcoming feed with full boxer info                   |
| `current_rankings`         | Latest ranking snapshot per org/weight class         |

### Key Design Decisions

**`submitted_at` as the lock mechanism**
A scorecard with `submitted_at = NULL` is a draft — freely editable. Once `submitted_at` is set to a timestamp, the RLS policy blocks any further updates. This is enforced at the database level, not just the app.

**One scorecard per user per fight per group**
The unique constraint `(user_id, fight_id, group_id)` on `scorecards` prevents duplicate entries. A user can have one personal scorecard (group_id = NULL) and one scorecard per group they belong to.

**Invite codes generated server-side**
The `generate_invite_code()` function produces a collision-free 6-character code using a charset without ambiguous characters (no I/O/0/1). This replaces the device-generated codes in the current SwiftData implementation.

---

## Authentication

Supabase Auth handles identity. The `auth.users` table is managed by Supabase; the app-specific `profiles` table extends it via a `REFERENCES auth.users(id)` foreign key.

**Supported providers:**
- Email + password
- Sign in with Apple (via Supabase OAuth)
- Google (for web/Android)

**Auto-profile creation:**
The `on_auth_user_created` trigger automatically inserts a `profiles` row whenever a new `auth.users` entry is created, so no extra signup step is needed.

---

## Real-time Scoring

Supabase Realtime uses Postgres logical replication to stream row-level changes over WebSocket.

### Recommended Channels

**Live group scoring (during a fight):**
```
channel: fight-{fight_id}-group-{group_id}
table:   round_scores
filter:  fight_id=eq.{fight_id}
```
Subscribe when a user opens a group scorecard during a live fight. Each insert/update to `round_scores` is broadcast to all subscribers in the channel.

**Scorecard submission events:**
```
channel: fight-{fight_id}-submissions
table:   scorecards
filter:  fight_id=eq.{fight_id}
event:   UPDATE  (submitted_at changed from null → timestamp)
```
Notify group members when someone locks in their scorecard.

### iOS Integration (Supabase Swift SDK)

```swift
let channel = supabase.realtime.channel("fight-\(fightID)-group-\(groupID)")

channel.on(.postgresChanges(
    event: .all,
    schema: "public",
    table: "round_scores",
    filter: "fight_id=eq.\(fightID)"
)) { payload in
    // update local state with new round scores
}

await channel.subscribe()
```

---

## Analytics

Pre-built views in `analytics_views.sql` handle the demographic breakdown queries described in `GLOBAL_STATISTICS_ROADMAP.md`.

| View                           | Purpose                                              |
|--------------------------------|------------------------------------------------------|
| `submitted_round_scores`       | Base view: only locked scorecards, joined with profile|
| `fight_crowd_scores`           | Overall crowd totals per fight                       |
| `fight_crowd_scores_by_round`  | Per-round consensus across all scorecards            |
| `fight_demographic_scores`     | Region / gender / age breakdown per fight            |
| `group_leaderboard`            | Per-group member scoring activity                    |
| `live_group_round_scores`      | Real-time-friendly view for group scoring sessions   |

Example query — crowd score by region for a fight:
```sql
SELECT segment, avg_score_margin, scorecard_count
FROM fight_demographic_scores
WHERE fight_id = '{fight_id}'
  AND dimension = 'region'
ORDER BY scorecard_count DESC;
```

---

## Migration Plan (CloudKit → Supabase)

### Phase 1 — Auth + Fights (no user impact)
- Create Supabase project and run SQL files
- Migrate fight import to an Edge Function that polls TheSportsDB and writes to `fights`
- iOS app authenticates via Supabase Auth (keep Apple Sign In, add email)
- `profiles` row created automatically on first sign-in

### Phase 2 — Scorecards + Real-time
- iOS app writes scorecards and round_scores to Supabase instead of SwiftData
- Add Realtime subscription for live group scoring
- Friend group creation/joining uses `generate_invite_code()` server-side

### Phase 3 — Analytics + Drop CloudKit
- Expose `fight_crowd_scores` and `fight_demographic_scores` views in the app
- Remove CloudKit container reference from Xcode project
- Launch web dashboard reading from the same Supabase REST API

---

## Environment Variables

When integrating the Supabase Swift SDK, add these to your Xcode scheme or a local config file (never commit secrets):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>   # safe for client use; RLS enforces access
```

The `anon` key is intentionally public-safe — all actual access control is enforced by the RLS policies in `rls_policies.sql`.
