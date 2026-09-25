# Betrayal runners

A deliberate friendly attack on an operative can produce a defector. Incidental splash does not turn a survivor. Friendly lethal damage still preserves evidence, including a one-shot execution. Destroying your own occupied house also preserves its safehouse's connections.

Ctrl+D on interrogatable player units starts a five-second termination warning. A second Ctrl+D cancels it. On expiry, an operative defects; a safehouse or other interrogatable structure is destroyed and leaves a remote dead drop. Ordinary combat units retain their existing self-destruct behavior.

## The chase

- A surviving operative changes employer through a replacement unit, because existing operative scripts cache their team at creation. Health and experience survive; queued attacks, production and self-destruct commands do not.
- The first surviving damaging hit schedules the escape for the next simulation frame. Further damage is suppressed only during that handoff, so a same-frame turret volley cannot preempt it. A lethal first hit still leaves evidence; the chase itself has no damage immunity.
- There is one emergency relocation through a nearby, completed civilian building. Buildings occupied by a live safehouse are excluded. Up to 32 walkable emergence points outside each building's collision volume are considered, within 600–1800 elmos of the execution site. The start must be at least 900 elmos from every operator and safehouse, regardless of team, cloak, or construction progress. Weapon ranges plus a 150-elmo buffer and a 300-elmo gap from other player units (including unarmed charges) are also checked on all sides.
- Building exits and receiving contacts are ranked together against the desired run length, with a small preference for less teleport distance and for a field operative over a safehouse. IDs and exit order break ties deterministically. If no suitable building/recipient pair exists, the runner flees from the original location; death or stalling still releases the backup. The escape is a single use abstraction of emerging from a building, not repeatable transport.
- The travel target is 35 seconds at the unit's nominal speed, clamped to 900–2400 elmos. A longer route can still win when nearby buildings cannot offer that target. This is an estimate from endpoint distance, not a measured path duration or a guarantee of an optimal route. Buildings, terrain, interception and a moving recipient change it.
- The runner is visible and targetable to every team, marked in the world, and permanently unable to cloak. Civilian disguise threads respect that state too. Injury causes fading blood patches on dry ground; healthy runners, water and rooftops do not create ground blood.
- The runner moves autonomously. Its new employer chooses a field rendezvous by moving another operative into its path. A completed, functioning friendly operative or safehouse can receive the intelligence after two seconds nearby. A safehouse is not required. The chosen destination's ID is private.
- Runners cannot be given scouting, attack, production, cloak, transport or transfer orders. After delivery, their new employer may command them normally, with their identity still permanently exposed.
- Delivery reveals the source's former recruiter and direct recruits/builds. It does not reveal the whole organization or include contacts made after the betrayal snapshot.

## Evidence and failure cases

Death before delivery releases a dead drop elsewhere in the city. An enemy operative collecting it reveals the same recorded connections; an operative allied with the former employer suppresses it. Bullets cannot erase the package. Drops expire after three minutes. A runner stalled for 30 seconds also releases the backup, without another relocation.

If no opposing operator or safehouse exists, the exposed witness waits for a valid recipient. If the engine cannot create a drop (for example at the unit limit), the recorded secrets are revealed instead of silently disappearing. Destruction removes recorded dead contacts so recycled unit IDs cannot become invented graph connections.

The old drop script's undefined IDs, reversed CreateUnit arguments, missing collector argument, and per-drop polling loop are replaced by centralized lifecycle handling. Graph expiry now compacts its list instead of assigning the return value of table.remove to the whole registry.

## Tuning and validation

`luarules/configs/betrayal.lua` holds timings, distances and escape clearances. The presentation caps blood marks at 256 and fades them after 30 seconds. Recipient searches use an operative/safehouse roster; escape hazards are snapshotted once per placement attempt and buildings are searched only within the local radius.

Standalone Lua 5.1 regression checks:

- `tests/betrayal_runners_test.lua`: deliberate versus splash damage, fatal hits, next-frame escape and bounded volley protection, nearby buildings and walkable exits, contact clearance on all teams, occupied/unfinished houses, weapon ranges and unarmed charges, joint destination selection, Ctrl+D cancellation/expiry, delivery, remote evidence, retries, unit cap and recycled IDs.
- `tests/betrayal_visibility_test.lua`: reveal expiration and list holes; blood cap, movement, water, rooftops, injury and cleanup.

In-game checks still required: run a turret/IED execution scenario on Last Day of Dhubai; check the route through dense streets and the appearance of blood at normal zoom; intercept with an operative away from the receiving safehouse; verify death and collection from both viewpoints. No Recoil match was available in the development environment. The 35-second target needs playtesting.

## Balance notes

Execution trades a known person for an uncertain information problem. A successful pursuit should buy breathing room, while a successful rescue should buy a useful local lead. Keeping the reveal local prevents a single betrayal from deciding the entire match.

The receiving side also takes a risk: approaching a publicly visible runner can expose an operative or suggest where a safehouse is. A field rendezvous makes that risk a choice. The strongest stories should come from choosing whom to trust under pressure, rather than from learning a mandatory cleanup sequence.

The chase should last long enough for both players to make one meaningful intervention. If every runner is inevitably caught, betrayal becomes cosmetic; if every runner inevitably escapes, containment becomes pointless. Tune the time window before increasing the punishment.
