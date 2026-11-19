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
