"""Offline integration tests for release success and failure boundaries."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

SPEC = importlib.util.spec_from_file_location('packaging_tool', Path(__file__).resolve().parents[1] / 'tools/package_windows_release.py')
p = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(p)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'repo'
        self.repo.mkdir()
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        for key, value in [('user.name', 'Release Test'), ('user.email', 'test@example.invalid'), ('core.autocrlf', 'false')]:
            p.run(self.repo, 'config', key, value)
        for name in p.REQUIRED_GAME:
            if name.endswith('.lua'):
                continue
            self.write(name + '/fixture.txt', 'game asset')
        self.write('scripts/lib_mosaic.lua', 'GameVersion = "1.033" --UpdateFlag\n')
        self.write('modinfo.lua', "return {\n version = '$VERSION',\n}\n")
        self.write('packaging/springsettings.cfg', 'Fullscreen = 0\n')
        self.write('tools/private.txt', 'must not ship')
        self.commit()
        self.out = self.base / 'output'

    def write(self, name, value):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding='utf-8')

    def commit(self):
        p.run(self.repo, 'add', '.')
        p.run(self.repo, 'commit', '-qm', 'fixture')

    def archive(self, name, files):
        path = self.base / name
        with zipfile.ZipFile(path, 'w') as z:
            for n, content in files.items():
                z.writestr(n, content)
        return path

    def lock(self):
        assets = {
            'engine': self.archive('engine.zip', {'spring.exe': 'exe', 'unitsync.dll': 'dll', 'base/springcontent.sdz': 'base'}),
            'lobby': self.archive('lobby.zip', {'Skylobby/skylobby.exe': 'exe', 'Skylobby/runtime.dll': 'runtime'}),
            'map': self.archive('map.sdz', {'mapinfo.lua': 'return {}', 'maps/Dhubai.smf': 'terrain'}),
        }
        lock = {'schema_version': 1}
        for role, path in assets.items():
            lock[role] = {'path': path.name, 'version': 'fixture-1', 'sha256': p.sha256(path), 'format': 'zip'}
        lock['engine'].update(root='.', required_files=['spring.exe', 'unitsync.dll'])
        lock['lobby'].update(root='Skylobby', required_files=['skylobby.exe', 'runtime.dll'])
        lock['map']['filename'] = 'LastDayOfDhubai.sdz'
        path = self.base / 'lock.json'
        path.write_text(json.dumps(lock))
        return path, lock

    def update_lock(self, path, lock):
        path.write_text(json.dumps(lock))

    def test_sdz_version_checksums_and_reproduction(self):
        manifest = p.package(self.repo, self.out, expected='v1.033')
        self.assertFalse(manifest['portable'])
        game = self.out / 'Mosaic_v1.033.sdz'
        with zipfile.ZipFile(game) as z:
            self.assertIn("version = '1.033'", z.read('modinfo.lua').decode())
            self.assertNotIn('tools/private.txt', z.namelist())
        self.assertIn('$VERSION', (self.repo / 'modinfo.lua').read_text())
        second = self.base / 'second'
        p.package(self.repo, second)
        self.assertEqual(game.read_bytes(), (second / game.name).read_bytes())
        for line in (self.out / 'SHA256SUMS').read_text().splitlines():
            digest, name = line.split('  ', 1)
            self.assertEqual(digest, p.sha256(self.out / name))

    def test_portable_payload_and_manifest(self):
        path, lock = self.lock()
        manifest = p.package(self.repo, self.out, path, '1.033')
        bundle = self.out / 'Mosaic_v1.033_windows-portable.zip'
        with zipfile.ZipFile(bundle) as z:
            for name in ('engine/spring.exe', 'engine/unitsync.dll', 'lobby/skylobby.exe', 'data/games/Mosaic_v1.033.sdz', 'data/maps/LastDayOfDhubai.sdz', 'data/springsettings.cfg', 'Start-Mosaic.cmd', 'PLAY.txt', 'manifest.json'):
                self.assertIn(name, z.namelist())
            for item in manifest['payload_files']:
                data = z.read(item['path'])
                self.assertEqual(item['sha256'], hashlib.sha256(data).hexdigest())
                self.assertEqual(item['bytes'], len(data))
        self.assertEqual(manifest['inputs'], lock)
        self.assertEqual(next(f['sha256'] for f in manifest['artifacts'] if f['path'] == bundle.name), p.sha256(bundle))

    def test_version_drift_and_duplicates(self):
        for lib, mod, expected in [
            ('GameVersion = "1.033"', "version = '1.032',", None),
            ('GameVersion = "1.033"', "version = '$VERSION',", '1.032'),
            ('GameVersion = "1.033"\nGameVersion = "1.034"', "version = '$VERSION',", None),
            ('GameVersion = "1.033"', "version = '$VERSION',\nversion = '$VERSION',", None),
        ]:
            with self.subTest(lib=lib, mod=mod), self.assertRaises(ValueError):
                p.resolve_version(lib, mod, expected)

    def test_failure_exposes_no_partial_output(self):
        path, lock = self.lock()
        lock['lobby']['sha256'] = '0' * 64
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'SHA-256 mismatch'):
            p.package(self.repo, self.out, path)
        self.assertFalse(self.out.exists())
        self.assertFalse(list(self.base.glob('.mosaic-release-*')))

    def test_missing_runtime_file(self):
        path, lock = self.lock()
        lock['lobby']['required_files'].append('missing.dll')
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'missing required file'):
            p.package(self.repo, self.out, path)
        self.assertFalse(self.out.exists())

    def test_missing_game_assets(self):
        shutil.rmtree(self.repo / 'objects3d')
        self.commit()
        with self.assertRaisesRegex(ValueError, 'Missing required game asset'):
            p.package(self.repo, self.out)

    def test_dirty_tree_and_lfs(self):
        self.write('modinfo.lua', "version = '1.033',")
        with self.assertRaisesRegex(ValueError, 'dirty'):
            p.package(self.repo, self.out)
        self.commit()
        self.write('objects3d/pointer', 'version https://git-lfs.github.com/spec/v1\noid sha256:abc\n')
        self.commit()
        with self.assertRaisesRegex(ValueError, 'LFS pointer'):
            p.package(self.repo, self.out)

    def test_unconfigured_lock_fails(self):
        example = Path(__file__).resolve().parents[1] / 'packaging/windows-inputs.json'
        with self.assertRaisesRegex(ValueError, 'must be pinned'):
            p.package(self.repo, self.out, example)

    def test_existing_output_is_preserved(self):
        self.out.mkdir()
        keep = self.out / 'keep.txt'
        keep.write_text('keep')
        with self.assertRaisesRegex(ValueError, 'already exists'):
            p.package(self.repo, self.out)
        self.assertEqual(keep.read_text(), 'keep')

    def test_package_version_drift_has_no_output(self):
        with self.assertRaisesRegex(ValueError, 'Version drift'):
            p.package(self.repo, self.out, expected='1.032')
        self.assertFalse(self.out.exists())

    def test_zip_symlink_rejected(self):
        archive = self.base / 'link.zip'
        with zipfile.ZipFile(archive, 'w') as z:
            entry = zipfile.ZipInfo('link')
            entry.create_system = 3
            entry.external_attr = 0o120777 << 16
            z.writestr(entry, '../outside')
        with self.assertRaisesRegex(ValueError, 'symlink rejected'):
            p.extract(archive, self.base / 'links', 'zip')

    def test_engine_base_assets_required(self):
        path, lock = self.lock()
        archive = self.archive('engine.zip', {'spring.exe': 'exe', 'unitsync.dll': 'dll'})
        lock['engine']['sha256'] = p.sha256(archive)
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'base SDZ'):
            p.package(self.repo, self.out, path)
        self.assertFalse(self.out.exists())

    def test_unsafe_and_duplicate_archives(self):
        for i, files in enumerate([{'../escaped': 'bad'}, {'A.txt': 'a', 'a.txt': 'b'}, {'C:/evil': 'bad'}, {'CON.txt': 'bad'}, {'a//b': 'bad'}, {'invalid?.exe': 'bad'}]):
            archive = self.archive(f'bad{i}.zip', files)
            with self.subTest(files=files), self.assertRaises(ValueError):
                p.extract(archive, self.base / f'unpack{i}', 'zip')
        self.assertFalse((self.base / 'escaped').exists())

    def test_map_metadata_and_terrain_required(self):
        path, lock = self.lock()
        archive = self.archive('map.sdz', {'mapinfo.lua': 'return {}'})
        lock['map']['sha256'] = p.sha256(archive)
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'SMF terrain'):
            p.package(self.repo, self.out, path)

    @unittest.skipUnless(shutil.which('7z') or shutil.which('7zz'), '7-Zip unavailable')
    def test_7z_extraction(self):
        exe = shutil.which('7z') or shutil.which('7zz')
        source = self.base / '7z-source'
        source.mkdir()
        (source / 'spring.exe').write_text('fixture')
        archive = self.base / 'engine.7z'
        subprocess.run([exe, 'a', str(archive), 'spring.exe'], cwd=source, check=True, stdout=subprocess.DEVNULL)
        destination = self.base / 'unpacked7z'
        p.extract(archive, destination, '7z')
        self.assertEqual((destination / 'spring.exe').read_text(), 'fixture')


if __name__ == '__main__':
    unittest.main()
