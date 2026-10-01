# Game configuration

`getGameConfig()` in `scripts/lib_mosaic.lua` returns the complete core
configuration as a fresh plain Lua table. `GG.GameConfig` and `_G.GameConfig`
keep their existing initialization behaviour. Population targets still use
`GG.unitFactor`, culture still comes from the existing selection function, and
version still comes from `GameVersion`.

There are no aliases, proxies, fallback paths, or compatibility modes for the
old flat configuration. Mosaic's production consumers and test fixtures use
the new schema. External map code that reads the game configuration must use
these paths too.

| Section | Contents |
|---|---|
| `game` | Culture, version, day length, phase timers and state names |
| `city` | Population targets, building dimensions, roads, alleys and rubble |
| `civilians` | Activity, traffic, movement, curiosity, panic and conversation |
| `police` | Officer limit, dispatch, pursuit, checkpoints, tear gas and riots |
| `economy` | Starting resources, storage, propaganda, collateral and shared rewards |
| `objectives` | Settlement interval and the shared income/risk budget |
| `espionage` | Assets, operatives, recruitment, safehouses, raids, interrogation, cybercrime, bribery, hacking and hiveminds |
| `military` | Combat, interception, aircraft, missiles, launchers, payloads, satellites, warheads and aerosols |
| `presentation` | Audio, particles and icon offsets |
| `performance` | Civilian work batches, animation caps and city-generation limits |

For example:

```lua
local config = getGameConfig()
local startingMoney = config.economy.starting.money
local startingSupply = config.economy.starting.supply
local panicRadius = config.civilians.panic.radius
local dispatchFrames = config.police.dispatch.durationFrames
local investigationFrames = config.espionage.interrogation.durationFrames
local objectiveBenchmark = config.objectives.income.referenceServerCount
```

The costs, ranges and timers of an ability live together. Cybercrime's reward
and duration are in `espionage.cybercrime`; the objective budget is in
`objectives.income`. `economy` contains the shared economic rules. The dedicated
collateral-collection, betrayal, counterintelligence and other system files in
`luarules/configs` continue to own their separate settings; this refactor does
not duplicate their data or move their include APIs.

## Naming and units

- Tables and keys use lowerCamelCase.
- Durations explicitly end in `Frames`, `Ms`, or `Seconds`.
- `Chance` means 0–1, `Percent` means 0–100, and `OneIn` means inverse odds.
- `Range`, `Radius`, dimensions and offsets use engine world units.
- Gameplay currency is money/supply. Calls to Spring still use its metal/energy
  resource identifiers.
- State values remain their existing strings, even where the key now uses
  camel case, for example `game.states.launchLeak == "launchleak"`.

## Preserved behaviour and cleanup

The refactor preserves the prior values, including the three-server objective
benchmark and the police dispatch duration of 2,000 simulation frames.
Duplicate civilian fields are consolidated. Unused old cybercrime rewards,
redundant interrogation-seconds and bribe-milliseconds constants are removed;
active durations remain in frames. Generic minute/hour/second constants are
removed, and the scrap-heap script's minute sleeps remain `60 * 1000` ms.

Rubble previously used the same numeric setting as milliseconds for standalone
sinking and as frames for city respawn. The configuration now makes those
separate clocks explicit: `city.rubble.disappearanceTimeMs = 300000` and
`city.rubble.respawnBaseDelayFrames = 300000`. This preserves both effective
delays; it deliberately does not turn the existing respawn behaviour into a
five-minute timer.

The satellite hijack script's misspelled lookup now reads the actual
`espionage.satelliteHijack.durationMs` setting (15 seconds).

## Verification

Run from the repository root:

```
lua5.1 tests/game_config_test.lua
python tests/game_config_references_test.py
```

The value contract checks 209 canonical settings across 20 population-factor
and culture combinations, prohibits legacy roots and metatables, and checks
that each call creates independent tables. The reference audit checks static
configuration paths throughout all tracked production Lua files, including
local subsection handles and dynamic aerosol settings.

Gameplay regressions cover objectives, cybercrime, police/bribery, collateral,
counterintelligence, betrayal, aerosols, prayer, military scripts, sticky bombs
and aircraft. The older city-arcology, aerosol-ribbon lifecycle and sniper-bird
tests also fail on the unchanged parent revision due to outdated mocks/runtime
assumptions. No in-engine multiplayer playtest has been run for this refactor.
