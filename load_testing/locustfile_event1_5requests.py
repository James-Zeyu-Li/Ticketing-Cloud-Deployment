"""
Deterministic Locust test: 50 users total, each purchases 2 seats from a shared
deterministic queue starting at seat 1-A-6 (zone=1, row=A, col=6). Each seat
gets purchase + query; user stops after 2 seats or queue exhaustion.
"""

import os
import yaml
import random
import gevent
from queue import Queue, Empty
from locust import HttpUser, task, constant

# Always default to ALB from env.py; no local fallbacks
from load_testing import env as env_cfg  # type: ignore

PURCHASE_HOST = env_cfg.purchase_host()
QUERY_HOST = env_cfg.query_host()
if not PURCHASE_HOST:
    raise SystemExit("ALB host not set in env.py or env vars.")

# Files with venue definitions
VENUES_FILE_PATH = env_cfg.venues_file()

# Target constants
TARGET_EVENT_ID = "Event1"
TARGET_VENUE_ID = "Venue1"
FIXED_ZONE_ID = 1
START_COL = 6  # start at column 6 on row A
TOTAL_SEATS = 100  # total seats to serve across all users

# Shared seat queue ---------------------------------------------------------


def load_venue_layout(venue_id: str):
    venues_data = env_cfg.load_venues()
    venue_config = venues_data.get(venue_id)
    if not venue_config:
        raise FileNotFoundError(venue_id)
    zones_config = venue_config.get("zones", {})
    return {
        "zone_count": zones_config.get("zone-count", 0),
        "row_count": zones_config.get("row-count", 0),
        "col_count": zones_config.get("col-count", 0),
    }


# Shared seat queue ---------------------------------------------------------
SEAT_QUEUE: "Queue[tuple[int, str, str]]" = Queue()


def _build_seat_queue():
    layout = load_venue_layout(TARGET_VENUE_ID)
    seats = []
    row_idx = 0  # A-indexed
    col = START_COL
    for _ in range(TOTAL_SEATS):
        if col > layout["col_count"]:
            col = 1
            row_idx += 1
        if row_idx >= layout["row_count"]:
            break
        row = chr(ord("A") + row_idx)
        seats.append((FIXED_ZONE_ID, row, str(col)))
        col += 1
    if len(seats) < TOTAL_SEATS:
        print(
            f"[Locust] WARNING: only generated {len(seats)} seats due to venue limits.")
    for s in seats:
        SEAT_QUEUE.put(s)


# Build queue at import time
try:
    _build_seat_queue()
except Exception as e:  # pragma: no cover
    print(f"[Locust] FATAL: failed to build seat queue: {e}")


class FiveRequestsUser(HttpUser):
    """Each user picks 2 seats from the shared queue; purchase + query for each, then stop."""
    wait_time = constant(0.5)
    host = PURCHASE_HOST

    def on_start(self):
        try:
            self.layout = load_venue_layout(TARGET_VENUE_ID)
        except Exception as e:
            print(f"FATAL: Venue '{TARGET_VENUE_ID}' not found. Error: {e}")
            if hasattr(self.environment, "runner") and self.environment.runner:
                self.environment.runner.quit()
            return

        if (
            self.layout["zone_count"] <= 0
            or self.layout["row_count"] <= 0
            or self.layout["col_count"] <= 0
        ):
            print("FATAL: Invalid venue layout (zero dimensions). Stopping test.")
            if hasattr(self.environment, "runner") and self.environment.runner:
                self.environment.runner.quit()
            return

        self.seats_remaining = 2
        print(
            f"[Locust] Starting user with host={self.host}, query_host={QUERY_HOST}, venue={TARGET_VENUE_ID}, seats_remaining={self.seats_remaining}")

    @task
    def send_purchase_and_query(self):
        if getattr(self, "seats_remaining", 0) <= 0:
            self.stop(True)
            return

        try:
            zone, row, column = SEAT_QUEUE.get_nowait()
        except Empty:
            print("[Locust] Seat queue empty; stopping user.")
            self.stop(True)
            return

        request_body = {
            "eventId": TARGET_EVENT_ID,
            "venueId": TARGET_VENUE_ID,
            "zoneId": zone,
            "row": row,
            "column": column,
        }

        with self.client.post(
            "/purchase/api/v1/tickets",
            json=request_body,
            catch_response=True,
            name="/purchase/api/v1/tickets [event1-venue1]",
        ) as response:
            if response.status_code == 201:
                response.success()
                ticket_id = response.json().get("ticketId")
                print(
                    f"[Locust] Purchased ticketId={ticket_id} seat={zone}-{row}-{column} status=201")
                if ticket_id and QUERY_HOST:
                    gevent.sleep(10.0)  # pause before checking
                    with self.client.get(
                        f"{QUERY_HOST}/query/api/v1/tickets/{ticket_id}",
                        name="/query/api/v1/tickets/{ticketId}",
                        catch_response=True,
                    ) as q_resp:
                        if q_resp.status_code == 200:
                            q_resp.success()
                            print(f"[Locust] Query OK ticketId={ticket_id}")
                        else:
                            q_resp.failure(
                                f"Query failed: {q_resp.status_code} body={q_resp.text}")
                            print(
                                f"[Locust] Query failed ticketId={ticket_id} status={q_resp.status_code} body={q_resp.text}")
            else:
                response.failure(f"Purchase failed: {response.status_code}")

        self.seats_remaining -= 1
