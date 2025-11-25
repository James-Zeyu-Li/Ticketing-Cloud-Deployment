#!/usr/bin/env zsh
# Run Locust inside a local Python virtualenv and provide useful defaults.
# Usage:
#   ./run_locust.sh [--file LOCUSTFILE] [--headless] [--users N] [--spawn R] [--time DURATION]
# Examples:
#   # Create venv, install deps, and open Locust UI for the default file
#   ./run_locust.sh
#
#   # Headless quick smoke run
#   ./run_locust.sh --file locustfile_event1_5requests.py --headless --users 1 --spawn 1 --time 30s

set -euo pipefail

BASE_DIR=$(cd "$(dirname "$0")" && pwd)
VENV_DIR="$BASE_DIR/.venv"
REQ_FILE="$BASE_DIR/requirements.txt"

# Defaults
LOCUSTFILE="locustfile_event1_5requests.py"
HEADLESS=0
USERS=1
SPAWN=1
TIME="30s"

function usage() {
  cat <<EOF
Usage: $0 [--file LOCUSTFILE] [--headless] [--users N] [--spawn R] [--time DURATION]

Defaults: --file $LOCUSTFILE --users $USERS --spawn $SPAWN --time $TIME
Examples:
  $0
  $0 --file locustfile_staggered.py --headless --users 10 --spawn 1 --time 1m

Environment overrides (optional):
  VENUES_FILE=/abs/path/to/venues.yml
  EVENTS_FILE=/abs/path/to/events.yml
  PURCHASE_SERVICE_HOST=http://localhost:8081
  QUERY_SERVICE_HOST=http://localhost:8082
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      LOCUSTFILE="$2"; shift 2;;
    --headless)
      HEADLESS=1; shift;;
    --users)
      USERS="$2"; shift 2;;
    --spawn)
      SPAWN="$2"; shift 2;;
    --time)
      TIME="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    # (no ALB flags - script always uses ALB defined in load_testing/env.py)
    *)
      echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

echo "Using python: $(command -v python3)"

if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating venv in $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

echo "Activating venv"
source "$VENV_DIR/bin/activate"

echo "Installing requirements from $REQ_FILE"
python -m pip install --upgrade pip >/dev/null
python -m pip install -r "$REQ_FILE"

cd "$BASE_DIR"

# If the script is configured to prefer ALB, set ALB_HOST from the
# load_testing.env default unless the user already provided PURCHASE_SERVICE_HOST
# or explicitly provided an ALB override. This ensures tests use the load
# balancer endpoint by default.
# Always prefer the ALB defined in load_testing/env.py and export it so
# tests cannot accidentally target local services.
DEFAULT_ALB=$(python3 - <<PY
import importlib.util, json, sys
# load the env.py module from the repo load_testing folder directly
spec = importlib.util.spec_from_file_location('envfile', 'env.py')
env = importlib.util.module_from_spec(spec)
try:
  spec.loader.exec_module(env)
  print(getattr(env, 'ALB_HOST', '') or '')
except Exception:
  print('')
PY
)

if [[ -n "$DEFAULT_ALB" ]]; then
  export ALB_HOST="$DEFAULT_ALB"
  export PURCHASE_SERVICE_HOST="$DEFAULT_ALB"
  export QUERY_SERVICE_HOST="$DEFAULT_ALB"
  echo "Using ALB endpoints: $ALB_HOST (exported PURCHASE_SERVICE_HOST, QUERY_SERVICE_HOST)"
else
  echo "Warning: no ALB found in load_testing/env.py; ensure ALB_HOST is set or set PURCHASE_SERVICE_HOST/QUERY_SERVICE_HOST env vars"
fi

if [[ "$HEADLESS" -eq 1 ]]; then
  echo "Running Locust headless: file=$LOCUSTFILE users=$USERS spawn_rate=$SPAWN time=$TIME"
  locust -f "$BASE_DIR/$LOCUSTFILE" --headless -u $USERS -r $SPAWN -t $TIME --loglevel INFO
else
  echo "Launching Locust UI with file=$LOCUSTFILE"
  locust -f "$BASE_DIR/$LOCUSTFILE"
fi
