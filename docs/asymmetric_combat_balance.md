# Asymmetric combat and defended breaches — first playtest pass

Conventional forces secure time and access for the covert game. Operatives,
assets, civilian agents, stealth explosives, surveillance and the sniper raid
minigame retain their existing rules and weapons. Nimrod's firing exposure is
the explicitly requested exception to concealment behaviour.

## Production and faction identity

- **Protagon:** reliable raid escorts, armed escort trucks, layered AA, and an
  army-base investment for tanks and air campaigns. The safehouse now offers
  the MG walker so covering a first raid does not require an assembly.
- **Antagon:** early walkers and expendable drones, technicals, mortar support
  and prepared ambushes. Existing suicide bombers and SSIED delivery units
  remain its close-range punishment for packed columns.
- Stationary assemblies are independent prototype copies with different menus.
  This fixes the shared-table overwrite that removed Antagon's technicals.
- Mobile assembly production follows the owner's faction. The UI disables
  unavailable products and synced command/creation checks enforce the menu,
  including inserted commands and queued production after capture. Unknown
  factions receive only the common subset. Fixed-wing combat aircraft require
  the army base instead of being available from any mobile assembly.
- Shared equipment retains shared stats; faction differences come from access,
  logistics and the force combinations available. Existing Godrod access remains.

## Ground and covering fire

| Item | Before | First-pass value / role |
| --- | --- | --- |
| MG walker | 1,000 M / 750 E, shared operative SMG | 650 M / 500 E; dedicated escort gun, 3.5 s reload |
| MG turret / attached truck MG | Shared heavy MG | Dedicated cover gun, 12 damage per bullet; avoids friendly firing obstructions |
| Civilian MG / mortar technical | 1,500 hull HP | 900 hull HP; mobility and surprise over staying power |
| Military truck hulls | Existing values | Unchanged; attached weapons included in playtest assessment |
| Destroyed conventional truck loadout | Recreated after roughly 100 ms | Additional 8 s recovery before recreation; stealth/SSIED loadouts unchanged |
| Day / night tank | 1,250 / 1,500 HP | Both 4,000 HP; no speculative armour-class changes |
| Tank cannon | 1,500 default damage, AoE 50 | New breaching cannon: 600 damage, AoE 32, 5 s reload; 4x damage to walls |
| Mortar | 1 damage, AoE 3, range 320 | New support mortar: 240 damage, AoE 120, range 750, 8 s reload |
| Conventional anti-tank launcher / truck loadout | Shared 60 s Javelin reload; 50 HP launcher | Separate 1,600-damage missile, 12 s reload, range 900, AoE 24; 350 HP launcher |

Conventional escorts use separate weapon definitions in
`weapons/military_support.lua`. The asset's SMG, sniper rifles, police missiles,
Javelin and concealed explosives are not retuned through shared definitions.

Cover means controlling the exterior approaches while an operative remains
exposed during a house raid. It does not grant an invulnerability aura or
extra minigame points. The existing hit/abort, placement, scoring and uplink
rules remain intact. Space escorts around the approach; stacking them directly
on the operative makes a single explosive attack more valuable.

## Walls and deliberate breaches

Brehmer walls now explicitly block ground movement; their previous definition
set `blocking=false`. Existing footprints, placement and costs are retained.
Both walls and barricades retain 10,000 HP.

Only the new conventional weapon profiles (and the Nimrod railgun) receive
wall-specific multipliers. All other weapons retain their previous damage.

| Weapon | Wall damage multiplier |
| --- | --- |
| Escort / cover / gunship MG | 0.05 |
| Dedicated AA | 0.10 |
| Mortar, Predator salvo, F35 ground missile | 0.25 |
| Nimrod railgun / conventional anti-tank missile | 0.50 |
| Tank breaching cannon | 4.00 |

One tank needs five full direct hits to breach a full-health wall segment:
20 seconds between first and fifth impact, plus aiming and travel. Splash
falloff is preserved. This is an isolated damage calculation, not a measured
in-engine breach time. A physical opening must also be wide enough for the
vehicle's footprint. Mortars are for displacing defenders, not demolishing a
wall line. Aircraft can bypass walls but do not create safe ground access.

