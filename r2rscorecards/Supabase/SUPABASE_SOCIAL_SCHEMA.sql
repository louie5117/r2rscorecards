-- Friend Requests and Friendships Schema
-- Add these tables to your Supabase database

-- Friend Requests Table
CREATE TABLE IF NOT EXISTS friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    group_id UUID REFERENCES friend_groups(id) ON DELETE SET NULL,
    message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    
    -- Prevent duplicate requests
    UNIQUE(from_user_id, to_user_id, status),
    
    -- Prevent self-requests
    CONSTRAINT no_self_request CHECK (from_user_id != to_user_id)
);

-- Friendships Table (bidirectional relationships)
CREATE TABLE IF NOT EXISTS friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Each friendship should be unique
    UNIQUE(user_id, friend_id),
    
    -- Prevent self-friendship
    CONSTRAINT no_self_friendship CHECK (user_id != friend_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_friend_requests_to_user ON friend_requests(to_user_id, status);
CREATE INDEX IF NOT EXISTS idx_friend_requests_from_user ON friend_requests(from_user_id, status);
CREATE INDEX IF NOT EXISTS idx_friendships_user ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend ON friendships(friend_id);

-- Row Level Security (RLS) Policies

-- Enable RLS
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Friend Requests Policies

-- Users can view requests they sent or received
CREATE POLICY "Users can view their own requests"
ON friend_requests FOR SELECT
USING (
    auth.uid() = from_user_id OR 
    auth.uid() = to_user_id
);

-- Users can send requests to anyone
CREATE POLICY "Users can send friend requests"
ON friend_requests FOR INSERT
WITH CHECK (auth.uid() = from_user_id);

-- Users can update requests they received (accept/reject)
CREATE POLICY "Users can respond to received requests"
ON friend_requests FOR UPDATE
USING (auth.uid() = to_user_id)
WITH CHECK (auth.uid() = to_user_id);

-- Users can delete requests they sent
CREATE POLICY "Users can delete sent requests"
ON friend_requests FOR DELETE
USING (auth.uid() = from_user_id);

-- Friendships Policies

-- Users can view their own friendships
CREATE POLICY "Users can view their friendships"
ON friendships FOR SELECT
USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can create friendships (via accepted requests)
CREATE POLICY "Users can create friendships"
ON friendships FOR INSERT
WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can delete their own friendships
CREATE POLICY "Users can delete their friendships"
ON friendships FOR DELETE
USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Function to automatically create bidirectional friendship
CREATE OR REPLACE FUNCTION create_bidirectional_friendship()
RETURNS TRIGGER AS $$
BEGIN
    -- When a friendship is created, also create the reverse
    -- But only if it doesn't already exist
    IF NOT EXISTS (
        SELECT 1 FROM friendships 
        WHERE user_id = NEW.friend_id AND friend_id = NEW.user_id
    ) THEN
        INSERT INTO friendships (user_id, friend_id, created_at)
        VALUES (NEW.friend_id, NEW.user_id, NEW.created_at);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create bidirectional friendships
DROP TRIGGER IF EXISTS ensure_bidirectional_friendship ON friendships;
CREATE TRIGGER ensure_bidirectional_friendship
AFTER INSERT ON friendships
FOR EACH ROW
EXECUTE FUNCTION create_bidirectional_friendship();

-- Function to clean up friendships when one is deleted
CREATE OR REPLACE FUNCTION delete_bidirectional_friendship()
RETURNS TRIGGER AS $$
BEGIN
    -- When a friendship is deleted, also delete the reverse
    DELETE FROM friendships
    WHERE user_id = OLD.friend_id AND friend_id = OLD.user_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to delete bidirectional friendships
DROP TRIGGER IF EXISTS cleanup_bidirectional_friendship ON friendships;
CREATE TRIGGER cleanup_bidirectional_friendship
BEFORE DELETE ON friendships
FOR EACH ROW
EXECUTE FUNCTION delete_bidirectional_friendship();

-- Notification Function (optional - for push notifications)
CREATE OR REPLACE FUNCTION notify_friend_request()
RETURNS TRIGGER AS $$
BEGIN
    -- You can integrate with your notification system here
    -- For now, this is a placeholder for future implementation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for friend request notifications
DROP TRIGGER IF EXISTS friend_request_notification ON friend_requests;
CREATE TRIGGER friend_request_notification
AFTER INSERT ON friend_requests
FOR EACH ROW
EXECUTE FUNCTION notify_friend_request();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON friend_requests TO authenticated;
GRANT SELECT, INSERT, DELETE ON friendships TO authenticated;
GRANT USAGE ON SEQUENCE friend_requests_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE friendships_id_seq TO authenticated;

-- Comments
COMMENT ON TABLE friend_requests IS 'Friend requests between users';
COMMENT ON TABLE friendships IS 'Established friendships (bidirectional)';
COMMENT ON COLUMN friend_requests.group_id IS 'Optional: if request is for a specific group invite';
COMMENT ON COLUMN friend_requests.message IS 'Optional personal message with the request';
