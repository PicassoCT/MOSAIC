"""Analyzer regression fixtures are synthetic, never visual gameplay evidence."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from PIL import Image

import analyze


class EvidenceAnalysisTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="animlab-evidence-test-")
        self.run = Path(self.temp.name)
        self.data = self.run / "engine-data"
        (self.data / "animlab" / "captures").mkdir(parents=True)
        self.events = [
            {"kind": "session", "sim_fps": 30, "capture_every_frames": 3, "synthetic_fixture": True},
            {"kind": "phase", "name": "walk", "frame": 30, "duration_frames": 12, "expected_motion": True},
        ]
        self.manifest = {"synthetic_fixture": True, "scenario": {"name": "synthetic_analyzer_fixture", "phases": [{"name": "walk", "frames": 12, "expected_motion": True}]}}
        for frame in (30, 33, 36, 39):
            image = f"animlab/captures/frame_{frame:06d}.png"
            Image.new("RGB", (160, 120), (frame * 4, frame, 100)).save(self.data / image)
            self.events.append({"kind": "sample", "frame": frame, "sim_time": frame / 30, "phase": "walk", "phase_index": 1, "phase_frame": frame - 30, "view": "side", "image": image, "capture_ok": True, "units": [{"name": "subject", "id": 1, "position": [frame / 3, 0, 0], "heading": 0, "in_view": True, "pieces": [{"name": "foot", "position": [frame / 3 + (frame % 2), 0, 0], "ground_y": 0}, {"name": "head", "position": [frame / 3, 10, 0], "ground_y": 0}]}]})
        self.events.append({"kind": "complete", "status": "complete", "frame": 42})
        self.write_fixture()

    def tearDown(self):
        self.temp.cleanup()

    def write_fixture(self):
        (self.run / "manifest.json").write_text(json.dumps(self.manifest), encoding="utf-8")
        (self.data / "animlab" / "events.jsonl").write_text("\n".join(json.dumps(e) for e in self.events) + "\n", encoding="utf-8")

    def analyze(self):
        self.write_fixture()
        return analyze.analyze_run(self.run, make_video=False)

    def codes(self, report, key="capture_problems"):
        return {issue["code"] for issue in report[key]}

    def test_complete_evidence_still_needs_visual_review(self):
        report = self.analyze()
        self.assertEqual(report["status"], "needs_visual_review")
        self.assertEqual(report["visual_quality"], "not_automatically_assessed")
        self.assertTrue(report["synthetic_fixture"])
        self.assertEqual(report["captured_samples"], 4)
        self.assertTrue((self.run / "analysis" / "contact_01.jpg").is_file())
        review = json.loads((self.run / "analysis" / "review.json").read_text())
        self.assertEqual(review["status"], "unreviewed")
        self.assertIn("SYNTHETIC TEST FIXTURE", (self.run / "analysis" / "index.html").read_text())

    def test_missing_png_and_completion_are_not_success(self):
        (self.data / self.events[3]["image"]).unlink()
        self.events.pop()
        report = self.analyze()
        self.assertEqual(report["status"], "capture_incomplete")
        self.assertTrue({"missing_completion", "missing_or_invalid_image", "capture_gap"} <= self.codes(report))

    def test_truncated_image_is_rejected(self):
        path = self.data / self.events[2]["image"]
        path.write_bytes(path.read_bytes()[:50])
        report = self.analyze()
        self.assertIn("missing_or_invalid_image", self.codes(report))

    def test_path_escape_is_rejected(self):
        self.events[2]["image"] = "../../outside.png"
        report = self.analyze()
        self.assertIn("missing_or_invalid_image", self.codes(report))

    def test_missing_phase_and_monotonicity_are_checked(self):
        self.manifest["scenario"]["phases"].append({"name": "return_to_idle", "frames": 30})
        self.events[3]["frame"] = self.events[2]["frame"]
        self.events[3]["sim_time"] = self.events[2]["sim_time"]
        report = self.analyze()
        self.assertTrue({"missing_phase", "nonmonotone_samples"} <= self.codes(report))

    def test_runtime_error_and_failed_check_fail_the_run(self):
        self.events.insert(-1, {"kind": "check", "frame": 41, "check": "transported", "unit": "subject", "ok": False})
        self.events.insert(-1, {"kind": "error", "message": "script call failed"})
        report = self.analyze()
        self.assertEqual(report["status"], "failed")
        self.assertTrue({"runtime_error", "mechanical_check_failed"} <= self.codes(report, "runtime_failures"))

    def test_runner_timeout_cannot_become_success_from_partial_artifacts(self):
        self.manifest["status"] = "timed_out"
        report = self.analyze()
        self.assertEqual(report["status"], "failed")
        self.assertIn("runner_failed", self.codes(report, "runtime_failures"))

    def test_explicit_lua_errors_are_reported_not_normal_chat(self):
        (self.data / "infolog.txt").write_text("[f=0] LuaRules has no errors\n[f=20] Error: LuaRules::RunCallIn: script.lua:52: attempt to index a nil value\n", encoding="utf-8")
        report = self.analyze()
        self.assertEqual(report["status"], "failed")
        errors = [i for i in report["runtime_failures"] if i["code"] == "engine_error"]
        self.assertEqual(len(errors), 1)
        self.assertEqual(errors[0]["line"], 2)

    def test_existing_review_is_preserved_and_staleness_flagged(self):
        self.analyze()
        path = self.run / "analysis" / "review.json"
        review = json.loads(path.read_text())
        review.update(status="changes_required", reviewer="test reviewer", conclusion="Example finding")
        path.write_text(json.dumps(review))
        self.events[2]["units"][0]["position"][0] += 1
        report = self.analyze()
        self.assertEqual(json.loads(path.read_text()), review)
        self.assertIn("stale_review", self.codes(report, "review_problems"))
        self.assertEqual(report["status"], "needs_visual_review")

    def test_auxiliary_offscreen_unit_is_allowed_but_subject_is_not(self):
        self.events[2]["units"][0].update(in_view=False, camera_subject=False)
        self.assertEqual(self.analyze()["status"], "needs_visual_review")
        self.events[2]["units"][0]["camera_subject"] = True
        self.assertIn("subject_out_of_view", self.codes(self.analyze()))

    def test_stationary_emission_points_are_a_hint_never_quality_failure(self):
        for event in self.events:
            if event["kind"] == "sample":
                unit = event["units"][0]
                unit["pieces"][0]["position"][0] = unit["position"][0]
        report = self.analyze()
        self.assertEqual(report["status"], "needs_visual_review")
        self.assertIn("possible_frozen_pose", self.codes(report, "candidates"))

    def test_failed_sample_records_do_not_fill_phase_coverage(self):
        for event in self.events:
            if event["kind"] == "sample":
                event["capture_ok"] = False
        report = self.analyze()
        self.assertEqual(report["captured_samples"], 0)
        self.assertIn("missing_phase", self.codes(report))

    def test_invalid_telemetry_does_not_fill_phase_coverage(self):
        for event in self.events:
            if event["kind"] == "sample":
                event["units"][0]["pieces"][0]["position"] = [1, 2]
        report = self.analyze()
        self.assertEqual(report["captured_samples"], 0)
        self.assertIn("missing_phase", self.codes(report))
        self.assertEqual(report["rendered_images_for_review"], 4)
        self.assertEqual(len(report["excluded_samples"]), 4)
        self.assertTrue(report["contact_sheets"])

    def test_explicit_destroy_action_allows_dead_subject_without_pose(self):
        self.manifest["scenario"]["phases"][0]["actions"] = [{"type": "destroy", "unit": "subject"}]
        for event in self.events:
            if event["kind"] == "sample":
                event["units"] = [{"name": "subject", "id": 1, "alive": False, "expected_destroyed": True, "camera_subject": True}]
        report = self.analyze()
        self.assertEqual(report["captured_samples"], 4)
        self.assertEqual(report["status"], "needs_visual_review")
        self.manifest["scenario"]["phases"][0]["actions"] = []
        report = self.analyze()
        self.assertEqual(report["captured_samples"], 0)
        self.assertEqual(report["status"], "failed")
        self.assertIn("unexpected_subject_death", self.codes(report, "runtime_failures"))

    def test_below_ground_emission_point_is_not_a_mesh_contact_assertion(self):
        for event in self.events:
            if event["kind"] == "sample":
                piece = event["units"][0]["pieces"][0]
                piece["position"][1] = -5
                piece["position_kind"] = "emission_point"
        report = self.analyze()
        self.assertEqual(report["status"], "needs_visual_review")
        candidates = [item for item in report["candidates"] if item["code"] == "emission_point_below_ground"]
        self.assertEqual(len(candidates), 1)
        self.assertIn("not a joint pivot", candidates[0]["message"])
        review_text = (self.run / "analysis" / "review.md").read_text()
        self.assertIn("interpolated rendered pose", review_text)

    def test_other_run_samples_do_not_fill_phase_coverage(self):
        self.manifest["run_id"] = "expected-run"
        for event in self.events:
            event["run_id"] = "expected-run"
            if event["kind"] == "sample":
                event["run_id"] = "different-run"
        report = self.analyze()
        self.assertEqual(report["captured_samples"], 0)
        self.assertIn("run_id_mismatch", self.codes(report))

    def test_phase_events_can_arrive_before_earlier_async_png_records(self):
        # Phase records and PNG completion are independent channels. A phase
        # event arriving ahead of queued earlier PNG records is not a defect.
        samples = [event for event in self.events if event["kind"] == "sample"]
        phase = self.events[1]
        self.events = [self.events[0], *samples[:1], phase, *samples[1:], self.events[-1]]
        self.assertEqual(self.analyze()["status"], "needs_visual_review")

    def test_timing_uses_real_frame_gaps(self):
        timing = analyze._video_timing([
            {"frame": 30, "image": "a.png"},
            {"frame": 33, "image": "b.png"},
            {"frame": 45, "image": "c.png"},
        ], fps=30, interval=3, complete_frame=48)
        self.assertEqual([round(item["duration_seconds"], 4) for item in timing], [0.1, 0.4, 0.1])

    def test_nonfinite_json_is_reported_without_crashing(self):
        self.events[2]["units"][0]["position"][0] = float("nan")
        report = self.analyze()
        self.assertIn("malformed_event", self.codes(report))

    @unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "ffmpeg/ffprobe optional")
    def test_encoded_video_keeps_simulation_duration(self):
        report = analyze.analyze_run(self.run, make_video=True)
        self.assertEqual(report["video"]["status"], "created")
        self.assertFalse(report["video"]["interpolated_frames"])
        result = subprocess.run([shutil.which("ffprobe"), "-v", "error", "-show_entries", "format=duration", "-of", "json", str(self.run / "analysis" / "animation.mp4")], capture_output=True, text=True, check=True)
        duration = float(json.loads(result.stdout)["format"]["duration"])
        self.assertAlmostEqual(duration, 0.4, delta=0.05)


if __name__ == "__main__":
    unittest.main()
