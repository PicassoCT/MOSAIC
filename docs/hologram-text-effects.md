# Letter-piece holograms

Western and brothel signs share inventory-aware phrase selection and slot allocation in `scripts/lib_textFx.lua`. Complete phrases are preferred without editing the source phrase pools. If none fit, the full pool remains available. Unavailable glyphs occupy one logical slot (including one slot per unsupported UTF-8 character), preserving spacing. Repeated supported glyphs borrow an already allocated physical piece: original and borrowed positions alternate instantaneously every 500 ms during readable holds. A donor with several borrowed positions cycles through them in source order. The layout stores unique physical IDs separately from logical slots.

A single text owner schedules the leases; other text effects do not compete with a background leasing thread. Static signs also run readable holds. Authored highlight glitches, RGB ghosts and night flickering remain. An obsolete highlight worker is stopped when changing phrases. Text restoration now uses a 400-ms engine-interpolated arrival; phrase replacement also uses a 400-ms departure. These are movement transitions, not opacity fades. Unit-script Show/Hide does not expose opacity. Glow-worm reveals retain their deliberate stepped visibility but correctly split the requested flicker lifetime and handle empty groups.

The shared effect review repairs piece/axis arguments, missing all-piece waits, the circle radius parameter and no-rest flag, the personal projection's civilian identity, scratch-global leakage, empty inputs, repeated-gap spacing in curved effects, and the duplicate wait helper. Matrix arrivals place every axis before dropping. Waterfall restoration targets each actual axis. The cube's loop index is no longer mutated.

## New effects

- **Civilian conga:** chooses a live civilian within 650 world units, drops the physical letters to terrain height over 800 ms, and follows a bounded path history with phased sway and hopping. Letter spacing uses the authored glyph's transformed bounds. A cached inverse of each glyph's parent-world basis accounts for house heading, parent rotation, imported scale and axes. Motion updates at 5 Hz for at most 16.6 seconds, ending early on disappearance or departure beyond 750 units. Letter leases also rotate through conga positions. No civilian orders, MoveCtrl or new gadgets are involved.
- **Hostile takeover:** selects a different phrase from the sign's existing phrase pool and places it below the original. Private glyphs stay in formation and recoil while shared physical glyphs shoot across the gap in opposing directions on a 500-ms beat for 12 seconds. Each shot travels through a raised midpoint for 120 ms, lands over 130 ms, then holds for 250 ms; engine interpolation supplies the motion. There are no weapon projectiles, damage, extra letter meshes or per-frame workers. Repeated occurrences cycle through their leased slots too. The original layout is restored afterward.

Both modes join the existing uniformly selected effect catalogue: each now has a **1/22 chance (~4.55%) per selection**. The existing sign eligibility and horizontal-layout gates still apply. Conga requires a nearby live civilian; takeover requires another phrase. Ineligible effects return without a new retry loop.

## Validation

Run from the repository root with Lua 5.1:

```sh
luac5.1 -p scripts/lib_textFx.lua scripts/house_western_hologram_script.lua scripts/house_western_brothel_hologram_script.lua
lua5.1 tests/hologram_text_fx_test.lua
```

The regression suite executes the real shared library and both scripts' production functions with strict animation-call mocks. It covers exhaustion, direct occurrence ordering, UTF-8 gaps, selection, logical spacing, half-second leases and restoration, matrix parameters, radius/no-rest handling, glow lifetime, all 22 registered modes in both orientations, empty groups, parent rotation/scale inversion, conga lifecycle, takeover crossfire timing/trajectories and scratch-global isolation. CI uses native Lua 5.1; local validation can also run the same suite through `lupa.lua51` (Lua 5.1).

No Recoil visual or target-hardware performance validation has been performed. In Recoil, check a long repeated-letter slogan, day/night and blackout transitions, all projection modes, conga descent on slopes and rotated houses, turns/stops/death of the target civilian, and takeover cleanup when a phrase changes or the hologram is destroyed. Confirm glyph size, facing, ground clearance and movement timing against actual exported models. Compare zoomed-out frame times in a dense city.
