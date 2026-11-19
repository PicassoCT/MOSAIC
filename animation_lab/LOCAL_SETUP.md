# Local setup and validation

Installed November 18, 2026, outside the playable game checkout.

| Component | Local path or setting |
| --- | --- |
| Lab root | `/home/picasso/.spring/games/MOSAIC_Animation_Lab` |
| Launcher | `lab.sh` in that directory |
| Python | `.venv312/bin/python`, isolated Python 3.12 environment |
| Dependencies | Pillow, Lupa with Lua 5.1, imageio-ffmpeg; exact versions in `../setup-requirements.lock` |
| Video | `.venv312/bin/ffmpeg` points to the environment's bundled binary; system `ffprobe` checks duration |
| Source game | `/home/picasso/.spring/games/Mosaic.sdd` |
| Graphical engine | `/home/picasso/MosaicDev/coil_compiled/coil`, reporting `105.1.1-1544-g058c8ea BAR105` |
| Map | `MOSAIC_LastDayOfDubai_V3 2026.11.18`, using the verified release archive |
| Evidence destination | New subdirectories of `/home/picasso/MosaicDev/animation-runs` |

## Local compatibility changes

The original ZIP is preserved. Local changes are confined to the external lab:

- The host Python 3.10 installation lacks `ensurepip`; use the isolated Python 3.12 environment instead. The incomplete `.venv` attempt is unused.
- The system FFmpeg cannot parse the per-image `option framerate` directive used to preserve observation timing. The launcher prepends the isolated environment's bundled FFmpeg to `PATH`. The analyzer uses its supported `-fps_mode vfr` option; no interpolation is added.
- Mosaic has three internal filename-alias symlinks: `engineoptions.lua → EngineOptions.lua`, `modoptions.lua → ModOptions.lua`, and `luaai.lua → LuaAI.lua`. The opt-in `--materialize-internal-symlinks` copies internal file targets into independent regular snapshot files and records the aliases. External links and directory links remain rejected. The original checkout and symlinks stay intact.
- This installed Coil predates `--only-local`. The opt-in `--local-server-compat` uses its documented `--server=127.0.0.1`, while retaining isolated data/write directories and `HostIP=127.0.0.1` in the startscript. The local launcher selects that mode; the upstream default remains unchanged.

The user-requested reminder is a local systemd user timer, `mosaic-animation-review-20261119.timer`, for **November 19, 2026, 10:00 Europe/Berlin**. It is persistent and retries notification-service failures. It does not create a ChatGPT/cloud reminder.

## Commands

Run these from `/home/picasso/.spring/games/MOSAIC_Animation_Lab`:

```bash
./lab.sh help
./lab.sh validate animation_lab/scenarios/civilian_locomotion.json

# Always choose a fresh output directory.
./lab.sh run \
  --scenario animation_lab/scenarios/civilian_locomotion.json \
  --output /home/picasso/MosaicDev/animation-runs/civilian-western0-side-1337-review01 \
  --seed 1337 --view side --timeout 240

./lab.sh analyze /home/picasso/MosaicDev/animation-runs/civilian-western0-side-1337-review01

PATH="$PWD/.venv312/bin:$PATH" .venv312/bin/python \
  -m unittest discover -s animation_lab -p 'test_*.py' -v

# Preserve earlier inventories and any human decisions.
.venv312/bin/python animation_lab/audit_inventory.py \
  --output animation_lab/review_inventory_next_revision
```

`prepare` stages an isolated game but does not observe an animation. `run` launches a real graphical engine and needs desktop graphics and loopback sockets. One staged snapshot occupies approximately 4.1 GiB with this source. Preserve evidence; only remove a disposable snapshot after deliberately deciding its evidence is no longer needed.

## Checks completed

- **56 automated harness tests pass**, including Lua 5.1 controller/observer tests, source isolation, internal-link materialization, external-link rejection, loopback-compatible command generation, and encoded-video timing. These are synthetic tests, not rendered Mosaic animation approval.
- Git-index completeness verified for **9,558 tracked paths** in the actual installed game checkout.
- Static inventory recorded **15 models, 74 named animation entries, and 470 model/clip coverage candidates**. See the review plan and separate model TODO.
- Initial live attempt preserved at `/home/picasso/MosaicDev/animation-runs/setup-civilian-20261118`: staging succeeded; engine exited before capture because `--only-local` was unsupported. No images from that attempt establish animation quality.

