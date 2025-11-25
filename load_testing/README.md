# load_testing — notes and conventions

This folder contains Locust performance tests used by the project. Recent
changes refactored configuration and file-path handling to make tests
robust regardless of the current working directory and to unify error
handling.

Key conventions
---------------
- Centralized configuration helpers live in `load_testing/env.py`.
  - Host helpers: `purchase_host()` and `query_host()` — prefer these instead
    of reading ALB_HOST / PURCHASE_SERVICE_HOST / QUERY_SERVICE_HOST directly.
  - Resource helpers: `venues_file()` and `events_file()` return absolute
    paths for `venues.yml` and `events.yml`. These support environment
    overrides via `VENUES_FILE` / `EVENTS_FILE`.
  - YAML helpers: `load_venues()` and `load_events()` parse and return the
    contents of those files.
  - Errors: malformed/missing configuration raises `ConfigError` from the
    env module.

Why this matters
-----------------
- Avoids brittle relative path assumptions (e.g. running Locust from
  `load_testing/` vs repository root).
- Avoids each locust script duplicating YAML parsing / path logic.
- Unifies error handling: locust files now catch configuration errors and
  call `environment.runner.quit()` instead of calling `exit()` — this keeps
  the test runner (UI or headless) responsible for shutting down.

How to override resources
-------------------------
To point tests at alternative YAML files (useful in CI or nonstandard
layouts), set the following environment variables before running Locust:

```bash
export VENUES_FILE=/absolute/path/to/venues.yml
export EVENTS_FILE=/absolute/path/to/events.yml
locust -f load_testing/locustfile_staggered.py
```

How errors are handled
----------------------
If a configuration file is missing or invalid, the env helpers raise
`ConfigError` and the locust test code will log an error and request the
Locust runner to quit. This avoids abrupt `sys.exit()` calls and makes the
behavior friendlier for UI and CI environments.

If you want help wiring a quick `run_locust.sh` wrapper (headless + path
overrides) or adding a `requirements.txt` for `locust, pyyaml`, I can add
that now.

Quick-start helper
------------------
I added a helper script `run_locust.sh` which creates a venv at
`load_testing/.venv`, installs required packages from
`load_testing/requirements.txt` and then runs locust. Example usage:

```bash
# headless smoke test
cd <repo-root>
load_testing/run_locust.sh --file locustfile_event1_5requests.py --headless \
  --users 1 --spawn 1 --time 30s

# start the UI
load_testing/run_locust.sh
```

Note: the script installs two dependencies `locust` and `PyYAML` into the
local venv so your system Python remains unchanged.

ALB defaults
------------
This test runner uses the ALB endpoint by default. The ALB endpoint is
defined at the top of `load_testing/env.py` in the `ALB_HOST` constant and
the runner will export `ALB_HOST`, `PURCHASE_SERVICE_HOST` and
`QUERY_SERVICE_HOST` so the locust tests always target the load balancer.

Examples (recommended):

```bash
# default (uses ALB defined in load_testing/env.py)
load_testing/run_locust.sh --file locustfile_event1_5requests.py --headless --users 1 --spawn 1 --time 30s

# UI mode (set number and spawn rate in Locust GUI)
load_testing/run_locust.sh
```
