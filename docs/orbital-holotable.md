# Transition-only holotable handover

The last loading picture briefly becomes a cyan-green projection. Mixed-size
image tiles flicker locally and are replaced by the first satellite image on
the **same screen-space plane**. A sparse set of old-picture fragments remains
late, then the perspective, luminous frame, grid and scanlines disappear. The
existing realistic orbital sequence follows without a holographic treatment.

This feature changes only the compositor's artwork-to-orbit interval and its
startup presentation clock. The Earth shader, survey shader, optical scales,
map projection, risk data, cloud transit and live-map handoff are unchanged.
There are no new table/room assets and no physical camera movements. The
projection surface is suggested with perspective, edge light and tile breakup;
the generated control-room storyboard is an art-direction reference, not an
engine screenshot or an additional scene loaded by this feature.

## Timing and boundaries

The existing **0.5-second blend** is retained, followed by the same four
0.5-second held orbital snapshots and 0.9-second cloud reveal: 3.4 seconds
nominal presentation time. Unlike an earlier 0.8-second preview proposal, this
implementation does not change the accepted sequence's timing constants.
Startup overhead and stalled display frames may extend elapsed wall time.

The compositor enters the effect only when all of these hold:

- Valid loading artwork is available.
- Cloud descent is still zero.
- Artwork fade progress is strictly between zero and one.

At fade zero the original image path remains intact. At fade one the old zoom
and reveal code runs unchanged, with no hologram sampling or grading. Missing
artwork takes the original fallback. Tile decisions are deterministic integer
hashes of cell identity and blend progress; Lua's RNG is not involved. Flicker
is restrained and per-tile, not a full-screen white flash.

The first snapshot is prepared at fade zero. The presentation timer is reset
only after that initial draw succeeds, so shader creation, texture allocation
and first-draw CPU/driver preparation cannot consume the visible blend. This is
not a GPU synchronization barrier: later GPU stalls still require a live test.
The post-screen pass reuses the same age/progress without advancing the clock.

During the artwork handover, each primary draw advances presentation time by
at most **0.05 seconds**. This preserves the nominal half-second blend at 20
display FPS and above. Slower startup frames stretch only this handover, so a
long gap cannot jump from plain artwork directly to the finished orbital image
without submitting any hologram draws. Discarded stall time is never caught up
later. The four existing snapshot boundaries and cloud reveal retain their
previous timing policy. This limits animation progress, not the rendering FPS;
it adds no rendering work to an individual frame.

The startup log identifies this correction with `[MOSAIC arrival] holotable v2`,
reports whether loading artwork is available, then reports the count of
primary transition draws at handover completion. Post-screen redraws do not
increase that count. A missing artwork texture reports the orbital fallback
explicitly. These are draw submissions, not GPU presentation acknowledgements.

The existing telemetry acquires its screen-space target during the last 18%
of the handover, as the plane settles. From the first held orbital snapshot
onward its previous alpha, content and behavior are unchanged. Loading artwork
is still held until a positive game frame; Escape, cleanup, prior hidden-UI
state and input ownership follow the existing implementation.

## Cost and validation

The effect reuses the cached orbital image and existing artwork texture in the
existing compositor. It introduces no render pass, texture allocation, asset
download, volume sampling or geometry. The transition branch has two image
samples plus bounded scalar/hash arithmetic. Its appearance does not establish
performance on a GTX 1050 Ti; target-hardware frame timing remains unmeasured.

Run from the repository root:

```sh
lua5.1 tests/orbital_arrival_holotable.lua
python3 tests/orbital_arrival_holotable_gpu.py
python3 tests/orbital_arrival_holotable_gpu.py --width 320 --height 240
python3 tests/orbital_arrival_holotable_gpu.py --width 840 --height 360
```

The Lua test executes the actual widget/helper with a renderer spy, including
six seconds of artificial compilation/allocation/first-draw work. It checks
static loading, the first unmodified image, clock reset, unchanged zoom timing,
late lock acquisition, post-pass reuse, terminal cleanup, failures and Escape.
It also covers stalls after warmup and during the handover, sustained slow
draws, recovery to healthy frame pacing, unchanged normal timing and missing
artwork diagnostics. It does not simulate or launch Recoil. CI runs this under
Lua 5.1.

The EGL test compiles the production compositor and an immutable copy of the
approved pre-feature compositor (Git blob `560904b32713e5028c57184e79cb43db0c0caec4`,
from master `473e16e433bfc0e83fbe60e1054c22c039e187f2`). At each tested resolution,
117 bit-for-bit comparisons cover cropped artwork, zoom/reveal samples and
missing-art/live fallbacks. Additional tests check deterministic transition
pixels, absence of live-map leakage, sparse lingering fragments, complete old
artwork removal and continuous endpoints. These test image fixtures and
headless GL, not in-engine rendering or target-hardware frame rate.

Optional production-compositor previews use Pillow:

```sh
python3 tests/orbital_arrival_holotable_gpu.py \
  --art loading.png --orbit first-orbit.png --preview-dir /tmp/holotable
```

Those images are inputs only. A recorded screenshot may already contain HUD
text; the compositor harness does not redraw or validate the Lua telemetry.
No preview image or reference-board asset is distributed with the game.
