#!/usr/bin/env python3
"""
yikely_simulator.py
--------------------
Simulates GPS tracker updates for the Yike.ly bike fleet.
Writes coordinate updates directly to the yellow_bike_coordinates table
at the configured interval.

When real AirTag/Traccar trackers are integrated, simply stop this script.
The PHP API, REST endpoints, and iPhone app require zero changes.

Usage:
    pip3 install mysql-connector-python
    python3 yikely_simulator.py
"""

import time
import random
import logging
import signal
import sys
import mysql.connector
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DB_CONFIG = {
    "host":     "localhost",
    "port":     3306,
    "database": "bike_project",   # ← replace with actual DB name
    "user":     "root",                  # ← or a limited user if one exists
    "password": "cs498",    # ← replace with actual password
}

UPDATE_INTERVAL_SECONDS = 30
MAX_DRIFT_DEGREES       = 0.00008   # ~8 meters per update

# Eckerd College campus bounding box — bikes won't drift outside this
CAMPUS_BOUNDS = {
    "lat_min": 27.7100, "lat_max": 27.7200,
    "lon_min": -82.6930, "lon_max": -82.6810,
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("yikely_simulator.log"),
    ]
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Graceful shutdown
# ---------------------------------------------------------------------------

running = True

def handle_shutdown(sig, frame):
    global running
    log.info("Shutdown signal received — stopping simulator.")
    running = False

signal.signal(signal.SIGINT,  handle_shutdown)
signal.signal(signal.SIGTERM, handle_shutdown)

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


def fetch_bikes(conn):
    """Fetches all bikes from yellow_bike_coordinates."""
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, bike_id, name, latitude, longitude, state
        FROM yellow_bike_coordinates
    """)
    rows = cursor.fetchall()
    cursor.close()
    return rows


def update_coordinates(conn, row_id, lat, lon):
    """Updates lat/lon and timestamp for a given row id."""
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE yellow_bike_coordinates
        SET latitude  = %s,
            longitude = %s,
            timestamp = %s
        WHERE id = %s
    """, (lat, lon, datetime.utcnow(), row_id))
    conn.commit()
    cursor.close()

# ---------------------------------------------------------------------------
# Movement simulation
# ---------------------------------------------------------------------------

def clamp(value, lo, hi):
    return max(lo, min(hi, value))


def simulate_drift(lat, lon, state):
    """
    Moves a bike based on its state:
      available   — normal random walk (bike is being ridden/moved)
      needsRepair — tiny jitter only (sitting broken somewhere)
      hidden      — no movement (on a workbench in the shop)

    Swap this function out for real GPS polling when trackers go live.
    """
    if state == "hidden":
        return lat, lon

    scale = 0.05 if state == "needsRepair" else 1.0

    new_lat = clamp(lat + random.gauss(0, MAX_DRIFT_DEGREES) * scale,
                    CAMPUS_BOUNDS["lat_min"], CAMPUS_BOUNDS["lat_max"])
    new_lon = clamp(lon + random.gauss(0, MAX_DRIFT_DEGREES) * scale,
                    CAMPUS_BOUNDS["lon_min"], CAMPUS_BOUNDS["lon_max"])
    return new_lat, new_lon

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def run():
    log.info("=== Yike.ly GPS Simulator starting ===")
    log.info(f"Table: yellow_bike_coordinates | Interval: {UPDATE_INTERVAL_SECONDS}s")

    # Verify DB connection before entering loop
    try:
        conn = get_connection()
        log.info("Database connection successful.")
        conn.close()
    except mysql.connector.Error as e:
        log.error(f"Cannot connect to database: {e}")
        log.error("Check DB_CONFIG and ensure MariaDB is running.")
        sys.exit(1)

    cycle = 0

    while running:
        cycle += 1
        log.info(f"--- Cycle {cycle} ---")

        try:
            conn = get_connection()
            bikes = fetch_bikes(conn)

            if not bikes:
                log.warning("No rows found in yellow_bike_coordinates.")

            for bike in bikes:
                new_lat, new_lon = simulate_drift(
                    float(bike["latitude"]),
                    float(bike["longitude"]),
                    bike["state"] or "available"
                )
                update_coordinates(conn, bike["id"], new_lat, new_lon)
                log.debug(f"  {bike['name']} (bike_id={bike['bike_id']}): "
                          f"({new_lat:.6f}, {new_lon:.6f}) [{bike['state']}]")

            log.info(f"Updated {len(bikes)} bikes.")
            conn.close()

        except mysql.connector.Error as e:
            log.error(f"Database error on cycle {cycle}: {e}")
            try: conn.close()
            except: pass

        except Exception as e:
            log.error(f"Unexpected error on cycle {cycle}: {e}")

        # Interruptible sleep — responds to shutdown within 1 second
        for _ in range(UPDATE_INTERVAL_SECONDS):
            if not running:
                break
            time.sleep(1)

    log.info("=== Simulator stopped cleanly ===")


if __name__ == "__main__":
    run()
