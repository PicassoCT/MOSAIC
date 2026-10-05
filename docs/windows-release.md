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
bash pack_mosaic.sh --output ../mosaic-game --expected-version 1.033
bash pack_mosaic_full.sh --output ../mosaic-windows --expected-version 1.033
```

On Windows, use the Python entry point directly:

```powershell
python tools/package_windows_release.py --output ../mosaic-windows --expected-version 1.033 --inputs packaging/windows-inputs.json
```

The full build intentionally fails until `packaging/windows-inputs.json` contains
verified pins. No engine, lobby or map download hash has been guessed. The
engine version is the migration target, not a claim that an artifact is verified.
Commit reviewed pins before running CI. Each input requires an exact version,
SHA-256, and either an HTTPS `url` or a local `path` relative to the lock file.
CI needs URLs; local paths are useful for offline builds. Do not use moving
`latest` URLs or Rapid tags as version pins. Download the actual archives, verify
their provenance, and compute hashes with `sha256sum` or `Get-FileHash`.

Engine and lobby require `format` (`zip` or `7z`), the archive `root` containing
their files (`.` for no wrapper), and `required_files` relative to that root.
List all required launcher/runtime/configuration files for the selected build,
including the lobby executable's actual path rather than assuming the example
`skylobby.exe` spelling. Use a portable lobby archive, never an MSI. Engine
validation additionally requires `spring.exe`, `unitsync.dll`, and a base SDZ.
The map requires `filename` (`.sdz` or `.sd7`), matching `format`, metadata
`mapinfo.lua`, and compiled `.smf` terrain. Pin the exact LastDayOfDhubai archive;
a pr-downloader cache or Rapid game package alone is not a standalone SDZ.

## Outputs and checks

The SDZ uses committed files, excluding repository tooling, CI, docs and tests.
Missing core game directories, unresolved LFS pointers, tracked local changes,
invalid archive paths, version drift, corrupt archives, missing files, or input
hash mismatches fail the build. ZIP entry timestamps/order are fixed; identical
committed inputs and Python/zlib versions produce identical ZIPs. Pin the tool
environment too when byte-for-byte reproduction across machines is required.

Successful full builds emit:

- `Mosaic_v<version>.sdz`.
- `Mosaic_v<version>_windows-portable.zip`, containing `engine/`, `lobby/`,
  `data/games/`, `data/maps/`, `data/springsettings.cfg`, and `Start-Mosaic.cmd`.
- `manifest.json`: source commit, resolved version, complete input lock,
  artifact hashes/sizes, and hashes/sizes of portable payload files.
- `SHA256SUMS`: hashes for the SDZ, portable ZIP, and external manifest.

The ZIP contains a payload manifest; its own hash is intentionally absent to
avoid recursion. The external manifest hashes the final ZIP. No completed
output directory is exposed on failure. Temporary files are removed, and
existing output directories are never overwritten.

Extract the portable ZIP anywhere and run `Start-Mosaic.cmd`. It sets
`SPRING_DATADIR` to the bundled data directory and starts the pinned lobby.
On first use, configure Skylobby's engine to the bundled `engine/spring.exe`
and its data directory to the bundled `data/`. The package includes `PLAY.txt`
with these instructions; no unverified Skylobby command-line API is assumed.
Lobby/network functionality and Recoil launch must still be smoke-tested on
Windows, including a path with spaces and no globally installed game data.

## CI and publishing boundary

The **Windows release artifacts** workflow tests packaging on Linux and Windows.
Manual dispatch builds the selected ref with an explicit expected game version.
Full portable builds require the committed input lock; disabling `portable`
builds only the game SDZ and reports `portable: false` in its manifest.
Uploads happen only after all validation passes and are Actions artifacts,
not GitHub Releases. The workflow has `contents: read`; it does not create a
release, tag, or push. Publishing is a separate maintainer operation after
reviewing the manifest/checksums and completing the Windows smoke test.
