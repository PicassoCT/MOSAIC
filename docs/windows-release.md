# Windows release artifacts

The packaging entry point builds committed HEAD, resolves `GameVersion` from
`scripts/lib_mosaic.lua`, cross-checks `modinfo.lua`, and stamps its `$VERSION`
placeholder inside the SDZ. Rapid's source placeholder remains unchanged.
An explicit modinfo version must agree. `--expected-version` (optionally prefixed
with `v`) must also agree; duplicate or missing declarations fail.

## Build

Requirements: Git, Python 3.12, and 7-Zip (`7z` or `7zz`) for 7z/SD7 inputs.
Run from a clean committed checkout. Output must be a new directory.

```bash
bash pack_mosaic.sh --output ../mosaic-game --expected-version 1.036
bash pack_mosaic_full.sh --output ../mosaic-windows --expected-version 1.036
```

On Windows, use the Python entry point directly:

```powershell
python tools/package_windows_release.py --output ../mosaic-windows --expected-version 1.036 --inputs packaging/windows-inputs.json
```

The committed input lock pins all four downloads by exact version and SHA-256.
The archives were downloaded, hashed and inspected before pinning:

| Input | Version | Source |
| --- | --- | --- |
| Recoil Windows x64 | `BAR105-105.1.1-1544-g058c8ea` | [Official engine release](https://github.com/beyond-all-reason/RecoilEngine/releases/tag/spring_bar_%7BBAR105%7D105.1.1-1544-g058c8ea) |
| Skylobby Windows JAR | `0.9.31016` | [Maintained Skylobby release](https://github.com/springraaar/skylobby/releases/tag/0.9.31016) |
| Temurin Windows x64 JRE | `21.0.13+9` | [Official Temurin release](https://github.com/adoptium/temurin21-binaries/releases/tag/jdk-21.0.13%2B9) |
| Last Day of Dubai | `MOSAIC_LastDayOfDubai_V3 1` | [Compiled map source](https://github.com/PicassoCT/MOSAIC_LastDayOfDubai/tree/f7938d012affd4cd2fc4c50fe3d92dd5c0af894e) |

The engine keeps the migration baseline at commit
`058c8eac9132df3efa338f238a67e79293ec5fb3`. Validation requires `spring.exe`,
`unitsync.dll` and engine base SDZs. The Java ZIP has root
`jdk-21.0.13+9-jre`; its release metadata identifies Windows x64 Java 21.
Skylobby is a single Windows JAR launched with that bundled runtime.

The map input is an immutable source ZIP containing compiled SMF/SMT terrain.
Its lock-file `root` identifies the GitHub wrapper directory. Packaging strips
that wrapper and writes a deterministic SDZ with `mapinfo.lua` at archive root,
preserving every file below the map root. Direct ZIP copying preserves member
case on both Windows and Linux. Repeated directory entries are accepted;
colliding files, file/directory aliases, unsafe paths and symlinks are rejected.
The input lock hashes the downloaded source ZIP; `payload_files` records the
separate hash of the produced `data/maps/MOSAIC_LastDayOfDubai_V3_1.sdz`.
The map's `Map Helper v1` dependency is included in the pinned engine.

Each input requires an exact version, SHA-256, and either an HTTPS `url` or a
local `path` relative to the lock file. CI uses committed URLs. Local paths are
useful for offline builds. Pin updates require downloading and inspecting the
actual archives again. Moving `latest` URLs and Rapid tags are not version pins.

## Outputs and checks

The SDZ uses committed files, excluding repository tooling, CI, docs and tests.
Missing core game directories, unresolved LFS pointers, tracked local changes,
invalid archive paths, version drift, corrupt archives, missing files, or input
hash mismatches fail the build. ZIP entry timestamps/order are fixed; identical
committed inputs and Python/zlib versions produce identical ZIPs. Pin the tool
environment too when byte-for-byte reproduction across machines is required.

Successful full builds emit:

- `Mosaic_v<version>.sdz`.
- `Mosaic_v<version>_windows-portable.zip`, containing `runtime/`, `lobby/`,
  `data/engine/`, `data/games/`, `data/maps/`, `data/springsettings.cfg`, and
  `Start-Mosaic.cmd`.
- `manifest.json`: source commit, resolved version, complete input lock,
  artifact hashes/sizes, hashes/sizes of portable payload files, and an explicit
  minimum-25-FPS zoomed-out gate marked `unverified` until runtime evidence is
  validated separately.
- `SHA256SUMS`: hashes for the SDZ, portable ZIP, and external manifest.

The ZIP contains a payload manifest; its own hash is intentionally absent to
avoid recursion. The external manifest hashes the final ZIP. No completed
output directory is exposed on failure. Temporary files are removed, and
existing output directories are never overwritten.

Extract the portable ZIP anywhere and run `Start-Mosaic.cmd`. It launches the
pinned Skylobby JAR with bundled Java, a local JVM home and temporary directory,
an isolated lobby state directory, the bundled Spring data root, `lobby.springrts.com:8200`, and a `MOSAIC` battle filter. This
implements the shared lobby plus agreed SPADS room approach; it does not add
matchmaking or create/host a room. Lobby/network functionality and Recoil launch
must still be checked interactively on Windows. The automated smoke job checks
paths with spaces and isolation from globally installed game data.

JVM home and temporary files stay under `state/home` and `state/tmp`. This also
keeps Skylobby's early startup log local, before its command-line root setting
is applied. `SPRING_WRITEDIR`, `SPRING_ISOLATED` and `SPRING_DATADIR` explicitly
select the bundled data and engine directories for native subprocesses.

## CI and publishing boundary

The **Windows release artifacts** workflow tests packaging on Linux and Windows
using the separately published suite pinned by `.github/mosaic-tests.ref`.
Tests stay outside the game checkout.

Manual dispatch builds the selected ref with an explicit expected game version.
Pull requests from this repository's `release/windows-portable-*` branches also
build a full portable candidate after tests pass. Both routes check out the exact
candidate commit, and the uploaded artifact name includes that SHA. Fork pull
requests run the regression suite without building a release bundle. Disabling
`portable` on manual dispatch builds only the game SDZ.

Full portable candidates then run a Windows smoke job from a fresh path with
spaces. It verifies the manifest and payload checksums, executes the bundled
Java and engine, checks the pinned lobby's command-line configuration, and checks
native game/map discovery and data-directory isolation. Its evidence is uploaded
separately. Interactive lobby sign-in, joining the MOSAIC room, rendered gameplay
and the GTX 1050 Ti performance capture still require their own runtime checks.

Uploads are Actions artifacts with 14-day retention. The workflow has
`contents: read`; it creates no release, tag or repository push. Publishing is a
separate maintainer operation after reviewing the checksums and runtime evidence.

## Qualify the performance gate

Packaging deliberately leaves the 25-FPS gate unverified. Record at least 600
seconds while fully zoomed out on the GTX 1050 Ti, including the exact candidate
commit, game/engine/map versions, resolution, settings and city/unit load. Keep
the raw per-sample CSV beside a completed copy of
`packaging/performance-gate.example.json`, then bind it to the portable manifest:

```powershell
python tools/qualify_windows_release.py --manifest ../mosaic-windows/manifest.json `
  --evidence ../captures/performance-gate.json `
  --output ../mosaic-windows/release-qualification.json
```

Qualification fails if minimum FPS is below 25 (regardless of average FPS), the
capture is shorter than ten minutes, the raw capture hash differs, or the tested
commit/version/engine/map is not the packaged candidate. The qualification file
is evidence for review; it does not publish a release.

## Standalone SD7 game release

Use `bash pack_mosaic.sh --output OUTPUT --expected-version 1.038 --game-format sd7`
for a complete engine-loadable 7-Zip game archive. The default remains SDZ. SD7
uses LZMA2 with bounded 64 MiB solid blocks and omits timestamps. It packages
committed runtime files only, excludes ignored untracked files, repository tools,
agent instructions, documentation and hidden path components, and validates
archive integrity and both version declarations before exposing the output.
Tracked Lua runtime files remain included under Git's normal ignore semantics.
