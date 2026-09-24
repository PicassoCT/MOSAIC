# Cybercrime and police bribery

Cybercrime spends construction time; bribery spends money. There are no residential/business building classes.

## Playing

- Both main operatives can build Botnet Nodes and Policebribes. Existing Asset/Hivemind bribe access remains.
- A Botnet Node costs no resources and takes 30 seconds to construct with an investigator or propagator (build power 1). Construction must finish before income or the police timer begins.
- Build within 240 elmos of a city building. The nearest building is selected. One completed extraction can run per building across all teams. Invalid, duplicate or exhausted targets discard the node without charging resources.
- After construction, extraction lasts up to 120 seconds and pays 25 money every 10 seconds. A completed safehouse belonging to your own team within 500 elmos doubles that payout.
- Enemy occupation uses the house's existing occupation mapping. It pays the ordinary 25 while removing up to 50 from the occupier's available money. Allied teams are excluded. Enemy occupation takes precedence over proximity support. Empty enemy accounts do not change your payout, effects, duration or police response. There is no enemy-status marker or loss popup tied to a building.
- Each building holds 600 extractable money. Creating another icon cannot refill it. Inactive buildings recover 1 money per second; active extractions do not replenish reserves.
- Police receive the report 60 seconds after construction completes, drive from another building, and stop extraction when they reach the target building. Remaining income is forfeited; already paid money stays with you.
- Gunfire involving police response units within 350 elmos of a safehouse exposes it for 30 seconds. A later shootout renews that duration. Its previous cloak request is restored afterward unless you changed that request while exposed.

## Temporary recovery aid

If a team has no completed propaganda server and lacks the money or energy to afford one, its next successful extraction payment includes **1,000 money and 1,000 energy** in recovery aid. This is available **once per team per match**, including if the treasury is completely empty. An unfinished, resource-starved server does not block it.

The operative still has to finish the 30-second construction and reach the first payout 10 seconds later. Destroying, transferring or recreating nodes does not reset the team entitlement. Several nodes paying simultaneously claim only one grant. The recovery bonus never increases the enemy debit and does not consume the building's reserves. A surviving cybercrime builder and a usable city building are still required.

Set `CyberCrime.comebackEnabled = false` in `scripts/lib_mosaic.lua` to remove the temporary aid.

## Bribery controls

A bribe costs **150 money**, no energy, and **1 build-work unit**: about 1 second for the main operatives, 2 seconds for an Asset. Its 60-second lifetime begins after completion. It can influence up to three police units within 750 elmos of the icon.

- A bribe built by an operative initially protects that operative.
- **Guard / right-click a friendly operative:** follow and protect that operative, steering eligible police away. It also covers routine cybercrime investigations linked to that builder.
- **Move / right-click the ground:** send eligible patrols or officers searching after losing sight to a false dispatch there. The icon travels to the destination; it cannot teleport its recruitment radius across the map.
- **Stop:** hold a false dispatch at the icon's current position.
- Select the icon to see its mode, time remaining, accepted officer count and rings around those officers. Selected cybercrime icons show time remaining and total income.

Only `policetruck` and `riotpolice` are eligible. `ground_tank_night`, `house_spinner`, army units and other military assistance are not bribed. Officers witnessing gunfire or in combat refuse influence; visible active pursuit cannot be bought away. Officers can be diverted once they lose sight and the brief combat grace period expires. Bribery does not create its own offence report. Effects end when the icon expires, dies or changes owner, and reissuing commands does not extend the paid duration.

## Verification

Run `lua tests/clandestine_operations_test.lua` and `lua tests/police_response_test.lua` (Lua 5.1+). The first loads the real configuration and both synced gadgets with mocked Spring resource, ownership, visibility, movement and lifecycle APIs. It covers construction gating, zero-resource recovery, simultaneous grants/debits, hidden occupation, allied teams, building reserves, police arrival, destroyed/captured targets, bribery caps, military exclusion, witnessed violence, lost-sight searches and temporary safehouse exposure.

In-engine smoke check: construct a node near a neutral building, one beside your safehouse, and one at a known enemy-occupied building. Confirm ordinary/bonus payouts, wait for the delayed police response, try Guard and Move bribes, then provoke a police shootout near a cloaked safehouse. Repeat from zero resources with no completed propaganda server to verify the recovery route and its one-time limit. HUD placement and the balance values still need an actual match.
