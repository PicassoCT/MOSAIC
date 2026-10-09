# Prometheus strategic play

Prometheus now runs MOSAIC-specific economy, reconnaissance and tactical managers.
The real controller submits construction, recruitment, upgrade, movement and attack
orders through the authenticated synced bridge. This replaces the old generic
frontline/GANN controller as the default; the legacy modules remain for reference
and their existing regression tests. No unit stats, prices, resource grants or
combat rules change. Runtime skirmish strength has **not** been validated in Recoil.

## Behavior

- Establish safehouses in separate neutral city houses. Respect the game's build
  mask, avoid known threats and keep at least one finished recruitment hub while
  another converts. Do not treat a queued building as a completed hub.
- Build propaganda income before an assembly. Increase the server target over
  time, rebuild losses, reserve costs within each decision pass, and use existing
  finite cybercrime recovery when funds cannot establish an economy.
- Resolve upgrades from the enabled UnitMorph command descriptor's destination
  texture. A safehouse conversion consumes that hub. Do not send `-serverDefID`
  as if the operative or safehouse could construct a server directly.
- Recruit operative, scout and assassin roles before optional escorts. Replace
  losses but stop at role limits. Hard/impossible: four main operatives, three
  assets, two scouts, two civilian agents and twelve mobile combat units;
  easy/medium: three main operatives, two assets, two scouts, two agents and eight
  mobile combat units. Individual escort types are limited to three.
- Scouts and civilian agents explore different city blocks. Idle main operatives
  scout too, but economy work can reclaim a scouting operative. LOS checks apply
  even to a spectator host. No reads of the hidden safehouse graph, enemy start
  positions or hard-difficulty perfect intelligence.
- Raid exposed enemy network buildings. Approach cloaked, decloak to attack,
  and preserve an ongoing raid while waiting for its resolution. The existing
  synced raid minigame provides its normal AI fallback placement.
- Assassin assets approach exposed enemy operatives for targeted attacks rather
  than being misassigned to building raids. Anti-air trucks select airborne
  targets and anti-armour gunships select ground targets.
- Send at most three combat units to a target per decision pass, use offset
  approaches, prefer valuable low-threat targets, defend a threatened hub and
  withdraw units below 40% health or facing overwhelming visible threats.
- Attack hostile live public objectives and restore friendly destroyed ones.
  New `objective_protagon` and `objective_destroyed` rules expose the same state
  already present in the objective tooltip, without depending on localized text.
- Betrayal rescue retains priority. The strategy cannot commandeer a runner or
  overwrite its reserved receiver. Production intents expire; a failed building
  site is quarantined before a retry rather than trapping the operative forever.

Decisions run once per 90 simulation frames per team. Unit/site iteration is
sorted and no random strategy choice is introduced. Identical observed state
produces identical choices; the AI remains hosted by its team leader client.

## Trace and diagnostics

`main.lua` resolves the faction from side, startUnit or an existing operative and
initializes `team.lua`. The team schedules betrayal rescue, then `strategy.lua`:
owned inventory/visible contacts -> economy -> reconnaissance -> tactics.
`GiveOrderToUnit` in `framework.lua` returns true for an enqueued order. The
framework batches it into a LuaRules message; its synced receiver verifies the
sender, current ownership and runner restrictions before calling the engine.

New packets use marker 214 with 32-bit unit IDs, command IDs and rounded integer
parameters. Legacy marker-213 packets remain readable. Separate option/count
bytes avoid truncating high IDs, large-map coordinates and custom commands.
Packets remain limited to 8192 bytes and 256 packets per frame. Malformed packets
execute no partial batch. Parameter rounding remains to the nearest world unit.

The first five strategy summaries (30-second intervals) report manager ticks,
queued/rejected submission counts and reasons for strategic waiting. Faction
warnings and each bridge failure reason also stop after five messages by default.
`/luarules prometheus` toggles continued strategy diagnostics.

Synced summaries and public team counters distinguish:

| Counter | Meaning |
| --- | --- |
| `prometheus_orders_dispatched` | Engine API returned success; not proof of completed construction or combat |
| `prometheus_orders_rejected` | Engine returned false/threw, or ownership/leader/runner check rejected an order |
| `prometheus_orders_unconfirmed` | Engine API returned nil; dispatch result remains unknown |

Counters are published every 900 frames. Manager ticks without queued orders,
combined with waiting reasons, separate resource/site/menu/roster waiting from a
missing update loop. Successful packet submission alone is never logged as a
completed game action.

## Verification and remaining acceptance

Run with Lua 5.1 (or `lupa.lua51`):

```
lua tests/prometheus_startup_test.lua
lua tests/prometheus_orders_test.lua
lua tests/prometheus_betrayal_test.lua
lua tests/civic_objectives_test.lua
lua tests/objective_income_test.lua
lua tests/objective_security_test.lua
```

`prometheus_orders_test.lua` loads real main/team/strategy/bridge code, actual
unit menus/costs and faction morph definitions. Only engine APIs and their
normalized UnitDef representation are simulated. Selected production units must
have actual definitions, not placeholder costs. Scenarios verify both-faction
construction/recruitment/morph dispatch, scouting, raids, LOS privacy, retreat,
resource and missing-menu waiting, bounded logs, two separate three-unit attacks,
stalled production recovery, public objective restoration, full roster limits,
engine rejection, ownership races and high-ID/large-coordinate serialization.
These tests do not simulate navigation, attachment, weapons or raid outcomes.

No Recoil executable is available in the implementation environment. Required
skirmish acceptance for each faction, with a human opponent and normal resources:

1. Inspect infolog: faction resolves once, manager ticks rise and the synced bridge
   reports dispatched orders rather than only successful initialization.
2. Inspect actual unit queues: starting operative builds a legal house-attached
   safehouse; another hub converts to propaganda while recruitment continues.
   Observe attachment survival, sufficient resources and later assembly creation.
3. Observe at least two separated scouts, exposed-network raids and objective
   pressure. Verify attacks cause actual weapon/raid effects, and operators finish
   raids instead of repeatedly resetting them.
4. Damage a squad and attack a hub; observe retreat and defensive response. Kill
   builders and a server; check replacement, stalled-site recovery and no queue
   spam. Try an initially delayed city/operative spawn and a midgame gadget reload.
5. Test fog-of-war, spectator-host and multiplayer command authority. Verify no
   hidden enemy targeting, ownership-race commands or runner interference.
6. Play 15–20 minutes against easy/medium and hard, record outcomes, active
   economy/operations, unit losses and frame time. Confirm the role caps prevent a
   massed attack and evaluate challenge through distributed pressure. Difficulty
   tuning and a claim of competitive strength require these gameplay results.

Advanced orbital interception, launcher/warhead logistics, discretionary bribery,
vehicle theft and active sniper placement are not added to this controller. They
remain future strategic extensions, rather than commands issued without a tested
legal path.
