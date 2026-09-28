# Sticky bomb inventory

- Click the existing Explosive Charge build tile to manufacture one carried bomb.
  The tile shows ready stock and queued production. Shift queues five; Ctrl multiplies by twenty.
  Right-click removes queued production, refunding unfinished work when the queue is cleared.
- Select **Plant bomb (N)** and click the exact visible enemy/neutral ground target.
  The operative approaches that unit and spends one charge only after attachment succeeds.
  The fuse starts on attachment and runs for five seconds. Lost/dead targets cancel the order;
  another nearby vehicle is never substituted. Shift can queue planting orders.
- Completed carried bombs stay inert. If the operative dies, their completed inventory drops
  at the death position and explodes after two seconds. Blast damage scales with bomb count;
  blast radius stays at 150. Unfinished production does not explode.

## Verification

Run `lua tests/sticky_bombs_test.lua` (or `luatex --luaonly tests/sticky_bombs_test.lua`).
The standalone mocked-engine tests exercise production costs, cancellation, shortages, stun,
exact targeting, approach, LOS loss, attachment failure, transfer, both fuse paths, and the
unit-limit fallback. `tests/asset_rooftop_test.lua` covers the neighboring movement widget.

In Recoil, check that the build tile immediately queues production without a ground cursor,
then plant a bomb on the farther of two moving vehicles. Check the count and five-second fuse.
Kill an operative carrying several charges and observe the delayed blast at the death location.
Repeat with a mixed selection and with a queued roof/movement order to verify UI interaction.

Timing, range, and damage live in `luarules/configs/sticky_bombs.lua`.
