-- Boxing Index Views
-- Computed statistics and query helpers for the boxing index.
-- Run after boxing_index_migration.sql.

-- ============================================================
-- BOXER FIGHT HISTORY
-- Full fight history for any boxer, with opponent details.
-- ============================================================

CREATE OR REPLACE VIEW public.boxer_fight_history AS
SELECT
    f.id                        AS fight_id,
    f.date,
    f.title,
    f.venue,
    f.city,
    f.country,
    f.weight_class,
    f.belts_at_stake,
    f.result,
    f.method,
    f.method_round,
    f.method_time,
    f.scheduled_rounds,
    f.status,
    f.broadcast,
    f.poster_url,

    -- Boxer perspective: who is "our" boxer vs opponent
    b_red.id                    AS red_boxer_id,
    b_red.name                  AS red_boxer_name,
    b_red.nickname              AS red_boxer_nickname,
    b_red.nationality           AS red_boxer_nationality,

    b_blue.id                   AS blue_boxer_id,
    b_blue.name                 AS blue_boxer_name,
    b_blue.nickname             AS blue_boxer_nickname,
    b_blue.nationality          AS blue_boxer_nationality,

    -- Denormalised record at time of query (not at fight time)
    b_red.wins || '-' || b_red.losses || '-' || b_red.draws  AS red_record,
    b_blue.wins || '-' || b_blue.losses || '-' || b_blue.draws AS blue_record,

    f.created_at,
    f.updated_at

FROM public.fights f
LEFT JOIN public.boxers b_red  ON b_red.id  = f.red_boxer_id
LEFT JOIN public.boxers b_blue ON b_blue.id = f.blue_boxer_id
WHERE f.red_boxer_id IS NOT NULL
   OR f.blue_boxer_id IS NOT NULL;


-- ============================================================
-- BOXER CAREER STATS (computed from fights table)
-- Source of truth for win/loss/KO records derived from fight outcomes.
-- Use this to validate / re-sync the denormalised columns on boxers.
-- ============================================================

CREATE OR REPLACE VIEW public.boxer_computed_stats AS
WITH all_appearances AS (
    -- Each fight appears twice: once for red corner, once for blue
    SELECT
        f.red_boxer_id          AS boxer_id,
        f.result = 'red_win'    AS won,
        f.result = 'blue_win'   AS lost,
        f.result = 'draw'       AS drew,
        f.result = 'no_contest' AS nc,
        f.method IN ('KO')      AS was_ko,
        f.method IN ('TKO')     AS was_tko
    FROM public.fights f
    WHERE f.red_boxer_id IS NOT NULL
      AND f.result IS DISTINCT FROM 'pending'

    UNION ALL

    SELECT
        f.blue_boxer_id         AS boxer_id,
        f.result = 'blue_win'   AS won,
        f.result = 'red_win'    AS lost,
        f.result = 'draw'       AS drew,
        f.result = 'no_contest' AS nc,
        f.method IN ('KO')      AS was_ko,
        f.method IN ('TKO')     AS was_tko
    FROM public.fights f
    WHERE f.blue_boxer_id IS NOT NULL
      AND f.result IS DISTINCT FROM 'pending'
)
SELECT
    a.boxer_id,
    b.name,
    b.weight_class,
    COUNT(*)                                        AS total_fights,
    COUNT(*) FILTER (WHERE a.won)                   AS wins,
    COUNT(*) FILTER (WHERE a.lost)                  AS losses,
    COUNT(*) FILTER (WHERE a.drew)                  AS draws,
    COUNT(*) FILTER (WHERE a.nc)                    AS no_contests,
    COUNT(*) FILTER (WHERE a.won AND a.was_ko)      AS ko_wins,
    COUNT(*) FILTER (WHERE a.won AND a.was_tko)     AS tko_wins,
    ROUND(
        COUNT(*) FILTER (WHERE a.won)::NUMERIC /
        NULLIF(COUNT(*) FILTER (WHERE a.won OR a.lost), 0) * 100,
        1
    )                                               AS win_pct,
    ROUND(
        (COUNT(*) FILTER (WHERE a.won AND (a.was_ko OR a.was_tko)))::NUMERIC /
        NULLIF(COUNT(*) FILTER (WHERE a.won), 0) * 100,
        1
    )                                               AS finish_pct
FROM all_appearances a
JOIN public.boxers b ON b.id = a.boxer_id
GROUP BY a.boxer_id, b.name, b.weight_class;


-- ============================================================
-- HEAD TO HEAD
-- All fights between two specific boxers (rematches included).
-- Usage: WHERE (red_boxer_id = $1 AND blue_boxer_id = $2)
--           OR (red_boxer_id = $2 AND blue_boxer_id = $1)
-- ============================================================

CREATE OR REPLACE VIEW public.head_to_head AS
SELECT
    f.id                    AS fight_id,
    f.date,
    f.title,
    f.venue,
    f.city,
    f.country,
    f.weight_class,
    f.belts_at_stake,
    f.result,
    f.method,
    f.method_round,
    f.method_time,
    f.scheduled_rounds,
    f.status,
    b_red.id                AS red_boxer_id,
    b_red.name              AS red_boxer_name,
    b_blue.id               AS blue_boxer_id,
    b_blue.name             AS blue_boxer_name
