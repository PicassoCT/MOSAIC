#!/usr/bin/env python3
"""Build validated MOSAIC artifacts. No publishing code or credentials required."""
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import tempfile
import urllib.parse
import urllib.request
import zipfile

VERSION = re.compile(r'^\s*GameVersion\s*=\s*[\'\"](\d+\.\d+(?:\.\d+)?)[\'\"]', re.M)
MOD_VERSION = re.compile(r'(?m)^\s*version\s*=\s*([\'\"])([^\'\"]+)\1\s*,')
EXCLUDED = {'.github', 'docs', 'Documents', 'tests', 'tools', 'packaging', 'release', 'dist',
            'pack_mosaic.sh', 'pack_mosaic_full.sh', 'TODO', 'UnitStats.ods'}
REQUIRED_GAME = ('modinfo.lua', 'scripts/lib_mosaic.lua', 'gamedata', 'units', 'weapons', 'objects3d', 'unittextures', 'luarules', 'luaui')


def run(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])


def sha256(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


@contextmanager
def blob_reader(repo):
    # One Git process for thousands of runtime assets, rather than one per file.
    process = subprocess.Popen(['git', '-C', str(repo), 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    try:
        yield process
    finally:
        process.stdin.close()
        process.stdout.close()
        process.wait()


def copy_blob(process, oid, path):
    process.stdin.write((oid + '\n').encode())
    process.stdin.flush()
    fields = process.stdout.readline().decode().split()
    if len(fields) != 3 or fields[0] != oid or fields[1] != 'blob':
        raise ValueError(f'Cannot read committed blob: {path}')
    remaining = int(fields[2])
    with path.open('wb') as destination:
        first = True
        while remaining:
            data = process.stdout.read(min(remaining, 1024 * 1024))
            if not data:
                raise ValueError(f'Truncated committed blob: {path}')
            if first and data.startswith(b'version https://git-lfs.github.com/spec/v1'):
                # Terminate before leaving an unread blob on the pipe.
                process.terminate()
                raise ValueError(f'Unresolved LFS pointer: {path}')
            first = False
            destination.write(data)
            remaining -= len(data)
    if process.stdout.read(1) != b'\n':
        raise ValueError('Invalid Git batch terminator')


def resolve_version(lib, mod, expected=None):
    matches = VERSION.findall(lib)
    declarations = MOD_VERSION.findall(mod)
    if (len(matches) != 1 or len(declarations) != 1 or
            len(re.findall(r'^\s*GameVersion\s*=', lib, re.M)) != 1 or
            len(re.findall(r'^\s*version\s*=', mod, re.M)) != 1):
        raise ValueError('Expected exactly one GameVersion and one modinfo version declaration')
    version = matches[0]
    if declarations[0][1] not in ('$VERSION', version):
        raise ValueError('Version drift: GameVersion and modinfo.lua disagree')
    if expected and expected.removeprefix('v') != version:
        raise ValueError('Version drift: requested version/tag differs from GameVersion')
    stamped = MOD_VERSION.sub(lambda m: m.group(0).replace(m.group(2), version), mod)
    if '$VERSION' in stamped:
        raise ValueError('Unresolved $VERSION in packaged modinfo.lua')
    return version, stamped


def safe_name(name):
    # Reject Windows aliases as well as traversal, absolute paths and ADS names.
    p = PurePosixPath(name)
    if not name or '\\' in name or p.is_absolute() or any(
        part in ('', '.', '..') or re.search(r'[\x00-\x1f<>:"|?*]', part) or part.endswith((' ', '.')) or
        re.match(r'(?i)^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)', part)
        for part in name.rstrip('/').split('/')
    ):
        raise ValueError(f'Unsafe archive path: {name}')
    return p


def zip_tree(root, destination):
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for path in sorted(root.rglob('*')):
            if path.is_symlink():
                raise ValueError(f'Symlink in payload: {path}')
            if path.is_file():
                name = path.relative_to(root).as_posix()
                safe_name(name)
                info = zipfile.ZipInfo(name, (2000, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info._compresslevel = 9
                info.external_attr = 0o100644 << 16
                with path.open('rb') as src, z.open(info, 'w') as dst:
                    shutil.copyfileobj(src, dst)
    with zipfile.ZipFile(destination) as z:
        if z.testzip():
            raise ValueError(f'Corrupt generated archive: {destination}')


def build_game(repo, target, expected=None):
    # Build only committed HEAD, never untracked build outputs or local modifications.
    if run(repo, 'status', '--porcelain', '--untracked-files=no').strip():
        raise ValueError('Tracked working tree is dirty; commit changes before packaging')
    commit = run(repo, 'rev-parse', 'HEAD').decode().strip()
    files = run(repo, 'ls-tree', '-rz', '--full-tree', 'HEAD').split(b'\0')
    with tempfile.TemporaryDirectory(prefix='mosaic-game-') as temp:
        root = Path(temp)
        with blob_reader(repo) as reader:
            for entry in files:
                if not entry:
                    continue
                metadata, raw_name = entry.split(b'\t', 1)
                mode, kind, oid = metadata.decode().split()
                name = raw_name.decode('utf-8')
                if name.split('/')[0] in EXCLUDED or name.startswith('.'):
                    continue
                if mode not in ('100644', '100755') or kind != 'blob':
                    raise ValueError(f'Unsupported tracked entry: {name}')
                safe_name(name)
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                copy_blob(reader, oid, path)
        for name in REQUIRED_GAME:
            path = root / name
            if not path.exists() or (path.is_dir() and not any(path.rglob('*'))):
                raise ValueError(f'Missing required game asset: {name}')
        version, mod = resolve_version((root / 'scripts/lib_mosaic.lua').read_text(), (root / 'modinfo.lua').read_text(), expected)
        (root / 'modinfo.lua').write_text(mod, encoding='utf-8', newline='\n')
        archive = target / f'Mosaic_v{version}.sdz'
        zip_tree(root, archive)
        with zipfile.ZipFile(archive) as z:
            packaged_version, _ = resolve_version(z.read('scripts/lib_mosaic.lua').decode(), z.read('modinfo.lua').decode(), version)
            assert packaged_version == version
    return version, commit, archive


def validate_lock(lock):
    if lock.get('schema_version') != 1:
        raise ValueError('Input lock schema_version must be 1')
    for role in ('engine', 'lobby', 'map'):
        asset = lock.get(role, {})
        if not isinstance(asset, dict):
            raise ValueError(f'Invalid {role} lock')
        if (not isinstance(asset.get('version'), str) or not asset['version'] or
                not isinstance(asset.get('sha256'), str) or
                not re.fullmatch(r'[0-9a-f]{64}', asset['sha256'])):
            raise ValueError(f'{role}: exact version and SHA-256 must be pinned in the input lock')
        if bool(asset.get('url')) == bool(asset.get('path')):
            raise ValueError(f'{role}: specify exactly one HTTPS url or local path')
        if asset.get('url') and urllib.parse.urlparse(asset['url']).scheme != 'https':
            raise ValueError(f'{role}: downloads require HTTPS')
        if role != 'map':
            if not isinstance(asset.get('required_files'), list) or not asset['required_files']:
                raise ValueError(f'{role}: required_files cannot be empty')
            safe_name(asset.get('root', '.')) if asset.get('root', '.') != '.' else None
            for name in asset['required_files']:
                safe_name(name)
            if not any(name.lower().endswith('.exe') for name in asset['required_files']):
                raise ValueError(f'{role}: required_files must include its Windows executable')
        else:
            name = asset.get('filename', '')
            safe_name(name)
            if '/' in name or not name.lower().endswith(('.sdz', '.sd7')):
                raise ValueError('map: filename must be an SDZ or SD7 basename')


def acquire(asset, base, temp, role):
    path = temp / (role + ('.7z' if asset.get('format') == '7z' else '.zip'))
    if asset.get('path'):
        shutil.copyfile(base / asset['path'], path)
    else:
        with urllib.request.urlopen(asset['url'], timeout=120) as src:
            if urllib.parse.urlparse(src.url).scheme != 'https':
                raise ValueError('Download redirected away from HTTPS')
            with path.open('wb') as dst:
                shutil.copyfileobj(src, dst)
    if not path.stat().st_size or sha256(path) != asset['sha256']:
        raise ValueError(f'{role}: input SHA-256 mismatch or empty file')
    return path


def extract(archive, destination, format):
    destination.mkdir(parents=True)
    names = []
    if format == 'zip':
        with zipfile.ZipFile(archive) as z:
            if z.testzip():
                raise ValueError('Corrupt ZIP input')
            for item in z.infolist():
                safe_name(item.filename)
                if stat.S_ISLNK(item.external_attr >> 16):
                    raise ValueError('Archive symlink rejected')
                names.append(item.filename.rstrip('/').casefold())
            if len(set(names)) != len(names):
                raise ValueError('Duplicate/case-colliding archive paths')
            z.extractall(destination)
    elif format == '7z':
        exe = shutil.which('7z') or shutil.which('7zz')
        if not exe:
            raise ValueError('7-Zip is required for 7z/SD7 inputs')
        listing = subprocess.check_output([exe, 'l', '-slt', str(archive)], text=True)
        if '\n----------\n' not in listing.replace('\r\n', '\n'):
            raise ValueError('Cannot validate 7-Zip listing')
        listing = listing.replace('\r\n', '\n').split('\n----------\n', 1)[1]
        for record in listing.strip().split('\n\n'):
            fields = dict(line.split(' = ', 1) for line in record.splitlines() if ' = ' in line)
            if 'Path' not in fields:
                continue
            safe_name(fields['Path'])
            if 'Symbolic Link' in fields or 'Hard Link' in fields or 'l' in fields.get('Attributes', ''):
                raise ValueError('Archive links rejected')
            names.append(fields['Path'].rstrip('/').casefold())
        if not names or len(set(names)) != len(names):
            raise ValueError('Empty or duplicate/case-colliding 7z paths')
        subprocess.run([exe, 't', str(archive)], check=True, stdout=subprocess.DEVNULL)
        subprocess.run([exe, 'x', '-y', '-o' + str(destination), str(archive)], check=True, stdout=subprocess.DEVNULL)
    else:
        raise ValueError(f'Unsupported input format: {format}; use zip or 7z')
    for path in destination.rglob('*'):
        if path.is_symlink():
            raise ValueError('Extracted symlink rejected')


def file_manifest(root):
    return [{'path': p.relative_to(root).as_posix(), 'bytes': p.stat().st_size, 'sha256': sha256(p)}
            for p in sorted(root.rglob('*')) if p.is_file()]


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n', encoding='utf-8')


def package(repo, output, lock_path=None, expected=None):
    repo, output = repo.resolve(), output.resolve()
    if output.exists():
        raise ValueError('Output path already exists; choose a fresh directory')
    lock = None
    if lock_path:
        lock = json.loads(lock_path.read_text())
        validate_lock(lock)  # Fail before building on an incomplete or drifting input lock.
    output.parent.mkdir(parents=True, exist_ok=True)
    # Commit the output directory only after every validation succeeds.
    with tempfile.TemporaryDirectory(prefix='.mosaic-release-', dir=output.parent) as temp:
        temp = Path(temp)
        result = temp / 'artifacts'
        result.mkdir()
        version, commit, game = build_game(repo, result, expected)
        manifest = {'schema_version': 1, 'game_version': version, 'source_commit': commit,
                    'portable': lock is not None, 'inputs': lock, 'artifacts': []}
        if lock:
            portable = temp / f'Mosaic_v{version}_windows-portable'
            portable.mkdir()
            for role in ('engine', 'lobby', 'map'):
                asset = lock[role]
                archive = acquire(asset, lock_path.resolve().parent, temp, role)
                unpack = temp / (role + '-unpacked')
                fmt = asset.get('format') or ('7z' if asset.get('filename', '').endswith('.sd7') else 'zip')
                extract(archive, unpack, fmt)
                if role == 'map':
                    # A Spring map needs metadata AND compiled map terrain.
                    if not any(p.name.lower() == 'mapinfo.lua' for p in unpack.rglob('*')) or not any(unpack.rglob('*.smf')):
                        raise ValueError('Map archive lacks mapinfo.lua or SMF terrain')
                    maps = portable / 'data/maps'
                    maps.mkdir(parents=True)
                    shutil.copyfile(archive, maps / asset['filename'])
                else:
                    source = unpack if asset.get('root', '.') == '.' else unpack / asset['root']
                    for name in asset['required_files']:
                        p = source / name
                        if not p.is_file() or not p.stat().st_size:
                            raise ValueError(f'{role}: missing required file {name}')
                    if role == 'engine':
                        for name in ('spring.exe', 'unitsync.dll'):
                            if not (source / name).is_file() or not (source / name).stat().st_size:
                                raise ValueError(f'Engine lacks {name}')
                        if not any((source / 'base').rglob('*.sdz')):
                            raise ValueError('Engine lacks base SDZ assets')
                    shutil.copytree(source, portable / role)
            games = portable / 'data/games'
            games.mkdir(parents=True)
            shutil.copyfile(game, games / game.name)
            config = repo / 'packaging/springsettings.cfg'
            if not config.is_file() or not config.stat().st_size:
                raise ValueError('Missing packaging/springsettings.cfg')
            shutil.copyfile(config, portable / 'data/springsettings.cfg')
            # SPRING_DATADIR is inherited by lobby/engine; isolation config is explicit.
            lobby_exe = next(n for n in lock['lobby']['required_files'] if n.lower().endswith('.exe'))
            if any(c in lobby_exe for c in '%!&|<>^\"\r\n'):
                raise ValueError('Lobby executable path cannot be safely launched by cmd.exe')
            launcher = '@echo off\r\nsetlocal\r\nset "SPRING_DATADIR=%~dp0data"\r\ncd /d "%~dp0lobby"\r\nstart "MOSAIC" "' + lobby_exe.replace('/', '\\') + '"\r\n'
            (portable / 'Start-Mosaic.cmd').write_bytes(launcher.encode())
            (portable / 'PLAY.txt').write_text('Run Start-Mosaic.cmd. In Skylobby configure the engine path to engine/spring.exe and the data directory to data (both beside this file). Select MOSAIC ' + version + ' and the bundled map. Lobby/server access requires internet.\n', encoding='utf-8')
            manifest['payload_files'] = file_manifest(portable)
            write_json(portable / 'manifest.json', manifest)
            bundle = result / (portable.name + '.zip')
            zip_tree(portable, bundle)
        manifest['artifacts'] = file_manifest(result)
        write_json(result / 'manifest.json', manifest)
        checksums = file_manifest(result)
        (result / 'SHA256SUMS').write_text(''.join(f"{f['sha256']}  {f['path']}\n" for f in checksums), encoding='utf-8')
        os.replace(result, output)
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--inputs', type=Path, help='Validated portable input lock; omit for SDZ only')
    parser.add_argument('--expected-version', help='Must match GameVersion; accepts a v prefix')
    args = parser.parse_args()
    try:
        manifest = package(args.repo, args.output, args.inputs, args.expected_version)
    except (ValueError, OSError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        parser.exit(1, f'Packaging failed: {error}\n')
    print(f"Validated MOSAIC {manifest['game_version']} from {manifest['source_commit']}: {args.output}")


if __name__ == '__main__':
    main()
