# Procedural building damage

Asian, Western and Arab procedural houses, including the ten Asian split
variants, lose individual structural blocks after health drops below 50%.
Unassembled model alternatives are never used as debris. Whole-model buildings
and objectives are unaffected.

## Damage and support

The engine applies health damage normally. The synced damage gadget queues only
the portion of a hit below half health. It ignores paralysis, healing, cancelled
damage and lethal hits. Every six simulation frames (0.2 seconds), the gadget
dispatches accumulated impacts for affected buildings. Small hits accumulate on
the selected structural block until its strength is exhausted. Block strength is
half the building's maximum HP divided by its assembled block count.

A fresh engine piece hit takes precedence; otherwise the nearest assembled block
to the projectile is selected, falling back to the attacker-facing side. The
existing whole-unit hitbox is retained: this is an approximation of the struck
block, not projectile collision against every generated mesh.

Supports come from the actual procedural grid placements. A failed block takes
every block above it in the same column with it, including its roof. This is a
conservative support rule; it does not simulate beams or permit cantilevered
upper blocks. Adjacent columns and the surviving lower section stay intact.
Independent nearby decorations, model children and day/night alternatives belong
to their structural block and disappear with it. Failure occurs one update tick
after the accumulated damage is resolved, giving a 0.2--0.4 second response from
the hit that exhausts the block's strength.

Broken pieces cannot reappear through construction, night lighting or scripted
animations. Their window/radiance entries, rooftop access and shadow-column bits
are removed. Anchored hologram units are removed; operatives on a failed roof
use the existing rooftop release behavior. Repairs do not regrow detached
geometry. A replacement house starts with fresh state.

## Final collapse

On destruction there is a 0.2 second pause. The lowest surviving floor crumbles,
and all remaining upper floors and roof decorations move down together over
0.32 seconds. This repeats upwards, then the remaining foundations and ground
furniture disappear. The existing unit destruction/rubble system still owns
replacement scheduling. Losing every structural block also destroys the unit,
so an invisible live building cannot remain.

## Cost limits

- One shared six-frame timer visits only buildings with queued hits or pending
  support failures; healthy buildings have no damage polling loop.
- Eight impact buckets per building per interval; excess impacts merge while
  retaining their damage. At most three new column failures are scheduled per
  interval; excess accumulated block damage is retained for later intervals.
- Eight native falling-piece projectiles and three dust puffs per damage update.
  Final collapse emits at most eight pieces and two puffs per floor.
- A shared city-wide ceiling allows 64 falling pieces and 16 puffs per six-frame
  interval, including final collapses. Exceeding it reduces decorative effects;
  unsupported geometry still falls/disappears and the support state stays correct.
- Eight short-lived particles per dust puff. Debris never creates gameplay units.
- Support and decoration ownership are built once, using spatial buckets.
  Batched targeting uses cached block positions, with no whole-model pose scan.

## Validation

`tests/building_block_damage_test.lua` exercises the real gadget and helper with
mock engine APIs: HP threshold crossing, accumulated hits, fixed ticks, delayed
supports, roofs, children, decorations, night variants, holograms, shadow holes,
bounded queues/debris, deferred excess failures, death cleanup and floor order.
The rooftop and split-assembly tests cover their integration paths.

In Recoil, check repeated hits on upper and lower blocks, destruction during
construction, a roof occupied by an operative, day/night transitions after
damage, and several simultaneous collapsing houses. Appearance and target-GPU
frame times need an engine run; headless tests do not establish visual quality
or an FPS guarantee.
