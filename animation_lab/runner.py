"""Create and launch disposable Mosaic animation observations.

The source game and its configuration are read only inputs. All engine output,
temporary Lua instrumentation and evidence are confined to a new run directory.
"""
from __future__ import annotations

import copy
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import time
import uuid
from typing import Any


SCHEMA_VERSION = 1
VIEWS = ("front", "side", "rear", "threequarter")
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
FUNCTION_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)?$")
RESERVED_SCRIPT_FUNCTIONS = {"load", "loadstring", "loadfile", "dofile", "include", "require", "getfenv", "setfenv", "setmetatable", "collectgarbage", "pcall", "xpcall"}
ACTION_FIELDS = {
    "move": {"type", "unit", "x", "z"},
    "stop": {"type", "unit"},
    "call": {"type", "unit", "function", "args"},
    "attach": {"type", "unit", "transporter", "piece"},
    "detach": {"type", "unit", "x", "z"},
    "attack": {"type", "unit", "target"},
    "destroy": {"type", "unit"},
    "expect_death": {"type", "unit"},
}
CHECK_FIELDS = {
    "displaced": {"type", "unit", "min"},
    "transported": {"type", "unit", "transporter"},
    "detached": {"type", "unit"},
    "alive": {"type", "unit"},
    "destroyed": {"type", "unit"},
}
IGNORED_SOURCE_NAMES = {".git", "__pycache__", ".pytest_cache", ".DS_Store"}
REQUIRED_GAME_DIRS = ("scripts", "luarules", "luaui", "units", "gamedata", "objects3d", "unittextures")


class LabError(ValueError):
    """An actionable validation or execution failure."""


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def digest_file(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True, allow_nan=False) + "\n", encoding="utf-8")
    temporary.replace(path)


def _object(value: Any, label: str, allowed: set[str], required: set[str] = frozenset()) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise LabError(f"{label} must be an object")
    unknown = set(value) - allowed
    missing = required - set(value)
    if unknown:
        raise LabError(f"{label}: unknown fields {', '.join(sorted(unknown))}")
    if missing:
        raise LabError(f"{label}: missing fields {', '.join(sorted(missing))}")
    return value


def _number(value: Any, label: str, low: float, high: float, integer: bool = False) -> int | float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise LabError(f"{label} must be a finite number")
    if integer and (not isinstance(value, int)):
        raise LabError(f"{label} must be an integer")
    if not low <= value <= high:
        raise LabError(f"{label} must be between {low} and {high}")
    return value


def _text(value: Any, label: str, identifier: bool = False) -> str:
    if not isinstance(value, str) or not value or len(value) > 256 or any(ord(c) < 32 for c in value):
        raise LabError(f"{label} must be a nonempty text value of at most 256 characters without controls")
    if identifier and not IDENTIFIER.fullmatch(value):
        raise LabError(f"{label} must contain only an identifier (letters, digits and underscores)")
    return value


def _tdf_value(value: Any, label: str) -> str:
    text = str(value) if not isinstance(value, bool) else ("1" if value else "0")
    if not text or any(c in text for c in ";{}[]\r\n\x00"):
        raise LabError(f"{label} contains a startscript delimiter or is empty")
    return text


def _arguments(value: Any, names: set[str], label: str, depth: int = 0) -> None:
    if depth > 6:
        raise LabError(f"{label}: argument nesting exceeds six levels")
    if value is None:
        raise LabError(f"{label}: null arguments are ambiguous in Lua; use an explicit value")
    if isinstance(value, (str, bool)):
        if isinstance(value, str):
            _text(value, label)
    elif isinstance(value, (int, float)):
        _number(value, label, -1e9, 1e9)
    elif isinstance(value, list):
        if len(value) > 64:
            raise LabError(f"{label}: at most 64 argument entries are supported")
        for index, item in enumerate(value):
            _arguments(item, names, f"{label}[{index}]", depth + 1)
    elif isinstance(value, dict):
        _object(value, label, {"ref"}, {"ref"})
        _text(value["ref"], f"{label}.ref", True)
        if value["ref"] not in names:
            raise LabError(f"{label}: unknown unit reference {value['ref']!r}")
    else:
        raise LabError(f"{label}: arguments must be scalars, arrays, or {{'ref': 'unitname'}}")


