"""External runner regression tests. Fake engines verify protocol, not animation quality."""
from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from runner import LabError, REQUIRED_GAME_DIRS, digest_file, execute_run, make_startscript, prepare_run, validate_scenario


def example_scenario() -> dict:
    return {
        "schema_version": 1,
        "name": "Locomotion smoke observation",
        "units": [{"name": "subject", "def": "civilian_western0"}],
        "phases": [
            {"name": "idle", "frames": 30, "checks": [{"type": "alive", "unit": "subject"}]},
            {"name": "walk", "frames": 90, "actions": [{"type": "move", "unit": "subject", "x": 100, "z": 0}],
             "checks": [{"type": "displaced", "unit": "subject", "min": 4}], "expected_motion": True},
        ],
    }


class IsolatedRunTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="animation-lab-runner-test-")
        self.root = Path(self.temporary.name)
        self.game = self.root / "game source"
        self.game.mkdir()
        (self.game / "modinfo.lua").write_text('return {name="MOSAIC", version="$VERSION", depend={"Spring content"}, shortname="MOSAIC"}\n')
        for directory in REQUIRED_GAME_DIRS:
            target = self.game / directory
            target.mkdir()
            (target / "fixture.txt").write_text("game data: " + directory)
        (self.game / ".git").mkdir()
        (self.game / ".git" / "config").write_text("must not be copied")
        self.harness = self.root / "external lab"
        overlay = self.harness / "overlay" / "luarules" / "gadgets"
        overlay.mkdir(parents=True)
        (overlay / "dbg_animation_lab.lua").write_text("-- synthetic runner fixture, no animation\n")
        self.output = self.root / "observation run"

    def tearDown(self):
        self.temporary.cleanup()

    def prepare(self, **kwargs):
        defaults = dict(game=self.game, scenario=example_scenario(), output=self.output, map_name="Dhubai Test v1", harness_root=self.harness, allow_unversioned_game=True)
        defaults.update(kwargs)
        return prepare_run(**defaults)

    def test_internal_file_link_is_opt_in_and_materialized_without_source_changes(self):
        link = self.game / 'alias.lua'
        target = self.game / 'scripts' / 'fixture.txt'
        link.symlink_to('scripts/fixture.txt')
        with self.assertRaisesRegex(LabError, 'symlink'):
            self.prepare()
        manifest = self.prepare(materialize_internal_symlinks=True)
        copied = Path(manifest['staged_game']) / 'alias.lua'
        self.assertTrue(link.is_symlink())
        self.assertFalse(copied.is_symlink())
        self.assertEqual(copied.read_bytes(), target.read_bytes())
        self.assertNotEqual(copied.stat().st_ino, target.stat().st_ino)
        self.assertEqual(manifest['source']['materialized_internal_links'], {'alias.lua': 'scripts/fixture.txt'})

    def test_opt_in_still_rejects_external_file_and_internal_directory_links(self):
        external = self.root / 'external.lua'
        external.write_text('outside')
        link = self.game / 'alias.lua'
        link.symlink_to(external)
        with self.assertRaisesRegex(LabError, 'symlink'):
            self.prepare(materialize_internal_symlinks=True)
        link.unlink()
        link.symlink_to(self.game / 'scripts', target_is_directory=True)
        with self.assertRaisesRegex(LabError, 'symlink'):
            self.prepare(materialize_internal_symlinks=True)

    def test_staging_does_not_change_source_or_share_file_inodes(self):
        before = {str(path.relative_to(self.game)): digest_file(path) for path in self.game.rglob("*") if path.is_file()}
        manifest = self.prepare()
        stage = Path(manifest["staged_game"])
        self.assertFalse((stage / ".git").exists())
        self.assertTrue((stage / "luarules/gadgets/dbg_animation_lab.lua").is_file())
        self.assertFalse((self.game / "luarules/gadgets/dbg_animation_lab.lua").exists())
        (stage / "scripts/fixture.txt").write_text("changed only in disposable copy")
        after = {str(path.relative_to(self.game)): digest_file(path) for path in self.game.rglob("*") if path.is_file()}
        self.assertEqual(before, after)
        self.assertEqual(manifest["status"], "prepared")
        self.assertEqual(manifest["visual_review"], "not_performed")
        self.assertEqual(manifest["interpolation"], "none")
        self.assertIsNone(manifest["command"])
        self.assertIn('depend={"Spring content"}', (stage / "modinfo.lua").read_text())
        settings = (self.output / "springsettings.cfg").read_text()
        self.assertIn("XResolutionWindowed = 1280", settings)
        self.assertIn("YResolutionWindowed = 720", settings)

    def test_output_inside_source_is_rejected_without_writes(self):
        with self.assertRaisesRegex(LabError, "must not contain"):
            self.prepare(output=self.game / "captures")
        self.assertFalse((self.game / "captures").exists())

    def test_output_inside_lab_is_rejected_without_writes(self):
        with self.assertRaisesRegex(LabError, "must not contain"):
            self.prepare(output=self.harness / "captures")
        self.assertFalse((self.harness / "captures").exists())

    def test_existing_evidence_is_not_overwritten(self):
        self.output.mkdir()
        sentinel = self.output / "manifest.json"
        sentinel.write_text("previous observation")
        with self.assertRaisesRegex(LabError, "new or empty"):
            self.prepare()
        self.assertEqual(sentinel.read_text(), "previous observation")

    @unittest.skipIf(os.name == "nt", "Symlink privileges are not universal on Windows")
    def test_external_symlink_cannot_smuggle_source_writes(self):
        outside = self.root / "other checkout"
        outside.mkdir()
        sentinel = outside / "sentinel.lua"
        sentinel.write_text("preserve me")
        (self.game / "scripts" / "linked").symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(LabError, "symlink"):
            self.prepare()
        self.assertEqual(sentinel.read_text(), "preserve me")
        self.assertFalse(self.output.exists())

    def test_sparse_game_is_rejected_before_expensive_copy(self):
        (self.game / "objects3d/fixture.txt").unlink()
        with self.assertRaisesRegex(LabError, "complete checkout"):
            self.prepare()
        self.assertFalse(self.output.exists())

    @unittest.skipUnless(shutil.which("git"), "Git required for partial-checkout regression")
    def test_nonempty_asset_dirs_do_not_hide_missing_indexed_files(self):
        shutil.rmtree(self.game / ".git")
        missing = self.game / "objects3d" / "actual_model.dae"
        missing.write_text("tracked asset")
        subprocess.run(["git", "init", "-q", str(self.game)], check=True)
        subprocess.run(["git", "-C", str(self.game), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.game), "update-index", "--skip-worktree", "objects3d/actual_model.dae"], check=True)
        missing.unlink()
        with self.assertRaisesRegex(LabError, "tracked paths are missing"):
            self.prepare()
        self.assertFalse(self.output.exists())
        self.assertFalse(missing.exists())

    def test_unversioned_source_requires_explicit_override(self):
        with self.assertRaisesRegex(LabError, "allow-unversioned-game"):
            self.prepare(allow_unversioned_game=False)
        self.assertFalse(self.output.exists())
        manifest = self.prepare(allow_unversioned_game=True)
        self.assertFalse(manifest["source"]["materialization"]["git_completeness_verified"])

    def test_map_archive_is_copied_hashed_and_not_linked(self):
        archive = self.root / "Dhubai.sd7"
        archive.write_bytes(b"synthetic map archive")
        manifest = self.prepare(map_archive=archive)
        staged_archive = Path(manifest["write_dir"]) / "maps/Dhubai.sd7"
        self.assertEqual(manifest["map"]["archive"]["sha256"], digest_file(archive))
        staged_archive.write_bytes(b"changed staged data")
        self.assertEqual(archive.read_bytes(), b"synthetic map archive")

    def test_startscript_uses_archive_filename_not_version_name_heuristic(self):
        manifest = self.prepare()
        archive = Path(manifest["staged_game"]).name
        self.assertEqual(manifest["game_type"], archive)
        self.assertTrue(archive.endswith(".sdd"))
        self.assertIn(f"GameType={archive};", (self.output / "startscript.txt").read_text())

    @unittest.skipIf(os.name == "nt", "POSIX fake executable protocol fixture")
    def test_graphical_engine_protocol_requires_matching_completion(self):
        engine = self.fake_engine('marker = {"schema_version": 1, "run_id": manifest["run_id"], "status": "complete"}\ncompletion.write_text(json.dumps(marker))\n')
        manifest = self.prepare(engine=engine)
        self.assertEqual(manifest["command"][0], str(engine))
        self.assertIn("--isolation-dir", manifest["command"])
        self.assertIn("--write-dir", manifest["command"])
        self.assertIn(str(engine.parent), manifest["environment"]["SPRING_DATADIR"].split(os.pathsep))
        completed = execute_run(self.output, timeout=3, poll_interval=0.01)
        self.assertEqual(completed["status"], "captured")
        self.assertEqual(completed["visual_review"], "not_performed")
        self.assertTrue((self.output / "engine-console.log").exists())

    @unittest.skipIf(os.name == "nt", "POSIX fake executable protocol fixture")
    def test_exit_zero_without_marker_is_not_a_successful_capture(self):
        self.prepare(engine=self.fake_engine("pass\n"))
        result = execute_run(self.output, timeout=3, poll_interval=0.01)
        self.assertEqual(result["status"], "capture_failed")
        self.assertIn("without the lab completion marker", result["error"])

    @unittest.skipIf(os.name == "nt", "POSIX fake executable protocol fixture")
    def test_stale_or_unspecified_completion_status_does_not_pass(self):
        self.prepare(engine=self.fake_engine('completion.write_text(json.dumps({"run_id": "another-run", "status": "complete"}))\n'))
        result = execute_run(self.output, timeout=3, poll_interval=0.01)
        self.assertEqual(result["status"], "capture_failed")
        self.assertIn("does not match", result["error"])

    @unittest.skipIf(os.name == "nt", "POSIX fake executable protocol fixture")
    def test_timeout_is_bounded_and_leaves_failure_evidence(self):
        self.prepare(engine=self.fake_engine("import time\ntime.sleep(10)\n"))
        result = execute_run(self.output, timeout=1, poll_interval=0.01)
        self.assertEqual(result["status"], "timed_out")
        self.assertLess(result["elapsed_seconds"], 5)
        self.assertIsNotNone(result["engine_exit_code"])

    def test_capture_window_position_is_explicit_and_recorded(self):
        manifest = self.prepare(window_position=(1000, 100))
        self.assertEqual(manifest["engine_settings"]["WindowPosX"], 1000)
        self.assertIn("WindowPosY = 100", (self.output / "springsettings.cfg").read_text())

    def test_disable_fontconfig_is_explicit_and_recorded(self):
        manifest = self.prepare(disable_fontconfig=True)
        self.assertEqual(manifest["engine_settings"]["UseFontConfigLib"], 0)
        self.assertIn("UseFontConfigLib = 0", (self.output / "springsettings.cfg").read_text())

    def test_piece_geometry_flag_is_typed(self):
        spec = example_scenario()
        spec['units'][0]['piece_geometry'] = 'yes'
        with self.assertRaisesRegex(LabError, 'piece_geometry'):
            validate_scenario(spec)
        spec['units'][0]['piece_geometry'] = True
        self.assertTrue(validate_scenario(spec)['units'][0]['piece_geometry'])

    def test_single_step_capture_is_recorded(self):
        result = self.prepare(single_step_capture=True)
        self.assertTrue(result["single_step_capture"])
        config = Path(result["staged_game"]) / "luarules/configs/animation_lab_run.lua"
        self.assertIn('["single_step_capture"] = true', config.read_text())

    def test_stationary_fixture_is_explicit_and_typed(self):
        spec = example_scenario()
        self.assertNotIn('stationary_fixture', validate_scenario(spec)['units'][0])
        spec['units'][0]['stationary_fixture'] = 'yes'
        with self.assertRaisesRegex(LabError, 'stationary_fixture'):
            validate_scenario(spec)
        spec['units'][0]['stationary_fixture'] = True
        result = self.prepare(scenario=spec)
        config = Path(result['staged_game']) / 'luarules/configs/animation_lab_run.lua'
        self.assertIn('["stationary_fixture"] = true', config.read_text())

    def test_observer_only_ui_is_opt_in_and_hashed(self):
        fixture = self.harness / "observer_only_luaui.lua"
        fixture.write_text("-- synthetic observer fixture\n")
        original = self.game / "luaui.lua"
        original.write_text("-- production UI\n")
        result = self.prepare(observer_only_ui=True)
        self.assertTrue(result["observer_only_ui"])
        self.assertEqual(original.read_text(), "-- production UI\n")
        self.assertTrue(any(record["path"] == "luaui.lua" and record["sha256"] == digest_file(fixture)
                            for record in result["instrumentation"]))

    def fake_engine(self, body):
        engine = self.root / "fake graphical engine"
        engine.write_text(f"#!{sys.executable}\n" + 'import json, sys\nfrom pathlib import Path\nif "--version" in sys.argv:\n    print("Synthetic runner fixture, not Recoil")\n    raise SystemExit(0)\nmanifest=json.loads(Path("manifest.json").read_text())\ncompletion=Path(manifest["completion_path"])\n' + body)
        engine.chmod(0o755)
        return engine

    @unittest.skipIf(os.name == "nt", "POSIX fake executable protocol fixture")
    def test_legacy_engine_mode_keeps_loopback_binding_and_isolated_paths(self):
        manifest = self.prepare(engine=self.fake_engine('pass\n'), local_server_compat=True)
        self.assertIn('--server=127.0.0.1', manifest['command'])
        self.assertNotIn('--only-local', manifest['command'])
        self.assertIn('--isolation-dir', manifest['command'])
        self.assertIn('--write-dir', manifest['command'])
        self.assertIn('HostIP=127.0.0.1;', (self.output/'startscript.txt').read_text())


