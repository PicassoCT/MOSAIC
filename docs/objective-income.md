# Objective income balance

Objectives pay money for holding the currently rewarded state: the live
building or its destroyed marker. Destroying and restoring them changes the
benefiting faction. This does not introduce a separate ownership capture command.

## Strategy benchmark and map budget

The baseline is a **three-server economy**, used as an initial configurable
estimate of medium success. This is a balancing assumption, not a measured
match statistic. A completed propaganda server produces 5 money and 10 supply
per second from its UnitDef, plus the script's network bonus: each server adds
one of each resource per second for every server on its team.

For N completed servers on one team:

- Money per second: `N * (5 + N)`.
- Supply per second: `N * (10 + N)`.

Three servers therefore produce **1,440 money and 2,340 supply per minute**.
The entire map's objective budget is **50% of the reference strategy's money
income: 720 money per minute, with no supply**. Capturing every site together
is worth half the money from that strategy. Fewer controlled sites yield a
fraction of that pool. More objective sites cannot increase the pool.

| Objective sites on map | Money/minute per site, at equal risk | Whole-map maximum |
|---|---:|---:|
| 2 | 360 | 720 |
| 4 | 180 | 720 |
| 8 | 90 | 720 |
| 16 | 45 | 720 |

Unequal risk redistributes these amounts. It does not create additional money.
The budget is divided among all objective sites, regardless of which faction
benefits. Each site's earnings are then split equally among living teams of
its benefiting faction, rather than multiplied by team count. An intact
building, its destroyed marker, and its pending replacement are the same site.
A pending replacement retains its weight but earns nothing while absent.

Configuration is in `getGameConfig().Objectives.Income` in
`scripts/lib_mosaic.lua`: `ReferenceServerCount`, `ServerNetworkBonus`, and
`StrategyIncomeFraction`. The server's base money rate is read from its
UnitDef. If the server script's network formula changes, update the reference
bonus formula too. Adjust the reference count after collecting representative
match data; this implementation does not dynamically follow players' current
server counts.

## Risk calculation

Each site receives `map budget * site weight / sum of all site weights`.
The default weight is `1 + exposure + attack pressure` (range 1 to 3).

Exposure is the distance to the nearest friendly starting position divided by
the sum of distances to the nearest friendly and opposing starting positions.
It ranges from zero near home to one deep forward. These fixed starts are a
geographic approximation, not a reading of current hidden bases or troops.
If usable starts are unavailable, public map centrality is used.

Only real HP damage from a non-allied team of the opposing faction adds attack
pressure. Twenty percent of the target's maximum HP fills the pressure meter.
It is capped at one and decays linearly to zero in 30 seconds from full.
Small isolated hits fade sooner; ongoing enemy damage sustains the weight.
Paralysis, friendly fire, Gaia/environmental damage and invalid damage do not
add pressure. There are no proximity scans or queries of cloaked units.

For example, two quiet sites with weights 1 and 2 earn 240 and 480 money/minute.
Full pressure on the forward site changes the weights to 1 and 3 and the
instantaneous rates to 180 and 540 money/minute. The sum remains 720.

Money accrues in simulation time and settles every ten seconds. The normalized
shares are integrated over pressure decay, so a last-second hit cannot award
an entire interval of extra income. Destruction settles the old state's actual
holding time; the new state starts with no accumulated money or pressure.
Rapid destruction/restoration cannot manufacture full-tick capture payouts.

## Restoration

Destroying a live objective spawns the existing 15,000-HP destroyed-objective
marker and flips the benefiting faction. Destroying that marker queues the
original building to return fully built and flips the faction back. There is
no builder, resource cost, or timed construction phase. The marker's existing
animation is decorative, not tied to progress. Restores retry once per second
and retain the original building's orientation and site identity.

## Implementation and verification

- Rate and accrual calculations: `luarules/gadgets/include/objective_income.lua`.
- Registration, damage events and settlement: `luarules/gadgets/game_objective.lua`.
- The public `objective_income` UnitRulesParam reports current money/second
  for the site before sharing among teams, refreshed at settlement.
- Money goes through the current `GG.Bank` queue; no stale bank is retained.
- Map-controlled initialization stops waiting when placement completes.
- Tracked states and accrual clocks persist across gadget code reinitialization
  while the shared GG tables remain available.

Tests cover budget conservation across objective counts and varying pressure,
payout cadence, late hits, friendly fire, team sharing, dead teams, missing
starts, changed server income/frame rate, bank replacement, restoration retries
and stable site identity. Run `tests/objective_income_test.lua` and
`tests/civic_objectives_test.lua` with Lua 5.1. The collateral regression also
passes. An in-game economy/playability pass remains necessary before treating
these figures as final competitive balance.
