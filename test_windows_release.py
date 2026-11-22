"""Offline integration tests for release success and failure boundaries."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock
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
        self.write('scripts/lib_mosaic.lua', 'GameVersion = "1.034" --UpdateFlag\n')
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
        lobby = self.base / 'skylobby.jar'
        lobby.write_bytes(b'fixture Skylobby jar')
        assets = {
            'engine': self.archive('engine.zip', {'spring.exe': 'exe', 'unitsync.dll': 'dll', 'base/springcontent.sdz': 'base'}),
            'lobby': lobby,
            'runtime': self.archive('runtime.zip', {'bin/java.exe': 'exe', 'release': 'JAVA_VERSION="21.0.8"\nOS_ARCH="amd64"\nOS_NAME="Windows"\n'}),
            'map': self.archive('map.sdz', {'mapinfo.lua': 'return {}', 'maps/Dhubai.smf': 'terrain'}),
        }
        lock = {'schema_version': 1}
        for role, path in assets.items():
            lock[role] = {'path': path.name, 'version': 'fixture-1', 'sha256': p.sha256(path), 'format': 'zip'}
        lock['engine'].update(root='.', required_files=['spring.exe', 'unitsync.dll'])
        lock['lobby'].update(format='file', filename='skylobby.jar')
        lock['runtime'].update(root='.', required_files=['bin/java.exe', 'release'])
        lock['map']['filename'] = 'LastDayOfDhubai.sdz'
        path = self.base / 'lock.json'
        path.write_text(json.dumps(lock))
        return path, lock

    def update_lock(self, path, lock):
        path.write_text(json.dumps(lock))

    def test_sdz_version_checksums_and_reproduction(self):
        manifest = p.package(self.repo, self.out, expected='v1.034')
        self.assertFalse(manifest['portable'])
        game = self.out / 'Mosaic_v1.034.sdz'
        with zipfile.ZipFile(game) as z:
            self.assertIn("version = '1.034'", z.read('modinfo.lua').decode())
            self.assertNotIn('tools/private.txt', z.namelist())
        self.assertIn('$VERSION', (self.repo / 'modinfo.lua').read_text())
        second = self.base / 'second'
        p.package(self.repo, second)
        self.assertEqual(game.read_bytes(), (second / game.name).read_bytes())
        for line in (self.out / 'SHA256SUMS').read_text().splitlines():
            digest, name = line.split('  ', 1)
            self.assertEqual(digest, p.sha256(self.out / name))

    @unittest.skipUnless(shutil.which('7z') or shutil.which('7zz'), '7-Zip required')
    def test_sd7_game_and_ignored_development_files(self):
        self.write('AGENTS.md', 'development instructions')
        self.write('scripts/.private/notes.txt', 'hidden development data')
        self.write('.gitignore', '*.secret\n')
        self.commit()
        self.write('sounds/local.secret', 'untracked ignored input')
        manifest = p.package(self.repo, self.out, expected='1.034', game_format='sd7')
        archive = self.out / 'Mosaic_v1.034.sd7'
        self.assertEqual(manifest['game_format'], 'sd7')
        exe = shutil.which('7z') or shutil.which('7zz')
        listing = subprocess.check_output([exe, 'l', '-slt', str(archive)], text=True)
        self.assertNotIn('AGENTS.md', listing)
        self.assertNotIn('notes.txt', listing)
        self.assertNotIn('local.secret', listing)
        data = subprocess.check_output([exe, 'x', '-so', str(archive), 'modinfo.lua']).decode()
        self.assertIn("version = '1.034'", data)
        second = self.base / 'sd7-repeat'
        p.package(self.repo, second, expected='1.034', game_format='sd7')
        self.assertEqual(archive.read_bytes(), (second/archive.name).read_bytes())

    def test_portable_payload_and_manifest(self):
        path, lock = self.lock()
        manifest = p.package(self.repo, self.out, path, '1.034')
        bundle = self.out / 'Mosaic_v1.034_windows-portable.zip'
        with zipfile.ZipFile(bundle) as z:
            for name in ('data/engine/mosaic-pinned/spring.exe', 'data/engine/mosaic-pinned/unitsync.dll', 'lobby/skylobby.jar', 'runtime/bin/java.exe', 'data/games/Mosaic_v1.034.sdz', 'data/maps/LastDayOfDhubai.sdz', 'data/springsettings.cfg', 'Start-Mosaic.cmd', 'PLAY.txt', 'manifest.json'):
                self.assertIn(name, z.namelist())
            launcher = z.read('Start-Mosaic.cmd').decode()
            self.assertIn('--server-url "lobby.springrts.com:8200"', launcher)
            self.assertIn('--filter-battles "MOSAIC"', launcher)
            self.assertIn('--no-update-check', launcher)
            self.assertIn('runtime\\bin\\java.exe', launcher)
            for item in manifest['payload_files']:
                data = z.read(item['path'])
                self.assertEqual(item['sha256'], hashlib.sha256(data).hexdigest())
                self.assertEqual(item['bytes'], len(data))
        self.assertEqual(manifest['inputs'], lock)
        self.assertEqual(manifest['performance_gate'],
                         {'minimum_zoomed_out_fps': 25, 'status': 'unverified'})
        self.assertEqual(next(f['sha256'] for f in manifest['artifacts'] if f['path'] == bundle.name), p.sha256(bundle))

    def test_portable_game_archive_uses_zip64_when_required(self):
        path, _ = self.lock()
        # Exercise the real large-file boundary with a tiny committed fixture.
        with mock.patch.object(zipfile, 'ZIP64_LIMIT', 512):
            p.package(self.repo, self.out, path, '1.034')
        game = self.out / 'Mosaic_v1.034.sdz'
        self.assertGreater(game.stat().st_size, 512)
        with zipfile.ZipFile(self.out / 'Mosaic_v1.034_windows-portable.zip') as bundle:
            member = bundle.getinfo('data/games/' + game.name)
            self.assertGreaterEqual(member.extract_version, 45)
            self.assertEqual(member.file_size, game.stat().st_size)
            packaged_game = bundle.read(member)
            self.assertEqual(packaged_game, game.read_bytes())
        with zipfile.ZipFile(io.BytesIO(packaged_game)) as nested:
            self.assertIn("version = '1.034'", nested.read('modinfo.lua').decode())

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
        lock['runtime']['required_files'].append('missing.dll')
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
        example, lock = self.lock()
        lock['engine']['sha256'] = None
        self.update_lock(example, lock)
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
            p.package(self.repo, self.out, expected='1.033')
        self.assertFalse(self.out.exists())

    def test_java_runtime_identity_required(self):
        path, lock = self.lock()
        archive = self.archive('runtime.zip', {'bin/java.exe': 'exe', 'release': 'JAVA_VERSION="17"\nOS_ARCH="amd64"\nOS_NAME="Windows"\n'})
        lock['runtime']['sha256'] = p.sha256(archive)
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'Java 21'):
            p.package(self.repo, self.out, path)
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

    def test_repeated_directory_entries_preserve_distinct_files(self):
        archive = self.archive('directory-aliases.zip', {
            'LuaUI/': '',
            'LuaUI/Images/': '',
            'LuaUI/images/': '',
            'LuaUI/Images/sun.png': 'sun',
            'LuaUI/images/moon.png': 'moon',
        })
        destination = self.base / 'directory-aliases'
        p.extract(archive, destination, 'zip')
        files = [path for path in destination.rglob('*') if path.is_file()]
        self.assertEqual(sorted(path.read_text() for path in files), ['moon', 'sun'])
        self.assertEqual(len({path.relative_to(destination).as_posix().casefold()
                              for path in files}), len(files))

    def test_file_directory_and_parent_aliases_are_rejected(self):
        cases = [
            {'assets': 'file', 'ASSETS/': ''},
            {'assets/': '', 'ASSETS': 'file'},
            {'assets': 'file', 'ASSETS/texture.png': 'image'},
            {'assets/texture.png': 'image', 'ASSETS': 'file'},
            {'assets/logo.png': 'first', 'ASSETS/LOGO.PNG': 'second'},
            {'assets/texture': 'file', 'ASSETS/TEXTURE/image.png': 'image'},
        ]
        for index, files in enumerate(cases):
            archive = self.archive(f'conflict-{index}.zip', files)
            with self.subTest(files=files), self.assertRaises(ValueError):
                p.extract(archive, self.base / f'conflict-{index}', 'zip')

    def test_wrapped_map_is_repacked_with_root_metadata(self):
        path, lock = self.lock()
        archive = self.archive('wrapped-map.zip', {
            'source-map/mapinfo.lua': 'return { name = "LastDayOfDhubai" }',
            'source-map/maps/Dhubai.smf': 'compiled terrain',
            'source-map/LuaUI/Images/': '',
            'source-map/LuaUI/images/': '',
            'source-map/LuaUI/Images/sun.png': 'sun',
            'source-map/LuaUI/images/moon.png': 'moon',
            'repository-note.txt': 'not part of selected map root',
        })
        input_digest = p.sha256(archive)
        lock['map'].update(path=archive.name, sha256=input_digest, root='source-map')
        self.update_lock(path, lock)
        manifest = p.package(self.repo, self.out, path, '1.034')
        bundle = self.out / 'Mosaic_v1.034_windows-portable.zip'
        map_name = 'data/maps/LastDayOfDhubai.sdz'
        with zipfile.ZipFile(bundle) as portable:
            payload = portable.read(map_name)
        with zipfile.ZipFile(io.BytesIO(payload)) as result:
            self.assertEqual(set(result.namelist()), {
                'mapinfo.lua', 'maps/Dhubai.smf', 'LuaUI/Images/sun.png',
                'LuaUI/images/moon.png',
            })
            self.assertEqual(result.read('maps/Dhubai.smf'), b'compiled terrain')
            self.assertEqual(result.read('LuaUI/Images/sun.png'), b'sun')
            self.assertEqual(result.read('LuaUI/images/moon.png'), b'moon')
        payload_digest = hashlib.sha256(payload).hexdigest()
        self.assertEqual(manifest['inputs']['map']['sha256'], input_digest)
        self.assertNotEqual(payload_digest, input_digest)
        map_record = next(item for item in manifest['payload_files'] if item['path'] == map_name)
        self.assertEqual(map_record['sha256'], payload_digest)
        self.assertEqual(map_record['bytes'], len(payload))
        second = self.base / 'wrapped-second'
        p.package(self.repo, second, path, '1.034')
        with zipfile.ZipFile(second / bundle.name) as portable:
            self.assertEqual(portable.read(map_name), payload)

    def test_wrapped_map_metadata_must_be_at_selected_root(self):
        path, lock = self.lock()
        archive = self.archive('misplaced-map.zip', {
            'source-map/nested/mapinfo.lua': 'return {}',
            'source-map/maps/Dhubai.smf': 'compiled terrain',
        })
        lock['map'].update(path=archive.name, sha256=p.sha256(archive), root='source-map')
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'mapinfo.lua'):
            p.package(self.repo, self.out, path, '1.034')
        self.assertFalse(self.out.exists())

    def test_wrapped_map_symlink_is_rejected_without_output(self):
        path, lock = self.lock()
        archive = self.archive('symlink-map.zip', {
            'source-map/mapinfo.lua': 'return {}',
            'source-map/maps/Dhubai.smf': 'compiled terrain',
        })
        with zipfile.ZipFile(archive, 'a') as source:
            link = zipfile.ZipInfo('source-map/Textures/link')
            link.create_system = 3
            link.external_attr = 0o120777 << 16
            source.writestr(link, '../../outside')
        lock['map'].update(path=archive.name, sha256=p.sha256(archive), root='source-map')
        self.update_lock(path, lock)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            p.package(self.repo, self.out, path)
        self.assertFalse(self.out.exists())
        self.assertFalse(list(self.base.glob('.mosaic-release-*')))

    def test_wrapped_map_bad_crc_is_rejected_without_output(self):
        path, lock = self.lock()
        terrain = b'terrain_crc_fixture_0123456789'
        archive = self.archive('bad-crc-map.zip', {
            'source-map/mapinfo.lua': 'return {}',
            'source-map/maps/Dhubai.smf': terrain,
        })
        damaged = bytearray(archive.read_bytes())
        damaged[damaged.index(terrain) + 3] ^= 1
        archive.write_bytes(damaged)
        # Accept the transport digest so this exercises ZIP CRC validation.
        lock['map'].update(path=archive.name, sha256=p.sha256(archive), root='source-map')
        self.update_lock(path, lock)
        with self.assertRaises((ValueError, zipfile.BadZipFile)):
            p.package(self.repo, self.out, path)
        self.assertFalse(self.out.exists())
        self.assertFalse(list(self.base.glob('.mosaic-release-*')))

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