class ScenarioTests(unittest.TestCase):
    def test_defaults_preserve_input_and_generate_explicit_seeded_startscript(self):
        original = example_scenario()
        untouched = copy.deepcopy(original)
        scenario = validate_scenario(original)
        self.assertEqual(original, untouched)
        script = make_startscript("MOSAIC Lab 1", "Dhubai v1", 321, scenario["modoptions"])
        self.assertIn("FixedRNGSeed=321;", script)
        self.assertIn("teamdeathmode=none;", script)
        self.assertIn("HostIP=127.0.0.1;", script)

    def test_tdf_injection_is_rejected(self):
        with self.assertRaisesRegex(LabError, "delimiter"):
            make_startscript("MOSAIC", "Dhubai; IsHost=0", 123, {})

    def test_unknown_action_and_reference_fail_before_engine_launch(self):
        for action in ({"type": "execute", "unit": "subject", "code": "os.execute('bad')"}, {"type": "stop", "unit": "missing"}):
            scenario = example_scenario()
            scenario["phases"][0]["actions"] = [action]
            with self.assertRaises(LabError):
                validate_scenario(scenario)

    def test_script_call_arguments_cannot_load_or_evaluate_code(self):
        for function in ("os.execute", "loadstring", "foo();os.execute('bad')"):
            scenario = example_scenario()
            scenario["phases"][0]["actions"] = [{"type": "call", "unit": "subject", "function": function, "args": []}]
            with self.assertRaises(LabError):
                validate_scenario(scenario)

    def test_nested_unit_refs_resolve_only_declared_names(self):
        scenario = example_scenario()
        scenario["phases"][0]["actions"] = [{"type": "call", "unit": "subject", "function": "setPartner", "args": [[{"ref": "ghost"}]]}]
        with self.assertRaisesRegex(LabError, "unknown unit reference"):
            validate_scenario(scenario)

    def test_nonfinite_and_boolean_coordinates_are_rejected(self):
        for value in (float("nan"), float("inf"), True):
            scenario = example_scenario()
            scenario["units"][0]["x"] = value
            with self.assertRaises(LabError):
                validate_scenario(scenario)

    def test_checks_refer_to_actual_units_and_known_predicates(self):
        scenario = example_scenario()
        scenario["phases"][0]["checks"] = [{"type": "transported", "unit": "subject", "transporter": "ghost"}]
        with self.assertRaisesRegex(LabError, "unknown unit reference"):
            validate_scenario(scenario)

    def test_malformed_reference_types_fail_as_validation_errors(self):
        actions = [
            {"type": [], "unit": "subject"},
            {"type": "stop", "unit": {}},
            {"type": "call", "unit": "subject", "function": "setPartner", "args": [{"ref": []}]},
        ]
        for action in actions:
            scenario = example_scenario()
            scenario["phases"][0]["actions"] = [action]
            with self.assertRaises(LabError):
                validate_scenario(scenario)


if __name__ == "__main__":
    unittest.main()
