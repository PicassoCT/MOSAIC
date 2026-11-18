# Propagator Human Shield

Select a Propagator, choose **Human Shield**, then click an ordinary civilian.
The operative approaches within 80 world units and takes that civilian hostage.
The civilian is visibly attached in front of the operative and stops ordinary
city and parade activities until released.

While a hostage is attached:

- The Propagator moves at **60% of normal speed**. The factor also applies to
  subsequent scripted speed changes.
- Hostile **Protagon** units cannot attack or interrogate the operative or his
  hostage with ordinary weapons. This includes queued attacks, automatic
  targeting, projectiles already in flight, and the effects of absorbed hits.
- **Sniper Rifle** and **Slow Sniper Rifle** can still fire and deal damage.
  The exception is per weapon: an Asset's other weapons remain blocked.
- The Propagator remains visibly uncloaked. A previously requested disguise can
  resume after release.
- **Release Hostage** replaces the capture button. It releases the civilian and
  restores the operative's speed and vulnerability.

The ability accepts living, visible, unarmed Gaia pedestrians. Other operatives'
disguise bodies, player-owned agents, already transported civilians, and
participants in an interrogation or close combat are ineligible. The hostage is
also released if the operative dies, changes team, or enters another transport.
If the hostage dies, protection ends immediately. Aerosol effects release the
hostage before continuing their existing behaviour. The existing safehouse
human-shield purchase and propaganda system is unchanged.

## Configuration and integration

`luarules/configs/human_shield.lua` holds capture range, movement factor and the
named sniper-weapon set. The command IDs in `commandsIDs.lua` are 33461 and
33462. `game_operative_human_shield.lua` owns attachment, rules parameters,
command validation, targeting, damage filtering and cleanup.

The unit-script framework checks the protection rule before each weapon's
existing `BlockShot` callback. This is needed because the engine's
`AllowWeaponTarget` call-in only controls automatic target selection; queued
and explicit attack commands also need a firing check. Projectile impact and
counterintelligence handlers use the same protection predicate before applying
interrogation or other hit effects. See the [Recoil Lua API](https://recoilengine.org/docs/lua-api/).

Civilian travel records remain registered and paused while held. The civilian
pose helper preserves and restores the model transforms it changes. The command
icon is a dark operative behind an amber civilian, with a crimson restraining
arm and an ivory outline. The PNG and single-frame cursor are included in the
game source.

## Validation

Regression tests belong to the external `mosaic-tests` suite, as required by
`AGENTS.md`. The Human Shield workflow runs the production gadget and relevant
integration functions under Lua 5.1 with mocked engine boundaries. The tests
cover target eligibility, faction and weapon exceptions, queued and inserted
commands, attachment failures, release/death/team changes, speed composition,
interrogation interruption, and preservation of civilian traffic records.

An in-engine visual and multiplayer smoke test remains necessary:

1. Capture a civilian while moving and while disguised; check the command icon,
   the visible hostage pose, grounded feet, turns and 40% speed penalty.
2. Test ordinary Protagon infantry, an Investigator, an Asset, a sniper turret
   and an Argus III. Only their sniper weapons should fire at the protected
   target; existing attack orders and investigation attempts must respect this.
3. Release manually, kill the carrier with a sniper, kill the hostage with a
   permitted weapon, and transfer the carrier to another team. Check normal
   movement and civilian behaviour resume, with no lingering attachment.
4. Repeat with a parade participant, during rain and with an incoming aerosol
   effect. Confirm ordinary city activities recover after release.

No in-engine appearance, frame-rate or multiplayer result is implied by the
Lua regression tests.
