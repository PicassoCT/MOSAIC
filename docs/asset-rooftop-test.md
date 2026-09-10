# Asset rooftop movement prototype

Branch: test/asset-rooftop-movement

Right-click a building with an asset selected, or issue Move onto it. A queued
custom movement command approaches the nearest roof tile, animates the unit
position upwards, walks between connected tile centres and attaches on arrival.
Click another tile to reposition. Shift queues normally; a new ground command or
Stop releases the asset. Mixed selections keep the original order for other units.
Explicit UI building attacks become approach/roof orders. Synced building attack
orders (including inserted attacks) and automatic shots at buildings are rejected.

## Animation hook

Implement `rooftopGrappleAnimation()` in `scripts/operativeassetscript.lua`.
It runs in a unit-script thread, can Sleep, and is signalled off on landing or
cancellation. There is deliberately no hook, cable, or grapple pose animation.
The gadget owns the unit's position; the hook should animate model pieces only.
Walking uses the existing asset animation. Rooftop occupancy forces visibility.

## Test in Recoil

1. Select one asset far from a completed house. Right-click a roof tile: approach,
   short launch pause, position ascent, short walk, attachment; no building fire.
2. Repeat using explicit Move and a mixed selection. Other units retain their order.
3. Click a second tile on the same roof. The asset walks without returning to ground.
4. Shift queue roof A, roof B, then a ground Move. Verify order and final release.
5. Stop or replace orders during approach, ascent, traversal and idle occupancy.
6. Destroy the building during ascent and while occupied. Verify no stuck MoveCtrl.
7. Test western, Arabic, Asian, standalone and compound houses; rotated houses,
   disconnected roof sections, blocked approaches and a building without roof tiles.
8. Check attacks on mobile enemies still work, and neither automatic nor explicit
   fire targets buildings. Verify recloaking after leaving the roof.

## Prototype limits

- Destinations snap to existing roof tile centres, not arbitrary surface points.
- Tile adjacency uses a 96-unit distance and 24-unit maximum height step; it is
  not a mesh navigation system. Test gaps/decorations and tune these constants.
- Ground release returns to the recorded approach point; descent animation is
  not implemented. A blocked approach times out after 60 simulated seconds.
- Mouse picking uses ray proximity to curated roof tiles, matching the previous
  picker concept. Facade/roof boundaries need visual testing.
- No engine session was available here. The standalone mocked behavior test
  exercises queue completion, cancellation, destruction, retargeting, input
  validation, UI routing and Shift preservation; it cannot verify engine physics,
  transport command execution or animation appearance.

Run `lua tests/asset_rooftop_test.lua` from the game root (Lua 5.1 or newer).
