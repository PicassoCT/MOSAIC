# Procedural cloud volumes

Branch: `gfx/cloud-volumes`, based on `gfx/procedural-smoke-ribbons`.

This is a standalone GLSL 150 compatibility renderer, not the Recoil model shader framework. The shaders live in `luarules/gadgets/shaders/cloudVolume.vert` and `.frag`.

## How it draws beyond the old surface

The old mesh is hidden. Its local bounding box is expanded by 20%, with a minimum thickness for flat pieces. A screen quad restricted to the projected box covers the effect. Each pixel unprojects a view ray into the animated piece's local coordinates, intersects the box, and integrates procedural density through it. Empty regions become transparent. This is a small bounded ray march, not a particle/fluid simulation or merely a texture applied to the old polygon surface.

Piece transforms include the unit and ancestor piece matrices; group Show/Hide helpers share the same lifecycle. Camera translation uses the same draw-position correction as the ribbons. Piece rotations still follow the engine's available piece matrix. The longest local dimension determines the exhaust axis; the thinnest determines a gas ring's axis. Nozzle orientation is inferred from the local bounds relative to the pivot and may need a preset adjustment for unusual models.

Three noise evaluations per sample provide density and approximate directional shading. This is not physically accurate multiple scattering. Fire cools to smoke; alpha and premultiplied RGB fade together. A copied scene depth texture clips the march at opaque geometry and softens intersections. Both traditional and zero-to-one clip depth, orthographic cameras, negative scale, and a camera inside the cloud are supported. Transparent surfaces which do not write depth cannot occlude it correctly. Intersecting separate volumes use approximate back-to-front ordering, not a unified density field.

## Integrations

- Spaceport: GroundGases, LaunchCone, LandCone*, GroundHeatedGasRing*, CrawlerBoosterGasRing*, CrawlerBoosterRing*, CrawlerSmokeRing*, ArenaSmoke, SmokeBubble*, FireFlower*, RocketPlume*/A*/B*, RocketThrustPillar*, ReturningBooster*ThrusterPlum*, RocketFusionPlume. Structural pieces and turbine meshes stay ordinary models. The existing launch ribbon remains alongside the replacement volumes. The repeated landing-pad light CEG is removed.
- Godrod: the impact helper registers a 16-second world-space cloud, plays its original sounds, and removes itself after 3.5 seconds. No impact CEG/shockwave particle loop. The weapon's redundant impact CEG is explicitly empty; its flight trail is unchanged.
- Physics warhead: 32-second expanding fireball, rising cap/stalk and ground dust, cooling to smoke. Replaces the mushroom, nuclear burst and ash CEGs.
- Bio/information warheads: finite greenish aerosol / blue emissive volumes replace their payload-specific CEG calls on affected units. Infection, stun and kill logic remain intact.
- Pump station: its existing ribbon starts once on the steady Igniter piece in Create and stops only on death. Old flame-out/reignition cycles no longer toggle it. The preset's colors, size, wind and speed remain unchanged. Its Smoke*/SmokeStem, Explosion*/ExplosionStem, Flame*/Flames*, FireRotor* and Igniter meshes are now replaced by volumes while retaining their piece animations. Rising smoke starts with emissive orange pockets and cools into dark soot; explosion puffs and flame tongues are luminous.

Spaceport radiance visibility registration is retained independently of hiding its old geometry. New explosion volumes are self-illuminated but do not themselves inject new light into the radiance cascade.

The payload integration also fixes pre-existing undefined crater size/function names, reversed decal creation arguments, a nil attacker lookup, and an invalid projectile-visibility call. A one-shot guard prevents multiple detonations through repeated hits.

## API (synced)

```lua
GG.CloudVolume.SetPiece(unitID, pieceID_or_name, 'fire') -- true on registration
GG.CloudVolume.RemovePiece(unitID, pieceID)
GG.CloudVolume.Burst('impact', x, y, z, 1) -- scale; independent of source lifetime
```

