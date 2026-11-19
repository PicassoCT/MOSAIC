#!/usr/bin/env python3
"""Stage, capture and inspect Mosaic animations outside the game checkout."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from runner import LabError, VIEWS, execute_run, load_scenario, prepare_run


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    commands = root.add_subparsers(dest="command", required=True)
    for command in ("prepare", "run"):
        sub = commands.add_parser(command, help="Create an isolated snapshot" if command == "prepare" else "Create a snapshot and launch graphical Recoil")
        sub.add_argument("--game", type=Path, required=True, help="Complete Mosaic source directory; never modified")
        sub.add_argument("--allow-unversioned-game", action="store_true", help="Explicitly allow an exported game without a Git index; its completeness cannot be verified against tracked files")
        sub.add_argument("--materialize-internal-symlinks", action="store_true", help="Copy in-checkout file symlinks as regular snapshot files; reject external links and directory links")
        sub.add_argument("--local-server-compat", action="store_true", help="Use --server=127.0.0.1 for older Coil engines without --only-local")
        sub.add_argument("--scenario", type=Path, required=True, help="Declarative animation scenario JSON")
        sub.add_argument("--output", type=Path, required=True, help="New or empty run directory, outside the source game and lab")
        sub.add_argument("--map", dest="map_name", required=True, help="Engine map name, including its version")
        sub.add_argument("--map-archive", type=Path, help="Optional .sd7/.sdz map to copy and hash for reproducibility")
        sub.add_argument("--data-dir", type=Path, action="append", default=[], help="Existing read-only engine content directory; repeat as needed")
        sub.add_argument("--engine", type=Path, required=command == "run", help="Graphical Recoil spring executable")
        sub.add_argument("--seed", type=int, default=1337, help="Nonzero FixedRNGSeed (default: 1337)")
        sub.add_argument("--view", choices=VIEWS, default="threequarter")
        if command == "run":
            sub.add_argument("--timeout", type=float, default=180, help="Wall-clock deadline including engine startup, in seconds")
            sub.add_argument("--no-analyze", action="store_true", help="Keep raw evidence and skip report generation")
    validate = commands.add_parser("validate", help="Validate a scenario without staging or launching")
    validate.add_argument("scenario", type=Path)
    analyze = commands.add_parser("analyze", help="Build review evidence from an existing run")
    analyze.add_argument("run_dir", type=Path)
    return root


def analyze_run(path: Path) -> dict:
    # Loaded only after capture: preparation does not depend on image libraries.
    from analyze import analyze_run as generate_report
    result = generate_report(path)
    if isinstance(result, dict):
        print(f"Analysis status: {result.get('status', 'unknown')}; report: {path.resolve() / 'analysis' / 'index.html'}")
    return result


def main(argv: list[str] | None = None) -> int:
    arguments = parser().parse_args(argv)
    try:
        if arguments.command == "validate":
            scenario = load_scenario(arguments.scenario)
            print(f"Valid scenario: {scenario['name']} ({len(scenario['phases'])} phases)")
            return 0
        if arguments.command == "analyze":
            result = analyze_run(arguments.run_dir)
            return 0 if result.get("status") == "needs_visual_review" else 2
        manifest = prepare_run(game=arguments.game, scenario=load_scenario(arguments.scenario), output=arguments.output,
                               map_name=arguments.map_name, engine=arguments.engine, data_dirs=arguments.data_dir,
                               map_archive=arguments.map_archive, seed=arguments.seed, view=arguments.view,
                               allow_unversioned_game=arguments.allow_unversioned_game,
                               materialize_internal_symlinks=arguments.materialize_internal_symlinks,
                               local_server_compat=arguments.local_server_compat)
        print(f"Prepared {manifest['run_id']}: {arguments.output.resolve()}")
        if arguments.command == "prepare":
            print("Game source unchanged. No animation has been observed yet.")
            return 0
        manifest = execute_run(arguments.output, timeout=arguments.timeout)
        print(f"Capture status: {manifest['status']}; visual review: {manifest['visual_review']}")
        if not arguments.no_analyze:
            result = analyze_run(arguments.output)
            if result.get("status") != "needs_visual_review":
                return 2
        return 0 if manifest["status"] == "captured" else 2
    except (LabError, OSError, json.JSONDecodeError, ImportError) as error:
        print(f"Animation lab: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
