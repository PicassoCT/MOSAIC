# Procedural building damage

Asian, Western and Arab procedural houses, including the ten Asian split
variants, begin accumulating structural damage after health drops below 80%.
Damage and collapse do not use `Explode` or emit model-piece debris. Whole-model
buildings and objectives are unaffected.

## Damage and support

The engine applies health damage normally. The synced damage gadget queues only
the portion of a hit below 80% health. It ignores paralysis, healing, cancelled
damage and lethal hits. Every six simulation frames (0.2 seconds), the gadget
dispatches accumulated impacts for affected buildings. Small hits accumulate on
the selected structural block until its strength is exhausted. Block strength is
80% of the building's maximum HP divided by its assembled block count. The
threshold and structural budget come from `getBuildingDamageConfig()` in
`lib_mosaic.lua`. A hit crossing the threshold contributes only its portion
below it; the earlier 20% health loss is not added retroactively.

A fresh engine piece hit takes precedence; otherwise the nearest assembled block
to the projectile is selected, falling back to the attacker-facing side. The
existing whole-unit hitbox is retained: this is an approximation of the struck
block, not projectile collision against every generated mesh.

Supports come from the actual procedural grid placements. A failed block takes
every block above it in the same column with it, including its roof. This is a
conservative support rule; it does not simulate beams or permit cantilevered
upper blocks. Adjacent columns and the surviving lower section stay intact.
Independent nearby decorations, model children and day/night alternatives belong
to their structural block. Failure occurs one update tick
after the accumulated damage is resolved, giving a 0.2--0.4 second response from
the hit that exhausts the block's strength.

The affected sections settle using the unit model's movement commands and tilt
outward by 3--5 degrees. The lowest block of each column remains visible and
stays above the terrain even after its structural support has failed. Each
failed upper block receives one deterministic 50% retention roll. Retained
upper blocks sink to the bottom block's height plus 20% of a floor, overlapping
it as collapsed remnants. The other upper blocks make the short settling move
and disappear into dust. The retention choice does not reroll on later hits
or consume the game's random-number stream.

Only geometry that was already visible can remain as a remnant. Children
inherit their parent's movement, independent decorations follow their owner,
and authored rotation is preserved under the small collapse tilt.

Broken pieces cannot reappear through construction, night lighting or scripted
animations; retained remnants cannot be moved or hidden by those later
animations. Failed sections lose their window/radiance entries and rooftop
access. Upper shadow bits are removed while retained bottom blocks continue
to block light. Anchored hologram units are removed; operatives on a failed roof
use the existing rooftop release behavior. Repairs do not regrow detached
geometry. A replacement house starts with fresh state.

## Fire and smoke

Damage selects a visible structural piece before creating an effect. The
structural controller owns at most two simultaneous effect anchors per house;
the wind-effects gadget consumes those live anchors rather than remembering
the last piece struck by an earlier hit. Existing fires keep their own anchors
when another part of the house is damaged.

Each ignition has a fixed eight-second fire lifetime and ten-second smoke
lifetime. Fire fades over its final two seconds using simulation time, without
per-frame registry updates. A building staying damaged does not refresh either
deadline. A later damaging hit may ignite a new effect after a slot is free.
Both emissions stop immediately when their piece is explicitly hidden or the
house dies. Visible retained remnants may finish their finite burn. Smoke
particles already emitted finish their own particle lifetime.

Flame origins are placed outside the selected facade and sized from the
structural block's dimensions. The effect follows its piece while it settles.
The flying-newspaper wind effect is independent of these damage lifetimes.

## Final collapse

On destruction there is a 0.2 second pause. The lowest surviving floor crumbles,
and all remaining upper floors and roof decorations move down together, with
the same small tilt, over 0.32 seconds. This repeats upwards, then the remaining
foundations and ground furniture disappear. The existing unit destruction/rubble
system still owns replacement scheduling. The retained partial-damage remnants
belong to the living house model; final destruction clears that model before
the scrapheap takes over. Losing every structural support also destroys the
unit after its settling animation even if some remnants remain visible.

## Cost limits

- One shared six-frame timer visits only buildings with queued hits, pending
  support failures, settling sections or finite active effects; healthy buildings have no damage
  polling loop.
- Eight impact buckets per building per interval; excess impacts merge while
  retaining their damage. At most three new column failures are scheduled per
  interval; excess accumulated block damage is retained for later intervals.
- Existing model roots use engine `Move`/`Turn` animation, with no per-frame Lua
  loop, emitted model pieces, debris projectiles or debris units. Completion is
  handled by the same shared timer.
- At most three dust puffs per damage update and two per final-collapse floor.
  A shared city-wide ceiling allows 16 puffs per six-frame interval, including
  final collapses. Exceeding it reduces dust; support state remains correct.
- Eight short-lived particles per dust puff, sized to the building blocks.
- Support and decoration ownership are built once, using spatial buckets.
  Batched targeting uses cached block positions, with no whole-model pose scan.

## Validation

`tests/building_block_damage_test.lua` exercises the real gadget and helper with
mock engine APIs: HP threshold crossing, accumulated hits, fixed ticks, delayed
supports, roofs, children, decorations, night variants, holograms, shadow holes,
bounded queues/dust, deferred excess failures, short drops, relative tilts,
both retention outcomes, permanent bottom blocks, finite effect cleanup,
death cleanup and floor order. Any call to `Explode` fails the test.
The rooftop and split-assembly tests cover their integration paths.

In Recoil, check repeated hits on upper and lower blocks, destruction during
construction, a roof occupied by an operative, day/night transitions after
damage, and several simultaneous collapsing houses. Appearance and target-GPU
frame times need an engine run; headless tests do not establish visual quality
or an FPS guarantee.
