# Temporary building, smoke and graphene traces

The final commit titled `debug: trace remnant and finite-effect transitions`
adds default-enabled `Spring.Echo` diagnostics after the functional building and
chute commits. Reverting that final commit removes its new lifecycle diagnostics
and their test assertions, retaining the 80% threshold, remnants, finite effects
and black canopy. The earlier delivery traces from
`debug: trace building fire and tank muzzle delivery` remain in the parent;
reverting this new commit does not remove that older instrumentation.

## Reading a trace

Lines identify their simulation `frame`, owning `unit`, originating `cycle`,
and `stage`, followed by named values. An effect's cycle is the frame at which
it was created. Its expiration can therefore report a much later `frame` while
retaining the original `cycle`. Use `piece` and `slot` to distinguish concurrent
attachments. Damage dispatch completion follows the last dispatched hit cycle
until all structural and effect work finishes.

The shared helper bounds its owner/cycle history and suppresses repeated
stage/reason/piece/slot combinations. Structural and smoke diagnostics describe
transitions; an unchanged eight-second fire or ten-second smoke lifetime does
not print on every timer or draw tick. Diagnostics use protected Echo calls so
an unavailable logging sink cannot interrupt damage, descent or cleanup.
History eviction can allow a very old renderer stage to appear again. This is
a debugging aid, not a complete event recording system.

Extract a run with:

```sh
rg '\[(BuildingDestruction|GrapheneChute|GrapheneArcs|SmokeRibbon|TankMuzzle)\]' infolog.txt
rg '\[BuildingDestruction\].*unit=24926 ' infolog.txt
rg '\[GrapheneChute\].*stage=(canopy_|graphene_chute_)' infolog.txt
```

The unit number is an example; substitute the ID in the current run.

## Damage admission and visible remnants

`damage_gadget_ready` reports `trace_version=3`, `health_threshold=0.8`,
`upper_remnant_chance=0.5`, `fire_frames=240`, `smoke_frames=300` and
`fade_frames=60`, together with the six-frame update interval and eight-impact
queue limit. These values come from the actual shared configuration.

Each structural house reports `structural_hooks_installed`,
`structural_init_begin` and `structural_init_complete`. Initialization includes
assembled blocks, columns and currently tracked visible blocks. Assembly may
show its selected pieces after initialization; the visible count at that instant
is not a permanent eligibility count.

The normal damage path is:

1. `damage_received` records the engine callback and attacker/weapon IDs.
2. `damage_queued` records post-hit health, the admitted portion below 80%,
   and the accumulated impact bucket. `damage_skipped` explains paralysis,
   nonpositive damage, missing health, a lethal hit, or health still at/above
   the configured threshold. A crossing hit contributes only its part below
   80%; the preceding health loss is not retroactively assigned to blocks.
3. `damage_dispatch_impact` lists each merged bucket, then
   `damage_dispatch_begin` records the aggregate sent to the script. Use these
   totals when several hits arrive in one interval.
4. `structural_update_received` confirms entry into the structural library.
   Missing script callbacks or dead units instead produce
   `damage_dispatch_skipped`.
5. `block_lookup_selected` identifies the owner of a fresh piece hit or the
   block selected by cached position. `block_lookup_skipped` gives candidate,
   hidden, pending and gone counts if selection fails.
6. `block_damage_accumulated` records the increment, total and strength.
   Strength is `0.8 * maximumHP / assembledBlockCount`, with a minimum of one.
   `block_failure_scheduled` gives the due frame once strength is exhausted.
7. On that tick, `block_failure_due` and `block_detach_begin` identify the
   failed support and every affected section above it in the same column.
   `block_remnant_decided` reports the bottom/upper classification, actual
   retention result and upper-piece roll. Bottom blocks do not need a roll.
8. `block_settle_begin` and `block_settle_issued` describe the model movement.
   Retained upper blocks sink toward `bottomY + 0.2 * floorHeight`. Six frames
   later, `block_fall_retained` confirms a visible remnant or `block_fall_hidden`
   confirms removal of a nonretained section.
9. `structural_update_complete` reports remaining work. The damage gadget's
   final `damage_dispatch_complete reason=finished waiting=false` appears when
   both structural work and finite effects have completed. Empty timer ticks
   in between stay quiet.

Retained geometry remains structurally failed. It cannot acquire new rooftop
access, move under a later animation, or be hidden/re-shown by a day/night
thread. Existing lower blocks under a higher hit remain intact. Full death
still clears the original house model and permits its scrapheap replacement;
partial remnants do not become separate debris units.

The original empty-candidate integration failure came from script-header
aliases bypassing the owning house's Show/Hide hooks. The earlier functional
commit fixed that dispatch and corrected height movement to axis 2. Those
changes remain underneath this feature.

## Fire registration, positioning and extinction

`block_effects_started` gives the selected visible piece and its fixed fire and
smoke deadlines. There are at most two concurrent authoritative effect anchors
per house. Repeated hits do not extend an existing anchor's lifetime or evict
another anchor.

`block_fire_requested` includes the actual FlamePainter dimensions, local root
offset, outward/upward direction, end frame and fade interval.
`block_fire_result` records provider acceptance. `block_fire_skipped` explains
an already active anchor, hidden piece, full slots or missing provider.

The placement helper chooses an outer facade near its upper edge, then
compensates for the piece's actual emitter offset. In the tested Recoil engine,
`GetUnitPiecePosDir` uses the mesh's first vertex for ordinary multi-vertex
pieces, which need not coincide with its pivot or center. Raw mesh bounds also
need the imported piece basis. Treating the returned emitter as the pivot can
put an apparently accepted flame inside the model. The helper now computes the
intended wall point and converts the displacement from that emitter back into
piece-local coordinates. The fixed local offset follows later settling.