Piece presets include `steam`, `soot`, `fire`, `plume`, `ring` and spaceport-specific `launchVapour`, `launchGas`, `launchRing`. Burst presets: `impact`, `nuclear`, `bio`, `electric`. Settings live in `cloud_volume_config.lua`. Repeated SetPiece calls with the same preset do not restart the animation. Empty geometry and invalid inputs are rejected. Unit death removes attached effects; timed bursts expire separately. Synced records support unsynced reloads, with at most 256 burst records.

## Cost and limits

- Up to 24 visible volumes, prioritizing nearby effects.
- Usually 12 samples at distance, 24 close up; reduces to 8 under load.
- Aggregate ray samples capped at 64 times the viewport pixel count each draw. Further effects are skipped if that budget is exhausted. Dense overlapping launch/explosion scenes can therefore lose some secondary clouds.
- Distance cutoff scales with volume size (40 times its bounding radius, allowing for an offset pivot), with a fade over the final 20%.
- LOS, cloaking, icon, transporter, no-draw and frustum filtering for attached effects. Bursts require positional LOS or spectator full view.
- One scene-depth copy per active draw; none if every effect is culled. Texture reused until viewport resize.
- No CEG fallback for explosions. Piece meshes fall back to their ordinary rendering if the synced API cannot register them, with a one-time `Cloud piece fallback` log message per piece. A GPU shader failure is logged; it does not restore CEGs or mesh rendering on that client.

These limits bound work; they are not a measured FPS guarantee. The earlier AI mockup is an appearance concept, not a screenshot of this shader. Actual shader images are softer and less detailed. Engine placement, transparent-surface ordering and GPU performance need an in-game check.

## Validation

From repository root, run the Lua 5.1 suites `tests/cloud_volumes_lifecycle.lua`, `tests/cloud_volumes_renderer.lua`, and `tests/cloud_payloads.lua`, and `tests/cloud_pump_pieces.lua`. They exercise lifecycle, source destruction, visibility/radiance wrappers, budgets, resource cleanup, pump startup/death, and actual payload/impact entrypoints with mocked engine services.

```sh
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/cloud_volumes_gpu.py
# Optional actual GLSL contact sheet:
MESA_GL_VERSION_OVERRIDE=3.3COMPAT python tests/cloud_volumes_gpu.py --preview /tmp/cloud-volumes.png
```

GPU tests require moderngl and numpy, plus Pillow for the optional image. They compile the production shader and check opacity, emission, cooling, turbulence, foreground occlusion and camera/depth conventions. Tested headlessly with Mesa llvmpipe; no in-game runtime is available here.

## Diagnose unchanged solid pieces

Select the affected unit and enter `/luarules cloudvolumes`. This reports shader initialization, the synced registry, matching piece names, active registrations, and up to six precise bounds rejection reasons. It remains available if GPU initialization fails. Also search infolog.txt for `Cloud piece fallback` or `Cloud volumes disabled`.

Commit `4b351f4b` contains the first spaceport implementation but predates pump integration `174f9f94`; merge the updated `gfx/cloud-volumes` branch before testing the pump. Missing pump integration explains solid pump meshes on that revision, but does not explain the spaceport's visible legacy meshes. Runtime status/logs are required to distinguish registration rejection from a missing/disabled gadget or another visibility writer.

## Per-effect time curves

Presets accept `opacityCurve`, `densityCurve`, `emissionCurve`, and
`expansionCurve`. Each is a sorted array of `{seconds, multiplier}` keys,
measured from the first Show/Burst. Interpolation uses smoothstep; values hold
before the first and after the last key. Missing curves default to 1. Opacity
multiplies both premultiplied RGB and alpha, so zero opacity leaves no glow.
Density changes optical thickness independently; emission changes glow without
changing alpha. Expansion also updates culling bounds. Curves run once per
candidate on the CPU and add no ray-march samples.

