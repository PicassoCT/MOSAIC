# Temporary building and tank effect traces

The commit titled `debug: trace building fire and tank muzzle delivery` adds
default-enabled `Spring.Echo` diagnostics. It is deliberately separate from the
structural script-binding and electrical-color fixes. Reverting that debug
commit removes its instrumentation, tests, and this guide while retaining the
functional fixes.

## Reading a trace

Each line has a prefix, the current simulation `frame`, a `unit`, a `cycle`, and
a `stage`, followed by named fields. A building damage cycle is its dispatch
frame; a tank cycle is the published shot frame. A registered building fire or
electrical arc retains its creation cycle through the synced registry and the
client renderer. Use `piece` and `slot` to distinguish simultaneous attachments.

The helper remembers up to 256 owners and 16 recent cycles per owner in each
logger. It emits each stage/reason/piece/slot combination once per retained
cycle, with a maximum of 64 events per cycle (256 in the structural library).
Repeated draws therefore remain silent. Diagnostic formatting and Echo calls
are protected so that logging errors cannot interrupt the callback. History
eviction can allow an old effect to log again; this is a debugging aid rather
than a complete event recording system.

To extract the relevant lines from an engine log:

```sh
rg '\[(BuildingDestruction|TankMuzzle|SmokeRibbon|GrapheneArcs)\]' infolog.txt
rg '\[BuildingDestruction\].*unit=25163 ' infolog.txt
rg '\[TankMuzzle\].*cycle=1832 ' infolog.txt
```

The unit and cycle numbers in the last two commands are examples; substitute
the identifiers from the current run.

## Building damage and falling sections

Startup reports `damage_gadget_ready` with `trace_version=2`, the eligible unit
definition count, the six-frame update interval, and the eight-impact limit.
Each structural house reports `structural_hooks_installed`,
`structural_init_begin`, and `structural_init_complete`. Initialization includes
the assembled block, column, and tracked-visible-block counts. The hook and
update lines report `header_dispatch` and the height movement axis.

The damage path is:

1. `damage_received` records the engine callback and attacker/weapon identifiers.
2. `damage_queued` records health, the admitted damage below half health, and the
   impact bucket. `damage_skipped` explains paralysis, nonpositive damage,
   missing health, a lethal hit, or health still at/above half.
3. `damage_dispatch_impact` reports each final merged bucket; then
   `damage_dispatch_begin` reports the exact aggregate delivered to the script.
   These are the totals to use when several hits occur in the same frame.
4. `structural_update_received` confirms entry into the library. A missing script
   environment/callback or a dead unit instead produces `damage_dispatch_skipped`.
5. `block_lookup_selected` records the chosen piece and selection method. A
   failed lookup reports candidate, hidden, gone, and pending counts in
   `block_lookup_skipped`.
6. `block_damage_accumulated` reports the increment, accumulated damage, and
   strength. `block_fire_requested` and `block_fire_result` bracket the actual
   provider call; `block_fire_skipped` explains an absent provider, an existing
   fire, or the two-fire limit.
7. `block_failure_scheduled` gives the due frame. On that tick,
   `block_failure_due`, `block_detach_begin`, `block_settle_begin`, and
   `block_settle_issued` record the affected sections and movement commands.
8. Six frames after detachment, `block_fall_hidden` reports completion and the
   fire provider reports removal. `structural_update_complete` and
   `damage_dispatch_complete` report whether more timed work remains.

The original integration failure produced assembled blocks but no eligible
visible block at step 5. The real script header had cached native `Show` and
`Hide` functions in each separately compiled chunk, bypassing the damage
library's tracker. The functional fix makes those chunks resolve the owning
house's hooks when called. Structural height tracking and settling now use
axis 2, matching the procedural generators.

The current animation moves existing model sections and then hides them. It
does not create flying debris pieces. Destruction enters `collapse_begin`,
reports `collapse_floor_begin`/`collapse_floor_complete` for each surviving
floor, and ends with `collapse_complete`. These lines describe the structural
collapse; they do not prove subsequent corpse/replacement work has completed.

## Building fire and electrical ribbon delivery

The synced smoke gadget reports `[SmokeRibbon] stage=provider_ready`; its
unsynced counterpart reports `stage=renderer_ready`. A tagged building fire
then reports these stages under `[BuildingDestruction]`:

| Stage | Meaning |
| --- | --- |
| `building_fire_registration_requested` | The synced provider received the request. |
| `building_fire_registered` | Normalization succeeded and the registry revision advanced. |
| `building_fire_received` | The client copied the registered record into its renderer. |
| `building_fire_render_ready` | Visibility, position, direction, distance, and frustum checks admitted it to the draw candidates. |
| `building_fire_draw_submitted` | The renderer's `gl.CallList` call returned. |
| `building_fire_removed` | The synced attachment was removed. |

Rejection stages give the concrete reason, including normalization failure,
missing piece position, disabled/hidden owner, distance cutoff, frustum, zero
fade, or ribbon budget. Distance rejections include squared distance and cutoff.
Only scalar metadata crosses the synced boundary; the client creates its own
logger. Graphene arcs use the same path under `[GrapheneArcs]` with the
`graphene_arc_` stage prefix. Registration includes the actual RGB endpoints.

`draw_submitted` means **CPU submission returned**, not that visible pixels
appeared. It cannot establish depth-test results, final screen coverage, or
appearance on the player's GPU.

Current building-fire dimensions and timing remain unchanged: length 24,
width 5, distance factor 35, and at most two active fires per house. The current
renderer therefore rejects these anchors beyond 840 world units. A block that
immediately exceeds its strength is scheduled to fail after six frames and
hidden six frames later, so its fire can last only about 0.4 seconds from
registration. These are existing limits to inspect after delivery succeeds,
not evidence that either limit caused the earlier empty-candidate failure.

## Tank muzzle delivery

`[TankMuzzle] stage=combat_renderer_ready` reports renderer availability and the
number of configured tank types. The normal path is:

1. `tank_registered`: the client recognizes this tank's muzzle profile.
2. `tank_shot_published`: the unit script publishes the shot frame.
3. `tank_shot_observed`: the client reads that frame and reports its age.
4. `tank_muzzle_anchors`: the named emitter and cannon pieces resolve when first
   needed. Their cached IDs appear again in `tank_muzzle_source_ready`.
5. `tank_muzzle_source_ready`: origin, direction, dimensions, and opacity are ready.
6. `tank_muzzle_queued`: the source survives the existing light budget.
7. `tank_muzzle_render_ready` and `tank_muzzle_draw_submitted`: the shared ribbon
   renderer admits the source and returns from its draw submission.

`tank_muzzle_rejected`, `tank_muzzle_budget_dropped`, and
`tank_muzzle_render_rejected` explain interruptions. If the client first sees a
shot after its 12-frame window, the expired-stamp line includes
`expired_on_first_observation=true`. Ordinary expiry after an observed active
shot reports false. Owner visibility rejections do not read hidden shot stamps.

The tank's visual timing, dimensions, CEGs, camouflage, and budgets are unchanged
by this debug commit. A live run is still needed to locate the reported missing
flash; passing mocked renderer calls cannot establish that it was visible.
