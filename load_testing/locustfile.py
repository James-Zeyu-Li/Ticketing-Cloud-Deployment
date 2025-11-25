
import os
import yaml
import random
import math
import gevent
from queue import Queue, Empty
from locust import HttpUser, task, constant, events

# --- Configuration ---

# Host configuration: prefer a local `load_testing/env.py` when available.
# Fall back to environment variables if the file is not present.
env_cfg = None
try:
    from load_testing import env as env_cfg  # type: ignore
except Exception:
    try:
        import env as env_cfg  # type: ignore
    except Exception:
        env_cfg = None

if env_cfg:
    PURCHASE_HOST = env_cfg.purchase_host()
    QUERY_HOST = env_cfg.query_host()
    PURCHASE_HOST = PURCHASE_HOST or os.getenv(
        "PURCHASE_SERVICE_HOST",
        "http://localhost:8081",
    )
    QUERY_HOST = QUERY_HOST or os.getenv(
        "QUERY_SERVICE_HOST",
        "http://localhost:8082",
    )
else:
    ALB_HOST = os.getenv("ALB_HOST")
    if ALB_HOST:
        ALB_HOST = ALB_HOST.rstrip('/')
        PURCHASE_HOST = os.getenv("PURCHASE_SERVICE_HOST", ALB_HOST)
        QUERY_HOST = os.getenv("QUERY_SERVICE_HOST", ALB_HOST)
    else:
        PURCHASE_HOST = os.getenv(
            "PURCHASE_SERVICE_HOST",
            "http://localhost:8081",
        )
        QUERY_HOST = os.getenv(
            "QUERY_SERVICE_HOST",
            "http://localhost:8082",
        )

# Target Event and Venue for this test
TARGET_EVENT_ID = "Event1"
TARGET_VENUE_ID = "Venue1"
if env_cfg and hasattr(env_cfg, "venues_file"):
    VENUES_FILE_PATH = env_cfg.venues_file()
else:
    REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    VENUES_FILE_PATH = os.path.join(
        REPO_ROOT, "PurchaseService", "src", "main", "resources", "venues.yml"
    )

# Test shaping
USERS_TARGET = 2000          # run locust with -u 2000 to match
SEATS_PER_USER = 78         # unique seats per user
DUPLICATE_RATIO = 0.2       # extra duplicate attempts (20%)

# Global queue to hold per-user seat slices. Populated on startup.
SEAT_SLICE_QUEUE: "Queue[list[dict]]" = Queue()

# --- Utility Functions ---


