# Manual validation in infolog

The enabled **MOSAIC validation checklist** widget prints an ordered TODO list
once at match startup on each client. Each row contains a command and the
observable result to check. The same checklist supplies on-demand help, so
startup reminders and testing instructions stay together in
`luaui/configs/mosaic_validation.lua`.

## Commands

| Command | Result |
| --- | --- |
| `/validate` | Repeat the short TODO list. |
| `/validate help` or `/validate list` | Repeat the short TODO list. |
| `/validate parachute` | Test the first operative's attached parachute and repeat its electrical ribbon material locally. |
| `/validate tank` | Check both tank variants' firing stamp, outward muzzle flame and radiance. |
| `/validate lights` | Check police lightbar placement, ordinary player visibility, scene illumination and wall blocking. |
| `/validate shadows` | Compare height-aware car/pedestrian shadows on and off, elevated receivers, caster visibility and budget statistics. |
| `/validate houses` | Check block support, accumulated damage and existing fire continuity across subsequent hits. |
| `/validate rebuild` | Check rubble blocking, peaceful decay/construction, safehouse exclusion and retained addresses. |
| `/validate roads` | Compare zoom transitions, road curves, labels, house numbers and sectors. |
| `/validate launch` | Check a launched ICBM, a cruise-missile pod and a godrod strike for the requested trails. |
| `/validate status` | Log renderer readiness, tank source counters, road metadata and state of the first selected unit. |
| `/validate all` | Print all detailed procedures. |

Numbers in the startup list also work, for example `/validate 2`. The aliases
`police`/`radiance`, `damage`/`fire`, and `godrod`/`cruise`/`launcher` resolve to
their respective checklist entries. Commands are case-insensitive. Unknown
validation tasks print help; unrelated commands are left for their own handler.

The explicit LuaUI form, such as `/luaui validate tank`, also works. Bare
`/validate` is supported by BAR105's command path: `ProcessCommandText` strips
the leading slash, `ProcessAction` sends an unhandled action to LuaUI's
`GotChatMsg`, and `GotChatMsg` falls back to `ConfigureLayout`. MOSAIC's
`ConfigureLayout` dispatches to widget `TextCommand` handlers. This was checked
against Recoil [Game.cpp at 058c8ea](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Game/Game.cpp)
and [LuaHandle.cpp at 058c8ea](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaHandle.cpp),
and the test executes MOSAIC's actual `ConfigureLayout` function.

## Parachute reproduction

The first operative's arrival in a fresh match exercises the complete attached
parachute. `giveParachutToUnit` registers a passenger and drop position; the
parachute script waits for that registration before enabling its ribbons.
`/give air_parachut` alone does not perform this step and is not a complete test.

For a repeatable check of the electrical material, select an uncloaked operative,
zoom in and enter:

```text
/luarules smokeribbon center electric
/luarules smokeribbon status
/luarules smokeribbon off
```

The preview shares the live graphene electrical profile and shader. A preview
on an operative tests that profile; the actual first-operative drop additionally
checks all canopy-tip attachments and the descent. The `/luarules` prefix is
needed for this gadget command; its chat action is forwarded to the requesting
client's unsynced renderer.

## Moving shadow comparison

The height-aware mobile shadow path is enabled by default and operates near the
camera; strategic zoom retains ordinary global lighting. `/validate shadows`
prints the existing commands for comparison and diagnostics:

```text
/radiancelight shadows stats
/radiancelight shadows off
/radiancelight shadows on
```

At the same close camera, compare cars and pedestrians crossing low and elevated
lights. A ray passing above a low blocker should still reach a higher wall or
roof. Fire a tank beside another unit and observe police rooftop lights;
ordinary scene lighting must survive either shadow mode. Repeat after a caster
leaves, becomes hidden/transported, or is destroyed.

The statistics report enabled/off mode, casters out of 128, over-budget entries,
grid overflow, occupied cells and caster height range. An unavailable component
reports its initialization or runtime failure reason. These counts describe
the shadow component; visual comparison still determines the result. See
[mobile radiance shadows](mobile-radiance-shadows.md) for the implementation
bounds and fallback behavior. `/radiancelight test on` supplies full daytime
lighting for comparison; restore it with `/radiancelight test off` afterward.

## Status and interpretation

`/validate status` reads `WG.lighteffects.getStatus()`, then reports the cascade
field and capture/occupancy provider presence. It does not render a test frame.
Tank counters distinguish tracked units, visible units, active firing windows,
queued sources, missing anchors and the latest observed shot frame/age. A
missing widget, failed status accessor or unlinked renderer is reported as
unavailable. `/effects status` (also `/luaui effects status`) is the dedicated
combat diagnostic.

`/validate status` also points to `/radiancelight shadows stats` for the mobile
caster counts and failure reason. It does not execute that command or infer
mobile-shadow success from the ordinary occupancy provider.

For the first selected unit, the helper reports health/build progress and any
available tank-shot, structural, construction or address rules parameters.
It does not inspect other units. A stale/unavailable selection stops those
unit reads. It also reports the published road revision/chunk count and whether
the orientation widget has published its API.

These are diagnostic observations. They do not mark tasks complete or claim
that a light, shadow, flame or address was visually correct. Requested missile
trails remain pending if the tested build does not yet provide them. Record
screenshots and the status output from the same match when a visual check fails.

## Once per match and cost

`game_validation_session.lua` captures Recoil's `GameID` event. The engine
already encodes its 16-byte identifier into 32 hexadecimal characters. The
bridge accepts that form, lowercases it and publishes a public
`mosaic_validation_game_id` string with an `engine:` prefix. It never publishes
raw bytes. String game rules parameters are supported by
[LuaSyncedCtrl.cpp at 058c8ea](https://github.com/beyond-all-reason/RecoilEngine/blob/058c8ea/rts/Lua/LuaSyncedCtrl.cpp).

The widget stores the last automatically printed match ID in ordinary widget
configuration. MOSAIC's handler saves `GetConfigData` before LuaUI shutdown and
loads `SetConfigData` before widget initialization, so `/luaui reload` does not
repeat the reminder. A different match ID prints a fresh list even on the same
map. A frame-zero initialization can precede identity delivery; `GameStart`
handles that normal ordering without polling. The explicit `/validate` command
can always repeat the instructions.

If the identity bridge is absent or the engine fails to deliver a valid ID, the
widget prints at game start once for that LuaUI session and explains the
limited deduplication. It does not persist a generic flag that would suppress
future matches.

There are no `Update`, `GameFrame`, drawing or all-unit scanning callbacks in
the checklist or identity bridge. The only synced write is match identity
metadata. Startup and `/validate` never enable cheats, issue orders, spawn
units, change resources, alter weather or toggle renderers. Procedures print
the existing commands for the user to run explicitly; spawning instructions
are scoped to a test match.

## Regression check

Run from the repository root with Lua 5.1:

```sh
lua5.1 tests/validation_widget.lua
```

The regression uses the real `luaui/system.lua` global layout with no `_G`,
the actual gadget `GameID` and widget `ConfigureLayout` dispatchers, delayed
startup identity, mid-match and frame-zero LuaUI reloads, another match on the
same map, every task command/alias, status with missing renderers and stale
selection, and traps for gameplay writes or unit scans. Live rendering and
performance remain in-game validation tasks.