def validate_scenario(raw: Any) -> dict[str, Any]:
    """Validate declarative actions; return a normalized independent copy."""
    scenario = copy.deepcopy(raw)
    _object(scenario, "scenario", {"schema_version", "name", "description", "fixture_kind", "units", "phases", "capture", "camera", "warmup_frames", "modoptions"}, {"schema_version", "name", "units", "phases"})
    if type(scenario["schema_version"]) is not int or scenario["schema_version"] != SCHEMA_VERSION:
        raise LabError(f"scenario.schema_version must be {SCHEMA_VERSION}")
    _text(scenario["name"], "scenario.name")
    if "description" in scenario:
        _text(scenario["description"], "scenario.description")
    if "fixture_kind" in scenario:
        _text(scenario["fixture_kind"], "scenario.fixture_kind")
    units = scenario["units"]
    if not isinstance(units, list) or not 1 <= len(units) <= 16:
        raise LabError("scenario.units must contain 1 to 16 units")
    names: set[str] = set()
    for index, unit in enumerate(units):
        label = f"units[{index}]"
        _object(unit, label, {"name", "def", "team", "x", "z", "facing", "pieces", "piece_geometry", "stationary_fixture"}, {"name", "def"})
        name = _text(unit["name"], f"{label}.name", True)
        _text(unit["def"], f"{label}.def", True)
        if name in names:
            raise LabError(f"duplicate unit name: {name}")
        names.add(name)
        _number(unit.setdefault("team", 0), f"{label}.team", 0, 1, True)
        _number(unit.setdefault("facing", 0), f"{label}.facing", 0, 3, True)
        for coordinate in ("x", "z"):
            _number(unit.setdefault(coordinate, 0), f"{label}.{coordinate}", -100000, 100000)
        if "stationary_fixture" in unit and not isinstance(unit["stationary_fixture"], bool):
            raise LabError(f"{label}.stationary_fixture must be a boolean")
        if "piece_geometry" in unit and not isinstance(unit["piece_geometry"], bool):
            raise LabError(f"{label}.piece_geometry must be a boolean")
        if "pieces" in unit:
            if not isinstance(unit["pieces"], list) or len(unit["pieces"]) > 128:
                raise LabError(f"{label}.pieces must be a list with at most 128 names")
            for piece in unit["pieces"]:
                _text(piece, f"{label}.pieces entry")
    phases = scenario["phases"]
    if not isinstance(phases, list) or not 1 <= len(phases) <= 64:
        raise LabError("scenario.phases must contain 1 to 64 phases")
    phase_names: set[str] = set()
    total_frames = 0
    for index, phase in enumerate(phases):
        label = f"phases[{index}]"
        _object(phase, label, {"name", "frames", "actions", "expected_motion", "checks"}, {"name", "frames"})
        name = _text(phase["name"], f"{label}.name")
        if name in phase_names:
            raise LabError(f"duplicate phase name: {name}")
        phase_names.add(name)
        total_frames += int(_number(phase["frames"], f"{label}.frames", 1, 18000, True))
        if "expected_motion" in phase and not isinstance(phase["expected_motion"], bool):
            raise LabError(f"{label}.expected_motion must be boolean")
        actions = phase.setdefault("actions", [])
        if not isinstance(actions, list) or len(actions) > 32:
            raise LabError(f"{label}.actions must be a list with at most 32 entries")
        for action_index, action in enumerate(actions):
            action_label = f"{label}.actions[{action_index}]"
            if not isinstance(action, dict) or not isinstance(action.get("type"), str) or action["type"] not in ACTION_FIELDS:
                raise LabError(f"{action_label}: unsupported action type")
            action_type = action["type"]
            required = ACTION_FIELDS[action_type] - ({"args"} if action_type == "call" else set())
            _object(action, action_label, ACTION_FIELDS[action_type], required)
            for key in ("unit", "transporter", "target"):
                if key in action:
                    _text(action[key], f"{action_label}.{key}", True)
                    if action[key] not in names:
                        raise LabError(f"{action_label}.{key}: unknown unit {action[key]!r}")
            for coordinate in ("x", "z"):
                if coordinate in action:
                    _number(action[coordinate], f"{action_label}.{coordinate}", -100000, 100000)
            if action_type == "call":
                function = _text(action["function"], f"{action_label}.function")
                if not FUNCTION_NAME.fullmatch(function) or ("." in function and not function.startswith("script.")):
                    raise LabError(f"{action_label}.function must name an existing global or script call-in")
                if function in RESERVED_SCRIPT_FUNCTIONS:
                    raise LabError(f"{action_label}.function must name a unit animation entry point, not a Lua loader or runtime primitive")
                args = action.setdefault("args", [])
                if not isinstance(args, list):
                    raise LabError(f"{action_label}.args must be an array")
                _arguments(args, names, f"{action_label}.args")
            if action_type == "attach":
                _text(action["piece"], f"{action_label}.piece")
                if action["unit"] == action["transporter"]:
                    raise LabError(f"{action_label}: a unit cannot attach to itself")
        checks = phase.setdefault("checks", [])
        if not isinstance(checks, list) or len(checks) > 32:
            raise LabError(f"{label}.checks must be a list with at most 32 entries")
        for check_index, check in enumerate(checks):
            check_label = f"{label}.checks[{check_index}]"
            if not isinstance(check, dict) or not isinstance(check.get("type"), str) or check["type"] not in CHECK_FIELDS:
                raise LabError(f"{check_label}: unsupported check type")
            _object(check, check_label, CHECK_FIELDS[check["type"]], CHECK_FIELDS[check["type"]])
            for key in ("unit", "transporter"):
                if key in check:
                    _text(check[key], f"{check_label}.{key}", True)
                    if check[key] not in names:
                        raise LabError(f"{check_label}.{key}: unknown unit reference")
            if "min" in check:
                _number(check["min"], f"{check_label}.min", 0, 100000)
    if total_frames > 108000:
        raise LabError("scenario duration exceeds one hour at 30 simulation frames per second")
    _number(scenario.setdefault("warmup_frames", 90), "warmup_frames", 0, 18000, True)
    capture = scenario.setdefault("capture", {})
    _object(capture, "capture", {"interval_frames", "width", "height"})
    _number(capture.setdefault("interval_frames", 3), "capture.interval_frames", 1, 300, True)
    _number(capture.setdefault("width", 1280), "capture.width", 320, 7680, True)
    _number(capture.setdefault("height", 720), "capture.height", 240, 4320, True)
    camera = scenario.setdefault("camera", {})
    _object(camera, "camera", {"distance", "height", "target_height", "target"})
    _number(camera.setdefault("distance", 150), "camera.distance", 1, 20000)
    _number(camera.setdefault("height", 65), "camera.height", 1, 10000)
    _number(camera.setdefault("target_height", 20), "camera.target_height", -1000, 10000)
    _text(camera.setdefault("target", units[0]["name"]), "camera.target", True)
    if camera["target"] not in names:
        raise LabError("camera.target must refer to a declared unit")
    modoptions = scenario.setdefault("modoptions", {})
    if not isinstance(modoptions, dict) or len(modoptions) > 64:
        raise LabError("modoptions must be a dictionary with at most 64 entries")
    for key, value in modoptions.items():
        _text(key, "modoption key", True)
        if not isinstance(value, (str, bool, int, float)):
            raise LabError(f"modoptions.{key} must be scalar")
        if isinstance(value, (int, float)):
            _number(value, f"modoptions.{key}", -1e9, 1e9)
        _tdf_value(value, f"modoptions.{key}")
    return scenario


