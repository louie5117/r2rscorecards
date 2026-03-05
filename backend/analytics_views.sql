-- R2R Scorecards - Analytics Views
-- Apply AFTER running schema.sql and rls_policies.sql.
-- These views power crowd statistics, demographic breakdowns,
-- and global scorecards without expensive ad-hoc queries.

-- ============================================================
-- SUBMITTED ROUND SCORES (base view)
-- Only includes locked (submitted) scorecards to avoid
-- counting in-progress drafts in aggregate stats.
-- ============================================================

CREATE OR REPLACE VIEW public.submitted_round_scores AS
SELECT
    rs.id,
    rs.fight_id,
    rs.scorecard_id,
    rs.round,
    rs.red_score,
    rs.blue_score,
    sc.user_id,
    sc.group_id,
    sc.submitted_at,
    p.region,
    p.gender,
    p.age_group
FROM public.round_scores    rs
JOIN public.scorecards      sc ON sc.id  = rs.scorecard_id
JOIN public.profiles        p  ON p.id   = sc.user_id
WHERE sc.submitted_at IS NOT NULL;


-- ============================================================
-- FIGHT CROWD SCORES
-- Overall crowd totals per fight across all submitted scorecards.
-- ============================================================

CREATE OR REPLACE VIEW public.fight_crowd_scores AS
SELECT
    fight_id,
    COUNT(DISTINCT scorecard_id)                    AS scorecard_count,
    ROUND(AVG(red_score  - blue_score), 2)          AS avg_score_margin,  -- positive = red leads
    SUM(red_score)                                  AS total_red,
    SUM(blue_score)                                 AS total_blue,
    COUNT(*) FILTER (WHERE red_score > blue_score)  AS red_rounds_won,
    COUNT(*) FILTER (WHERE blue_score > red_score)  AS blue_rounds_won,
    COUNT(*) FILTER (WHERE red_score = blue_score)  AS even_rounds
FROM public.submitted_round_scores
GROUP BY fight_id;


-- ============================================================
-- FIGHT CROWD SCORES BY ROUND
-- Per-round consensus across all submitted scorecards.
-- ============================================================

CREATE OR REPLACE VIEW public.fight_crowd_scores_by_round AS
SELECT
    fight_id,
    round,
    COUNT(DISTINCT scorecard_id)                    AS scorecard_count,
    ROUND(AVG(red_score),  2)                       AS avg_red_score,
    ROUND(AVG(blue_score), 2)                       AS avg_blue_score,
    COUNT(*) FILTER (WHERE red_score > blue_score)  AS red_wins,
    COUNT(*) FILTER (WHERE blue_score > red_score)  AS blue_wins,
    COUNT(*) FILTER (WHERE red_score = blue_score)  AS even
FROM public.submitted_round_scores
GROUP BY fight_id, round
ORDER BY fight_id, round;


-- ============================================================
-- FIGHT DEMOGRAPHIC SCORES
-- Crowd totals broken down by demographic dimension.
-- The `dimension` column identifies which field is being sliced.
-- ============================================================

CREATE OR REPLACE VIEW public.fight_demographic_scores AS

-- Breakdown by region
SELECT
    fight_id,
    'region'            AS dimension,
    region              AS segment,
    COUNT(DISTINCT scorecard_id)                    AS scorecard_count,
    ROUND(AVG(red_score - blue_score), 2)           AS avg_score_margin,
    SUM(red_score)                                  AS total_red,
    SUM(blue_score)                                 AS total_blue
FROM public.submitted_round_scores
GROUP BY fight_id, region

UNION ALL

-- Breakdown by gender
SELECT
    fight_id,
    'gender'            AS dimension,
    gender              AS segment,
    COUNT(DISTINCT scorecard_id),
    ROUND(AVG(red_score - blue_score), 2),
    SUM(red_score),
    SUM(blue_score)
FROM public.submitted_round_scores
GROUP BY fight_id, gender

UNION ALL

-- Breakdown by age group
SELECT
    fight_id,
    'age_group'         AS dimension,
    age_group           AS segment,
    COUNT(DISTINCT scorecard_id),
    ROUND(AVG(red_score - blue_score), 2),
    SUM(red_score),
    SUM(blue_score)
FROM public.submitted_round_scores
GROUP BY fight_id, age_group;


-- ============================================================
-- GROUP LEADERBOARD
-- Who in a group has the most submitted scorecards,
-- and whose picks align closest with the crowd consensus.
-- ============================================================

CREATE OR REPLACE VIEW public.group_leaderboard AS
SELECT
    sc.group_id,
    sc.user_id,
    p.display_name,
    COUNT(DISTINCT sc.id)   AS submitted_count,
    SUM(rs.red_score)       AS total_red_scored,
    SUM(rs.blue_score)      AS total_blue_scored
FROM public.scorecards  sc
JOIN public.round_scores rs ON rs.scorecard_id = sc.id
JOIN public.profiles     p  ON p.id = sc.user_id
WHERE sc.submitted_at IS NOT NULL
  AND sc.group_id IS NOT NULL
GROUP BY sc.group_id, sc.user_id, p.display_name;


-- ============================================================
-- REALTIME-FRIENDLY: LIVE GROUP ROUND SCORES
-- Returns each member's latest round scores for a given fight
-- within a group. Intended for Supabase Realtime subscriptions.
-- Filter by group_id and fight_id on the client.
-- ============================================================

CREATE OR REPLACE VIEW public.live_group_round_scores AS
SELECT
    sc.group_id,
    sc.fight_id,
    sc.user_id,
    p.display_name,
    rs.round,
    rs.red_score,
    rs.blue_score,
    rs.scored_at,
    sc.submitted_at  -- null = still drafting
FROM public.scorecards   sc
JOIN public.round_scores rs ON rs.scorecard_id = sc.id
JOIN public.profiles     p  ON p.id = sc.user_id
WHERE sc.group_id IS NOT NULL;
