#!/usr/bin/env python3
"""Check a real portable candidate on Windows without connecting or starting a game.

This is a native dependency/archive smoke test, not GUI, multiplayer, gameplay,
or performance qualification. A copy of the production CMD invokes clojure.main
inside the pinned JAR to validate its exact CLI declarations and filesystem
functions. It preserves the production arguments, JVM flags and environment;
it never loads the GUI main class or connects to a server.
"""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
import zipfile


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as source:
        for data in iter(lambda: source.read(1024 * 1024), b''):
            h.update(data)
    return h.hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inside(path, root):
    return Path(path).resolve().is_relative_to(Path(root).resolve())


def sync_version(version):
    # The historical lock uses BAR105-<version>; Spring reports <version> BAR105.
    return version.removeprefix('BAR105-') + ' BAR105' if version.startswith('BAR105-') else version


def has_exact_output_line(text, expected):
    # Recoil writes the version among startup diagnostics. Runner/CPU-dependent
    # warnings may follow it, so the final output line is not stable.
    return any(line.strip() == expected for line in text.splitlines())


def native_probe(root):
    """Load unitsync in a disposable child; a native crash cannot lose the report."""
    root = Path(root).resolve()
    manifest = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
    data = root / 'data'
    engine = data / 'engine/mosaic-pinned'
    os.chdir(data)
    os.environ.update(SPRING_DATADIR=str(data), SPRING_WRITEDIR=str(data), SPRING_ISOLATED=str(engine))
    directory = os.add_dll_directory(str(engine))
    api = ctypes.CDLL(str(engine / 'unitsync.dll'))

    def bind(name, returns, *args):
        function = getattr(api, name)
        function.restype = returns
        function.argtypes = list(args)
        return function

    integer, string = ctypes.c_int, ctypes.c_char_p
    initialize = bind('Init', integer, ctypes.c_bool, integer)
    uninitialize = bind('UnInit', None)
    get_error = bind('GetNextError', string)
    get_version = bind('GetSpringVersion', string)
    get_writable = bind('GetWritableDataDirectory', string)
    get_dir_count = bind('GetDataDirectoryCount', integer)
    get_dir = bind('GetDataDirectory', string, integer)
    get_map_count = bind('GetMapCount', integer)
    get_map = bind('GetMapName', string, integer)
    get_map_archive_count = bind('GetMapArchiveCount', integer, string)
    get_map_archive = bind('GetMapArchiveName', string, integer)
    get_mod_count = bind('GetPrimaryModCount', integer)
    get_mod_info_count = bind('GetPrimaryModInfoCount', integer, integer)
    get_info_key = bind('GetInfoKey', string, integer)
    get_info_type = bind('GetInfoType', string, integer)
    get_info_value = bind('GetInfoValueString', string, integer)
    set_config = bind('SetSpringConfigFile', None, string)
    decode = lambda value: value.decode('utf-8', errors='replace') if value else ''
    set_config(os.fsencode(data / 'springsettings.cfg'))
    if initialize(False, 0) == 0:
        raise ValueError('unitsync initialization failed: ' + decode(get_error()))
    try:
        version = decode(get_version())
        require(version == sync_version(manifest['inputs']['engine']['version']), 'unitsync version differs from input lock')
        writable = decode(get_writable())
        directories = [decode(get_dir(i)) for i in range(get_dir_count())]
        require(Path(writable).resolve() == data.resolve(), 'unitsync writes outside portable data directory')
        require(directories and all(inside(p, root) for p in directories), 'unitsync reads a global data directory')
        maps = [decode(get_map(i)) for i in range(get_map_count())]
        expected_map = manifest['inputs']['map']['version']
        require(expected_map in maps, 'Pinned map not discovered by unitsync: ' + repr(maps))
        archives = [decode(get_map_archive(i)) for i in range(get_map_archive_count(expected_map.encode('utf-8')))]
        require(archives, 'Pinned map archives/dependencies did not resolve')
        games = []
        for index in range(get_mod_count()):
            info = {}
            for key_index in range(get_mod_info_count(index)):
                if decode(get_info_type(key_index)) == 'string':
                    info[decode(get_info_key(key_index))] = decode(get_info_value(key_index))
            games.append(info)
        require(any(game.get('shortname', '').upper() == 'MOSAIC' and
                    game.get('version') == manifest['game_version'] for game in games),
                'Packaged MOSAIC version not discovered by unitsync: ' + repr(games))
        errors = []
        for _ in range(100):
            error = get_error()
            if not error:
                break
            errors.append(decode(error))
        require(not errors, 'unitsync reported errors: ' + repr(errors))
        print('MOSAIC_NATIVE_PROBE:' + json.dumps({'engine_version': version, 'writable_directory': writable,
              'data_directories': directories, 'maps': maps, 'map_archives': archives, 'games': games}))
    finally:
        uninitialize()
        directory.close()