def load_scenario(path: Path) -> dict[str, Any]:
    try:
        return validate_scenario(json.loads(path.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError) as error:
        raise LabError(f"Cannot load scenario {path}: {error}") from error


def lua_literal(value: Any) -> str:
    """Serialize data, never executable fragments, to portable Lua 5.1 syntax."""
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        if not math.isfinite(value):
            raise LabError("Cannot encode a non-finite Lua number")
        return repr(value)
    if isinstance(value, str):
        # Decimal byte escapes avoid JSON's unsupported Lua \u escape syntax.
        encoded = value.encode("utf-8")
        parts = []
        for byte in encoded:
            if byte == 34:
                parts.append('\\"')
            elif byte == 92:
                parts.append("\\\\")
            elif 32 <= byte < 127:
                parts.append(chr(byte))
            else:
                parts.append(f"\\{byte:03d}")
        return '"' + "".join(parts) + '"'
    if isinstance(value, list):
        return "{" + ", ".join(lua_literal(item) for item in value) + "}"
    if isinstance(value, dict):
        return "{" + ", ".join("[" + lua_literal(key) + "] = " + lua_literal(value[key]) for key in sorted(value)) + "}"
    raise LabError(f"Cannot serialize {type(value).__name__} to Lua")


def _inside(path: Path, parent: Path) -> bool:
    return path == parent or parent in path.parents


def _source_files(root: Path, materialize_internal_symlinks: bool = False) -> list[Path]:
    files: list[Path] = []
    for current, dirs, names in os.walk(root, followlinks=False):
        dirs[:] = sorted(name for name in dirs if name not in IGNORED_SOURCE_NAMES)
        for name in dirs + names:
            if name in IGNORED_SOURCE_NAMES:
                continue
            path = Path(current) / name
            if path.is_symlink():
                resolved = path.resolve()
                if materialize_internal_symlinks and name in names and resolved.is_file() and _inside(resolved, root):
                    continue
                raise LabError(f"Source contains a symlink: {path}. Materialize it before staging; the lab will not follow links into another checkout.")
        for name in sorted(names):
            if name not in IGNORED_SOURCE_NAMES:
                path = Path(current) / name
                if not path.is_file():
                    raise LabError(f"Source contains a special file: {path}")
                files.append(path)
    return files


def _git_environment() -> dict[str, str]:
    environment = os.environ.copy()
    # Metadata inspection must not fetch promised objects or refresh the user's
    # index. In particular, a partial checkout must remain a partial checkout.
    environment.update(GIT_NO_LAZY_FETCH="1", GIT_OPTIONAL_LOCKS="0")
    return environment


def verify_materialization(root: Path, *, allow_unversioned: bool = False) -> dict[str, Any]:
    """Reject missing indexed files, including paths hidden by sparse checkout."""
    try:
        result = subprocess.run(["git", "-C", str(root), "ls-files", "--cached", "-z", "--", "."],
                                capture_output=True, timeout=30, check=False, env=_git_environment())
    except (OSError, subprocess.TimeoutExpired):
        result = None
    if result is None or result.returncode or not result.stdout:
        if not allow_unversioned:
            raise LabError("Cannot verify complete game files against a Git index. Use a materialized Git checkout, or explicitly pass --allow-unversioned-game for a complete exported game directory.")
        return {"method": "filesystem_only", "git_completeness_verified": False,
                "explicit_unversioned_override": True,
                "note": "Required directories exist; archive completeness cannot be proved without a Git index. Engine loading must still succeed."}
    tracked = [os.fsdecode(item) for item in result.stdout.split(b"\0") if item]
    missing = []
    for relative in tracked:
        path = root / relative
        if not path.exists() or (path.is_dir() and not any(path.iterdir())):
            missing.append(relative)
    if missing:
        examples = ", ".join(missing[:8])
        raise LabError(f"Game checkout is incomplete: {len(missing)} of {len(tracked)} tracked paths are missing or empty ({examples}). Use a fully materialized checkout or export. The lab does not download missing files or disable sparse checkout.")
    return {"method": "git_index", "git_completeness_verified": True, "tracked_paths": len(tracked)}


def git_identity(root: Path) -> dict[str, Any]:
    results: dict[str, Any] = {}
    commands = {"commit": ["rev-parse", "HEAD"], "branch": ["branch", "--show-current"], "status": ["status", "--porcelain=v1", "--untracked-files=all"]}
    try:
        for key, arguments in commands.items():
            result = subprocess.run(["git", "-C", str(root), *arguments], capture_output=True, text=True, timeout=15, check=False, env=_git_environment())
            if result.returncode:
                return {"available": False}
            results[key] = result.stdout.strip()
        patch = subprocess.run(["git", "-C", str(root), "diff", "HEAD", "--binary", "--no-ext-diff", "--no-textconv"], capture_output=True, timeout=30, check=False, env=_git_environment())
        results["tracked_diff_sha256"] = hashlib.sha256(patch.stdout).hexdigest() if patch.returncode == 0 else None
        if patch.returncode:
            results["tracked_diff_note"] = "Diff unavailable without fetching Git objects; source snapshot hashes remain authoritative."
        results["available"] = True
        results["dirty"] = bool(results["status"])
        return results
    except (OSError, subprocess.TimeoutExpired):
        return {"available": False}


def probe_engine(engine: Path, cwd: Path) -> dict[str, Any]:
    engine = engine.expanduser().resolve()
    if not engine.is_file():
        raise LabError(f"Recoil executable does not exist: {engine}")
    if any(kind in engine.name.lower() for kind in ("headless", "dedicated")):
        raise LabError("Animation screenshots require the graphical Recoil executable, not headless or dedicated")
    if os.name != "nt" and not os.access(engine, os.X_OK):
        raise LabError(f"Recoil file is not executable: {engine}")
    try:
        environment = os.environ.copy()
        environment.update(SPRING_WRITEDIR=str(cwd / "engine-data"), SPRING_ISOLATED=str(cwd / "engine-data"), SPRING_DATADIR="")
        result = subprocess.run([str(engine), "--version"], cwd=cwd, env=environment, capture_output=True, text=True, timeout=15, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise LabError(f"Unable to probe Recoil --version: {error}") from error
    version = (result.stdout + result.stderr).strip()
    if result.returncode or not version:
        raise LabError(f"Recoil --version failed ({result.returncode}): {version[:1000]}")
    return {"path": str(engine), "sha256": digest_file(engine), "version": version[:4000]}


def make_startscript(game_type: str, map_name: str, seed: int, modoptions: dict[str, Any]) -> str:
    _number(seed, "seed", 1, 2147483647, True)
    options = {"maxspeed": 1, "minspeed": 1, "teamdeathmode": "none", **modoptions}
    entries = "\n".join(f"        {key}={_tdf_value(value, 'modoption ' + key)};" for key, value in sorted(options.items()))
    return f"""[GAME]
{{
    MapName={_tdf_value(map_name, 'map name')};
    GameType={_tdf_value(game_type, 'game type')};
    IsHost=1;
    HostIP=127.0.0.1;
    HostPort=0;
    MyPlayerName=AnimationLab;
    NumPlayers=1;
    NumTeams=2;
    NumAllyTeams=2;
    StartPosType=0;
    GameStartDelay=0;
    FixedRNGSeed={seed};
    RecordDemo=1;
    [PLAYER0]
    {{ Name=AnimationLab; Team=0; Spectator=0; }}
    [TEAM0]
    {{ TeamLeader=0; AllyTeam=0; Side=Protagon; RGBColor=0.2 0.7 1.0; }}
    [TEAM1]
    {{ TeamLeader=0; AllyTeam=1; Side=Antagon; RGBColor=1.0 0.4 0.2; }}
    [ALLYTEAM0]
    {{ NumAllies=0; }}
    [ALLYTEAM1]
    {{ NumAllies=0; }}
    [MODOPTIONS]
    {{
{entries}
    }}
}}
"""


def prepare_run(*, game: Path, scenario: dict[str, Any], output: Path, map_name: str, engine: Path | None = None, data_dirs: list[Path] | None = None, map_archive: Path | None = None, seed: int = 1337, view: str = "threequarter", harness_root: Path | None = None, allow_unversioned_game: bool = False, materialize_internal_symlinks: bool = False, local_server_compat: bool = False, disable_fontconfig: bool = False, observer_only_ui: bool = False, single_step_capture: bool = False, window_position: tuple[int, int] | None = None) -> dict[str, Any]:
    """Snapshot complete input files and add instrumentation only to that copy."""
    game = game.expanduser().resolve()
    output = output.expanduser().resolve()
    harness_root = (harness_root or Path(__file__).parent).resolve()
    scenario = validate_scenario(scenario)
    if window_position is not None:
        if len(window_position) != 2:
            raise LabError("window_position needs x and y")
        for coordinate in window_position:
            _number(coordinate, "window_position", 0, 32767, True)
    _number(seed, "seed", 1, 2147483647, True)
    if view not in VIEWS:
        raise LabError(f"view must be one of {', '.join(VIEWS)}")
    _tdf_value(map_name, "map name")
    if not (game / "modinfo.lua").is_file():
        raise LabError(f"Not a Mosaic game directory: missing {game / 'modinfo.lua'}")
    for name in REQUIRED_GAME_DIRS:
        if not (game / name).is_dir() or not any((game / name).iterdir()):
            raise LabError(f"The game must be a complete checkout, including {name}; sparse or code-only checkouts cannot render animations")
    materialization = verify_materialization(game, allow_unversioned=allow_unversioned_game)
    if _inside(output, game) or _inside(game, output):
        raise LabError("Output and game directories must not contain each other")
    if _inside(output, harness_root) or _inside(harness_root, output):
        raise LabError("Output and harness directories must not contain each other")
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise LabError(f"Output must be a new or empty directory: {output}")
    requested_data_dirs = [path.expanduser().resolve() for path in data_dirs or []]
    # Explicit isolation-dir replaces the engine's automatic portable directory.
    # Keep its packaged base/ archives searchable, but never writable, alongside
    # the caller's map/rapid content directories.
    engine_root = [engine.expanduser().resolve().parent] if engine is not None else []
    data_dirs = list(dict.fromkeys(engine_root + requested_data_dirs))
    for directory in data_dirs:
        if not directory.is_dir():
            raise LabError(f"Engine data directory does not exist: {directory}")
        if os.pathsep in str(directory):
            raise LabError(f"Data directory contains path-list separator {os.pathsep!r}: {directory}")
    if map_archive is not None:
        map_archive = map_archive.expanduser().resolve()
        if not map_archive.is_file() or map_archive.suffix.lower() not in {".sd7", ".sdz"}:
            raise LabError("--map-archive must name an existing .sd7 or .sdz archive")
    overlay = harness_root / "overlay"
    if not overlay.is_dir():
        raise LabError(f"Missing lab instrumentation: {overlay}")
    overlay_files = _source_files(overlay)
    if not overlay_files:
        raise LabError(f"Lab instrumentation folder is empty: {overlay}")
    source_files = _source_files(game, materialize_internal_symlinks)
    materialized_links = {p.relative_to(game).as_posix(): p.resolve().relative_to(game).as_posix()
                          for p in source_files if p.is_symlink()}
    output.mkdir(parents=True, exist_ok=True)
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S") + "-" + uuid.uuid4().hex[:8]
    write_dir = output / "engine-data"
    stage = write_dir / "games" / f"animlab-{run_id}.sdd"
    stage.mkdir(parents=True)
    (write_dir / "animlab" / "captures").mkdir(parents=True)
    manifest: dict[str, Any] = {
        "schema_version": 1, "run_id": run_id, "created_utc": utc_now(), "status": "preparing",
        "source": {"path": str(game), "git": git_identity(game), "materialization": materialization,
                   "materialized_internal_links": materialized_links}, "scenario": scenario,
        "scenario_sha256": hashlib.sha256(canonical_json(scenario)).hexdigest(),
        "seed": seed, "view": view, "map": {"requested_name": map_name},
        "engine": {"path": str(engine.expanduser().resolve()) if engine else None, "verified": False},
        "requested_data_dirs": [str(path) for path in requested_data_dirs],
        "data_dirs": [str(path) for path in data_dirs], "write_dir": str(write_dir),
        "staged_game": str(stage), "capture_dir": "engine-data/animlab/captures",
        "events_path": "engine-data/animlab/events.jsonl", "completion_path": "engine-data/animlab/complete.json",
        "visual_review": "not_performed", "interpolation": "none",
    }
    manifest_path = output / "manifest.json"
    write_json(manifest_path, manifest)
    try:
        file_records = []
        for path in source_files:
            relative = path.relative_to(game)
            destination = stage / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            copy_source = game / materialized_links.get(relative.as_posix(), relative.as_posix())
            if not _inside(copy_source.resolve(), game):
                raise LabError(f"Source symlink changed to an external target: {relative}")
            before = copy_source.stat()
            shutil.copy2(copy_source, destination)
            after = copy_source.stat()
            if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                raise LabError(f"Game source changed while copying {relative}; run again after the edit finishes")
            file_records.append({"path": relative.as_posix(), "bytes": destination.stat().st_size, "sha256": digest_file(destination)})
        write_json(output / "source-files.json", file_records)
        manifest["source"]["files_manifest"] = "source-files.json"
        manifest["source"]["snapshot_sha256"] = hashlib.sha256(canonical_json(file_records)).hexdigest()
        overlay_records = []
        for path in overlay_files:
            relative = path.relative_to(overlay)
            destination = stage / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.exists():
                destination.chmod(destination.stat().st_mode | stat.S_IWUSR)
            shutil.copy2(path, destination)
            overlay_records.append({"path": relative.as_posix(), "sha256": digest_file(destination)})
        if observer_only_ui:
            fixture = harness_root / "observer_only_luaui.lua"
            shutil.copy2(fixture, stage / "luaui.lua")
            overlay_records.append({"path": "luaui.lua", "sha256": digest_file(stage / "luaui.lua")})
        manifest["observer_only_ui"] = observer_only_ui
        manifest["single_step_capture"] = single_step_capture
        manifest["instrumentation"] = overlay_records
        game_name = f"MOSAIC Animation Lab {run_id}"
        original_modinfo = (stage / "modinfo.lua").read_text(encoding="utf-8-sig")
        (stage / "modinfo.lua").chmod((stage / "modinfo.lua").stat().st_mode | stat.S_IWUSR)
        (stage / "modinfo.lua").write_text("-- Generated in this disposable snapshot only.\nlocal info = (function()\n" + original_modinfo + "\nend)()\n" + f"info.name = {lua_literal(game_name)}\ninfo.version = \"1\"\ninfo.mutator = \"Animation Lab\"\nreturn info\n", encoding="utf-8")
        # Recoil's archive scanner may avoid appending a version already found
        # anywhere in the name (including a timestamp). The concrete archive
        # filename has no such heuristic and is unique in this isolated run.
        manifest["game_type"] = stage.name
        manifest["game_display_name"] = game_name
        manifest["staged_modinfo_sha256"] = digest_file(stage / "modinfo.lua")
        config = {"scenario": scenario, "seed": seed, "view": view, "run_id": run_id, "output_dir": "animlab", "capture_dir": "animlab/captures", "single_step_capture": single_step_capture}
        config_path = stage / "luarules" / "configs" / "animation_lab_run.lua"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        if config_path.exists():
            config_path.chmod(config_path.stat().st_mode | stat.S_IWUSR)
        config_path.write_text("-- Generated data, not a production game file.\nreturn " + lua_literal(config) + "\n", encoding="utf-8")
        manifest["run_config_sha256"] = digest_file(config_path)
        if map_archive is not None:
            destination = write_dir / "maps" / map_archive.name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(map_archive, destination)
            manifest["map"]["archive"] = {"source_path": str(map_archive), "sha256": digest_file(destination), "bytes": destination.stat().st_size}
        settings = {
            "Fullscreen": 0, "XResolution": scenario["capture"]["width"], "YResolution": scenario["capture"]["height"],
            "XResolutionWindowed": scenario["capture"]["width"], "YResolutionWindowed": scenario["capture"]["height"],
            "VSync": 0, "DualScreenMode": 0, "WindowBorderless": 0, "WindowPosX": 0, "WindowPosY": 0,
            "LuaUI": 1, "LuaRules": 1, "Sound": 0, "MaxSounds": 0, "HangTimeout": 120,
            "ShowFPS": 0, "ShowClock": 0,
        }
        if window_position is not None:
            settings["WindowPosX"], settings["WindowPosY"] = window_position
        if disable_fontconfig:
            settings["UseFontConfigLib"] = 0
        manifest["engine_settings"] = settings.copy()
        settings_path = output / "springsettings.cfg"
        settings_path.write_text("\n".join(f"{key} = {value}" for key, value in sorted(settings.items())) + "\n", encoding="utf-8")
        script_path = output / "startscript.txt"
        script_path.write_text(make_startscript(manifest["game_type"], map_name, seed, scenario["modoptions"]), encoding="utf-8")
        environment = {"SPRING_WRITEDIR": str(write_dir), "SPRING_ISOLATED": str(write_dir), "SPRING_DATADIR": os.pathsep.join(str(path) for path in data_dirs)}
        manifest["environment"] = environment
        if engine is not None:
            manifest["engine"] = {**probe_engine(engine, output), "verified": True}
            manifest["local_server_compat"] = local_server_compat
            local_flag = "--server=127.0.0.1" if local_server_compat else "--only-local"
            manifest["command"] = [manifest["engine"]["path"], local_flag, "--isolation", "--isolation-dir", str(write_dir), "--write-dir", str(write_dir), "--config", str(settings_path), str(script_path)]
        else:
            manifest["command"] = None
        manifest["status"] = "prepared"
        manifest["prepared_utc"] = utc_now()
        write_json(manifest_path, manifest)
        return manifest
    except BaseException as error:
        manifest["status"] = "preparation_failed"
        manifest["error"] = str(error)
        write_json(manifest_path, manifest)
        raise


def execute_run(output: Path, *, timeout: float = 180, poll_interval: float = 0.2) -> dict[str, Any]:
    """Launch only this run's process and wait for its explicit completion marker."""
    output = output.expanduser().resolve()
    _number(timeout, "timeout", 1, 86400)
    manifest_path = output / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("status") != "prepared" or not manifest.get("command"):
        raise LabError("Run is not prepared with a verified graphical Recoil executable")
    completion_path = output / manifest["completion_path"]
    if completion_path.exists():
        raise LabError("Completion output already exists; prepare a new run instead of overwriting evidence")
    environment = os.environ.copy()
    environment.update(manifest["environment"])
    manifest.update(status="running", started_utc=utc_now(), timeout_seconds=timeout)
    write_json(manifest_path, manifest)
    began = time.monotonic()
    process: subprocess.Popen[bytes] | None = None
    completion: dict[str, Any] | None = None
    timed_out = False
    terminated_after_capture = False
    try:
        with (output / "engine-console.log").open("wb") as log:
            process = subprocess.Popen(manifest["command"], cwd=output, env=environment, stdout=log, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
            while process.poll() is None:
                if completion_path.is_file():
                    try:
                        completion = json.loads(completion_path.read_text(encoding="utf-8"))
                        if not isinstance(completion, dict):
                            completion = None
                    except (OSError, json.JSONDecodeError):
                        completion = None  # Writer may still be flushing.
                    if completion is not None:
                        try:
                            process.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            terminated_after_capture = True
                            process.terminate()
                        break
                if time.monotonic() - began >= timeout:
                    timed_out = True
                    process.terminate()
                    break
                time.sleep(min(poll_interval, max(0.01, timeout - (time.monotonic() - began))))
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        if completion is None and completion_path.is_file():
            try:
                completion = json.loads(completion_path.read_text(encoding="utf-8"))
                if not isinstance(completion, dict):
                    completion = None
            except (OSError, json.JSONDecodeError):
                completion = None
        manifest["engine_exit_code"] = process.returncode
        manifest["runner_terminated_after_capture"] = terminated_after_capture
        manifest["completion"] = completion
        if timed_out:
            manifest["status"] = "timed_out"
            manifest["error"] = "Recoil did not emit a complete capture before the deadline"
        elif completion is None:
            manifest["status"] = "capture_failed"
            manifest["error"] = "Engine exited without the lab completion marker; inspect engine-console.log and engine-data/infolog.txt"
        elif completion.get("status") != "complete" or completion.get("success") is False:
            manifest["status"] = "capture_failed"
            manifest["error"] = "The runtime did not report an explicit complete status; inspect completion and events"
        elif completion.get("run_id") != manifest["run_id"]:
            manifest["status"] = "capture_failed"
            manifest["error"] = "Completion marker does not match this run ID"
        elif process.returncode != 0 and not terminated_after_capture:
            manifest["status"] = "capture_failed"
            manifest["error"] = f"Recoil exited with error {process.returncode} after recording its completion marker"
        else:
            manifest["status"] = "captured"
        manifest["visual_review"] = "not_performed"
    except BaseException as error:
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        manifest["status"] = "launch_failed"
        manifest["error"] = str(error)
        raise
    finally:
        manifest["finished_utc"] = utc_now()
        manifest["elapsed_seconds"] = round(time.monotonic() - began, 3)
        write_json(manifest_path, manifest)
    return manifest
