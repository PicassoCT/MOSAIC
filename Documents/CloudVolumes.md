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
- Pump station: its existing ribbon starts once on the steady Igniter piece in Create and stops only on death. Old flame-out/reignition cycles no longer toggle it. The preset's colors, size, wind and speed remain unchanged. Its Smoke*/SmokeStem, Explosion*/ExplosionStem, Flame*/Flames*, FireRotor* and Igniter meshes are now replaced by volumes while retaining their piece animations. Smoke uses a dark non-emissive soot preset; explosion puffs and flame tongues are luminous.

Spaceport radiance visibility registration is retained independently of hiding its old geometry. New explosion volumes are self-illuminated but do not themselves inject new light into the radiance cascade.

The payload integration also fixes pre-existing undefined crater size/function names, reversed decal creation arguments, a nil attacker lookup, and an invalid projectile-visibility call. A one-shot guard prevents multiple detonations through repeated hits.

## API (synced)

```lua
GG.CloudVolume.SetPiece(unitID, pieceID_or_name, 'fire') -- true on registration
GG.CloudVolume.RemovePiece(unitID, pieceID)
GG.CloudVolume.Burst('impact', x, y, z, 1) -- scale; independent of source lifetime
```

Piece presets: `steam`, `soot`, `fire`, `plume`, `ring`. Burst presets: `impact`, `nuclear`, `bio`, `electric`. Settings live in `cloud_volume_config.lua`. Repeated SetPiece calls with the same preset do not restart the animation. Empty geometry and invalid inputs are rejected. Unit death removes attached effects; timed bursts expire separately. Synced records support unsynced reloads, with at most 256 burst records.

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

Select the affected unit and enter `/cloudvolumes`. This reports shader initialization, the synced registry, matching piece names, active registrations, and up to six precise bounds rejection reasons. It remains available if GPU initialization fails. Also search infolog.txt for `Cloud piece fallback` or `Cloud volumes disabled`.

Commit `4b351f4b` contains the first spaceport implementation but predates pump integration `174f9f94`; merge the updated `gfx/cloud-volumes` branch before testing the pump. Missing pump integration explains solid pump meshes on that revision, but does not explain the spaceport's visible legacy meshes. Runtime status/logs are required to distinguish registration rejection from a missing/disabled gadget or another visibility writer.