FROM public.fights f
JOIN public.boxers b_red  ON b_red.id  = f.red_boxer_id
JOIN public.boxers b_blue ON b_blue.id = f.blue_boxer_id;


-- ============================================================
-- UPCOMING FIGHTS WITH BOXER DETAILS
-- Convenient view for the app's "upcoming" feed.
-- ============================================================

CREATE OR REPLACE VIEW public.upcoming_fights_detail AS
SELECT
    f.id,
    f.date,
    f.title,
    f.venue,
    f.city,
    f.country,
    f.weight_class,
    f.belts_at_stake,
    f.scheduled_rounds,
    f.broadcast,
    f.poster_url,
    f.api_source_id,
    f.sports_db_id,

    -- Red corner
    b_red.id                AS red_boxer_id,
    b_red.name              AS red_boxer_name,
    b_red.nickname          AS red_boxer_nickname,
    b_red.nationality       AS red_boxer_nationality,
    b_red.photo_url         AS red_boxer_photo,
    b_red.wins || '-' || b_red.losses || '-' || b_red.draws  AS red_record,
    b_red.kos               AS red_kos,

    -- Blue corner
    b_blue.id               AS blue_boxer_id,
    b_blue.name             AS blue_boxer_name,
    b_blue.nickname         AS blue_boxer_nickname,
    b_blue.nationality      AS blue_boxer_nationality,
    b_blue.photo_url        AS blue_boxer_photo,
    b_blue.wins || '-' || b_blue.losses || '-' || b_blue.draws AS blue_record,
    b_blue.kos              AS blue_kos

FROM public.fights f
LEFT JOIN public.boxers b_red  ON b_red.id  = f.red_boxer_id
LEFT JOIN public.boxers b_blue ON b_blue.id = f.blue_boxer_id
WHERE f.status = 'upcoming'
  AND f.date >= NOW() - INTERVAL '12 hours'
ORDER BY f.date ASC;


-- ============================================================
-- WEIGHT CLASS RANKINGS WITH BOXER DETAILS
-- Current top-ranked boxers per organization per weight class.
-- ============================================================

CREATE OR REPLACE VIEW public.current_rankings AS
SELECT
    r.organization,
    r.weight_class,
    r.rank,
    r.as_of_date,
    b.id            AS boxer_id,
    b.name,
    b.nickname,
    b.nationality,
    b.photo_url,
    b.wins,
    b.losses,
    b.draws,
    b.kos,
    b.is_active
FROM public.boxer_rankings r
JOIN public.boxers b ON b.id = r.boxer_id
WHERE r.as_of_date = (
    -- Latest snapshot for this org + weight_class combo
    SELECT MAX(r2.as_of_date)
    FROM public.boxer_rankings r2
    WHERE r2.organization = r.organization
      AND r2.weight_class  = r.weight_class
)
ORDER BY r.organization, r.weight_class, r.rank;


-- ============================================================
-- FUNCTION: Refresh boxer record from fights table
-- Call after inserting/updating a fight result to keep
-- the denormalised wins/losses/kos columns accurate.
-- ============================================================

CREATE OR REPLACE FUNCTION public.refresh_boxer_record(p_boxer_id UUID)
RETURNS VOID AS $$
DECLARE
    stats RECORD;
BEGIN
    SELECT
        wins, losses, draws, no_contests, ko_wins, tko_wins
    INTO stats
    FROM public.boxer_computed_stats
    WHERE boxer_id = p_boxer_id;

    IF FOUND THEN
        UPDATE public.boxers
        SET
            wins        = stats.wins,
            losses      = stats.losses,
            draws       = stats.draws,
            no_contests = stats.no_contests,
            kos         = stats.ko_wins,
            tkos        = stats.tko_wins,
            updated_at  = NOW()
        WHERE id = p_boxer_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- TRIGGER: Auto-refresh boxer records when a fight result is set
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_fight_result_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Only act when result changes from pending to an actual result
    IF OLD.result = 'pending' AND NEW.result != 'pending' THEN
        IF NEW.red_boxer_id IS NOT NULL THEN
            PERFORM public.refresh_boxer_record(NEW.red_boxer_id);
        END IF;
        IF NEW.blue_boxer_id IS NOT NULL THEN
            PERFORM public.refresh_boxer_record(NEW.blue_boxer_id);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_fight_result_set
    AFTER UPDATE OF result ON public.fights
    FOR EACH ROW EXECUTE FUNCTION public.handle_fight_result_update();


-- ============================================================
-- RLS for new tables
-- ============================================================

ALTER TABLE public.boxers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boxer_rankings ENABLE ROW LEVEL SECURITY;

-- Public read access — boxer data is world-readable
CREATE POLICY "Boxers are publicly readable"
    ON public.boxers FOR SELECT USING (true);

CREATE POLICY "Rankings are publicly readable"
    ON public.boxer_rankings FOR SELECT USING (true);

-- Only authenticated users can insert/update boxers
CREATE POLICY "Authenticated users can insert boxers"
    ON public.boxers FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update boxers"
    ON public.boxers FOR UPDATE
    USING (auth.role() = 'authenticated');
