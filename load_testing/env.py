# standard imports
import os


# Errors
class ConfigError(Exception):
    """Raised when test configuration files are missing or invalid."""


ALB_HOST = "http://ticketing-alb-1896570314.us-west-2.elb.amazonaws.com"
# Optionally set these to override the ALB for a single service.
PURCHASE_SERVICE_HOST = None
QUERY_SERVICE_HOST = None


def _normalize_host(host: str | None) -> str | None:
    if not host:
        return None
    return host.rstrip('/')


def purchase_host() -> str:
    """Return the effective purchase service host.

    Priority: PURCHASE_SERVICE_HOST > ALB_HOST > None
    """
    ph = PURCHASE_SERVICE_HOST or ALB_HOST
    return _normalize_host(ph) if ph else None


def query_host() -> str:
    """Return the effective query service host.

    Priority: QUERY_SERVICE_HOST > ALB_HOST > None
    """
    qh = QUERY_SERVICE_HOST or ALB_HOST
    return _normalize_host(qh) if qh else None


# Resource file helpers ----------------------------------------------------


def repo_root() -> str:
    """Return an absolute path to the repository root (one level up from
    the `load_testing` package). This makes file paths robust regardless of
    the CWD used to run locust.
    """
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def resources_root(service_name: str = "PurchaseService") -> str:
    """Return the absolute path to a service's resources folder.

    The default assumes Maven style java service layout located at:
      <repo_root>/<service_name>/src/main/resources

    These are configurable by callers and can be overridden with
    environment variables if needed (see: VENUES_FILE and EVENTS_FILE below).
    """
    return os.path.join(repo_root(), service_name, "src", "main", "resources")


def venues_file() -> str:
    """Return the absolute path to the venues.yml file.

    Priority: env var VENUES_FILE > default repo path
    """
    env = os.getenv("VENUES_FILE")
    if env:
        return os.path.abspath(env)
    return os.path.join(resources_root("PurchaseService"), "venues.yml")


def events_file() -> str:
    """Return the absolute path to the events.yml file.

    Priority: env var EVENTS_FILE > default repo path
    """
    env = os.getenv("EVENTS_FILE")
    if env:
        return os.path.abspath(env)
    return os.path.join(resources_root("PurchaseService"), "events.yml")


def load_yaml_file(path: str) -> dict:
    """Load a YAML file and return the parsed dictionary.

    Raises FileNotFoundError if the file does not exist and ValueError if the
    file can't be parsed as YAML.
    """
    # Use a dedicated config error to make callers' handling consistent
    if not path:
        raise ConfigError(f"Config path not provided: {path}")
    if not os.path.exists(path):
        raise ConfigError(f"Config file not found: {path}")
    import yaml

    with open(path, "r") as f:
        try:
            data = yaml.safe_load(f) or {}
        except Exception as e:
            raise ConfigError(f"Error parsing YAML {path}: {e}")
    return data


def load_venues() -> dict:
    """Return parsed contents of the venues.yml as a dict.

    Uses VENUES_FILE env override if present.
    """
    path = venues_file()
    data = load_yaml_file(path)
    return data.get("venues", {}).get("map", {})


def load_events() -> dict:
    """Return parsed contents of events.yml as a dict.

    Uses EVENTS_FILE env override if present.
    """
    path = events_file()
    data = load_yaml_file(path)
    return data.get("events", {})
