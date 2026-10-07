# Orbital arrival

Loading artwork may fade into a low-orbit Earth limb during LuaIntro, but
**no descent runs until the simulation frame counter becomes positive**.
At the first LuaUI screen draw with `Spring.GetGameFrame() > 0`, the
artwork/orbit blend begins (0.5 seconds), followed by five discrete zoom
steps of 0.5 seconds each (2.5 seconds of descent, 3 seconds total).
Each beat reveals finer terrain/cloud detail instead of stretching one
continuous zoom. Neither LuaIntro shutdown nor city spawn completion gates
the zoom. The original location widget resumes its city/region/district/time
telex after the cinematic releases the live map.

Every apparent movement is in screen space. The sequence never changes the
camera position, orientation, mode, field of view, simulation speed or pause state.
The orbital renderer keeps a fixed horizon orientation, adds a day/night terminator,
night-side settlement lights, water glint, elevated cloud layers and displaced
cloud shadows, plus atmospheric limb/twilight lighting.
The Earth surface is a procedural cinematic regional coastline, not a geographical
atlas. It does not claim to locate the city accurately on a real globe.

## Handoff and readiness

LuaIntro and LuaUI share the renderer and GLSL programs. LuaIntro freezes its
chosen loading artwork and records the last displayed age/fade in runtime-only
configuration state. LuaUI uses that artwork when available, but **does not wait**
for a LuaIntro phase or readiness flag. The first positive game frame starts
the presentation clock; wall time governs the half-second beats regardless of
simulation speed. This avoids the race where LuaUI initializes after frame 0.
First initialization during the opening 300 game frames remains eligible;
midgame joins and reloads are bypassed. A runtime-only `played` marker blocks
replays even during those first 300 frames. No handoff state is written to disk.

The city gadget still publishes `mosaic_city_spawn_complete`, but the arrival
does not consume it: the camera blends to whatever world is actually rendered
when the last step completes, so startup cannot wait indefinitely for generation.

At descent 0.42–0.55 clouds fully cover the screen. During this interval the
renderer switches from Earth to the live framebuffer. It captures only before
the interface is drawn, then reuses that clean texture in DrawScreenPost to
cover engine overlays. The expanding image plane's borders remain behind clouds.
The live framebuffer replay corrects CopyToTexture's vertical texture orientation
while preserving X, so the handoff cannot mirror or rotate the map. The final
frame samples the original live pixels at native scale and screen orientation.

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
the animation cannot begin until game frames advance.

The procedural pass is capped at 960×540 and reused by both composites in a
frame. Resources are released when arrival finishes. GLSL requires the same
compatibility profile used by the existing MOSAIC postprocessing shaders.

## Validation

Run from the repository root:

```sh
lua5.1 tests/orbital_arrival.lua
python3 tests/orbital_arrival_gpu.py
```

The Lua suite covers game-frame triggering, half-second blend and steps,
late widget initialization, no replay after completion, input routing,
skip/failure cleanup, hidden-interface preservation, both Dubai/Dhubai
spellings and title resize. The GPU test uses NumPy and headless EGL/OpenGL on
Linux to compile the production shaders and verify the opaque handoff, finite
output, artwork continuity and unchanged final live pixels.

In Recoil, check slow and fast loads, both map spellings, pause, Escape,
window resizing, interface restoration and tutorial audio. Check city assembly
and frame timing on the 1050 Ti. These in-game and hardware checks remain pending.
