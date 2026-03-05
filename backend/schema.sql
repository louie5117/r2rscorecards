-- R2R Scorecards - Supabase Schema
-- Run this in the Supabase SQL editor to initialize the database.

-- ============================================================
-- EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================================
-- PROFILES
-- Extends Supabase's auth.users with app-specific fields.
-- ============================================================

CREATE TABLE public.profiles (
    id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT       NOT NULL,
    email       TEXT,
    region      TEXT        NOT NULL DEFAULT 'unspecified',
    gender      TEXT        NOT NULL DEFAULT 'unspecified',  -- 'male' | 'female' | 'nonbinary' | 'unspecified'
    age_group   TEXT        NOT NULL DEFAULT 'unspecified',  -- '<18' | '18-24' | '25-34' | '35-44' | '45-54' | '55+' | 'unspecified'
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-create a profile row when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1), 'User'),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- FIGHTS
-- ============================================================

CREATE TABLE public.fights (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    title            TEXT        NOT NULL,
    date             TIMESTAMPTZ NOT NULL,
    scheduled_rounds INT         NOT NULL DEFAULT 12 CHECK (scheduled_rounds BETWEEN 1 AND 15),
    status           TEXT        NOT NULL DEFAULT 'upcoming', -- 'upcoming' | 'inProgress' | 'complete'
    api_source_id    TEXT,       -- TheSportsDB event ID for deduplication
    created_by       UUID        REFERENCES public.profiles(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER fights_updated_at
    BEFORE UPDATE ON public.fights
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_fights_status  ON public.fights(status);
CREATE INDEX idx_fights_date    ON public.fights(date DESC);
CREATE UNIQUE INDEX idx_fights_api_source ON public.fights(api_source_id) WHERE api_source_id IS NOT NULL;


-- ============================================================
-- FRIEND GROUPS
-- ============================================================

CREATE TABLE public.friend_groups (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT        NOT NULL,
    invite_code TEXT        NOT NULL UNIQUE,
    fight_id    UUID        NOT NULL REFERENCES public.fights(id) ON DELETE CASCADE,
    created_by  UUID        NOT NULL REFERENCES public.profiles(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_friend_groups_fight   ON public.friend_groups(fight_id);
CREATE INDEX idx_friend_groups_invite  ON public.friend_groups(invite_code);

-- Helper to generate a unique 6-character invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I/O/0/1 to avoid confusion
    i     INT;
BEGIN
    LOOP
        code := '';
        FOR i IN 1..6 LOOP
            code := code || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
        END LOOP;
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.friend_groups WHERE invite_code = code);
    END LOOP;
    RETURN code;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- GROUP MEMBERS (many-to-many: friend_groups <-> profiles)
-- ============================================================

CREATE TABLE public.group_members (
    group_id  UUID        NOT NULL REFERENCES public.friend_groups(id) ON DELETE CASCADE,
    user_id   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);

CREATE INDEX idx_group_members_user ON public.group_members(user_id);


-- ============================================================
-- SCORECARDS
-- submitted_at = NULL means the scorecard is still a draft.
-- Once submitted_at is set the scorecard is locked.
-- ============================================================

CREATE TABLE public.scorecards (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    title        TEXT        NOT NULL,
    user_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fight_id     UUID        NOT NULL REFERENCES public.fights(id) ON DELETE CASCADE,
    group_id     UUID        REFERENCES public.friend_groups(id) ON DELETE SET NULL,
    submitted_at TIMESTAMPTZ,             -- NULL = draft; timestamp = locked
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, fight_id, group_id)  -- one scorecard per user per fight per group
);

CREATE TRIGGER scorecards_updated_at
    BEFORE UPDATE ON public.scorecards
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_scorecards_fight ON public.scorecards(fight_id);
CREATE INDEX idx_scorecards_user  ON public.scorecards(user_id);
CREATE INDEX idx_scorecards_group ON public.scorecards(group_id);


-- ============================================================
-- ROUND SCORES
-- ============================================================

CREATE TABLE public.round_scores (
    id           UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
    scorecard_id UUID  NOT NULL REFERENCES public.scorecards(id) ON DELETE CASCADE,
    fight_id     UUID  NOT NULL REFERENCES public.fights(id) ON DELETE CASCADE,
    round        INT   NOT NULL CHECK (round BETWEEN 1 AND 15),
    red_score    INT   NOT NULL DEFAULT 0 CHECK (red_score BETWEEN 0 AND 10),
    blue_score   INT   NOT NULL DEFAULT 0 CHECK (blue_score BETWEEN 0 AND 10),
    scored_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scorecard_id, round)
);

CREATE INDEX idx_round_scores_scorecard ON public.round_scores(scorecard_id);
CREATE INDEX idx_round_scores_fight     ON public.round_scores(fight_id);