## Air defence and concentration punishment

| System | First-pass behaviour |
| --- | --- |
| Incidental walker / MG-turret AA | Range 650; 12 x 12 damage burst, 4 s reload |
| Dedicated AA turret / attached AA truck weapon | Range 1,050; 650 damage, 6 s reload; turret 450 HP |
| MG copter | Cover-gun variant; existing chassis cost, HP and sight |
| Blackhawk | 1,400 M / 900 E, build time 90; 12 x 18 gun burst, range 420, 4 s reload; ground target mask corrected |
| Predator VII | 1,250 M / 1,000 E, 900 HP, speed 5; four 300-damage area rockets, AoE 160, 24 s salvo reload |
| Predator magazine | One model pod per salvo; last salvo starts one 60 s magazine reload; laser disabled during reload |
| F35 | 6,000 M / 4,500 E, build time 180; 1,200-range interceptor missile, limited 200-damage / 18 s ground missile |
| Nimrod | Ground aim enabled; one 1,200-damage area round, AoE 160, 35 s reload, existing 250 M / 250 E shot cost |
| Godrod / SSIED / suicide bomber | Existing damage, delivery and concealment rules retained |

AoE values are WeaponDef fields. Predator rockets are unguided so movement
and dispersal matter. Ground AA reaches beyond the strike weapon's range;
walkers provide local drone protection, not city-wide air denial. The F35's
ground weapon is deliberately much weaker than the Predator's area salvo.

Nimrod is permanently visible to all players after either ground or orbital
weapon fires. Its public `nimrod_fired` rule survives gadget reload and team
transfer. Cloak requests are rejected and its icon/model handler cannot hide
the fired gun. An unfired Nimrod keeps its previous concealment. Satellite
production alone is not a weapon shot and does not trigger this rule.

Antagon's existing explosives punish compression at a breach immediately;
Protagon's air campaign punishes remaining concentrated over successive
passes. Both retain orbital escalation. Nimrod's 500 HP and permanent exposure
make its new area fire a commitment with a vulnerable firing position.

## Verification and required playtests

Automated standalone checks:

```
lua tests/military_balance_test.lua
lua tests/military_weapon_scripts_test.lua
```

They exercise real definition inheritance, independent faction menus, frozen
shared weapons, wall damage routing, persistent Nimrod exposure, mobile-factory
capture/command restrictions, Nimrod aim/fire callbacks and two complete
Predator magazine cycles with a signal-aware coroutine mock. These are not
engine simulations or evidence of competitive balance.

Before merging, playtest:

1. **Covered house raid:** operative plus two separated escorts versus an
   exposed defender and a flanking technical. Complete a sniper-minigame round
   while exterior combat occurs. Losing cover must remain dangerous.
2. **Defended breach:** one tank opens a passage through a wall, then vehicles
   and pedestrians use it. Verify footprint clearance, projectile collision,
   civilian rerouting, both wall orientations and barricades.
3. **Packed versus dispersed:** replay identical-value formations against an
   existing SSIED, a Nimrod and a Predator. Record surviving value and collateral
   transfers. Dispersal must substantially reduce losses.
4. **Air denial:** Predator attacks with and without dedicated AA; compare to
   incidental walker AA. Observe real hit rates, flight altitude and attack
   passes. Test magazine exhaustion and completion of the 60 s reload.
5. **Nimrod exposure:** fire each weapon, lose all enemy LOS, attempt recloak,
   transfer/capture the gun, and reload a save. The fired model must stay visible.
6. **Truck weapon loss:** destroy an attached weapon while leaving the hull
   alive; verify the recovery window and unchanged SSIED behaviour.
7. **Full asymmetric match:** compare military spending with investigation and
   launcher progress. Track deployment delay, economic collateral, idle/unused
   units and whether a pure combat composition can bypass the covert game.

No new smoke system, damage-reduction aura, global armour taxonomy or minigame
rewrite is included. Argus/sniper behaviour and strategic Godrod timing need
live assessment alongside this first pass before further tuning.
