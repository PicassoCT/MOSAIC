#!/usr/bin/env python3
"""Bind one portable artifact manifest to reproducible GTX 1050 Ti FPS evidence."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path, PurePosixPath

SPEC = importlib.util.spec_from_file_location(
    "performance_gate", Path(__file__).with_name("validate_performance_gate.py")
)
performance_gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(performance_gate)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require_equal(actual, expected, label):
    if actual != expected:
        raise ValueError(f"{label} does not match the packaged candidate")


def qualify(manifest, evidence, evidence_directory):
    if manifest.get("schema_version") != 1 or not manifest.get("portable"):
        raise ValueError("manifest must describe a schema-1 portable build")
    inputs = manifest.get("inputs")
    if not isinstance(inputs, dict):
        raise ValueError("manifest has no portable input lock")
    declared_gate = manifest.get("performance_gate")
    if declared_gate != {"minimum_zoomed_out_fps": 25, "status": "unverified"}:
        raise ValueError("manifest performance gate is missing or already altered")

    measured = performance_gate.validate(evidence)
    if measured["status"] != "passed":
        raise ValueError("minimum zoomed-out FPS is below 25")
    require_equal(evidence.get("source_commit"), manifest.get("source_commit"), "source_commit")
    require_equal(evidence.get("game_version"), manifest.get("game_version"), "game_version")
    require_equal(evidence.get("engine_build"), inputs.get("engine", {}).get("version"), "engine_build")
    require_equal(evidence.get("map"), inputs.get("map", {}).get("version"), "map")
    require_equal(evidence.get("gpu"), "NVIDIA GeForce GTX 1050 Ti", "gpu")

    raw_name = evidence.get("evidence_file", "")
    raw_path = PurePosixPath(raw_name)
    if (not raw_name or raw_path.is_absolute() or ".." in raw_path.parts or
            evidence_directory is None):
        raise ValueError("evidence_file must be a relative path beside the evidence JSON")
    raw_file = evidence_directory / raw_path
    if not raw_file.is_file() or not raw_file.stat().st_size:
        raise ValueError("raw FPS evidence file is missing or empty")
    raw_hash = evidence.get("raw_evidence_sha256")
    if not isinstance(raw_hash, str) or len(raw_hash) != 64 or sha256(raw_file) != raw_hash:
        raise ValueError("raw FPS evidence SHA-256 mismatch")

    return {
        "schema_version": 1,
        "release_qualified": True,
        "game_version": manifest["game_version"],
        "source_commit": manifest["source_commit"],
        "portable_artifacts": manifest.get("artifacts", []),
        "performance_gate": measured,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.output.exists():
            raise ValueError("output already exists")
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
        evidence = json.loads(args.evidence.read_text(encoding="utf-8"))
        result = qualify(manifest, evidence, args.evidence.resolve().parent)
        args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, json.JSONDecodeError, ValueError) as error:
        parser.exit(2, f"Release qualification failed: {error}\n")
    print(f"Qualified MOSAIC {result['game_version']} from {result['source_commit']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

