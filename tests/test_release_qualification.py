import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "qualification",
    Path(__file__).resolve().parents[1] / "tools/qualify_windows_release.py",
)
qualification = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(qualification)


class QualificationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.raw = self.root / "capture.csv"
        self.raw.write_text("second,fps\n0,25\n600,26\n", encoding="utf-8")
        self.manifest = {
            "schema_version": 1, "portable": True, "game_version": "1.035",
            "source_commit": "a" * 40,
            "inputs": {
                "engine": {"version": "BAR105-105.1.1-1544-g058c8ea"},
                "map": {"version": "LastDayOfDhubai"},
            },
            "artifacts": [{"path": "Mosaic_v1.035_windows-portable.zip", "sha256": "b" * 64}],
            "performance_gate": {"minimum_zoomed_out_fps": 25, "status": "unverified"},
        }
        self.evidence = {
            "schema_version": 1, "gate": "minimum-25-fps-zoomed-out",
            "measured_at": "2026-11-13T12:00:00+01:00",
            "source_commit": "a" * 40, "game_version": "1.035",
            "engine_build": "BAR105-105.1.1-1544-g058c8ea",
            "map": "LastDayOfDhubai",
            "resolution": {"width": 1920, "height": 1080},
            "settings_profile": "packaging/springsettings.cfg",
            "gpu": "NVIDIA GeForce GTX 1050 Ti",
            "load": {"city_buildings": 120, "units_total": 175},
            "camera": "fully-zoomed-out", "duration_seconds": 600,
            "minimum_fps": 25, "average_fps": 31,
            "evidence_file": self.raw.name,
            "raw_evidence_sha256": hashlib.sha256(self.raw.read_bytes()).hexdigest(),
        }

    def qualify(self):
        return qualification.qualify(self.manifest, self.evidence, self.root)

    def test_exact_threshold_qualifies_bound_candidate(self):
        result = self.qualify()
        self.assertTrue(result["release_qualified"])
        self.assertEqual(result["performance_gate"]["status"], "passed")

    def test_average_cannot_hide_failed_minimum(self):
        self.evidence.update(minimum_fps=24.9, average_fps=60)
        with self.assertRaisesRegex(ValueError, "below 25"):
            self.qualify()

    def test_candidate_identity_must_match(self):
        for key, value in (("source_commit", "c" * 40), ("game_version", "1.034"),
                           ("engine_build", "other"), ("map", "other")):
            with self.subTest(key=key):
                original = self.evidence[key]
                self.evidence[key] = value
                with self.assertRaisesRegex(ValueError, key):
                    self.qualify()
                self.evidence[key] = original

    def test_raw_capture_is_hash_bound(self):
        self.raw.write_text("tampered", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            self.qualify()

    def test_nonportable_manifest_is_rejected(self):
        self.manifest["portable"] = False
        with self.assertRaisesRegex(ValueError, "portable"):
            self.qualify()


if __name__ == "__main__":
    unittest.main()

