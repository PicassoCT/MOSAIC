# Initial city war ruins

An initial civilian plot contains either an intact house or `house_ruin`.
The unit type is selected before `Spring.CreateUnit`, so an intact house is
never created underneath the ruin. There is no initial destroy-and-recreate
step, no reconstruction event, and no intact house script or attachment to
clean up afterward.

In MOSAIC's setting, the perma wars and expanding bulb belt leave more damage
toward the equator. Latitude controls the probability of a ruined plot; these
are fictional world-generation settings.

## Central configuration and membership

`scripts/lib_mosaic.lua` owns `getCityRuinConfig()`, also available at
`getGameConfig().city.ruins`. The current defaults are:

| Field | Default | Meaning |
| --- | --- | --- |
| `equatorChance` | `0.45` | Ruin probability at latitude zero. |
| `polewardChance` | `0.02` | Probability at and beyond the poleward threshold. |
| `polewardLatitude` | `60` | Degrees from the equator where the decline stops. |
| `unknownLatitude` | `45` | Policy fallback for missing or invalid latitude. |
| `protectedMinimums` | `{house_asian1 = 3}` | Arcology plots protected from ruin conversion. |
| `ruinFootprintSize` | `130` | Full ruin footprint used for automatic placement clearance, in elmos. |
| `plotClearance` | `2` | Additional separation around that footprint, in elmos. |

The central helpers distinguish ordinary house spawn choices, civilian house
membership, eligible ruin-conversion candidates, and ruin membership:
`getCityHouseSpawnTypeTable`, `getCivilianHouseTypeTable`,
`getCityRuinCandidateTypeTable`, and `getCityRuinTypeTable`.
The ordinary house lottery excludes ruins and additional model variants;
general house gameplay membership retains both. Consumers use these sets
instead of repeating building names in spawning code.

`scripts/lib_city_ruins.lua` applies the linear latitude rule:

```text
chance = 0.45 + (0.02 - 0.45) * min(abs(latitude) / 60, 1)
```

| Latitude, north or south | Ruin probability |
| --- | ---: |
| 0 degrees | 45% |
| 25.2 degrees, Dubai's configured latitude | 26.94% |
| 30 degrees | 23.5% |
| 45 degrees | 12.75% |
| 60–90 degrees | 2% |

The roll is deterministic for a map hash and full plot coordinates, quantized
to 1/16 elmo. It does not consume the shared random-number sequence. Moving
the same plots closer to the equator adds eligible ruins to the selection.
This is a probability per eligible full plot, not an exact city-wide quota:
finite samples, protected arcologies, explicitly authored ruins, fillers, and
placement failures affect the final fraction of visible buildings.

## City location and metadata

`getCityGeography(Game)` reads optional `mosaic/location.lua` from the map
archive through `VFS.MAP`, once per Lua environment. A map can declare:

```lua
-- mosaic/location.lua, inside the map archive
return {
    country = "United Arab Emirates",
    region = "MiddleEast", -- optional recognized region name
    latitude = 25.2,
}
```

`scripts/lib_city_geography.lua` resolves latitude in this order:

1. A valid explicit `latitude`: a finite number or numeric string in
   `[-90, 90]`. Zero and southern negative values are valid.
2. The known LastDayOfDubai/LastDayOfDhubai map location at `25.2` degrees,
   provided an explicit country has not relocated that map elsewhere.
3. The selected country's approximate representative latitude.
4. A documented `45`-degree fallback for fictional entities without an
   established location or for unrecognized custom countries.

Invalid latitude metadata falls through to the remaining choices. Explicit
country metadata takes precedence over the known map and procedural country
selection. For example, a country-only Finland override on Dubai terrain uses
Finland's fallback latitude; an absent country or compatible Dubai/UAE country
retains the known Dubai location. A recognized explicit region overrides the
region label. Providing both country and latitude is recommended for an
authored city.

Older maps retain the original location widget's map-name byte-sum hash,
region slots, and country choices. All 205 existing country and city-state
names remain available. Country fallbacks are approximate geographic inputs,
not exact coordinates for every procedurally named city. The neighborhood,
province, and city name catalogues are unchanged.

LuaUI and synced placement use the same resolver. The known Dubai maps retain
the existing Dhubay/Dubai, Capital City, and Trade center display. Custom
countries without a place-name catalogue show `Unspecified` for missing
province or city information. Client `LOCATION` messages and `GG.Location`
do not determine ruin selection. The city gadget publishes
`mosaic_city_country`, `mosaic_city_latitude`, and `mosaic_city_ruin_chance`
as public game rules parameters for inspection.

## Plot integrity and the paired map update

Automatic generation reserves its first three successful eligible full plots
for arcologies. The map placer protects its first three successfully created
authored arcology plots. Failed creates do not consume these reservations.
Explicitly authored ruins remain ruins, including when the probability is
zero. Other unit categories do not undergo civilian-house conversion.

Small automatic gap fillers remain intact buildings. Explicit ruins cannot
be replicated through the filler helper, and placement checks the actual
jittered coordinates against nearby ruin footprints before creating a unit.
The population spawner additionally checks shared mobile-civilian, house,
and scrapheap memberships at its creation boundary. A contaminated pedestrian
or truck pool therefore cannot create another building inside its origin
house.

The LuaGaia city placer in **MOSAIC_LastDayOfDubai must be updated alongside
the game**. It imports the game's pure helpers, chooses the plot occupant
before creation, and prevents duplicate civilian plots across its authored
unit and building lists. Its source data also removes the repeated arcology
at `(5910, 2181)`, preserving 199 distinct civilian plots and the three explicit
war ruins. Deliberately stacked non-house decoration and objectives remain
available. Older game versions retain the map's authored placement choices
when the new shared helpers are unavailable.

Updating only the automatic game generator does not apply this policy to an
older LuaGaia-authored Dubai map. Use a new match with both updated archives;
the fix does not remove already spawned overlaps from an existing match.

## Verification

From the game repository root:

```sh
lua5.1 tests/city_geography_test.lua
lua5.1 tests/city_ruin_generation_test.lua
lua5.1 tests/civilian_spawn_type_guard_test.lua
lua5.1 tests/culture_unit_type_membership.lua
```

These cover shared location/UI agreement, metadata validation, latitude
probabilities and repeatability, pre-creation plot selection, protected
minima, filler and jitter clearance, manual ruin registration, and rejection
of buildings in population spawn paths. Existing arcology, reconstruction,
blocking, and orbital-arrival tests cover adjacent behavior.

From the paired map repository root:

```sh
MOSAIC_GAME_ROOT=/path/to/MOSAIC lua tests/city_ruin_placement_test.lua
```

The map test exercises the actual LuaGaia gadget and, with that environment
variable, the game's real geography and ruin policy. Automated checks use
mocked engine calls. **Recoil runtime and visual validation have not been
performed for this change**; a new match with the paired archives is still
needed to confirm the rendered result.
