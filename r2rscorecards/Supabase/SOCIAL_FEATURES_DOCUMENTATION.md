# Social Features: User Search & Friend Requests

## 🎉 Complete Social System Implementation

A comprehensive friend request and user search system has been added to your app!

## Features Added

### 1. **User Search** 
- Search for users by display name or email
- Real-time search results
- Send friend requests directly from search
- Optional personal message with requests

### 2. **Friend Requests**
- Send friend requests to other users
- Receive and manage incoming requests
- Accept or decline requests
- Cancel sent requests
- Optional message support

### 3. **Friends Management**
- View all your friends
- Remove friends
- Bidirectional relationships (both users are friends)
- Friend list with profiles

### 4. **Group Invites** (Future Ready)
- Infrastructure for group-specific invites
- Friend requests can be associated with a fight group
- Ready for notifications integration

## Files Created

### Services
1. **`UserSearchService.swift`** - User search functionality
   - Search by name or email
   - Get user by ID or email
   - Batch user fetching

2. **`FriendRequestService.swift`** - Friend request management
   - Send/cancel friend requests
   - Accept/reject requests
   - Friends list management
   - Bidirectional friendship handling

### Views
3. **`UserSearchView.swift`** - Search UI
   - Search bar with live results
   - User cards with avatars
   - "Add Friend" button
   - Message input for requests

4. **`FriendRequestsView.swift`** - Request management UI
   - Three tabs: Received, Sent, Friends
   - Accept/Decline buttons
   - Swipe to remove friends
   - Pull to refresh

### Models
5. **`SupabaseModels.swift`** - UPDATED
   - Added `SBFriendRequest`
   - Added `SBFriendRequestInsert`
   - Added `SBFriendRequestWithProfiles`
   - Added `SBFriendship`

### Database
6. **`SUPABASE_SOCIAL_SCHEMA.sql`** - Database schema
   - `friend_requests` table
   - `friendships` table
   - Indexes for performance
   - Row Level Security policies
   - Bidirectional friendship triggers

### UI Integration
7. **`SettingsView.swift`** - UPDATED
   - Added "Social" section
   - "Friend Requests & Friends" link
   - "Find Users" link

## Database Setup

### Step 1: Run the SQL Schema

In your Supabase dashboard:
1. Go to **SQL Editor**
2. Create a new query
3. Paste the contents of `SUPABASE_SOCIAL_SCHEMA.sql`
4. Run the query
5. Verify tables were created

### Step 2: Verify Tables

Check that these tables exist:
- ✅ `friend_requests`
- ✅ `friendships`

### Step 3: Test Policies

The RLS policies ensure:
- Users can only see their own requests
- Users can only respond to requests sent to them
- Users can only manage their own friendships
- Friendships are automatically bidirectional

## User Flows

### Flow 1: Send Friend Request

1. User taps Settings → "Find Users"
2. Types name or email in search
3. Sees matching users
4. Taps "Add Friend" icon
5. (Optional) Adds personal message
6. Taps "Send"
7. Request sent! ✅

### Flow 2: Receive & Accept Request

1. User opens app
2. Taps Settings → "Friend Requests & Friends"
3. Sees "Received" tab with pending requests
4. Reviews request and optional message
5. Taps "Accept"
6. Now friends! ✅

### Flow 3: View Friends List

1. User taps Settings → "Friend Requests & Friends"
2. Switches to "Friends" tab
3. Sees all friends with profiles
4. Can swipe to remove friends
5. Can search through friends list

### Flow 4: Cancel Sent Request

1. User taps Settings → "Friend Requests & Friends"
2. Switches to "Sent" tab
3. Sees pending sent requests
4. Taps "Cancel" on a request
5. Request removed ✅

## How to Use in Your App

### Access User Search
```swift
NavigationLink {
    UserSearchView()
} label: {
    Label("Find Users", systemImage: "magnifyingglass")
}
```

### Access Friend Requests
```swift
NavigationLink {
    FriendRequestsView()
} label: {
    Label("Friend Requests", systemImage: "person.2.fill")
}
```

### Send Request Programmatically
```swift
@StateObject private var friendService = FriendRequestService()

Task {
    try await friendService.sendFriendRequest(
        from: currentUserId,
        to: targetUserId,
        message: "Let's score fights together!"
    )
}
```