The corrected live-attempt result is recorded in the dated setup status below. Mechanical capture completion and visual approval remain separate gates.


## November 19 animation-polish session

The versioned lab now lives at `/home/picasso/MosaicDev/tests/MOSAIC/animation_lab` on `mosaic-tests`. The installed lab uses the same Python environment. Use the versioned source for development.

The compatible Coil crashes in the normal HUD's font rendering shortly after the opening cinematic. Disabling fontconfig alone did not resolve it. The newer installed Spring 2025.01.6 cannot load Mosaic models with more than 254 pieces. For body-animation review, use the explicit `--observer-only-ui` fixture: it hosts the existing capture observer, preserves the production simulation/models, and records the UI substitution in the manifest. It cannot approve normal HUD integration.

The desktop has a 900-pixel-wide portrait monitor to the left of the main monitor. Use `--window-position 1000 100` for a complete 1280×720 framebuffer. The free camera now supplies the engine's explicit pitch/yaw convention. The analyzer accepts integral JSON numbers emitted with decimal places by this Lua engine, while rejecting fractional frames and nonfinite values.

The conversation/death and melee scenarios set `minspeed=maxspeed=0.25` to avoid dropped samples during PNG capture. Timing-preserving videos still use simulation time and display normal-speed motion. This is a capture-quality setting, not a production animation speed change or a performance benchmark.

From the external test repository:

```bash
PATH=/home/picasso/.spring/games/MOSAIC_Animation_Lab/.venv312/bin:$PATH \
/home/picasso/.spring/games/MOSAIC_Animation_Lab/.venv312/bin/python animation_lab/animlab.py run \
  --game /home/picasso/.spring/games/Mosaic.sdd \
  --materialize-internal-symlinks --local-server-compat \
  --disable-fontconfig --observer-only-ui --window-position 1000 100 \
  --engine /home/picasso/MosaicDev/coil_compiled/coil \
  --map 'MOSAIC_LastDayOfDubai_V3 2026.11.18' \
  --map-archive /home/picasso/MosaicDev/releases/last-day-of-dubai-2026.11.18/MOSAIC_LastDayOfDubai_V3_2026.11.18.sdz \
  --scenario animation_lab/scenarios/operative_melee_exchanges.json \
  --output /home/picasso/MosaicDev/animation-runs/CHOOSE-A-NEW-RUN \
  --seed 1337 --view threequarter --timeout 600
```

The typed `expect_death` action declares an expected native lifecycle event without killing the unit. The `destroyed` check verifies it actually occurred. The melee fixture uses these for arena cleanup, then checks that the survivor is alive and detached.

For detailed contact/continuity review, add `--single-step-capture`. The isolated host pauses when the first review phase begins and advances one real simulation frame only after it has been drawn and any PNG write has completed. This avoids relying on render throughput to keep up with simulation. The flag is recorded in the manifest and generated run configuration. It is an observation mode, not a real-time performance test. The `operative_melee_grounded.json` and `operative_melee_propagator.json` scenarios allow the normal arrival effects to settle before entering combat.

## November 20 capture fixtures

The lab now passes 67 synthetic tests. Complete gap-free native captures have validated the recording path (`animation-polish-civilian-05`, `06` and `animation-polish-melee-propagator-01`); visual defects are recorded separately.

A unit's optional `piece_geometry: true` records native piece bounds, offsets, parents, matrices and unit basis, including the dying body while it still exists. These data diagnose support; they do not replace images or establish exact mesh contact.

A unit's optional `stationary_fixture: true` locks its map position with MoveCtrl. The fixed melee scenarios use this on the arena so buildings cannot occlude a moving review camera. Production attachment, piece animation, health and release still run. This fixture cannot approve arena navigation or native engagement.

Long execution-tool sessions were interrupted around five minutes. For lengthy local captures, use a supervised user service with its own capture timeout, explicit desktop environment and the lab virtualenv on PATH. The November 20 runs use transient `mosaic-animlab-*` services. Preserve failure manifests and partial captures rather than resuming a partially played simulation as if it were continuous.