CLOJURE_PROBE = r'''(require '[clojure.java.io :as io]
         '[clojure.tools.cli :as cli]
         '[skylobby.fs :as fs]
         '[skylobby.util :as u]
         '[taoensso.timbre :as log])
;; Read only the vendor's CLI declarations; requiring GUI main initializes JavaFX.
(with-open [reader (java.io.PushbackReader. (io/reader (io/resource "spring_lobby/main.clj")))]
  (binding [*read-eval* false]
    (loop []
      (let [form (read {:eof ::eof} reader)]
        (when-not (= ::eof form)
          (when (and (seq? form) (= 'def (first form))
                     (contains? #{'players-disply-types 'cli-options} (second form)))
            (eval form))
          (recur))))))
(let [{:keys [arguments errors options]} (cli/parse-opts *command-line-args* cli-options :in-order true)
      _ (assert (empty? errors) (str errors))
      _ (assert (empty? arguments) (str arguments))
      _ (assert (= "lobby.springrts.com:8200" (:server-url options)))
      _ (assert (= "MOSAIC" (:filter-battles options)))
      _ (assert (:no-update-check options))
      root (fs/parent-file (fs/file (:spring-root options)))
      home (fs/file root "state" "home")
      lobby (fs/file root "state" "lobby")
      data (fs/file root "data")
      engine (fs/file data "engine" "mosaic-pinned")]
  (assert (= (fs/canonical-path home) (fs/canonical-path (fs/file (System/getProperty "user.home")))))
  (assert (= (fs/canonical-path (fs/file root "state" "tmp"))
             (fs/canonical-path (fs/file (System/getProperty "java.io.tmpdir")))))
  (assert (= (fs/canonical-path data) (fs/canonical-path (fs/file (System/getenv "SPRING_DATADIR")))))
  (assert (= (fs/canonical-path data) (fs/canonical-path (fs/file (System/getenv "SPRING_WRITEDIR")))))
  (assert (= (fs/canonical-path engine) (fs/canonical-path (fs/file (System/getenv "SPRING_ISOLATED")))))
  (assert (= (fs/canonical-path (fs/file home ".skylobby")) (fs/canonical-path (fs/app-root))))
  (assert (.startsWith (fs/canonical-path (fs/spring-root)) (fs/canonical-path home)))
  (assert (.startsWith (fs/canonical-path (fs/bar-root)) (fs/canonical-path home)))
  (assert (.startsWith (fs/canonical-path (fs/springlobby-root)) (fs/canonical-path home)))
  ;; Mirror the real main's early log call, before --skylobby-root is applied.
  (u/log-to-file (fs/canonical-path (fs/config-file "skylobby.log")))
  (log/info "MOSAIC portable filesystem smoke")
  (alter-var-root #'fs/app-root-override (constantly (:skylobby-root options)))
  (assert (= (fs/canonical-path lobby) (fs/canonical-path (fs/app-root))))
  (assert (some #{(fs/canonical-path engine)} (map fs/canonical-path (fs/engine-dirs data))))
  (println "MOSAIC_CLOJURE_PROBE_OK"))
(shutdown-agents)
(System/exit 0)
'''


