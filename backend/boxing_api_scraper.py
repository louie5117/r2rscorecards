Content is user-generated and unverified.
"""
Boxing API Scraper
==================
Scrapes boxer profiles, fight records, and upcoming schedules
from public sources and pushes data into your Supabase database.


import os
import time
import logging
from datetime import datetime, date
from typing import Optional

import requests
from bs4 import BeautifulSoup
from supabase import create_client, Client
from dotenv import load_dotenv

# ── Config ─────────────────────────────────────────────────────────────────
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_KEY"]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    )
}

# ── Supabase client ─────────────────────────────────────────────────────────
def get_supabase() -> Client:
    return create_client(SUPABASE_URL, SUPABASE_KEY)


# ── Helpers ─────────────────────────────────────────────────────────────────
def safe_get(url: str, delay: float = 1.5) -> Optional[BeautifulSoup]:
    """Fetch a URL and return a BeautifulSoup object, or None on failure."""
    try:
        time.sleep(delay)  # polite crawl delay
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return BeautifulSoup(resp.text, "lxml")
    except Exception as e:
        log.warning(f"Failed to fetch {url}: {e}")
        return None


def parse_date(raw: str) -> Optional[str]:
    """Try common date formats, return ISO string or None."""
    for fmt in ("%d %B %Y", "%B %d, %Y", "%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y"):
        try:
            return datetime.strptime(raw.strip(), fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return None


def upsert_boxer_record(sb: Client, boxer_id: str, record: dict) -> None:
    """Insert or update a boxer_records row."""
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


# ── Wikipedia boxer scraper ─────────────────────────────────────────────────
def scrape_boxer_from_wikipedia(wikipedia_url: str, sb: Client) -> Optional[str]:
    """
    Scrape a boxer's profile page from Wikipedia and upsert into Supabase.
    Returns the boxer UUID if successful, None otherwise.

    Example URL: https://en.wikipedia.org/wiki/Anthony_Joshua
    """
    log.info(f"Scraping boxer: {wikipedia_url}")
    soup = safe_get(wikipedia_url)
    if not soup:
        return None

    infobox = soup.find("table", class_="infobox")
    if not infobox:
        log.warning("No infobox found — page may not be a boxer article")
        return None

    def get_field(label: str) -> Optional[str]:
        for row in infobox.find_all("tr"):
            th = row.find("th")
            td = row.find("td")
            if th and td and label.lower() in th.get_text(strip=True).lower():
                return td.get_text(separator=" ", strip=True)
        return None

    full_name = soup.find("h1", id="firstHeading")
    full_name = full_name.get_text(strip=True) if full_name else "Unknown"

    # Parse record string like "87-3-1 (57 KOs)"
    record_raw = get_field("Total fights") or get_field("Record") or ""
    wins = losses = draws = kos = 0
    import re
    m = re.search(r"(\d+)[–\-](\d+)[–\-](\d+)", record_raw)
    if m:
        wins, losses, draws = int(m.group(1)), int(m.group(2)), int(m.group(3))
    ko_m = re.search(r"(\d+)\s*KO", record_raw, re.IGNORECASE)
    if ko_m:
        kos = int(ko_m.group(1))

    boxer_data = {
        "full_name":     full_name,
        "nickname":      get_field("Nickname"),
        "nationality":   get_field("Nationality") or get_field("Born"),
        "date_of_birth": parse_date(get_field("Born") or ""),
        "weight_class":  get_field("Weight"),
        "stance":        get_field("Stance"),
        "source_url":    wikipedia_url,
    }
    # Remove None values so Supabase doesn't complain
    boxer_data = {k: v for k, v in boxer_data.items() if v is not None}

    # Upsert boxer (match on full_name as natural key)
    existing = (
        sb.table("boxers")
        .select("id")
        .eq("full_name", full_name)
        .execute()
    )
    if existing.data:
        boxer_id = existing.data[0]["id"]
        sb.table("boxers").update(boxer_data).eq("id", boxer_id).execute()
        log.info(f"Updated boxer: {full_name} ({boxer_id})")
    else:
        result = sb.table("boxers").insert(boxer_data).execute()
        boxer_id = result.data[0]["id"]
        log.info(f"Inserted boxer: {full_name} ({boxer_id})")

    # Upsert record
    upsert_boxer_record(sb, boxer_id, {
        "wins":        wins,
        "losses":      losses,
        "draws":       draws,
        "wins_by_ko":  kos,
        "updated_at":  datetime.utcnow().isoformat(),
    })

    return boxer_id


# ── Wikipedia fight table scraper ────────────────────────────────────────────
def scrape_fight_history_from_wikipedia(wikipedia_url: str, boxer_id: str, sb: Client) -> int:
    """
    Scrape the professional boxing record table from a Wikipedia boxer page
    and insert fights into the fights table.
    Returns the number of fights inserted.
    """
    log.info(f"Scraping fight history for boxer {boxer_id}")
    soup = safe_get(wikipedia_url)
    if not soup:
        return 0

    # Wikipedia boxing records are in a wikitable with headers like Res., Record, Opponent, etc.
    tables = soup.find_all("table", class_="wikitable")
    inserted = 0

    for table in tables:
        headers = [th.get_text(strip=True).lower() for th in table.find_all("th")]
        if not any(h in headers for h in ["res.", "res", "result", "opponent"]):
            continue

        for row in table.find_all("tr")[1:]:
            cells = [td.get_text(separator=" ", strip=True) for td in row.find_all("td")]
            if len(cells) < 4:
                continue
            try:
                result_raw = cells[0].upper()
                # Normalise result
                if "WIN" in result_raw or result_raw == "W":
                    result_flag = "win"
                elif "LOSS" in result_raw or result_raw in ("L", "LO"):
                    result_flag = "loss"
                else:
                    result_flag = "draw_nc"

                opponent_name = cells[2] if len(cells) > 2 else None
                method        = cells[3] if len(cells) > 3 else None
                round_raw     = cells[4] if len(cells) > 4 else None
                time_raw      = cells[5] if len(cells) > 5 else None
                date_raw      = cells[6] if len(cells) > 6 else None
                location_raw  = cells[7] if len(cells) > 7 else None

                fight_date = parse_date(date_raw or "")

                # Find or skip opponent boxer
                opponent_id = None
                if opponent_name:
                    opp = (
                        sb.table("boxers")
                        .select("id")
                        .eq("full_name", opponent_name)
                        .execute()
                    )
                    if opp.data:
                        opponent_id = opp.data[0]["id"]

                fight_row = {
                    "date":         fight_date or "1900-01-01",
                    "boxer_a_id":   boxer_id,
                    "boxer_b_id":   opponent_id,
                    "result":       method,
                    "result_round": int(round_raw) if round_raw and round_raw.isdigit() else None,
                    "result_time":  time_raw,
                    "location":     location_raw,
                    "winner_id":    boxer_id if result_flag == "win" else (opponent_id if result_flag == "loss" else None),
                    "source_url":   wikipedia_url,
                }
                fight_row = {k: v for k, v in fight_row.items() if v is not None}
                sb.table("fights").insert(fight_row).execute()
                inserted += 1

            except Exception as e:
                log.debug(f"Skipping row due to parse error: {e}")
                continue

    log.info(f"Inserted {inserted} historical fights")
    return inserted


# ── Upcoming schedule scraper (BBC Sport / Sky Sports) ───────────────────────
def scrape_upcoming_schedule_sky(sb: Client) -> int:
    """
    Scrape upcoming boxing schedule from Sky Sports boxing news.
    Returns number of scheduled fights inserted.
    """
    url = "https://www.skysports.com/boxing/schedule"
    log.info(f"Scraping schedule from: {url}")
    soup = safe_get(url)
    if not soup:
        return 0

    inserted = 0
    # Sky Sports renders schedule as a list of fight cards
    cards = soup.find_all("div", class_=lambda c: c and "fixture" in c.lower())

    for card in cards:
        try:
            fighters = card.find_all(class_=lambda c: c and "team" in c.lower())
            if len(fighters) < 2:
                continue

            boxer_a = fighters[0].get_text(strip=True)
            boxer_b = fighters[1].get_text(strip=True)
            date_el = card.find(class_=lambda c: c and "date" in c.lower())
            date_str = parse_date(date_el.get_text(strip=True)) if date_el else None
            venue_el = card.find(class_=lambda c: c and "venue" in c.lower())

            row = {
                "scheduled_date": date_str or date.today().isoformat(),
                "status":         "confirmed",
                "source_url":     url,
            }
            if venue_el:
                row["venue"] = venue_el.get_text(strip=True)

            # Try to link to existing boxer records
            for name, field in [(boxer_a, "boxer_a_id"), (boxer_b, "boxer_b_id")]:
                match = sb.table("boxers").select("id").ilike("full_name", f"%{name}%").execute()
                if match.data:
                    row[field] = match.data[0]["id"]

            sb.table("scheduled_fights").insert(row).execute()
            inserted += 1
            log.info(f"Scheduled: {boxer_a} vs {boxer_b} on {date_str}")

        except Exception as e:
            log.debug(f"Skipping schedule row: {e}")
            continue

    log.info(f"Inserted {inserted} scheduled fights")
    return inserted


# ── Manual data entry helpers ────────────────────────────────────────────────
def add_boxer_manually(sb: Client, data: dict) -> str:
    """
    Insert a boxer manually.

    Example:
        add_boxer_manually(sb, {
            "full_name": "Tyson Fury",
            "nickname": "The Gypsy King",
            "nationality": "British",
            "date_of_birth": "1988-08-12",
            "weight_class": "Heavyweight",
            "stance": "Orthodox",
        })
    """
    result = sb.table("boxers").insert(data).execute()
    boxer_id = result.data[0]["id"]
    log.info(f"Manually inserted boxer: {data['full_name']} ({boxer_id})")
    return boxer_id


def add_scheduled_fight_manually(sb: Client, data: dict) -> str:
    """
    Insert a scheduled fight manually.

    Example:
        add_scheduled_fight_manually(sb, {
            "scheduled_date": "2025-04-12",
            "boxer_a_id": "<uuid>",
            "boxer_b_id": "<uuid>",
            "title_fought": "IBF Heavyweight",
            "venue": "Wembley Stadium",
            "location": "London, UK",
            "broadcast": "Sky Sports",
            "status": "confirmed",
        })
    """
    result = sb.table("scheduled_fights").insert(data).execute()
    fight_id = result.data[0]["id"]
    log.info(f"Manually inserted scheduled fight: {fight_id}")
    return fight_id


# ── Main entrypoint ──────────────────────────────────────────────────────────
def main():
    sb = get_supabase()
    log.info("Connected to Supabase ✓")

    # ── Example: scrape a batch of boxers from Wikipedia ──
    boxer_wikipedia_pages = [
        "https://en.wikipedia.org/wiki/Anthony_Joshua",
        "https://en.wikipedia.org/wiki/Tyson_Fury",
        "https://en.wikipedia.org/wiki/Oleksandr_Usyk",
        "https://en.wikipedia.org/wiki/Deontay_Wilder",
        "https://en.wikipedia.org/wiki/Joe_Joyce_(boxer)",
    ]

    for url in boxer_wikipedia_pages:
        boxer_id = scrape_boxer_from_wikipedia(url, sb)
        if boxer_id:
            scrape_fight_history_from_wikipedia(url, boxer_id, sb)
        time.sleep(2)

    # ── Scrape upcoming schedule ──
    scrape_upcoming_schedule_sky(sb)

    log.info("Scrape complete ✓")


if __name__ == "__main__":
    main()
