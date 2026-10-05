# Orbital arrival

Loading artwork fades into a low-orbit Earth limb after three seconds. The shader
lingers in orbit while loading and initial city placement finish. A 3.8-second
descent then expands an image of the real map through clouds. The existing
location widget draws the city, country, district and time above those clouds.

Every apparent movement is in screen space. The sequence never changes the
camera position, orientation, mode, field of view, simulation speed or pause state.
The Earth surface is a procedural cinematic regional coastline, not a geographical
atlas. It does not claim to locate the city accurately on a real globe.

## Handoff and readiness

LuaIntro and LuaUI share the renderer and GLSL programs. LuaIntro freezes its
chosen loading artwork, then records the last displayed age, fade and descent
in a runtime-only configuration overlay. LuaUI reads it on its first draw:
LuaUI initialization occurs while LuaIntro can still be rendering. No handoff
state is written to the player's configuration file.

The city gadget exposes a public `mosaic_city_spawn_complete` flag when either
generated or map-placed houses and their routes have been registered. This is
two one-time parameter writes, not per-unit streaming. The arrival waits for
this flag, with a 12-second client-side safety limit. House-script assembly can
continue after placement; this flag is not a promise that every animation is done.

At descent 0.42–0.55 clouds fully cover the screen. During this interval the
renderer switches from Earth to the live framebuffer. It captures only before
the interface is drawn, then reuses that clean texture in DrawScreenPost to
cover engine overlays. The expanding image plane's borders remain behind clouds.
The final frame samples the original live pixels at native scale and orientation.

## Interface and exits

The handler blocks interface drawing and intercepts input before widget actions,
selection, commands or camera bindings. World postprocessing continues for the
live capture. Scene effects outside the `gfx_` naming convention can declare
`arrivalWorldEffect = true` in GetInfo to participate.

The engine interface is temporarily hidden. Edge scrolling is temporarily
disabled using runtime-only settings. The tutorial waits to begin narration.
Escape skips the sequence and returns control immediately. Normal completion,
widget shutdown, shader failure and texture-allocation failure restore the UI
and edge settings; an interface hidden before arrival stays hidden.

Mid-match joins, saved games and LuaUI reloads during a running match bypass
arrival. Re-enabling the widget after a completed or skipped arrival does not
replay it. The timer uses wall time, so a paused simulation cannot trap the UI.
In a multiplayer start-position lobby, Escape can return to setup immediately;
the safety limit also bounds the pregame wait.

The procedural pass is capped at 960×540 and reused by both composites in a
frame. Resources are released when arrival finishes. GLSL requires the same
compatibility profile used by the existing MOSAIC postprocessing shaders.

## Validation

Run from the repository root:

```sh
lua5.1 tests/orbital_arrival.lua
python3 tests/orbital_arrival_gpu.py
```

The Lua suite covers the shared handoff, readiness and timeout, input routing,
skip/failure/reload cleanup, hidden-interface preservation, both Dubai/Dhubai
spellings and title resize. The GPU test uses NumPy and headless EGL/OpenGL on
Linux to compile the production shaders and verify the opaque handoff, finite
output, artwork continuity and unchanged final live pixels.

In Recoil, check slow and fast loads, both map spellings, pause, Escape,
window resizing, interface restoration and tutorial audio. Check city assembly
and frame timing on the 1050 Ti. These in-game and hardware checks remain pending.