def execute(name, command, output, cwd, env, timeout=180):
    process = subprocess.Popen(command, cwd=cwd, env=env, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace')
    try:
        text, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], capture_output=True, timeout=20)
        text, _ = process.communicate(timeout=20)
        (output / (name + '.log')).write_text(text[-131072:], encoding='utf-8')
        raise ValueError(name + ' exceeded timeout')
    (output / (name + '.log')).write_text(text[-131072:], encoding='utf-8')
    require(process.returncode == 0, name + ' failed with exit ' + str(process.returncode) + '; see log')
    return process.returncode, text


def smoke(artifacts, output):
    artifacts, output = Path(artifacts).resolve(), Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    report = {'schema_version': 1, 'status': 'failed', 'checks': [],
              'started_utc': datetime.now(timezone.utc).isoformat(),
              'scope': 'Native Windows dependency and archive smoke only',
              'unverified': ['GUI rendering', 'multiplayer', 'gameplay', '25 FPS performance gate']}
    try:
        require(sys.platform == 'win32', 'This smoke test requires Windows')
        require(ctypes.sizeof(ctypes.c_void_p) == 8, 'This smoke test requires 64-bit Python')
        manifest_path = artifacts / 'manifest.json'
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        report['source_commit'] = manifest.get('source_commit')
        require(manifest.get('portable') is True, 'Expected a portable candidate manifest')
        require(re.fullmatch(r'[0-9a-f]{40}', manifest.get('source_commit', '')), 'Missing source commit identity')
        expected_commit = os.environ.get('CANDIDATE_COMMIT')
        if expected_commit:
            report['expected_source_commit'] = expected_commit
            require(manifest['source_commit'] == expected_commit, 'Candidate source commit differs from CI build identity')
        zip_name = 'Mosaic_v' + manifest['game_version'] + '_windows-portable.zip'
        payloads = [item for item in manifest['artifacts'] if item['path'] == zip_name]
        require(len(payloads) == 1, 'Portable ZIP missing or ambiguous in manifest')
        archive = artifacts / zip_name
        expected = payloads[0]
        actual_digest = digest(archive)
        require(archive.stat().st_size == expected['bytes'] and actual_digest == expected['sha256'], 'Portable ZIP hash/size mismatch')
        report.update(source_commit=manifest['source_commit'], game_version=manifest['game_version'],
                      portable_zip=zip_name, portable_sha256=actual_digest,
                      external_manifest_sha256=digest(manifest_path))
        report['checks'].append('Portable archive matches external manifest')
        with tempfile.TemporaryDirectory(prefix='MOSAIC clean path with spaces ', dir=output.parent) as temp:
            root = Path(temp)
            with zipfile.ZipFile(archive) as zipped:
                for info in zipped.infolist():
                    name = PurePosixPath(info.filename)
                    require(not name.is_absolute() and '..' not in name.parts and '\\' not in info.filename
                            and ':' not in info.filename, 'Unsafe portable archive member')
                zipped.extractall(root)
            embedded = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
            require(embedded['source_commit'] == manifest['source_commit'] and embedded['inputs'] == manifest['inputs']
                    and embedded['game_version'] == manifest['game_version'], 'Embedded manifest identity mismatch')
            for item in manifest['payload_files']:
                path = root / item['path']
                require(inside(path, root) and path.is_file() and path.stat().st_size == item['bytes']
                        and digest(path) == item['sha256'], 'Payload integrity failure: ' + item['path'])
            report['checks'].append('Extracted payload integrity in a fresh path containing spaces')
            data, engine, home, lobby, temporary = root / 'data', root / 'data/engine/mosaic-pinned', root / 'state/home', root / 'state/lobby', root / 'state/tmp'
            for path in (home, lobby, temporary):
                path.mkdir(parents=True)
            env = os.environ.copy()
            env.update(SPRING_DATADIR=str(data), SPRING_WRITEDIR=str(data), SPRING_ISOLATED=str(engine))
            for key in ('JAVA_TOOL_OPTIONS', '_JAVA_OPTIONS', 'JDK_JAVA_OPTIONS'):
                env.pop(key, None)
            java = root / 'runtime/bin/java.exe'
            jvm = [str(java), '-XX:+UseZGC', '-Xmx2g', '-XX:+ExitOnOutOfMemoryError',
                   '--add-opens=java.base/java.nio=ALL-UNNAMED', '--add-opens=java.base/sun.nio.ch=ALL-UNNAMED',
                   '-Duser.home=' + str(home), '-Djava.io.tmpdir=' + str(temporary)]
            _, text = execute('java-version', jvm + ['-version'], output, root, env)
            version_match = re.search(r'version "(\d+)', text)
            require(version_match and int(version_match[1]) >= 21, 'Bundled Java is older than 21')
            report['checks'].append('Bundled Windows Java accepts production JVM flags')
            expected_version = sync_version(manifest['inputs']['engine']['version'])
            _, text = execute('engine-sync-version', [str(engine / 'spring-headless.exe'), '--sync-version'], output, data, env)
            require(has_exact_output_line(text, expected_version), 'Native engine version differs from input lock')
            report['checks'].append('Bundled native engine sync version matches lock')
            launcher = (root / 'Start-Mosaic.cmd').read_text(encoding='utf-8')
            require(launcher.count('--no-update-check') == 1, 'Production launcher shape changed; update smoke diagnostic')
            require('-Duser.home=' in launcher and '-Djava.io.tmpdir=' in launcher,
                    'Launcher lacks portable JVM home/temp overrides')
            for key in ('SPRING_DATADIR', 'SPRING_WRITEDIR', 'SPRING_ISOLATED'):
                require('set "' + key + '=' in launcher, 'Launcher lacks explicit ' + key)
            production_entry = '-jar "%~dp0lobby\\skylobby.jar"'
            require(launcher.count(production_entry) == 1, 'Production Java invocation changed; update smoke diagnostic')
            diagnostic = launcher.replace(production_entry,
                '-cp "%~dp0lobby\\skylobby.jar" clojure.main "%~dp0portable-probe.clj"', 1)
            diagnostic = diagnostic.replace('if not "%MOSAIC_EXIT%"=="0" pause', 'rem Diagnostic suppresses the interactive error pause')
            diagnostic_path = root / 'Smoke-Mosaic.cmd'
            diagnostic_path.write_text(diagnostic, encoding='utf-8', newline='\r\n')
            probe = root / 'portable-probe.clj'
            probe.write_text(CLOJURE_PROBE, encoding='utf-8')
            _, text = execute('launcher-cli', ['cmd.exe', '/d', '/c', str(diagnostic_path)], output, output, env)
            require('MOSAIC_CLOJURE_PROBE_OK' in text, 'Lobby filesystem probe did not finish')
            require((home / '.skylobby/skylobby.log').is_file(), 'Early Skylobby log did not stay in portable JVM home')
            report['checks'].append('Production CMD quoting/JVM flags and pinned lobby CLI declarations accept all arguments')
            report['checks'].append('Pinned lobby uses local early log/config/home and discovers bundled engine directory')
            _, text = execute('unitsync', [sys.executable, str(Path(__file__).resolve()), '--native-probe', str(root)], output, data, env, timeout=300)
            native_lines = [line.split(':', 1)[1] for line in text.splitlines() if line.startswith('MOSAIC_NATIVE_PROBE:')]
            require(len(native_lines) == 1, 'Native archive probe did not finish')
            report['native'] = json.loads(native_lines[0])
            report['checks'].append('Native unitsync discovers exact MOSAIC game/map and uses only portable data directories')
            for path in (home / '.skylobby/skylobby.log', data / 'infolog.txt'):
                if path.is_file():
                    (output / ('portable-' + path.name)).write_bytes(path.read_bytes()[-131072:])
        report['status'] = 'passed'
    except Exception as error:
        report['error'] = str(error)
    finally:
        report['finished_utc'] = datetime.now(timezone.utc).isoformat()
        (output / 'windows-smoke.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    return 0 if report['status'] == 'passed' else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--artifacts-directory', type=Path)
    parser.add_argument('--output-directory', type=Path)
    parser.add_argument('--native-probe', type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.native_probe:
        native_probe(args.native_probe)
        return 0
    if not args.artifacts_directory or not args.output_directory:
        parser.error('--artifacts-directory and --output-directory are required')
    return smoke(args.artifacts_directory, args.output_directory)


if __name__ == '__main__':
    sys.exit(main())