```lua
opacityCurve = {{0,0}, {.12,.9}, {.7,.8}, {2,.45}, {4,0}},
emissionCurve = {{0,.8}, {.2,1.3}, {.8,1}, {1.8,.55}, {3,0}},
```

- Pump Smoke*/SmokeStem: `risingSmoke` with hot orange pockets cooling over
  12 seconds, slow expansion, 28-second
  visibility envelope. Explosion*/ExplosionStem: four-second gas bloom whose
  glow dies by three seconds. Flame*/Flames*: fast onset, held while animated.
  Igniter and FireRotor retain continuous fire; the steady pump ribbon remains on.
- Launch vapour: ArenaSmoke, SmokeBubble* and RocketPlumeB* use `launchVapour`:
  pale non-emissive steam, density 8.5, near-opaque from 1.2–18 seconds, with
  a gradual fade to zero at 70 seconds. Expansion reaches 1.5 times the original
  proxy dimensions at 14 seconds, spreading the cloud across the launch building.
  The integrated alpha is multiplied by the opacity curve: increasing density
  alone would still leave the ordinary steam profile's 65% opacity ceiling.
  GroundHeatedGasRing* uses dense `launchRing`, fading over 32 seconds and
  losing its glow by three seconds. GroundGases/FireFlower use dense `launchGas`
  with the original four-second explosion/cooling timing. Exhaust stays fed;
  booster landing rings and pump effects retain their existing profiles.
- Godrod/nuclear: independently configured expansion, opacity and fast emission
  decay within their existing 16/32-second durations. Bio/electric retain their
  existing durations with finite fades.
- Industrial complex: independent upward ribbons follow the selected CoolDown
  slagheap and Pot2 of the slag crane. The latter also responds to unit motion;
  both respond to wind. The molten-pot ribbon remains separate.

`GG.CloudVolume.ReleasePiece(id,piece)` detaches profiles marked `linger=true`
(steam/launchVapour/soot/risingSmoke), preserving their original age and freezing an enclosing world-space
box before piece reset. Other profiles are removed immediately. Show/Hide
wrappers use this automatically. `RemovePiece` remains immediate for shutdown.
Released smoke survives source removal and expires at the original lifetime;
repeated Hide does not duplicate it. Its world-aligned box can change the shape
of strongly rotated or elongated smoke proxies slightly. It does not yet advect
with wind. Continuous effects hold their final curve value; finite attached
curves stay registered but incur no drawing after opacity reaches zero, until
Hide removes them. Repeated Show does not restart their clock.

Validation additions: `tests/cloud_volume_curves.lua` and
`tests/cloud_volume_release.lua` cover curve interpolation, relative lifetimes,
cooling, detached bounds/age, idempotency and expiry. Renderer tests cover the
curve uniforms and zero-opacity culling. Runtime appearance and placement still
need an in-game check; these changes do not establish the cause of the earlier
solid-mesh rendering report.

The diagnostic is registered with Mosaic's chat-action dispatcher and forwarded
to the requesting player's unsynced renderer. It does not require cheats.
`TextCommand` is not dispatched by this project's gadget handler. Startup now
logs synced API and renderer status. Each cloud-enabled objective also logs its
matching piece count and its first successful registration/mesh hiding, so an
infolog from a fresh game is useful without any manual diagnostic command.

## Header-local visibility fix

`unit_script.lua` prepends `gamedata/unit_script_header.lua` to both owning
scripts and included libraries. That header localizes Show/Hide. Replacing only
the global functions therefore left original effect meshes visible. Pump station
and spaceport now opt in via `customparams.cloud_piece_volumes = 1`; their header
resolves per-unit cloud visibility hooks at call time. The hooks call engine
primitives directly to avoid recursion. Other unit types keep direct primitives.