Primary engine definitions are
[`S3DModelPiece::GetEmitPos` and `LocalModelPiece::GetEmitDirPos`](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Rendering/Models/3DModel.cpp)
and the
[`GetUnitPiecePosDir`/`GetUnitPieceMatrix` Lua bindings](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaSyncedRead.cpp).

A tagged fire then follows the shared ribbon path:

| Stage | Meaning |
| --- | --- |
| `building_fire_registration_requested` | The synced provider received the request. |
| `building_fire_registered` | Normalization succeeded and the registry revision advanced. |
| `building_fire_received` | The client copied the record into its renderer. |
| `building_fire_render_ready` | Visibility, position, direction, distance and frustum checks admitted a draw candidate. |
| `building_fire_draw_submitted` | The renderer's `gl.CallList` call returned. |
| `building_fire_removed` | The synced attachment was removed. |
| `block_fire_stopped` | The structural controller ended the fire, with the concrete reason. |
| `block_effects_removed` | The authoritative fire/smoke anchor was released. |

Rejections include missing position, owner visibility, distance cutoff,
frustum, ribbon budget and `expired_effect`. The simulation deadline is also
carried into the client renderer, so a UI reload cannot restart expired fire.
Fire fades during seconds 6–8 and ends at eight seconds unless hiding or death
stops it earlier. The flame is sized from the block: length is 2.2 world floor
heights, width is 0.55 world cell widths, with distance factor 120.

`draw_submitted` means **CPU submission returned**. It does not prove depth-test
results, final visible pixels or appearance on the player's GPU. A run which
reaches this stage but shows no flame should retain these dimensions, root
coordinates and any rejection lines for comparison with the scene.

## Smoke and newspapers

The wind gadget reads `GG.BuildingDamageEffects[unitID][piece]`. It no longer
starts a separate 25-second timer from the previous damage anchor. Structural
layer 0 updates that table before wind layer 1 reads it, and the wind gadget
independently checks visibility, presence, start/deadline, validity and death.

| Stage | Meaning |
| --- | --- |
| `building_smoke_anchor_started` | A new authoritative piece/lifetime was observed. |
| `building_smoke_emission_started` | The first `vehsmokepillar` spawn call returned. |
| `building_smoke_emission_skipped` | The selected piece had no usable position. |
| `building_smoke_fade_started` | The final two-second reduction in new emission began. |
| `building_smoke_anchor_stopped` | This source stopped, with its removal/visibility/expiry/death reason. |

A spawn-call trace establishes that Lua requested the CEG, not that the engine
produced visible particles. Smoke emission ends at ten seconds and tapers
during seconds 8–10. Hiding the source or destroying the house stops new
emission immediately. Smoke particles already emitted keep their original
finite particle lifetimes, so a short dissipating tail can outlast the stop
line. The existing vehicle smoke particle definition is unchanged.

The paper/ash burst occurs once per new damage-effect lifetime. Windblown
newspapers retain their independent wind threshold and 270-frame cadence.
Damage smoke also runs on calm maps; calm weather does not enable the separate
windblown-paper event.

## Graphene chute

`[GrapheneChute]` identifies the replacement black canopy. The normal path is:

1. `canopy_polygons_hidden`: the 156 Rotator and three DownWardSpiral pieces
   were hidden. Their old Show animation paths are removed.
2. `canopy_deploy_begin` and `canopy_layout_ready`: the stable support, its
   imported span and chosen canopy radius are available.
3. `canopy_deploy_complete`: `black=4 arcs=4 slots=8` confirms accepted
   registration of four black one-strand ribbons and four electrical fans.
4. `passenger_attached`: the existing passenger attachment returned.
5. `canopy_clear_begin`, `canopy_cleared` and `passenger_released`: landing
   removes the effect slots and releases the passenger. Invalid passengers or
   Killed use their corresponding cleanup reason.

`canopy_deploy_skipped` explains a missing provider or unusable support geometry;
`canopy_registration_skipped` identifies a failed black-ribbon slot. These
optional visual failures do not prevent descent and passenger cleanup.

Black ribbons are tagged through the same provider/client/renderer sequence as
fire, under `[GrapheneChute]` with the `graphene_chute_` stage prefix.
Electrical fans retain `[GrapheneArcs]` and the `graphene_arc_` prefix. Black
material has zero RGB, emission and source glow; the electrical fans retain
the cyan/violet palette. Both use the corrected rim attachment offsets.

The Cord chain, travel commands, drop rates, water behavior, cloaked infantry
stand-in and landing retraction remain in the passenger lifecycle. The black
canopy test renders the production shader and checks opacity, no glow, pinned
roots and bounded material length; that render is a diagnostic rather than an
in-game screenshot.

## Tank muzzle delivery

The tank flash was confirmed visible in the latest user run. This feature does
not change its timing, dimensions, CEGs, camouflage or budgets. The existing
`[TankMuzzle]` delivery stages remain available:

`tank_registered`, `tank_shot_published` and `tank_shot_observed` identify the
shot. `tank_muzzle_source_ready`, `tank_muzzle_queued`,
`tank_muzzle_render_ready` and `tank_muzzle_draw_submitted` follow it through
source construction and rendering.

Rejection and expired-first-observation stages explain interrupted delivery.
Their draw-submission meaning is the same CPU-only statement described above.

## Focused verification

The Lua regressions exercise the actual house header/provider, imported facade
transform, structural lifetimes, authoritative smoke consumer and live chute
coroutines. Diagnostic assertions cover start, retained/hidden completion,
expiry, quiet steady ticks, teardown and contained Echo failure. The headless
GLSL tests cover the black canopy, electrical palette and existing smoke
material. Live-engine appearance remains the final visual check.
