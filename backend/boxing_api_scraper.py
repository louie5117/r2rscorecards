"""
Boxing API Scraper
==================
Pulls boxer profiles, fight history, and upcoming schedules from the
Boxing Data API (RapidAPI) and upserts into your Supabase database.
"""

import os
import logging
from datetime import datetime
from typing import Optional

import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# ── Config ────────────────────────────────────────────────────────────────────
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
RAPIDAPI_KEY = os.environ.get("RAPIDAPI_KEY", "")

API_BASE     = "https://boxing-data-api.p.rapidapi.com/v1"
API_HEADERS  = {
    "x-rapidapi-key":  RAPIDAPI_KEY,
    "x-rapidapi-host": "boxing-data-api.p.rapidapi.com",
}

# ── Supabase client ───────────────────────────────────────────────────────────
def get_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)


# ── API helper ────────────────────────────────────────────────────────────────
def api_get(path: str, params: dict = None) -> list:
    """GET a Boxing Data API endpoint, paginating through all results."""
    if not RAPIDAPI_KEY:
        log.warning("RAPIDAPI_KEY not set")
        return []

    results = []
    page = 1
    page_size = 100

    while True:
        p = {"page_num": page, "page_size": page_size, **(params or {})}
        try:
            resp = requests.get(
                f"{API_BASE}{path}",
                headers=API_HEADERS,
                params=p,
                timeout=15,
            )
            resp.raise_for_status()
            data = resp.json()
        except Exception as e:
            log.warning(f"API request failed ({path}): {e}")
            break

        if not data or not isinstance(data, list):
            break

        results.extend(data)
        if len(data) < page_size:
            break
        page += 1

    return results


# ── Supabase helpers ──────────────────────────────────────────────────────────
def upsert_boxer_record(sb: Client, boxer_id: str, record: dict) -> None:
    existing = (
        sb.table("boxer_records")
        .select("id")
        .eq("boxer_id", boxer_id)
        .execute()
    )
    if existing.data:
        sb.table("boxer_records").update(record).eq("boxer_id", boxer_id).execute()
    else:
        record["boxer_id"] = boxer_id
        sb.table("boxer_records").insert(record).execute()


def resolve_boxer_id(sb: Client, full_name: str, name_cache: dict) -> Optional[str]:
    """Look up a boxer's Supabase UUID by full name, using a local cache."""
    if full_name in name_cache:
        return name_cache[full_name]
    match = sb.table("boxers").select("id").ilike("full_name", full_name).execute()
    boxer_id = match.data[0]["id"] if match.data else None
    if boxer_id:
        name_cache[full_name] = boxer_id
    return boxer_id


def broadcast_str(broadcasters: list) -> Optional[str]:
    """Flatten [{Country: Network}, ...] to a comma-separated string."""
    all_bc = []
    for bc in broadcasters:
        if isinstance(bc, dict):
            all_bc.extend(bc.values())
        elif isinstance(bc, str):
            all_bc.append(bc)
    return ", ".join(all_bc) if all_bc else None


# ── 1. Fighters ───────────────────────────────────────────────────────────────
def fetch_fighters(sb: Client) -> dict:
    """
    Pull all fighters from the API, upsert into boxers + boxer_records.
    Returns a cache of {full_name: supabase_uuid} for use by fight fetchers.
    """
    log.info("Fetching fighters from Boxing Data API…")
    fighters = api_get("/fighters/")
    log.info(f"  {len(fighters)} fighters retrieved")

    name_cache = {}
    inserted = updated = 0

    for f in fighters:
        full_name = f.get("name")
        if not full_name:
            continue

        boxer_data = {"full_name": full_name}
        for src, dst in [
            ("nickname",    "nickname"),
            ("nationality", "nationality"),
            ("stance",      "stance"),
            ("height_cm",   "height_cm"),
            ("reach_cm",    "reach_cm"),
        ]:
            val = f.get(src)
            if val and str(val).strip() not in ("", "-", "null"):
                boxer_data[dst] = val

        division = f.get("division") or {}
        if division.get("name"):
            boxer_data["weight_class"] = division["name"]

        try:
            existing = sb.table("boxers").select("id").eq("full_name", full_name).execute()
            if existing.data:
                boxer_id = existing.data[0]["id"]
                sb.table("boxers").update(boxer_data).eq("id", boxer_id).execute()
                updated += 1
            else:
                result = sb.table("boxers").insert(boxer_data).execute()
                boxer_id = result.data[0]["id"]
                inserted += 1

            name_cache[full_name] = boxer_id

            stats = f.get("stats") or {}
            upsert_boxer_record(sb, boxer_id, {
                "wins":       stats.get("wins", 0),
                "losses":     stats.get("losses", 0),
                "draws":      stats.get("draws", 0),
                "updated_at": datetime.utcnow().isoformat(),
            })

        except Exception as e:
            log.debug(f"Skipping fighter {full_name}: {e}")

    log.info(f"Fighters done — {inserted} inserted, {updated} updated")
    return name_cache


