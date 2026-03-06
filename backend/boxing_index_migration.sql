-- Boxing Index Migration
-- Adds boxer profiles, extends fights with full metadata, and enables
-- historical + planned fight indexing similar to BoxRec.
--
-- Run AFTER schema.sql, rls_policies.sql, analytics_views.sql.

-- ============================================================
-- WEIGHT CLASSES
-- Canonical list used as a CHECK constraint on boxers and fights.
-- ============================================================

CREATE TYPE public.weight_class AS ENUM (
    'minimumweight',       -- 105 lb
    'light_flyweight',     -- 108 lb
    'flyweight',           -- 112 lb
    'super_flyweight',     -- 115 lb
    'bantamweight',        -- 118 lb
    'super_bantamweight',  -- 122 lb
    'featherweight',       -- 126 lb
    'super_featherweight', -- 130 lb
    'lightweight',         -- 135 lb
    'super_lightweight',   -- 140 lb
    'welterweight',        -- 147 lb
    'super_welterweight',  -- 154 lb
    'middleweight',        -- 160 lb
    'super_middleweight',  -- 168 lb
    'light_heavyweight',   -- 175 lb
    'cruiserweight',       -- 200 lb
    'heavyweight',         -- 200+ lb
    'super_heavyweight'    -- unlimited
);

CREATE TYPE public.fight_result AS ENUM (
    'red_win',
    'blue_win',
    'draw',
    'no_contest',
    'pending'
);

CREATE TYPE public.fight_method AS ENUM (
    'KO',   -- knockout
    'TKO',  -- technical knockout
    'UD',   -- unanimous decision
    'SD',   -- split decision
    'MD',   -- majority decision
    'RTD',  -- retired / corner stoppage
    'DQ',   -- disqualification
    'NC',   -- no contest
    'pending'
);

-- ============================================================
-- BOXERS
-- Stores individual fighter profiles with career stats.
-- Stats (wins/losses/etc.) are denormalised here for fast reads
-- but are also computable from the fights table via views.
-- ============================================================

CREATE TABLE public.boxers (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    name            TEXT            NOT NULL,
    nickname        TEXT,
    nationality     TEXT,
    date_of_birth   DATE,
    birth_city      TEXT,
    birth_country   TEXT,

    -- Physical
    stance          TEXT            CHECK (stance IN ('orthodox', 'southpaw', 'switch')),
    height_cm       NUMERIC(5,1),
    reach_cm        NUMERIC(5,1),
    weight_class    public.weight_class,

    -- Career record (denormalised for quick display)
    wins            INT             NOT NULL DEFAULT 0 CHECK (wins >= 0),
    losses          INT             NOT NULL DEFAULT 0 CHECK (losses >= 0),
    draws           INT             NOT NULL DEFAULT 0 CHECK (draws >= 0),
    no_contests     INT             NOT NULL DEFAULT 0 CHECK (no_contests >= 0),
    kos             INT             NOT NULL DEFAULT 0 CHECK (kos >= 0),   -- subset of wins
    tkos            INT             NOT NULL DEFAULT 0 CHECK (tkos >= 0),  -- subset of wins

    -- Active status
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    pro_debut       DATE,

    -- External IDs for deduplication / enrichment
    boxrec_id       TEXT            UNIQUE,
    espn_id         TEXT            UNIQUE,
    sports_db_id    TEXT            UNIQUE,   -- TheSportsDB person ID
    wikidata_id     TEXT            UNIQUE,

    -- Image
    photo_url       TEXT,

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TRIGGER boxers_updated_at
    BEFORE UPDATE ON public.boxers
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_boxers_name        ON public.boxers(name);
CREATE INDEX idx_boxers_weight      ON public.boxers(weight_class);
CREATE INDEX idx_boxers_nationality ON public.boxers(nationality);
CREATE INDEX idx_boxers_active      ON public.boxers(is_active);

-- Full-text search index on boxer names + nicknames
CREATE INDEX idx_boxers_fts ON public.boxers
    USING GIN (to_tsvector('english', name || ' ' || COALESCE(nickname, '')));


-- ============================================================
-- EXTEND FIGHTS TABLE
-- Add boxer foreign keys, venue, result, and belt metadata.
-- ============================================================

ALTER TABLE public.fights
    ADD COLUMN IF NOT EXISTS red_boxer_id      UUID        REFERENCES public.boxers(id),
    ADD COLUMN IF NOT EXISTS blue_boxer_id     UUID        REFERENCES public.boxers(id),
    ADD COLUMN IF NOT EXISTS weight_class      public.weight_class,
    ADD COLUMN IF NOT EXISTS belts_at_stake    TEXT[],     -- e.g. ARRAY['WBC', 'WBA', 'IBF']
    ADD COLUMN IF NOT EXISTS venue             TEXT,
    ADD COLUMN IF NOT EXISTS city              TEXT,
    ADD COLUMN IF NOT EXISTS country           TEXT,
    ADD COLUMN IF NOT EXISTS result            public.fight_result DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS method            public.fight_method DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS method_round      INT         CHECK (method_round BETWEEN 1 AND 15),
    ADD COLUMN IF NOT EXISTS method_time       TEXT,       -- e.g. "2:47"
    ADD COLUMN IF NOT EXISTS sports_db_id      TEXT        UNIQUE,  -- TheSportsDB event ID
    ADD COLUMN IF NOT EXISTS poster_url        TEXT,
    ADD COLUMN IF NOT EXISTS broadcast         TEXT[];     -- e.g. ARRAY['ESPN+', 'DAZN']

CREATE INDEX IF NOT EXISTS idx_fights_red_boxer  ON public.fights(red_boxer_id);
CREATE INDEX IF NOT EXISTS idx_fights_blue_boxer ON public.fights(blue_boxer_id);
CREATE INDEX IF NOT EXISTS idx_fights_weight     ON public.fights(weight_class);
CREATE INDEX IF NOT EXISTS idx_fights_result     ON public.fights(result);
CREATE INDEX IF NOT EXISTS idx_fights_country    ON public.fights(country);


-- ============================================================
-- BOXER RANKINGS
-- Snapshot of a boxer's ranking at a point in time.
-- Organization: WBC, WBA, IBF, WBO, The Ring, etc.
-- ============================================================

CREATE TABLE public.boxer_rankings (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    boxer_id        UUID            NOT NULL REFERENCES public.boxers(id) ON DELETE CASCADE,
    organization    TEXT            NOT NULL,   -- 'WBC' | 'WBA' | 'IBF' | 'WBO' | 'The Ring'
    weight_class    public.weight_class NOT NULL,
    rank            INT             NOT NULL CHECK (rank >= 0), -- 0 = champion
    as_of_date      DATE            NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rankings_boxer     ON public.boxer_rankings(boxer_id);
CREATE INDEX idx_rankings_org       ON public.boxer_rankings(organization, weight_class, rank);
CREATE INDEX idx_rankings_date      ON public.boxer_rankings(as_of_date DESC);

-- Only one rank per boxer per org per weight class per date
CREATE UNIQUE INDEX idx_rankings_unique
    ON public.boxer_rankings(boxer_id, organization, weight_class, as_of_date);
