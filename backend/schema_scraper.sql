-- ============================================================
-- BOXING API - Supabase Schema
-- Run this in your Supabase SQL Editor to set up all tables
-- ============================================================

-- 1. BOXERS — core profiles
CREATE TABLE boxers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name     TEXT NOT NULL,
  nickname      TEXT,
  nationality   TEXT,
  date_of_birth DATE,
  weight_class  TEXT,         -- e.g. 'Heavyweight', 'Welterweight'
  stance        TEXT,         -- 'Orthodox' or 'Southpaw'
  height_cm     NUMERIC,
  reach_cm      NUMERIC,
  active        BOOLEAN DEFAULT TRUE,
  image_url     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BOXER RECORDS — win/loss/draw + KO stats (denormalised for fast reads)
CREATE TABLE boxer_records (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  boxer_id      UUID REFERENCES boxers(id) ON DELETE CASCADE,
  wins          INT DEFAULT 0,
  losses        INT DEFAULT 0,
  draws         INT DEFAULT 0,
  no_contests   INT DEFAULT 0,
  wins_by_ko    INT DEFAULT 0,
  wins_by_tko   INT DEFAULT 0,
  wins_by_dec   INT DEFAULT 0,
  losses_by_ko  INT DEFAULT 0,
  losses_by_tko INT DEFAULT 0,
  losses_by_dec INT DEFAULT 0,
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (boxer_id)
);

-- 3. FIGHTS — historical results (two boxers, one fight row)
CREATE TABLE fights (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date            DATE NOT NULL,
  boxer_a_id      UUID REFERENCES boxers(id),
  boxer_b_id      UUID REFERENCES boxers(id),
  winner_id       UUID REFERENCES boxers(id),   -- NULL = draw / no contest
  result          TEXT,   -- 'KO', 'TKO', 'UD', 'SD', 'MD', 'Draw', 'NC', 'DQ'
  result_round    INT,
  result_time     TEXT,   -- e.g. '2:35'
  total_rounds    INT,
  weight_class    TEXT,
  title_fought    TEXT,   -- e.g. 'WBC Heavyweight' or NULL
  venue           TEXT,
  location        TEXT,
  promoter        TEXT,
  notes           TEXT,
  source_url      TEXT,   -- where this data was scraped from
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 4. SCHEDULED FIGHTS — upcoming bouts
CREATE TABLE scheduled_fights (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scheduled_date  DATE NOT NULL,
  boxer_a_id      UUID REFERENCES boxers(id),
  boxer_b_id      UUID REFERENCES boxers(id),
  weight_class    TEXT,
  title_fought    TEXT,
  venue           TEXT,
  location        TEXT,
  promoter        TEXT,
  broadcast       TEXT,   -- e.g. 'Sky Sports', 'DAZN'
  status          TEXT DEFAULT 'confirmed',  -- 'confirmed', 'rumoured', 'cancelled'
  notes           TEXT,
  source_url      TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES for common query patterns
-- ============================================================
CREATE INDEX idx_boxers_name        ON boxers (full_name);
CREATE INDEX idx_boxers_weight      ON boxers (weight_class);
CREATE INDEX idx_boxers_nationality ON boxers (nationality);
CREATE INDEX idx_fights_date        ON fights (date DESC);
CREATE INDEX idx_fights_boxer_a     ON fights (boxer_a_id);
CREATE INDEX idx_fights_boxer_b     ON fights (boxer_b_id);
CREATE INDEX idx_scheduled_date     ON scheduled_fights (scheduled_date ASC);

-- ============================================================
-- HELPER VIEW — full boxer profile with record in one query
-- ============================================================
CREATE OR REPLACE VIEW boxer_profiles AS
SELECT
  b.id,
  b.full_name,
  b.nickname,
  b.nationality,
  b.date_of_birth,
  b.weight_class,
  b.stance,
  b.height_cm,
  b.reach_cm,
  b.active,
  b.image_url,
  r.wins,
  r.losses,
  r.draws,
  r.no_contests,
  r.wins_by_ko,
  r.wins_by_tko,
  r.wins_by_dec,
  r.losses_by_ko,
  r.losses_by_tko,
  r.losses_by_dec
FROM boxers b
LEFT JOIN boxer_records r ON r.boxer_id = b.id;

-- ============================================================
-- HELPER VIEW — upcoming schedule with boxer names
-- ============================================================
CREATE OR REPLACE VIEW upcoming_schedule AS
SELECT
  s.id,
  s.scheduled_date,
  s.weight_class,
  s.title_fought,
  s.venue,
  s.location,
  s.broadcast,
  s.status,
  a.full_name AS boxer_a_name,
  b.full_name AS boxer_b_name,
  a.nationality AS boxer_a_nationality,
  b.nationality AS boxer_b_nationality
FROM scheduled_fights s
LEFT JOIN boxers a ON a.id = s.boxer_a_id
LEFT JOIN boxers b ON b.id = s.boxer_b_id
WHERE s.scheduled_date >= CURRENT_DATE
ORDER BY s.scheduled_date ASC;

-- ============================================================
-- ROW LEVEL SECURITY (optional but recommended)
-- Enables public read, restricts writes to authenticated users
-- ============================================================
ALTER TABLE boxers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE boxer_records    ENABLE ROW LEVEL SECURITY;
ALTER TABLE fights           ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;

-- Public can read everything
CREATE POLICY "Public read boxers"           ON boxers           FOR SELECT USING (true);
CREATE POLICY "Public read boxer_records"    ON boxer_records    FOR SELECT USING (true);
CREATE POLICY "Public read fights"           ON fights           FOR SELECT USING (true);
CREATE POLICY "Public read schedule"         ON scheduled_fights FOR SELECT USING (true);

-- Only authenticated (your scraper/admin) can write
CREATE POLICY "Auth write boxers"           ON boxers           FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Auth write boxer_records"    ON boxer_records    FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Auth write fights"           ON fights           FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Auth write schedule"         ON scheduled_fights FOR ALL USING (auth.role() = 'authenticated');