`tests/cloud_piece_header.lua` runs the real header and included group/radiance
helpers with cached include chunks in two unit environments. The original header
fails this test; the fixed header routes direct and grouped visibility through
registration, hides original geometry, preserves structures and lights, and
removes registrations on Hide/death. This verifies the integration bug, not
in-game shader appearance or performance.


## Flare brightness and aerosol identification

`emission` lights the dense hot knots; optional `glow` adds `hotColor * glow`
throughout the participating gas. Both follow `emissionCurve`. Glow defaults to
zero and adds no noise samples or ray-march steps. It changes RGB only; the
final opacity still multiplies RGB and alpha together. This is self-illumination,
not an injected scene light or a bloom pass.

Flame tongues use emission 6 and body glow 1.4, while the gas burst uses emission
7 and glow 1.6 with a longer luminous phase. Pump rising smoke uses emission 3.8
and a subtler .22 body glow, cooling completely by 12 seconds. The hot pockets
replace the visual role of emissive mesh textures procedurally; this does not
sample or reproduce the original texture's UV pattern. Ordinary steam and soot
presets remain non-emissive.

Aerosol drones now use `scripts/lib_aerosol_effects.lua` from their existing
100 ms spray worker. A 120-unit downward ribbon with width 42, emission 3 to 1.6,
wind response and motion trailing shows the nozzle spray. Every .8 seconds it
leaves a world-space puff with a 150-unit radius / 120-unit height proxy and
six-second expansion/fade. At most eight live puffs per continuously spraying
drone feed the existing global registry and draw/sample budgets. Visible density
occupies the soft interior of the proxy; these are visual dimensions, not an
exact depiction of the unchanged 250-unit gameplay spray radius.

| Aerosol | Identification colour |
| --- | --- |
| Depressol | Blue |
| Tollwutox | Red |
| Orgyanyl | Orange |
| Wanderlost | Green |

Aerosol body glow is 2.2 and holds its colour through dispersal. Puffs are
anchored below the nozzle at emission time and remain behind a moving drone;
they do not yet advect with wind. The attached ribbon bends with wind and
movement. Landing or tank exhaustion stops new emission, death also blocks
restart, and already released gas finishes its fade. Flight-driven spraying,
tank consumption, civilian effects and their range are unchanged. The legacy
spray CEG call and the drone's CEG declarations are removed.

`tests/aerosol_effects.lua` runs the actual drone worker and registration APIs for
all four types, checking cadence, palette, trailing positions, bounded puffs,
landing, death and expiry. `tests/cloud_volumes_gpu.py` reads production presets
through Lua 5.1 (`lupa`), renders their night appearance, and checks identifying
hues, glow without extra opacity, cooling and zero-opacity output. Its optional
preview now shows the four aerosols, flame tongue, burst, hot smoke and cooled
smoke. Neither test is a live-engine or target-hardware performance check.

## Pumpstation smoke wind deformation

Only `risingSmoke` opts into `windDeform` (currently .38). The renderer reads
Spring's world wind once per draw and scales the response against `Game.windMax`.
The volume shader bends the density downwind more strongly toward the upper
cloud, rolls its boundary along the radial normal, and carries its internal
noise upward/downwind. The lower end stays anchored. The same preset also
deforms released smoke while its existing expansion, cooling and fade continue.
This is bounded shape motion, not unlimited transport of the cloud centre.

Wind and world-up are transformed through the camera and animated piece matrices;
rotating, mirrored and stretched pieces retain the world wind direction. The
proxy and culling bound expand together, while density coordinates and optical
path length compensate for the padding. The existing draw/ray-sample budgets
still apply, and no extra noise samples or ray-march steps are added.

`gasExplosion`, launch bursts, impact/nuclear explosions, flames, spaceport vapour
and all other presets keep wind deformation disabled. They retain their own
expansion and motion. The renderer regression test verifies this isolation;
the GPU test checks wind direction under piece transforms, animation, padding,
foreground depth and opacity. Live pumpstation appearance still needs an
in-game check.
