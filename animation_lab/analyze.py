#!/usr/bin/env python3
"""Build review evidence from real Recoil captures, without grading their artistry.

The input stream is written by the temporary animation-lab widget. Screenshots
are the evidence; metrics only suggest frames to inspect. Synthetic test inputs
must identify themselves in the manifest and are never presented as game runs.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import datetime, timezone
import hashlib
import html
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
from typing import Any


SCHEMA_VERSION = 1
RENDER_ERROR_PATTERNS = (
    re.compile(r"(?:Error|ERROR).*?(?:LuaRules|LuaUI|Lua unit script|unit script).*", re.I),
    re.compile(r"(?:LuaRules|LuaUI|Lua unit script).*?(?:error|call-in failed|stack traceback)", re.I),
    re.compile(r"(?:Failed to load|Could not load) (?:Lua|unit script|model|map|game archive)", re.I),
    re.compile(r"(?:LuaRules|LuaUI).*?\[[^\]]*\].*?:\d+:.*?(?:attempt to|bad argument|stack overflow)", re.I),
)
ENGINE_LOG_PATHS = ("engine-data/infolog.txt", "engine-console.log", "stdout.log", "engine.log", "engine.stdout.log")
FAILED_RUN_STATUSES = {"capture_failed", "timed_out", "preparation_failed", "launch_failed"}


class AnalysisError(ValueError):
    """The analyzer cannot safely read or write a run directory."""


def _number(value: Any) -> bool:
    try:
        return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)
    except OverflowError:
        return False


def _frame(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def _vector(value: Any) -> bool:
    return isinstance(value, list) and len(value) == 3 and all(_number(v) for v in value)


def _sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _write(path: Path, text: str) -> None:
    if path.is_symlink():
        raise AnalysisError(f"Refusing to overwrite output symlink: {path}")
    path.write_text(text, encoding="utf-8")


def _write_json(path: Path, value: Any) -> None:
    _write(path, json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False) + "\n")


def _issue(code: str, message: str, **details: Any) -> dict:
    return {"code": code, "message": message, **details}


def _read_json(path: Path, problems: list, code: str) -> dict:
    try:
        obj = json.loads(path.read_text(encoding="utf-8"), parse_constant=_invalid_json_number)
        if not isinstance(obj, dict):
            raise ValueError("root is not an object")
        return obj
    except (OSError, ValueError) as exc:
        problems.append(_issue(code, f"Cannot read {path.name}: {exc}"))
        return {}


def _invalid_json_number(token: str) -> None:
    raise ValueError(f"Nonfinite JSON number: {token}")


def _load_events(path: Path, problems: list) -> list[dict]:
    if not path.is_file():
        problems.append(_issue("missing_events", "The rendered capture event stream does not exist."))
        return []
    events = []
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                obj = json.loads(line, parse_constant=_invalid_json_number)
                if not isinstance(obj, dict) or not isinstance(obj.get("kind"), str):
                    raise ValueError("record must be an object with a kind")
                events.append(obj)
            except ValueError as exc:
                problems.append(_issue("malformed_event", f"Event line {line_number}: {exc}", line=line_number))
    return events


def _capture_path(data_dir: Path, value: Any) -> Path:
    if not isinstance(value, str) or not value or any(ord(c) < 32 for c in value):
        raise AnalysisError("image must be a nonempty relative path without control characters")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise AnalysisError("image path must stay inside animlab/captures")
    resolved = (data_dir / path).resolve()
    capture_dir = (data_dir / "animlab" / "captures").resolve()
    if not resolved.is_relative_to(capture_dir) or path.suffix.lower() != ".png":
        raise AnalysisError("image path must reference a PNG inside animlab/captures")
    return resolved


def _expected_phases(manifest: dict, phase_events: list[dict]) -> list[dict]:
    scenario = manifest.get("scenario", {})
    phases = scenario.get("phases", []) if isinstance(scenario, dict) else []
    return phases if isinstance(phases, list) and phases else phase_events


def _phase_name(phase: dict) -> str:
    return str(phase.get("name", phase.get("phase", phase.get("id", "unnamed"))))


def _scan_engine_errors(run_dir: Path) -> list[dict]:
    results, seen = [], set()
    for relative_path in ENGINE_LOG_PATHS:
        path = run_dir / relative_path
        if not path.is_file():
            continue
        with path.open(encoding="utf-8", errors="replace") as handle:
            for line_number, line in enumerate(handle, 1):
                # An event stream may quote an old error. Only scan engine log
                # lines, not our JSON echo payload or text saying "no errors".
                if "ANIMLAB" in line or re.search(r"\b(?:no|zero|0) errors?\b", line, re.I):
                    continue
                if any(pattern.search(line) for pattern in RENDER_ERROR_PATTERNS):
                    excerpt = line.strip()[:1200]
                    if excerpt in seen:
                        continue
                    seen.add(excerpt)
                    results.append(_issue("engine_error", excerpt, file=str(path.relative_to(run_dir)), line=line_number))
                    if len(results) >= 50:
                        return results
    return results


def _relative_piece(unit: dict, piece: dict) -> tuple[float, float, float] | None:
    position, root = piece.get("position"), unit.get("position")
    if not (_vector(position) and _vector(root)):
        return None
    x, y, z = (position[i] - root[i] for i in range(3))
    heading = unit.get("heading", 0)
    angle = float(heading) * math.tau / 65536 if _number(heading) else 0.0
    c, s = math.cos(angle), math.sin(angle)
    return c * x + s * z, y, -s * x + c * z


def _motion_candidates(samples: list[dict], phases: dict[str, dict], fps: float, settings: dict) -> list[dict]:
    """Advisory telemetry only: emission points are not mesh/contact geometry."""
    by_unit: dict[tuple, list] = defaultdict(list)
    for sample in samples:
        for unit in sample.get("units", []):
            if isinstance(unit, dict):
                key = (sample["phase"], str(unit.get("name", unit.get("id", "unit"))))
                by_unit[key].append((sample, unit))
    candidates = []
    jump_speed = settings.get("piece_speed_hint", 300.0)
    ground_depth = settings.get("ground_depth_hint", 2.0)
    jump_speed = float(jump_speed) if _number(jump_speed) and jump_speed > 0 else 300.0
    ground_depth = float(ground_depth) if _number(ground_depth) and ground_depth > 0 else 2.0
    for (phase, unit_name), observations in by_unit.items():
        trajectories, low_emitters = defaultdict(list), defaultdict(list)
        for sample, unit in observations:
            for piece in unit.get("pieces", []):
                if not isinstance(piece, dict):
                    continue
                name = str(piece.get("name", "piece"))
                relative = _relative_piece(unit, piece)
                if relative is not None:
                    trajectories[name].append((sample["frame"], relative, sample["image"]))
                position, ground = piece.get("position"), piece.get("ground_y")
                if re.search(r"foot|toe", name, re.I) and _vector(position) and _number(ground) and ground - position[1] > ground_depth:
                    low_emitters[name].append((sample["frame"], float(ground - position[1]), sample["image"]))
        max_travel = 0.0
        peak = None
        for piece_name, points in trajectories.items():
            if len(points) < 2:
                continue
            anchor = points[0][1]
            max_travel = max(max_travel, max(math.dist(anchor, point[1]) for point in points))
            for previous, current in zip(points, points[1:]):
                delta = current[0] - previous[0]
                if delta <= 0:
                    continue
                speed = math.dist(previous[1], current[1]) * fps / delta
                if speed > jump_speed and (peak is None or speed > peak[0]):
                    peak = (speed, piece_name, previous, current)
        common = {"phase": phase, "unit": unit_name, "severity": "review_hint"}
        if phases.get(phase, {}).get("expected_motion") is True and len(observations) >= 3 and len(trajectories) >= 2 and max_travel < 0.01:
            candidates.append(_issue("possible_frozen_pose", "Tracked piece emission points barely changed relative to the unit. Inspect whether the intended animation actually played; a stationary emission point does not prove that the piece mesh stopped moving.", **common, frames=[observations[0][0]["frame"], observations[-1][0]["frame"]], images=[observations[0][0]["image"], observations[-1][0]["image"]], max_relative_displacement=max_travel))
        if peak:
            speed, piece_name, before, after = peak
            candidates.append(_issue("possible_pose_jump", "A tracked piece emission point moved quickly relative to the unit. Inspect both real frames and the surrounding video; this may be intentional motion or a difference between synced telemetry and render interpolation.", **common, piece=piece_name, frames=[before[0], after[0]], images=[before[2], after[2]], relative_speed_units_per_second=speed))
        for piece_name, points in low_emitters.items():
            if len(points) >= 3:
                worst = max(points, key=lambda point: point[1])
                candidates.append(_issue("emission_point_below_ground", "A foot/toe piece emission point is below terrain in several samples. GetUnitPiecePosDir reports an emission point, not a joint pivot, mesh surface or ground contact. This is only a frame-selection hint; inspect the rendered mesh before alleging penetration.", **common, piece=piece_name, frames=[worst[0]], images=[worst[2]], depth_units=worst[1], affected_samples=len(points)))
    return candidates


def _select_evenly(samples: list[dict], count: int = 12) -> list[dict]:
    if len(samples) <= count:
        return samples
    return [samples[round(i * (len(samples) - 1) / (count - 1))] for i in range(count)]


def _make_sheets(data_dir: Path, out: Path, samples: list[dict], synthetic: bool) -> list[dict]:
    from PIL import Image, ImageDraw, ImageOps

    groups: dict[str, list] = defaultdict(list)
    for sample in samples:
        groups[sample["phase"]].append(sample)
    results = []
    for index, (phase, group) in enumerate(groups.items(), 1):
        selected = _select_evenly(group)
        cell_w, image_h, caption_h, header_h, columns = 360, 240, 42, 46, 3
        rows = math.ceil(len(selected) / columns)
        sheet = Image.new("RGB", (cell_w * columns, header_h + rows * (image_h + caption_h)), "#10151e")
        draw = ImageDraw.Draw(sheet)
        title = ("SYNTHETIC TEST FIXTURE | " if synthetic else "ACTUAL CAPTURE SAMPLES | ") + phase
        draw.text((12, 12), title, fill="#e8f0fa")
        evidence = []
        for number, sample in enumerate(selected):
            x, y = (number % columns) * cell_w, header_h + (number // columns) * (image_h + caption_h)
            with Image.open(_capture_path(data_dir, sample["image"])) as image:
                thumb = ImageOps.contain(image.convert("RGB"), (cell_w - 8, image_h - 8))
            sheet.paste(thumb, (x + (cell_w - thumb.width) // 2, y + (image_h - thumb.height) // 2))
            label = f"frame {sample['frame']} | t={sample['sim_time']:.3f}s | {sample.get('view', '')}"
            draw.text((x + 6, y + image_h + 2), label, fill="#e8f0fa")
            caption = Path(sample["image"]).name
            if sample.get("coverage_valid") is False:
                caption = "EXCLUDED: " + caption
            draw.text((x + 6, y + image_h + 17), caption, fill="#ffd899" if sample.get("coverage_valid") is False else "#a9bbd0")
            evidence.append({"frame": sample["frame"], "sim_time": sample["sim_time"], "image": sample["image"]})
        name = f"contact_{index:02d}.jpg"
        if (out / name).is_symlink():
            raise AnalysisError(f"Refusing output symlink: {out / name}")
        sheet.save(out / name, quality=94)
        results.append({"phase": phase, "path": name, "selected_samples": evidence, "total_samples": len(group)})
    return results


def _video_timing(samples: list[dict], fps: float, interval: int, complete_frame: int | None) -> list[dict]:
    timing = []
    for index, sample in enumerate(samples):
        if index + 1 < len(samples):
            delta = samples[index + 1]["frame"] - sample["frame"]
        else:
            delta = (complete_frame - sample["frame"]) if complete_frame is not None else interval
            delta = max(1, min(delta, interval))
        if delta <= 0:
            raise AnalysisError("Video requires strictly increasing simulation frames.")
        timing.append({"frame": sample["frame"], "image": sample["image"], "duration_seconds": delta / fps})
    return timing


def _make_video(data_dir: Path, out: Path, samples: list[dict], fps: float, interval: int, complete_frame: int | None) -> dict:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return {"status": "unavailable", "reason": "ffmpeg is not installed; contact sheets and original PNGs remain available."}
    if not samples:
        return {"status": "unavailable", "reason": "No valid capture samples."}
    try:
        timing = _video_timing(samples, fps, interval, complete_frame)
    except AnalysisError as exc:
        return {"status": "unavailable", "reason": str(exc)}
    concat = ["ffconcat version 1.0"]
    for entry in timing:
        path = _capture_path(data_dir, entry["image"]).as_posix().replace("'", "'\\''")
        concat.extend((f"file '{path}'", f"option framerate {fps:.10g}", f"duration {entry['duration_seconds']:.10f}"))
    # Repeat the last real image to preserve its final hold. No interpolated
    # frames are synthesized; all input samples remain attributable to PNGs.
    concat.extend((concat[-3], f"option framerate {fps:.10g}"))
    _write(out / "video.ffconcat", "\n".join(concat) + "\n")
    _write_json(out / "video_timing.json", {"basis": "simulation frame deltas", "sim_fps": fps, "samples": timing})
    target = out / "animation.mp4"
    if target.is_symlink():
        raise AnalysisError(f"Refusing output symlink: {target}")
    command = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(out / "video.ffconcat"), "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2", "-fps_mode", "vfr", "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-video_track_timescale", "30000", "-movflags", "+faststart", str(target)]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=180, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"status": "unavailable", "reason": str(exc)}
    _write(out / "ffmpeg.log", result.stderr)
    if result.returncode != 0 or not target.is_file() or target.stat().st_size == 0:
        return {"status": "failed", "reason": "ffmpeg could not encode the evidence; inspect ffmpeg.log.", "returncode": result.returncode}
    return {"status": "created", "path": target.name, "timing": "video_timing.json", "source_frames": len(samples), "interpolated_frames": False, "duration_seconds": sum(entry["duration_seconds"] for entry in timing)}


def _write_review(out: Path, report: dict, review: dict) -> None:
    lines = ["# Animation visual review", "", f"Machine evidence status: **{report['status']}**.", "", "This report checks capture integrity and points to possible problems. It does not certify animation quality. Inspect the original frames and playback, then complete review.json with evidence for each conclusion.", "", "Piece positions from GetUnitPiecePosDir are emission points, not pivots, mesh bounds or contact surfaces. Synced piece telemetry can differ from the interpolated rendered pose; frame_time_offset records the engine interpolation offset when available. Use the PNGs to judge contacts, penetrations and silhouettes.", ""]
    if report["synthetic_fixture"]:
        lines += ["**Synthetic fixture: these images are test data, not a live Mosaic capture.**", ""]
    for title, key in (("Capture problems", "capture_problems"), ("Runtime failures", "runtime_failures"), ("Review record problems", "review_problems"), ("Frames to inspect", "candidates")):
        lines += [f"## {title}", ""]
        items = report[key]
        if not items:
            lines += ["None recorded.", ""]
        for item in items:
            lines += [f"- **{item['code']}**: {item['message']}"]
            if item.get("frames"):
                lines += [f"  Frames: {', '.join(str(frame) for frame in item['frames'])}; phase: {item.get('phase', '')}; unit: {item.get('unit', '')}."]
        lines += [""]
    lines += ["## Evidence by phase", "", "Images marked EXCLUDED have valid PNG data but incomplete observation metadata. They are retained to diagnose capture problems and do not satisfy phase coverage.", ""]
    for sheet in report["contact_sheets"]:
        lines += [f"### {sheet['phase']}", "", f"![Actual capture samples]({sheet['path']})", "", "| Frame | Simulation time | Original image |", "| --- | --- | --- |"]
        for sample in sheet["selected_samples"]:
            lines.append(f"| {sample['frame']} | {sample['sim_time']:.3f} s | [PNG](../engine-data/{sample['image']}) |")
        lines.append("")
    if report["video"].get("status") == "created":
        lines += ["[Open timing-preserving playback](animation.mp4). Video holds recorded frames for the observed simulation intervals; it does not interpolate new poses.", ""]
    lines += ["## Review procedure", "", "1. Check capture problems first. Missing phases, dropped samples, clipped subjects or runtime errors require a new run before approving the animation.", "2. Open the contact sheet for every phase, then inspect original PNGs around each transition and candidate frame.", "3. Watch playback at normal speed and slow speed. Check planted feet, skating, penetrations, limb range, attachment alignment, pose transitions, timing, return to idle and plausible motion.", "4. Compare the other camera views and seed runs. A single view can hide penetration and a single procedural seed does not cover every branch.", "5. Record reviewer identity, exact frames/image paths, findings and conclusion in review.json. Use `accepted`, `changes_required`, or `inconclusive`; never infer acceptance merely from the absence of automatic hints.", "", "## Review state", "", f"Current saved review: `{review.get('status', 'unreviewed')}`. Machine results remain separate from that judgment.", ""]
    _write(out / "review.md", "\n".join(lines))
    cards = []
    for sheet in report["contact_sheets"]:
        links = " ".join(f'<a href="../engine-data/{html.escape(sample["image"], quote=True)}">frame {sample["frame"]}</a>' for sample in sheet["selected_samples"])
        cards.append(f'<section><h2>{html.escape(sheet["phase"])}</h2><img alt="Recorded frames" src="{sheet["path"]}"><p>{links}</p></section>')
    issues = "".join(f'<li><strong>{html.escape(item["code"])}</strong>: {html.escape(item["message"])}</li>' for item in report["runtime_failures"] + report["capture_problems"] + report["review_problems"] + report["candidates"])
    video = '<video controls preload="metadata" src="animation.mp4"></video>' if report["video"].get("status") == "created" else ""
    fixture = '<p class="badge">SYNTHETIC TEST FIXTURE — NOT GAMEPLAY</p>' if report["synthetic_fixture"] else ""
    _write(out / "index.html", f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Animation evidence review</title><style>body{{background:#10151e;color:#e8f0fa;font:16px/1.55 system-ui;margin:2rem auto;padding:0 1.25rem;max-width:1180px}}a{{color:#9cd5ff;margin-right:1rem}}img,video{{width:100%;max-width:1080px}}section{{border-top:1px solid #34465b;margin-top:2rem;padding-top:1rem}}.badge{{color:#ffd899}}code{{color:#b6e3c3}}li{{margin-bottom:.7rem}}</style><h1>Animation evidence review</h1>{fixture}<p>Evidence status: <strong>{html.escape(report['status'])}</strong>. Animation quality requires visual review.</p><p>These are captured frames. Playback preserves simulation timing and holds the last recorded image between captures; no interpolated poses are invented.</p><p><a href="report.json">Machine report</a><a href="review.md">Review instructions</a><a href="review.json">Review record</a></p>{video}<h2>Problems and inspection hints</h2><ul>{issues or '<li>None recorded. Review every phase before accepting.</li>'}</ul>{''.join(cards)}</html>''')


def analyze_run(run_dir: Path, make_video: bool = True) -> dict:
    """Analyze a completed/partial capture; never automatically approve a pose."""
    from PIL import Image, UnidentifiedImageError

    run_dir = Path(run_dir).resolve()
    if not run_dir.is_dir():
        raise AnalysisError(f"Run directory does not exist: {run_dir}")
    out = run_dir / "analysis"
    if out.is_symlink():
        raise AnalysisError("The analysis output directory must not be a symlink.")
    out.mkdir(exist_ok=True)
    problems, failures = [], []
    manifest_path = run_dir / "manifest.json"
    manifest = _read_json(manifest_path, problems, "missing_manifest")
    runner_status = manifest.get("status")
    if runner_status in FAILED_RUN_STATUSES:
        failures.append(_issue("runner_failed", f"The runner finished with status {runner_status}."))
    elif runner_status != "captured" and manifest.get("synthetic_fixture") is not True:
        problems.append(_issue("unfinished_runner", f"The runner has not confirmed capture completion (status {runner_status!r})."))
    data_dir = run_dir / "engine-data"
    event_path = data_dir / "animlab" / "events.jsonl"
    events = _load_events(event_path, problems)
    sessions = [event for event in events if event["kind"] == "session"]
    if len(sessions) != 1:
        problems.append(_issue("session_count", f"Expected one capture session, found {len(sessions)}."))
    session = sessions[0] if sessions else {}
    fps = session.get("sim_fps", 30)
    if not _number(fps) or fps <= 0:
        problems.append(_issue("invalid_fps", "Session simulation frame rate is invalid."))
        fps = 30
    fps = float(fps)
    interval = session.get("capture_every_frames", manifest.get("interval_frames", 3))
    if not _frame(interval) or interval < 1:
        problems.append(_issue("invalid_interval", "Capture interval must be a positive integer frame count."))
        interval = 3
    complete = [event for event in events if event["kind"] == "complete"]
    if not complete:
        problems.append(_issue("missing_completion", "No capture-complete event; the session may have stopped early."))
    elif len(complete) != 1:
        problems.append(_issue("completion_count", f"Expected one completion record, found {len(complete)}."))
    if complete and (complete[-1].get("status") == "failed" or complete[-1].get("success") is False):
        failures.append(_issue("run_failed", "The runtime marked the scenario failed.", detail=complete[-1]))
    if complete and (complete[-1].get("status") not in {"complete", "failed"} or not _frame(complete[-1].get("frame"))):
        problems.append(_issue("invalid_completion", "Completion must report an explicit status and simulation frame."))
    for event in events:
        if manifest.get("run_id") and event.get("run_id") != manifest["run_id"]:
            problems.append(_issue("run_id_mismatch", "An event does not belong to the manifest's run.", kind=event["kind"], frame=event.get("frame")))
        if event["kind"] == "error":
            failures.append(_issue("runtime_error", str(event.get("message", event.get("error", "Runtime error"))), event=event))
        if event["kind"] == "check" and event.get("ok") is False:
            failures.append(_issue("mechanical_check_failed", f"Mechanical check {event.get('check', 'unknown')} failed for {event.get('unit', 'unit')}.", event=event))
    failures.extend(_scan_engine_errors(run_dir))
    phase_events = [event for event in events if event["kind"] == "phase"]
    phases = {_phase_name(event): event for event in phase_events}
    observed_phase_names = set(phases)
    expected = _expected_phases(manifest, phase_events)
    expected_names = {_phase_name(phase) for phase in expected if isinstance(phase, dict)}
    destroyed_by_phase, destroyed_names = {}, set()
    for phase in expected:
        if isinstance(phase, dict):
            name = _phase_name(phase)
            phases[name] = {**phase, **phases.get(name, {})}
            for action in phase.get("actions", []):
                if isinstance(action, dict) and action.get("type") == "destroy" and isinstance(action.get("unit"), str):
                    destroyed_names.add(action["unit"])
            destroyed_by_phase[name] = set(destroyed_names)
        else:
            problems.append(_issue("invalid_phase_plan", "Every planned phase must be an object."))
    scenario = manifest.get("scenario", {})
    expected_unit_names = {unit["name"] for unit in scenario.get("units", []) if isinstance(unit, dict) and isinstance(unit.get("name"), str)} if isinstance(scenario, dict) else set()
    samples, review_samples, rejected_samples, hashes, seen_images = [], [], [], [], set()
    previous_frame = None
    previous_time = None
    for row in (event for event in events if event["kind"] == "sample"):
        problem_count, failure_count = len(problems), len(failures)
        if manifest.get("run_id") and row.get("run_id") != manifest["run_id"]:
            continue
        frame = row.get("frame")
        if not _frame(frame) or not isinstance(row.get("phase"), str):
            problems.append(_issue("invalid_sample", "Sample needs a nonnegative integer frame and phase name."))
            continue
        timestamp = row.get("sim_time", frame / fps)
        if not _number(timestamp) or abs(timestamp - frame / fps) > 1.01 / fps:
            problems.append(_issue("invalid_timestamp", f"Frame {frame} has an invalid simulation time.", frame=frame))
            continue
        if previous_frame is not None and (frame <= previous_frame or timestamp <= previous_time):
            problems.append(_issue("nonmonotone_samples", f"Simulation frames/times did not increase at frame {frame}.", frame=frame))
            continue
        previous_frame, previous_time = frame, timestamp
        phase_name = row["phase"]
        if phase_name not in expected_names:
            problems.append(_issue("unexpected_phase", f"Captured phase {phase_name} is absent from the scenario plan.", phase=phase_name))
            continue
        if phase_name not in observed_phase_names:
            problems.append(_issue("missing_phase_event", f"Sample frame {frame} has no phase-start event for {phase_name}.", phase=phase_name, frame=frame))
            continue
        phase = phases[phase_name]
        duration = phase.get("duration_frames", phase.get("frames"))
        if not _frame(phase.get("frame")) or not _frame(duration) or duration < 1:
            problems.append(_issue("invalid_phase_window", f"Phase {phase_name} lacks a valid start frame and duration.", phase=phase_name))
            continue
        phase_frame = frame - phase["frame"]
        if phase_frame < 0 or phase_frame >= duration:
            problems.append(_issue("sample_outside_phase", f"Frame {frame} falls outside the declared {phase_name} window.", phase=phase_name, frame=frame))
            continue
        if "phase_frame" in row and row["phase_frame"] != phase_frame:
            problems.append(_issue("phase_timestamp_mismatch", f"Frame {frame} has a phase-relative time that disagrees with the phase start.", phase=phase_name, frame=frame))
            continue
        if row.get("capture_ok") is not True:
            problems.append(_issue("capture_failed", f"The widget did not confirm a successful capture for frame {frame}.", frame=frame))
            continue
        try:
            path = _capture_path(data_dir, row.get("image"))
            with Image.open(path) as image:
                image.verify()
            with Image.open(path) as image:
                image.load()
                width, height = image.size
                if width < 2 or height < 2:
                    raise ValueError("capture is too small")
            if path in seen_images:
                problems.append(_issue("reused_image", f"Frame {frame} reuses an earlier image path.", frame=frame))
                continue
            seen_images.add(path)
            hashes.append((row["image"], _sha(path)))
        except (AnalysisError, OSError, UnidentifiedImageError, ValueError) as exc:
            problems.append(_issue("missing_or_invalid_image", f"Frame {frame}: {exc}", frame=frame))
            continue
        sample = {**row, "sim_time": float(timestamp), "image_size": [width, height]}
        units = sample.get("units")
        if not isinstance(units, list) or not units:
            problems.append(_issue("missing_unit_telemetry", f"Frame {frame} has no observed units.", frame=frame))
            sample["units"] = []
        else:
            valid_units = []
            observed_unit_names = [unit["name"] for unit in units if isinstance(unit, dict) and isinstance(unit.get("name"), str)]
            if expected_unit_names and (set(observed_unit_names) != expected_unit_names or len(observed_unit_names) != len(expected_unit_names)):
                problems.append(_issue("incomplete_subject_telemetry", f"Frame {frame} does not report each scenario subject exactly once.", frame=frame))
            for unit in units:
                if isinstance(unit, dict) and unit.get("alive") is False:
                    if unit.get("expected_destroyed") is True and unit.get("name") in destroyed_by_phase.get(phase_name, set()):
                        valid_units.append({**unit, "pieces": []})
                    else:
                        failures.append(_issue("unexpected_subject_death", f"Frame {frame}: {unit.get('name', 'subject')} is dead without a matching scenario destroy action.", frame=frame, phase=phase_name))
                    continue
                if not isinstance(unit, dict) or not _vector(unit.get("position")):
                    problems.append(_issue("invalid_unit_telemetry", f"Frame {frame} has invalid unit position telemetry.", frame=frame))
                    continue
                if (unit.get("in_view") is False or unit.get("root_in_view") is False) and unit.get("camera_subject", True):
                    problems.append(_issue("subject_out_of_view", f"Frame {frame}: {unit.get('name', unit.get('id', 'unit'))} is outside the camera view.", frame=frame))
                pieces = unit.get("pieces", [])
                if not isinstance(pieces, list):
                    problems.append(_issue("invalid_piece_telemetry", f"Frame {frame} has an invalid piece collection.", frame=frame))
                    pieces = []
                valid_pieces = []
                for piece in pieces:
                    if not isinstance(piece, dict) or not _vector(piece.get("position")):
                        problems.append(_issue("invalid_piece_telemetry", f"Frame {frame} has a nonfinite or incomplete piece position.", frame=frame))
                    else:
                        valid_pieces.append(piece)
                valid_units.append({**unit, "pieces": valid_pieces})
            sample["units"] = valid_units
        if len(problems) != problem_count or len(failures) != failure_count:
            # A PNG alone is not complete evidence for this sample. Invalid
            # telemetry or a failed observation must not fill phase coverage.
            sample["coverage_valid"] = False
            review_samples.append(sample)
            rejected_samples.append({"frame": frame, "phase": phase_name, "image": sample["image"], "reason_codes": [item["code"] for item in problems[problem_count:] + failures[failure_count:]]})
            continue
        sample["coverage_valid"] = True
        samples.append(sample)
        review_samples.append(sample)
    if not samples:
        problems.append(_issue("no_captures", "There are no validated rendered frames to review."))
    by_phase = defaultdict(list)
    for sample in samples:
        by_phase[sample["phase"]].append(sample)
    if not expected:
        problems.append(_issue("missing_phase_plan", "No planned phases or phase events are available to check coverage."))
    for phase in expected:
        if not isinstance(phase, dict):
            continue
        name = _phase_name(phase)
        group = by_phase.get(name, [])
        if not group:
            problems.append(_issue("missing_phase", f"No captured samples for required phase {name}.", phase=name))
            continue
        event = phases[name]
        if not any(_phase_name(item) == name for item in phase_events):
            problems.append(_issue("missing_phase_event", f"No phase-start event for {name}.", phase=name))
        if len(group) < 2:
            problems.append(_issue("insufficient_phase_samples", f"Phase {name} has fewer than two captured samples.", phase=name))
        start = event.get("capture_start_frame", event.get("frame"))
        duration = event.get("duration_frames", event.get("frames"))
        if _frame(start) and group[0]["frame"] - start > interval + 1:
            problems.append(_issue("missing_phase_start", f"Phase {name} is missing its initial capture window.", phase=name, frames=[start, group[0]["frame"]]))
        if _frame(event.get("frame")) and _frame(duration) and event["frame"] + duration - 1 - group[-1]["frame"] > interval + 1:
            problems.append(_issue("missing_phase_end", f"Phase {name} is missing its final capture window.", phase=name, frames=[group[-1]["frame"], event["frame"] + duration - 1]))
        for before, after in zip(group, group[1:]):
            if after["frame"] - before["frame"] > interval + 1:
                problems.append(_issue("capture_gap", f"Phase {name} skipped simulation frames between captures.", phase=name, frames=[before["frame"], after["frame"]], observed_gap_frames=after["frame"] - before["frame"], requested_interval_frames=interval))
    complete_frame = complete[-1].get("frame") if complete else None
    complete_frame = complete_frame if _frame(complete_frame) else None
    if complete_frame is not None and samples and samples[-1]["frame"] > complete_frame:
        problems.append(_issue("completion_before_samples", "Samples continue after the declared completion frame."))
    settings = manifest.get("analysis", {})
    settings = settings if isinstance(settings, dict) else {}
    candidates = _motion_candidates(samples, phases, fps, settings)
    synthetic = manifest.get("synthetic_fixture") is True or session.get("synthetic_fixture") is True
    sheets = _make_sheets(data_dir, out, review_samples, synthetic)
    video = _make_video(data_dir, out, review_samples, fps, interval, complete_frame) if make_video else {"status": "disabled"}
    digest = hashlib.sha256()
    for path in (manifest_path, event_path, *(run_dir / name for name in ENGINE_LOG_PATHS)):
        if path.is_file():
            digest.update(_sha(path).encode("ascii"))
    digest.update(json.dumps(hashes, separators=(",", ":")).encode("utf-8"))
    fingerprint = digest.hexdigest()
    review_path = out / "review.json"
    review = {"schema_version": SCHEMA_VERSION, "status": "unreviewed", "reviewer": None, "reviewed_at_utc": None, "evidence_sha256": fingerprint, "views_reviewed": [], "phases_reviewed": [], "issues": [], "evidence": [], "conclusion": None}
    review_problems = []
    if review_path.exists():
        existing = _read_json(review_path, review_problems, "invalid_review")
        if existing:
            review = existing
        if existing.get("evidence_sha256") != fingerprint:
            review_problems.append(_issue("stale_review", "The saved visual review refers to different evidence. Re-review this run and update its fingerprint."))
    else:
        _write_json(review_path, review)
    report = {"schema_version": SCHEMA_VERSION, "created_at_utc": datetime.now(timezone.utc).isoformat(), "status": "failed" if failures else "capture_incomplete" if problems else "needs_visual_review", "visual_quality": "not_automatically_assessed", "synthetic_fixture": synthetic, "evidence_sha256": fingerprint, "sim_fps": fps, "capture_every_frames": interval, "captured_samples": len(samples), "rendered_images_for_review": len(review_samples), "excluded_samples": rejected_samples, "phase_count": len(expected), "capture_problems": problems, "runtime_failures": failures, "candidates": candidates, "contact_sheets": sheets, "video": video, "review_status": review.get("status", "unreviewed"), "review_problems": review_problems, "telemetry_note": session.get("note"), "limitations": ["GetUnitPiecePosDir reports piece emission points, not joint pivots, mesh bounds or contact surfaces.", "Synced piece telemetry can differ from interpolated rendered poses; inspect image evidence and frame_time_offset before judging contact or penetration.", "A fixed seed supports repeatability but does not guarantee identical IDs, background scheduling or rendering across environments.", "Contact sheets include verified PNGs marked EXCLUDED when their sample fails coverage checks; they remain useful to investigate capture failures.", "Contact sheets sample the capture; inspect original frames and playback for transitions.", "Valid captures require an explicit visual review before animation acceptance."]}
    _write_json(out / "report.json", report)
    _write_review(out, report, review)
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir", type=Path)
    parser.add_argument("--no-video", action="store_true")
    args = parser.parse_args(argv)
    try:
        report = analyze_run(args.run_dir, make_video=not args.no_video)
    except (AnalysisError, ImportError, OSError) as exc:
        parser.exit(2, f"Analysis failed: {exc}\n")
    print(json.dumps({"status": report["status"], "captured_samples": report["captured_samples"], "report": str(args.run_dir.resolve() / "analysis" / "index.html")}, indent=2))
    return 0 if report["status"] == "needs_visual_review" else 2


if __name__ == "__main__":
    raise SystemExit(main())