def load_venue_layout(venue_id: str):
    """
    Loads the layout for a specific venue from the venues.yml file.
    """
    try:
        if env_cfg and hasattr(env_cfg, "load_venues"):
            venues_map = env_cfg.load_venues()
            venue_config = venues_map.get(venue_id)
        else:
            with open(VENUES_FILE_PATH, 'r') as f:
                venues_data = yaml.safe_load(f) or {}
                venue_map = venues_data.get("venues", {}).get("map", {})
                venue_config = venue_map.get(venue_id)

        if not venue_config:
            raise Exception(
                f"VenueID '{venue_id}' not found in {VENUES_FILE_PATH}"
            )

        zones_config = venue_config.get("zones")
        return {
            "zone_count": zones_config.get("zone-count", 0),
            "row_count": zones_config.get("row-count", 0),
            "col_count": zones_config.get("col-count", 0),
        }
    except FileNotFoundError:
        raise Exception(
            f"{VENUES_FILE_PATH} not found. "
            "Make sure you are running locust from the project root."
        )
    except Exception as e:
        raise Exception(f"Error parsing {VENUES_FILE_PATH}: {e}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """
    This function is called once when the test starts.
    It generates all possible seats and puts them into the shared queue.
    """
    print("--- Populating seat queue ---")
    try:
        layout = load_venue_layout(TARGET_VENUE_ID)
    except Exception as e:
        print(f"FATAL: unable to load venue layout: {e}")
        environment.runner.quit()
        return
    zone_count = layout["zone_count"]
    row_count = layout["row_count"]
    col_count = layout["col_count"]

    if zone_count == 0:
        print("FATAL: Venue layout has 0 zones. Stopping test.")
        environment.runner.quit()
        return

    total_capacity = zone_count * row_count * col_count
    seats_per_zone = row_count * col_count

    def idx_to_seat(idx: int):
        zone_idx = idx // seats_per_zone
        rem = idx % seats_per_zone
        row_idx = rem // col_count  # 0-based
        col_idx = rem % col_count
        # rows as letters A, B, ...
        row_label = chr(ord('A') + row_idx)
        return {
            "zoneId": zone_idx + 1,
            "row": row_label,
            "column": str(col_idx + 1),
        }

    # Build per-user slices of SEATS_PER_USER seats
    slice_count = 0
    for start in range(0, total_capacity, SEATS_PER_USER):
        slice_seats = []
        for idx in range(start, min(start + SEATS_PER_USER, total_capacity)):
            slice_seats.append(idx_to_seat(idx))
        if not slice_seats:
            continue
        SEAT_SLICE_QUEUE.put(slice_seats)
        slice_count += 1

    print(
        f"--- Seat slices populated: {slice_count} slices, {total_capacity} seats total for Venue '{TARGET_VENUE_ID}' ---")


# --- Locust User Class ---

class SequentialTicketPurchaser(HttpUser):
    """
    Each user owns a unique slice of SEATS_PER_USER seats. Total attempts per
    user = SEATS_PER_USER * (1 + DUPLICATE_RATIO). 20% of attempts randomly
    reuse a previously attempted seat (to simulate duplicates), the rest consume
    a fresh seat from the user's slice. After attempts are exhausted, the user
    stops.
    """
    wait_time = constant(0.5)
    host = PURCHASE_HOST  # Default host for the client

    def on_start(self):
        try:
            self.slice = SEAT_SLICE_QUEUE.get_nowait()
        except Empty:
            print("Seat slice queue empty. Stopping user.")
            self.stop(True)
            return

        random.shuffle(self.slice)  # randomize within the slice
        self.attempts_total = math.ceil(SEATS_PER_USER * (1 + DUPLICATE_RATIO))
        self.attempts_done = 0
        self.attempted_seats: list[dict] = []
        print(
            f"[Locust] User got slice size={len(self.slice)} attempts={self.attempts_total}")

    @task
    def purchase_ticket_sequentially(self):
        if not hasattr(self, "slice"):
            self.stop(True)
            return

        if self.attempts_done >= self.attempts_total:
            self.stop(True)
            return

        use_duplicate = random.random() < DUPLICATE_RATIO and self.attempted_seats
        if use_duplicate:
            seat_to_purchase = random.choice(self.attempted_seats)
        else:
            if not self.slice:
                # no fresh seats left; fall back to duplicate
                if self.attempted_seats:
                    seat_to_purchase = random.choice(self.attempted_seats)
                else:
                    print("No seats available; stopping user.")
                    self.stop(True)
                    return
            else:
                seat_to_purchase = self.slice.pop()
                self.attempted_seats.append(seat_to_purchase)

        request_body = {
            "eventId": TARGET_EVENT_ID,
            "venueId": TARGET_VENUE_ID,
            **seat_to_purchase
        }

        with self.client.post(
            "/purchase/api/v1/tickets",
            json=request_body,
            catch_response=True,
            name="/api/v1/tickets [purchase]"
        ) as response:
            if response.status_code == 201:
                response.success()
                # 50% chance to verify the ticket
                if random.random() < 0.5:
                    ticket_id = response.json().get("ticketId")
                    if ticket_id:
                        # wait before query to simulate user delay
                        gevent.sleep(10.0)
                        with self.client.get(
                            f"{QUERY_HOST}/query/api/v1/tickets/{ticket_id}",
                            name="/api/v1/tickets/{ticketId} [query]",
                            catch_response=True,
                        ) as q_resp:
                            if q_resp.status_code == 200:
                                q_resp.success()
                            else:
                                q_resp.failure(
                                    f"Query failed: {q_resp.status_code} body={q_resp.text}")
            else:
                status_code = response.status_code
                msg = (
                    "Failed to purchase seat "
                    + str(seat_to_purchase)
                    + ". Status: "
                    + str(status_code)
                )
                response.failure(msg)

        self.attempts_done += 1