# ── 2. Historical fights ──────────────────────────────────────────────────────
def fetch_fight_history(sb: Client, name_cache: dict) -> int:
    """
    Pull all finished fights from the API and insert into the fights table.
    Returns number of fights inserted.
    """
    log.info("Fetching historical fights from Boxing Data API…")
    fights = api_get("/fights/", {"status": "FINISHED"})
    log.info(f"  {len(fights)} finished fights retrieved")

    inserted = 0

    for fight in fights:
        try:
            fighters   = fight.get("fighters", {})
            f1         = fighters.get("fighter_1", {})
            f2         = fighters.get("fighter_2", {})
            name_a     = f1.get("full_name")
            name_b     = f2.get("full_name")
            if not name_a or not name_b:
                continue

            raw_date = fight.get("date", "")
            date_str = raw_date[:10] if raw_date else None
            if not date_str:
                continue

            boxer_a_id = resolve_boxer_id(sb, name_a, name_cache)
            boxer_b_id = resolve_boxer_id(sb, name_b, name_cache)

            winner_id = None
            if f1.get("winner") and boxer_a_id:
                winner_id = boxer_a_id
            elif f2.get("winner") and boxer_b_id:
                winner_id = boxer_b_id

            results      = fight.get("results") or {}
            division     = fight.get("division") or {}
            titles       = fight.get("titles") or []
            event        = fight.get("event") or {}
            broadcasters = event.get("broadcasters", [])

            fight_row = {
                "date":          date_str,
                "result":        results.get("outcome"),
                "result_round":  results.get("round"),
                "weight_class":  division.get("name"),
                "title_fought":  titles[0]["name"] if titles else None,
                "venue":         fight.get("venue"),
                "location":      fight.get("location"),
                "notes":         fight.get("title"),
                "source_url":    f"{API_BASE}/fights/",
            }
            if boxer_a_id:
                fight_row["boxer_a_id"] = boxer_a_id
            if boxer_b_id:
                fight_row["boxer_b_id"] = boxer_b_id
            if winner_id:
                fight_row["winner_id"] = winner_id

            bc = broadcast_str(broadcasters)
            if bc:
                fight_row["promoter"] = bc  # closest available column

            fight_row = {k: v for k, v in fight_row.items() if v is not None}
            sb.table("fights").insert(fight_row).execute()
            inserted += 1

        except Exception as e:
            log.debug(f"Skipping fight: {e}")
            continue

    log.info(f"Historical fights done — {inserted} inserted")
    return inserted


# ── 3. Upcoming schedule ──────────────────────────────────────────────────────
def fetch_upcoming_schedule(sb: Client, name_cache: dict) -> int:
    """
    Pull all upcoming fights from the API and insert into scheduled_fights.
    Returns number inserted.
    """
    log.info("Fetching upcoming fights from Boxing Data API…")
    fights = api_get("/fights/", {"status": "NOT_STARTED"})
    log.info(f"  {len(fights)} upcoming fights retrieved")

    inserted = 0

    for fight in fights:
        try:
            fighters = fight.get("fighters", {})
            name_a   = fighters.get("fighter_1", {}).get("full_name")
            name_b   = fighters.get("fighter_2", {}).get("full_name")
            if not name_a or not name_b:
                continue

            raw_date = fight.get("date", "")
            date_str = raw_date[:10] if raw_date else None
            if not date_str:
                continue

            division     = fight.get("division") or {}
            titles       = fight.get("titles") or []
            event        = fight.get("event") or {}
            broadcasters = event.get("broadcasters", [])

            row_data = {
                "scheduled_date": date_str,
                "status":         "confirmed",
                "weight_class":   division.get("name"),
                "title_fought":   titles[0]["name"] if titles else None,
                "venue":          fight.get("venue"),
                "location":       fight.get("location"),
                "broadcast":      broadcast_str(broadcasters),
                "source_url":     f"{API_BASE}/fights/",
            }

            boxer_a_id = resolve_boxer_id(sb, name_a, name_cache)
            boxer_b_id = resolve_boxer_id(sb, name_b, name_cache)
            if boxer_a_id:
                row_data["boxer_a_id"] = boxer_a_id
            if boxer_b_id:
                row_data["boxer_b_id"] = boxer_b_id

            row_data = {k: v for k, v in row_data.items() if v is not None}
            sb.table("scheduled_fights").insert(row_data).execute()
            inserted += 1
            log.info(f"Scheduled: {name_a} vs {name_b} on {date_str}")

        except Exception as e:
            log.debug(f"Skipping upcoming fight: {e}")
            continue

    log.info(f"Upcoming schedule done — {inserted} inserted")
    return inserted


# ── Manual helpers ────────────────────────────────────────────────────────────
def add_boxer_manually(sb: Client, data: dict) -> str:
    result = sb.table("boxers").insert(data).execute()
    boxer_id = result.data[0]["id"]
    log.info(f"Manually inserted boxer: {data['full_name']} ({boxer_id})")
    return boxer_id


def add_scheduled_fight_manually(sb: Client, data: dict) -> str:
    result = sb.table("scheduled_fights").insert(data).execute()
    fight_id = result.data[0]["id"]
    log.info(f"Manually inserted scheduled fight: {fight_id}")
    return fight_id


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    sb = get_supabase()
    log.info("Connected to Supabase ✓")

    # Step 1: load all fighters — builds the name→id cache used by steps 2 & 3
    name_cache = fetch_fighters(sb)

    # Step 2: historical fight results
    fetch_fight_history(sb, name_cache)

    # Step 3: upcoming schedule
    fetch_upcoming_schedule(sb, name_cache)

    log.info("Sync complete ✓")


if __name__ == "__main__":
    main()
