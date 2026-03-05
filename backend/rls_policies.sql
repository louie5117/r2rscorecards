-- R2R Scorecards - Row Level Security Policies
-- Apply AFTER running schema.sql.
-- These policies enforce data access rules at the database level,
-- so they apply equally to iOS, web, and Android clients.

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================

ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fights        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scorecards    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.round_scores  ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- PROFILES
-- Users can read all profiles (for group member display).
-- Users can only update their own profile.
-- ============================================================

CREATE POLICY "profiles_read_all"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());


-- ============================================================
-- FIGHTS
-- All authenticated users can read fights.
-- Only admins can insert/update/delete fights.
-- (Admin = any user for MVP; tighten with a role column later.)
-- ============================================================

CREATE POLICY "fights_read_all"
    ON public.fights FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "fights_insert_authenticated"
    ON public.fights FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "fights_update_creator"
    ON public.fights FOR UPDATE
    USING (created_by = auth.uid());

CREATE POLICY "fights_delete_creator"
    ON public.fights FOR DELETE
    USING (created_by = auth.uid());


-- ============================================================
-- FRIEND GROUPS
-- All authenticated users can read groups (needed to join via invite code).
-- Any authenticated user can create a group.
-- Only the creator can update or delete their group.
-- ============================================================

CREATE POLICY "friend_groups_read_all"
    ON public.friend_groups FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "friend_groups_insert_authenticated"
    ON public.friend_groups FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND created_by = auth.uid());

CREATE POLICY "friend_groups_update_creator"
    ON public.friend_groups FOR UPDATE
    USING (created_by = auth.uid());

CREATE POLICY "friend_groups_delete_creator"
    ON public.friend_groups FOR DELETE
    USING (created_by = auth.uid());


-- ============================================================
-- GROUP MEMBERS
-- Users can see members of any group they belong to.
-- Users can add themselves to a group (joining via invite code).
-- Users can remove themselves from a group.
-- Group creators can remove any member.
-- ============================================================

CREATE POLICY "group_members_read_if_member"
    ON public.group_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.group_members gm
            WHERE gm.group_id = group_members.group_id
              AND gm.user_id = auth.uid()
        )
    );

CREATE POLICY "group_members_insert_self"
    ON public.group_members FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "group_members_delete_self_or_creator"
    ON public.group_members FOR DELETE
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.friend_groups fg
            WHERE fg.id = group_members.group_id
              AND fg.created_by = auth.uid()
        )
    );


-- ============================================================
-- SCORECARDS
-- Users can read their own scorecards.
-- Users can read scorecards of group members in shared groups.
-- Users can create, update (draft only), and delete their own scorecards.
-- A submitted scorecard cannot be updated (enforced via check).
-- ============================================================

CREATE POLICY "scorecards_read_own"
    ON public.scorecards FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "scorecards_read_group_members"
    ON public.scorecards FOR SELECT
    USING (
        group_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM public.group_members gm
            WHERE gm.group_id = scorecards.group_id
              AND gm.user_id = auth.uid()
        )
    );

CREATE POLICY "scorecards_insert_own"
    ON public.scorecards FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can only update draft scorecards (submitted_at IS NULL).
CREATE POLICY "scorecards_update_own_draft"
    ON public.scorecards FOR UPDATE
    USING (user_id = auth.uid() AND submitted_at IS NULL);

CREATE POLICY "scorecards_delete_own"
    ON public.scorecards FOR DELETE
    USING (user_id = auth.uid());


-- ============================================================
-- ROUND SCORES
-- Readable if you can read the parent scorecard.
-- Writable only by the scorecard owner, only while draft.
-- ============================================================

CREATE POLICY "round_scores_read_own"
    ON public.round_scores FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.scorecards sc
            WHERE sc.id = round_scores.scorecard_id
              AND sc.user_id = auth.uid()
        )
    );

CREATE POLICY "round_scores_read_group"
    ON public.round_scores FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.scorecards sc
            JOIN public.group_members gm ON gm.group_id = sc.group_id
            WHERE sc.id = round_scores.scorecard_id
              AND gm.user_id = auth.uid()
        )
    );

CREATE POLICY "round_scores_insert_draft_owner"
    ON public.round_scores FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.scorecards sc
            WHERE sc.id = round_scores.scorecard_id
              AND sc.user_id = auth.uid()
              AND sc.submitted_at IS NULL
        )
    );

CREATE POLICY "round_scores_update_draft_owner"
    ON public.round_scores FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.scorecards sc
            WHERE sc.id = round_scores.scorecard_id
              AND sc.user_id = auth.uid()
              AND sc.submitted_at IS NULL
        )
    );

CREATE POLICY "round_scores_delete_draft_owner"
    ON public.round_scores FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.scorecards sc
            WHERE sc.id = round_scores.scorecard_id
              AND sc.user_id = auth.uid()
              AND sc.submitted_at IS NULL
        )
    );
