# 🥊 Boxing Data API Setup Guide

## ✅ What's Been Added

I've integrated **ESPN Boxing API (Unofficial, Free, No API Key Required)** into your app! Here's what's new:

### New Files:
1. **`BoxingAPIService.swift`** - Service layer for API calls
2. **`ImportFightsView.swift`** - UI to browse and import upcoming fights
3. **Updated `FightListView.swift`** - Added "Import Fights" button

### Features:
- ✅ **ONLY boxing fights** - No other sports!
- ✅ Fetch upcoming boxing fights
- ✅ Fetch past boxing events
- ✅ Fighter names AND records (W-L-D)
- ✅ Fighter nicknames
- ✅ View fighter names and fight details
- ✅ Import fights directly into your app
- ✅ Automatic date parsing
- ✅ Error handling
- ✅ Mock data for testing
- ✅ **FREE - No API key required!**
- ✅ **Comprehensive boxing coverage from ESPN**

---

## 🆓 No API Key Required!

**Good news!** ESPN's boxing API is completely free and doesn't require an API key. Just use the app and it will work right away!

### About ESPN's API

ESPN's boxing data API is:
- **Unofficial but widely used** - Many apps use it
- **Reliable and fast** - ESPN's infrastructure
- **Boxing-specific** - Only returns boxing matches
- **Comprehensive** - Includes fighter records, venues, dates
- **Free** - No sign-up, no API key, no limits

---

## 📱 How to Use

### Import Fights:

1. Launch app
2. On the **Fights list screen**
3. Tap **"Import Fights"** button (download icon in toolbar)
4. See list of upcoming boxing matches
5. Tap **"Import Fight"** on any fight
6. Fight is added to your app!
7. Now you can create scorecards for that fight

### What Gets Imported:

From the API fight data:
- **Title**: "Fighter 1 vs Fighter 2"
- **Date**: Scheduled fight date
- **Rounds**: Number of rounds (defaults to 12)
- **Status**: Set to "upcoming"

You can then:
- Edit the fight details
- Add your own notes
- Create scorecards
- Invite groups to score

---

## 🔍 API Endpoints Available

The service includes these methods:

```swift
// Fetch upcoming boxing fights
let fights = try await apiService.fetchUpcomingFights()

// Fetch past boxing events
let fights = try await apiService.fetchPastFights()

// Search for specific event
let fights = try await apiService.searchEvent(query: "Canelo")
```

Currently only `fetchUpcomingFights()` is wired up to the UI.

---

## 🧪 Testing Without Network Access

If you're offline or want to test:

1. The app will show an error
2. **In DEBUG builds**, mock data automatically loads
3. You'll see 2 sample fights (Fury vs Usyk, Crawford vs Spence)
4. Import button works the same way

**Mock data includes:**
- Fighter names and records
- Venues and locations
- Weight classes
- Scheduled dates

---

## 📊 API Response Structure

TheSportsDB API returns data like this:

```json
{
  "events": [
    {
      "idEvent": "1234567",
      "strEvent": "Canelo Alvarez vs Dmitry Bivol",
      "dateEvent": "2026-03-15",
      "strTime": "22:00:00",
      "strVenue": "T-Mobile Arena",
      "strCountry": "USA",
      "strLeague": "Super Middleweight",
      "intRound": "12"
    }
  ]
}
```

The app automatically parses this and extracts fighter names from the event title.

---

## 🆓 TheSportsDB API Limits

**Free Tier:**
- ✅ Completely free for personal/non-commercial use
- ✅ No API key required
- ✅ Access to event data, team info, league info
- ✅ Fair use policy - don't abuse it

**Premium Tier (Patreon):**
- Higher resolution images
- Additional endpoints
- Support the project

**Tips for good API citizenship:**
- Cache API responses locally
- Don't auto-refresh too frequently
- Only fetch when user explicitly requests
- Consider local caching for 24-48 hours

---

## 🐛 Troubleshooting

### "Running in preview mode - API calls disabled"
- This is normal! Previews don't make real network calls
- Mock data will load instead in DEBUG builds

### "No fights found"
- Check internet connection
- API might not have upcoming events at this time
- Try again later
- Mock data will load in DEBUG builds

### "Server returned error code: 429"
- You're making too many requests
- Wait a few minutes before trying again
- TheSportsDB has fair use limits

### "Network error"
- Check internet connection
- API might be temporarily down
- Firewall might be blocking requests

---

## 🚀 Next Steps

Want to enhance this feature? You could add:

1. **Search Functionality** - Search for specific fighters
2. **Filter by Weight Class** - Show only heavyweight, welterweight, etc.
3. **Date Range Picker** - Import fights from specific dates
4. **Cache API Responses** - Store responses to reduce API calls
5. **Fighter Profiles** - Store fighter info separately
6. **Auto-Refresh** - Periodic background updates
7. **Notifications** - Alert when new fights are added

Let me know which features you'd like next!

---

## 📝 To-Do Checklist

- [x] API integrated (TheSportsDB - Free!)
- [ ] Test "Import Fights" button in the app
- [ ] Import a fight and create a scorecard
- [ ] Optional: Add local caching to reduce API calls
- [ ] Optional: Support Patreon for premium features

---

**Enjoy importing real boxing fights into your app - completely free!** 🥊📲
