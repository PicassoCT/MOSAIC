#!/usr/bin/env python3
"""Run external tests against a game checkout without adding files to that checkout.

python prepare_workspace.py --game GAME -- lua tests/city_roads_test.lua
python prepare_workspace.py --game GAME --workspace NEW_DIRECTORY
With no command/workspace, run the focused placeable/audio smoke tests.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

SUITE = Path(__file__).resolve().parent
ADMIN = {'prepare_workspace.py', 'run.sh', 'README.txt', 'relocation-manifest.json',
         'relocated-bytecode', '.git', '.gitignore', '__pycache__'}


def link(source, target):
    try:
        target.symlink_to(source, target_is_directory=source.is_dir())
    except OSError:
        if os.name != 'nt':
            raise
        if source.is_dir():
            # Directory junctions work on Windows without Developer Mode/admin.
            subprocess.run(['cmd', '/c', 'mklink', '/J', str(target), str(source)],
                           check=True, stdout=subprocess.DEVNULL)
        else:
            # Runner workspace and checkout normally share a volume.
            try:
                os.link(source, target)
            except OSError:
                shutil.copy2(source, target)


def prepare(game, destination):
    game, destination = game.resolve(), destination.absolute()
    if not (game / 'modinfo.lua').is_file():
        raise ValueError('Not a MOSAIC checkout: ' + str(game))
    if destination == game or game in destination.parents:
        raise ValueError('Test workspace must be outside the game checkout')
    if destination == SUITE or SUITE in destination.parents:
        raise ValueError('Test workspace must be outside the test source directory')
    destination.mkdir(parents=True, exist_ok=False)
    for source in game.iterdir():
        if source.name not in {'tests', '.mosaic-tests-source'}:
            link(source, destination / source.name)
    test_dir = destination / 'tests'
    test_dir.mkdir()
    # Real copies keep __file__.resolve().parents[1] pointing at this workspace.
    # Shader helpers, fixtures and cross-test imports retain their original paths.
    for source in SUITE.iterdir():
        if source.name in ADMIN or source.name.startswith('.'):
            continue
        target = test_dir / source.name
        if source.is_dir():
            shutil.copytree(source, target, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        elif source.suffix != '.pyc':
            shutil.copy2(source, target)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game', type=Path,
                        default=Path(os.environ.get('MOSAIC_GAME_ROOT', '/home/picasso/.spring/games/Mosaic.sdd')))
    parser.add_argument('--workspace', type=Path, help='Create a persistent, new external workspace')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if args.workspace:
        workspace = prepare(args.game, args.workspace)
        print(workspace)
        if command:
            return subprocess.call(command, cwd=workspace)
        return 0
    with tempfile.TemporaryDirectory(prefix='mosaic-tests-') as temporary:
        workspace = prepare(args.game, Path(temporary) / 'workspace')
        if command:
            return subprocess.call(command, cwd=workspace)
        lua = shutil.which('lua5.1') or shutil.which('lua')
        if not lua:
            parser.error('Lua is required for the default smoke tests')
        for name in ('house_asian_placeable_terrain_test.lua', 'house_asian_placeables_test.lua',
                     'lost_and_found_audio_test.lua'):
            result = subprocess.call([lua, 'tests/' + name], cwd=workspace)
            if result:
                return result
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