### Check if Friends
```swift
let areFriends = try await friendService.areFriends(
    userId: currentUserId,
    friendId: otherUserId
)
```

## Integration Points

### Already Integrated ✅
- Settings menu has "Social" section
- User search accessible
- Friend requests accessible
- All environment objects connected

### Ready for Future Integration

#### 1. Group Invites
```swift
// Send friend request for a specific group
try await friendService.sendFriendRequest(
    from: currentUserId,
    to: friendId,
    groupId: fightGroupId,  // 👈 Associate with group
    message: "Join my fight scoring group!"
)
```

#### 2. Push Notifications
The database trigger `notify_friend_request()` is ready for integration:
- APNs (Apple Push Notification service)
- Firebase Cloud Messaging
- Supabase Realtime subscriptions

#### 3. Activity Feed
Use the `friend_requests` table to show recent activity:
```swift
// Get recent friend activity
let recentActivity = try await supabase
    .from("friend_requests")
    .select()
    .order("created_at", ascending: false)
    .limit(10)
    .execute()
```

## Security Features

### Row Level Security (RLS)
✅ **Users can only:**
- View requests they sent or received
- Send requests from their own account
- Respond to requests sent to them
- Delete requests they sent
- Manage their own friendships

### Automatic Protections
✅ **Prevents:**
- Self-friend requests
- Duplicate requests
- Self-friendships
- Unauthorized access to others' data

### Bidirectional Friendships
✅ **Automatic:**
- When A accepts B's request, both become friends
- When A removes B, the friendship is removed for both
- Database triggers handle synchronization

## Testing

### Test User Search
1. Create multiple test accounts
2. Sign in with Account A
3. Go to Settings → Find Users
4. Search for Account B
5. Should appear in results

### Test Friend Requests
1. Send request from Account A to Account B
2. Sign out, sign in as Account B
3. Go to Settings → Friend Requests
4. See request from Account A
5. Accept it
6. Both should see each other in Friends tab

### Test Bidirectional Friendship
1. Sign in as Account A
2. View Friends list → See Account B
3. Sign in as Account B
4. View Friends list → See Account A
5. Remove friend as Account B
6. Sign back as Account A → B should be gone

## Future Enhancements

### Phase 1: Notifications (Next Step)
- [ ] Push notifications for friend requests
- [ ] In-app notification badge
- [ ] Notification center view

### Phase 2: Enhanced Social
- [ ] Friend suggestions based on mutual friends
- [ ] Block/unblock users
- [ ] Privacy settings (who can send requests)
- [ ] Friend groups/categories

### Phase 3: Group Integration
- [ ] Invite friends directly to scoring groups
- [ ] Share scorecards with friends
- [ ] Friend-only groups
- [ ] Group chat/comments

### Phase 4: Activity & Engagement
- [ ] Activity feed
- [ ] Friend leaderboards
- [ ] Compare scorecards with friends
- [ ] Friend fight recommendations

## Error Handling

The system handles common errors:
- ✅ Request already exists
- ✅ Already friends
- ✅ User not found
- ✅ Network errors
- ✅ Permission denied

Error messages are user-friendly and actionable.

## Performance

### Optimizations
- Indexed database queries
- Batch profile fetching
- Efficient search with ILIKE
- Limited result sets (50 users max)

### Caching
Consider adding:
- Friend list caching
- Search results caching
- Request count badge

## Privacy Considerations

### Current Settings
- Email is searchable (can be hidden in RLS)
- Display names are public
- User profiles are searchable

### Optional Enhancements
```sql
-- Hide email in search results
CREATE POLICY "Hide email in search"
ON profiles FOR SELECT
USING (
    auth.uid() = id OR  -- Own profile
    id IN (  -- Friends only
        SELECT friend_id FROM friendships WHERE user_id = auth.uid()
    )
);
```

## Status

🎉 **FULLY IMPLEMENTED AND READY TO USE!**

Users can now:
- ✅ Search for other users
- ✅ Send friend requests with messages
- ✅ Accept or decline requests
- ✅ View and manage friends
- ✅ Remove friends
- ✅ Cancel sent requests

---

**Next Step:** Run the SQL schema in Supabase, then test the features!

**Documentation Created:** March 5, 2026
**Status:** ✅ Complete - Ready for Production
