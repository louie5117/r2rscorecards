# 🌍 Global Statistics Roadmap

## Vision

Enable users to compare their scores with other users globally for the same fight, creating a community-driven boxing scoring platform.

## Current Status ✅

### Completed
1. **API Integration** - Using API-Sports Boxing via RapidAPI
2. **API Fight ID Tracking** - `Fight.apiSourceID` stores the external API ID
3. **Import System** - Users can import fights from API
4. **Duplicate Prevention** - Won't import same fight twice (checks by API ID)

### Data Model
```swift
@Model
final class Fight {
    var apiSourceID: String? // API-Sports fight ID
    // e.g., "12345" from API-Sports
    
    // When user imports from API, this is set
    // When user creates manually, this is nil
}
```

## Phase 1: Local Foundation (Current) ✅

- [x] Add `apiSourceID` to Fight model
- [x] Store API ID when importing fights
- [x] Prevent duplicate imports using API ID
- [x] API endpoints for upcoming/past fights

## Phase 2: Backend Infrastructure (Future)

To enable global statistics, you'll need a backend service:

### Backend Requirements

1. **Database** - Store aggregated scores
   - Firebase Firestore (easiest)
   - PostgreSQL + Backend API
   - Supabase (good middle ground)

2. **Data to Store**
   ```json
   {
     "fightID": "12345",
     "totalScorers": 1234,
     "averageScores": {
       "round1": {
         "fighter1": 9.2,
         "fighter2": 10.0
       },
       "round2": { ... }
     },
     "officialWinner": {
       "fighter1": 65,  // 65% scored fighter1 winner
       "fighter2": 30,  // 30% scored fighter2 winner
       "draw": 5        // 5% scored a draw
     },
     "popularityScore": 1234  // How many people scored it
   }
   ```

3. **API Endpoints Needed**
   - `POST /scores/submit` - Submit user's scorecard
   - `GET /scores/fight/:fightID` - Get global stats for a fight
   - `GET /scores/user/:userID` - Get user's scoring history
   - `GET /scores/leaderboard` - Most accurate scorers

### Backend Options

#### Option A: Firebase (Easiest)
**Pros:**
- Free tier is generous
- Real-time updates
- Easy Swift integration
- No server management

**Cons:**
- Vendor lock-in
- Costs scale with usage

**Setup:**
```swift
// Add Firebase to your app
import FirebaseFirestore

func submitScorecard(fight: Fight, scorecard: Scorecard) async {
    guard let apiID = fight.apiSourceID else { return }
    
    let db = Firestore.firestore()
    let fightRef = db.collection("fights").document(apiID)
    
    // Submit scores
    // Aggregate with existing data
}
```

#### Option B: Supabase (Recommended)
**Pros:**
- Open source
- PostgreSQL backend
- Real-time subscriptions
- Row-level security
- Free tier

**Cons:**
- Bit more setup than Firebase

**Setup:**
```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "YOUR_PROJECT_URL")!,
    supabaseKey: "YOUR_ANON_KEY"
)

func submitScorecard(fight: Fight, scorecard: Scorecard) async throws {
    guard let apiID = fight.apiSourceID else { return }
    
    try await client.database
        .from("scorecards")
        .insert([
            "fight_id": apiID,
            "user_id": auth.currentUserIdentifier,
            "rounds": scorecard.rounds
        ])
}
```

#### Option C: Custom Backend
**Pros:**
- Full control
- Can use any database
- No vendor lock-in

**Cons:**
- Most work
- Need to host/maintain
- Costs for hosting

## Phase 3: Global Statistics UI (Future)

### New Views to Add

1. **Global Stats View**
   ```swift
   struct GlobalStatsView: View {
       let fight: Fight
       @State private var globalStats: GlobalFightStats?
       
       var body: some View {
           // Show how your score compares
           // "You scored Fighter A to win"
           // "65% of users agree with you"
           // "Your score: 115-113"
           // "Average score: 116-112"
       }
   }
   ```

2. **Comparison View**
   ```swift
   struct ScoreComparisonView: View {
       let userScorecard: Scorecard
       let globalStats: GlobalFightStats
       
       var body: some View {
           // Round-by-round comparison
           // Your score vs average for each round
       }
   }
   ```

3. **Leaderboard View**
   ```swift
   struct ScorerLeaderboardView: View {
       @State private var topScorers: [UserStats]
       
       var body: some View {
           // Most accurate scorers
           // Most active scorers
           // Top rated in your region
       }
   }
   ```

### Features to Add

- [ ] "Compare with Community" button on scorecard
- [ ] Show % agreement on fight result
- [ ] Heat map of round-by-round scoring
- [ ] "You're more generous to Fighter A than average"
- [ ] Accuracy tracking (vs official judges)
- [ ] Regional comparisons
- [ ] Friend comparisons

