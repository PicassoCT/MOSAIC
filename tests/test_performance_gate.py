import importlib.util
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location(
    "performance_gate",
    Path(__file__).resolve().parents[1] / "tools/validate_performance_gate.py",
)
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)


def evidence(**updates):
    data = {
        "schema_version": 1,
        "gate": "minimum-25-fps-zoomed-out",
        "measured_at": "2026-10-09T12:00:00+02:00",
        "source_commit": "0" * 40,
        "engine_build": "BAR105 105.1.1-1544-g058c8ea",
        "map": "LastDayOfDhubai",
        "resolution": {"width": 1280, "height": 720},
        "settings_profile": "packaging/springsettings.cfg",
        "gpu": "NVIDIA GeForce GTX 1050 Ti",
        "load": {"city_buildings": 120, "units_total": 175},
        "camera": "fully-zoomed-out",
        "duration_seconds": 600,
        "minimum_fps": 25.0,
        "average_fps": 31.2,
        "evidence_file": "captures/gtx1050ti.csv",
    }
    data.update(updates)
    return data


class PerformanceGateTests(unittest.TestCase):
    def test_exact_threshold_passes(self):
        self.assertEqual(gate.validate(evidence())["status"], "passed")

    def test_average_does_not_hide_minimum_failure(self):
        result = gate.validate(evidence(minimum_fps=24.9, average_fps=60))
        self.assertEqual(result["status"], "failed")

    def test_short_or_not_zoomed_out_is_invalid(self):
        for update in ({"duration_seconds": 599}, {"camera": "mid-zoom"}):
            with self.subTest(update=update), self.assertRaises(ValueError):
                gate.validate(evidence(**update))

    def test_context_fields_are_required(self):
        for key in ("engine_build", "map", "settings_profile", "gpu", "evidence_file"):
            with self.subTest(key=key), self.assertRaises(ValueError):
                gate.validate(evidence(**{key: ""}))


if __name__ == "__main__":
    unittest.main()
