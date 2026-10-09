#!/usr/bin/env python3
"""Validate measured MOSAIC zoomed-out performance evidence."""
import argparse
import json
from pathlib import Path
import re
import sys

MINIMUM_FPS = 25.0
MINIMUM_DURATION_SECONDS = 600


def require_text(data, key):
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{key} must be a non-empty string")
    return value.strip()


def validate(data):
    if data.get("schema_version") != 1:
        raise ValueError("schema_version must be 1")
    if data.get("gate") != "minimum-25-fps-zoomed-out":
        raise ValueError("gate must be minimum-25-fps-zoomed-out")
    for key in ("measured_at", "engine_build", "map", "settings_profile", "gpu", "camera", "evidence_file"):
        require_text(data, key)
    if data["camera"] != "fully-zoomed-out":
        raise ValueError("camera must be fully-zoomed-out")
    commit = require_text(data, "source_commit")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("source_commit must be a full 40-character Git commit SHA")
    resolution = data.get("resolution")
    if not isinstance(resolution, dict) or not all(isinstance(resolution.get(k), int) and resolution[k] > 0 for k in ("width", "height")):
        raise ValueError("resolution width and height must be positive integers")
    load = data.get("load")
    if not isinstance(load, dict) or not all(isinstance(load.get(k), int) and load[k] >= 0 for k in ("city_buildings", "units_total")):
        raise ValueError("load city_buildings and units_total must be non-negative integers")
    duration = data.get("duration_seconds")
    minimum = data.get("minimum_fps")
    if not isinstance(duration, (int, float)) or duration < MINIMUM_DURATION_SECONDS:
        raise ValueError(f"duration_seconds must be at least {MINIMUM_DURATION_SECONDS}")
    if not isinstance(minimum, (int, float)):
        raise ValueError("minimum_fps must be numeric")
    result = dict(data)
    result["status"] = "passed" if minimum >= MINIMUM_FPS else "failed"
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("evidence", type=Path)
    args = parser.parse_args(argv)
    try:
        result = validate(json.loads(args.evidence.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError, ValueError) as error:
        parser.exit(2, f"Performance evidence invalid: {error}\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