## Phase 4: Advanced Features

### Social Features
- Share your scorecard on social media
- Challenge friends to score a fight
- Prediction pools before fights
- Live scoring parties (real-time sync)

### Gamification
- Accuracy badges
- Streak tracking
- Points for scoring fights
- Unlock features with points
- Seasonal leaderboards

### Analytics
- Your scoring tendencies
- Fighter bias detection
- Agreement rate with judges
- Close round analysis
- Favorite weight classes

## Implementation Roadmap

### Now (You Have This ✅)
- API integration
- Import fights
- Store API IDs
- Local scoring

### Next Steps (Recommended Order)

**Step 1: Set Up Backend (2-3 days)**
- Choose backend (recommend Supabase)
- Set up project
- Create database tables
- Test connection from app

**Step 2: Submit Scores (1 day)**
- Add "Submit to Community" button
- Send scorecard data to backend
- Handle errors gracefully
- Add privacy controls

**Step 3: Fetch Global Stats (1 day)**
- Create API endpoint for fight stats
- Add GlobalStats model
- Display basic stats in UI
- Cache results locally

**Step 4: Comparison UI (2-3 days)**
- Design comparison view
- Show round-by-round differences
- Add charts/graphs
- Polish UI/UX

**Step 5: Advanced Features (ongoing)**
- Leaderboards
- Accuracy tracking
- Social features
- Gamification

## Database Schema (Supabase/PostgreSQL)

```sql
-- Scorecards submitted by users
CREATE TABLE scorecards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    fight_id TEXT NOT NULL,  -- API-Sports fight ID
    submitted_at TIMESTAMP DEFAULT NOW(),
    winner TEXT,  -- 'fighter1', 'fighter2', 'draw'
    total_score_f1 INTEGER,
    total_score_f2 INTEGER,
    rounds JSONB  -- Array of round scores
);

-- Aggregated statistics per fight
CREATE TABLE fight_stats (
    fight_id TEXT PRIMARY KEY,
    total_scorers INTEGER DEFAULT 0,
    avg_score_f1 DECIMAL,
    avg_score_f2 DECIMAL,
    winner_votes JSONB,  -- {fighter1: 65, fighter2: 30, draw: 5}
    round_averages JSONB,  -- Per-round averages
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User statistics
CREATE TABLE user_stats (
    user_id TEXT PRIMARY KEY,
    total_fights_scored INTEGER DEFAULT 0,
    accuracy_rate DECIMAL,  -- % agreement with judges
    favorite_weight_class TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_scorecards_fight ON scorecards(fight_id);
CREATE INDEX idx_scorecards_user ON scorecards(user_id);
```

## Privacy Considerations

### User Options
- [ ] Opt-in to global statistics (default: on)
- [ ] Anonymous mode (don't show username)
- [ ] Private fights (don't submit to global)
- [ ] Delete my data option

### Data Protection
- Don't store personal info beyond user ID
- Allow users to delete submissions
- Clear data retention policy
- GDPR/privacy law compliance

## Cost Estimates

### Free Tier (Supabase)
- 500MB database
- 2GB file storage
- 50,000 monthly active users
- **Cost: $0/month**

### Paid (When You Grow)
- Unlimited database
- 100GB file storage
- Unlimited users
- **Cost: $25/month**

### RapidAPI (API-Sports)
- Free: 100 requests/day
- Basic: 500 requests/day ($10/month)
- Pro: Unlimited ($50/month)

## Testing Strategy

### Phase 1 Testing (Local Only)
- ✅ Import fights from API
- ✅ Create scorecards
- ✅ Verify API ID is stored
- ✅ Mock data works

### Phase 2 Testing (Backend)
- Submit test scorecards
- Verify aggregation math
- Test concurrent submissions
- Load testing with fake data

### Phase 3 Testing (UI)
- Beta test with friends
- Gather feedback
- A/B test different UI designs
- Monitor user engagement

## Success Metrics

### Launch Goals
- 100 active users
- 500 fights scored
- 10% of users enable global stats
- < 2 second load time for stats

### Growth Goals
- 1,000 active users
- 5,000 fights scored
- Trending on App Store in Sports category
- Partnership with boxing media

## Next Immediate Steps

1. **Try the current API integration** ✅
   - Run the app
   - Tap "Import Fights"
   - See if API-Sports works
   - Check console logs

2. **If API works:**
   - Document which fights appear
   - Test importing a fight
   - Verify API ID is saved
   - Create a scorecard

3. **If API fails:**
   - Use mock data for now
   - Focus on app features
   - Add real API later

4. **When ready for backend:**
   - Come back to this doc
   - Choose backend platform
   - Follow Step 1 in roadmap

---

**You have a great vision! Let's get the API working first, then we can build the global statistics feature.** 🥊📊

Want to try the app now and see if the API-Sports integration works?
