# Orbital arrival

**LuaIntro displays only static artwork and the normal loading progress bar.**
The satellite renderer never compiles or runs while the engine is loading.
**No descent runs until the simulation frame counter becomes positive.**
At the first LuaUI screen draw with `Spring.GetGameFrame() > 0`, the
artwork/orbit blend begins (0.5 seconds), holding the initial low Earth orbit view.
It is followed by **four planetary snapshots of 0.35 seconds each**, then a
separate 0.6-second cloud descent and city reveal (about 2.5 seconds total).
Each snapshot holds one optical scale, with a hard zoom cut to the next.
Earth fills most of the opening frame, with a broad curved atmospheric limb
and a narrow band of space above it. The initial projected radius is eight
times the former whole-globe view. The Earth's optical diameter expands roughly
9.7x across the four shots, keeping the same surface point under the screen
center. The final radius compensates for the lower viewing angle so the final
shot retains its previous central terrain scale. All four snapshots show the planetary surface;
the cloud transit and live city reveal begin only after the fourth hold.
The city appears progressively through thinning clouds instead of replacing
the image in one frame. Neither LuaIntro shutdown nor city spawn completion gates
the zoom. The original location widget resumes its city/region/district/time
telex after the cinematic releases the live map.

| Phase | Nominal time after first advancing game frame |
| --- | --- |
| Loading artwork blends into low Earth orbit | 0.00–0.50 seconds |
| Snapshot 1: low orbit with a curved atmospheric horizon | 0.50–0.85 seconds |
| Snapshot 2: closer regional view | 0.85–1.20 seconds |
| Snapshot 3: terrain and cloud detail | 1.20–1.55 seconds |
| Snapshot 4: close atmospheric approach | 1.55–1.90 seconds |
| Cloud transit, then live city reveal | 1.90–2.50 seconds |

The presentation clock lands on each snapshot boundary in an actual draw.
Display-frame rounding or startup stalls can extend these times so no shot is
skipped. There is no backlog that can fast-forward through unseen snapshots.

Every apparent movement is in screen space. The sequence never changes the
camera position, orientation, mode, field of view, simulation speed or pause state.
The orbital renderer keeps a fixed horizon orientation and places the sun
directly above the destination: every match arrives at local **high noon**.
Cloud tops and water reflections use neutral daylight, with a thin blue
atmospheric rim. Changing the generated region never changes the solar angle.
Clouds combine broad sheets, broken cumulus and sparse cirrus. Layered billows
share their detail with the lighting, while softer fine-scale normals avoid
making the cloud tops look like crumpled material.

The Earth surface is a procedural cinematic regional coastline. A deterministic
hash of the map name, map checksum and game ID selects another part of that
generated world for each match. If a game ID is unavailable, the same map uses
a stable fallback region. The renderer captures this choice once; every zoom
stage and viewport resize samples that same region without consuming Lua's RNG.
This is a fictional generated world, not a geographical atlas or a claim to
locate the live map accurately on Earth.

**Orbital clouds are stationary.** Terrain, cloud coverage, shadows and detail
depend on world coordinates and the selected region, with no time input or wind
offset. Fixed spatial frequencies keep formations aligned between snapshots;
pixel-footprint filtering reveals fine detail as the view approaches and limits
aliasing at the horizon. The final cloud passage changes the viewing scale of a
frozen cloud field, then opens onto the live city. Its motion comes from the
approach and reveal, rather than weather moving over the ground.

## Handoff and readiness

LuaIntro chooses one loading PNG, draws it without shaders, and passes the
artwork's VFS path to LuaUI in runtime-only configuration state.
The LuaUI widget arms immediately but does not compile the expensive orbital
shaders while the frame counter is zero. It draws the exact same static artwork
in DrawScreenEffects **and** DrawScreenPost, bridging LuaIntro shutdown without
revealing the unfinished map. Only the first positive game frame starts the
orbital compositor and
the presentation clock; wall time governs the snapshots regardless of
simulation speed, with the draw-boundary protection described above. This avoids
the race where LuaUI initializes after frame 0.
First initialization during the opening 300 game frames remains eligible;
midgame joins and reloads are bypassed. A runtime-only `played` marker blocks
replays even during those first 300 frames. No handoff state is written to disk.

The city gadget still publishes `mosaic_city_spawn_complete`, but the arrival
does not consume it: the screen-space composite blends to whatever world is actually rendered
when the cloud reveal completes, so startup cannot wait indefinitely for generation.

Planetary optical scale and cloud descent use separate shader values: reaching
the closest planetary snapshot cannot accidentally begin the city handoff.
At cloud descent 0.42–0.55 clouds fully cover the screen, hiding the projection
boundary. After that the cloud bank disperses and the live framebuffer
appears through a continuously enlarging opening. It captures only before
the interface is drawn, then reuses that clean texture in DrawScreenPost
to cover engine overlays. The expanding image plane's borders remain behind clouds.
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

The procedural pass uses native resolution up to **1920×1080**. Each of the
four stationary orbital snapshots is rendered once and reused throughout its
hold, including the artwork blend. Resizing or changing the viewport aspect
refreshes the image without choosing a new region. The final cloud approach
alone updates at a bounded 12 Hz. Snapshot cuts, reveal entry, clock resets and
the final frame force an immediate refresh. Uniform shader branches skip cloud
transit work during the orbital snapshots and skip the planet once the transit
clouds cover it. The compositor waits for the cached image to
reach the fully cloudy scene before it can show the live framebuffer, preventing
an early reveal when the cache trails the presentation clock. Artwork blending
and the live framebuffer composite remain display-rate. No procedural GPU pass runs during loading.
Resources are released when arrival finishes. GLSL requires the same
compatibility profile used by the existing MOSAIC postprocessing shaders.

## Validation

Run from the repository root:

```sh
lua5.1 tests/orbital_arrival.lua
python3 tests/orbital_arrival_gpu.py
python3 tests/orbital_arrival_gpu.py --width 1920 --height 1080 --preview-dir /tmp/arrival-preview
```

The Lua suite covers a shader-free, progress-visible LuaIntro, an artwork
bridge before gameframe 1, stable regional seeding without global RNG use,
native 1080p stationary snapshot caching, viewport resize, bounded 12 Hz cloud
descent with immediate cuts, game-frame triggering, the half-second blend,
four held optical scales before
cloud reveal, stalled-frame protection, cached-cloud handoff safety,
late widget initialization, no replay after completion, input routing,
skip/failure cleanup, hidden-interface preservation, both Dubai/Dhubai
spellings and title resize. The GPU test uses NumPy and headless EGL/OpenGL on
Linux to compile the production shaders and verify four distinct planetary
images without live-city leakage, identical repeated frames at a fixed region
and stage, distinct regional terrain and cloud formations, the opaque handoff,
finite output, artwork continuity and unchanged final live pixels within the
existing floating-point tolerance. Its optional `--preview-dir` writes the four
planetary snapshots, cloud-reveal samples and alternate-region samples from
the production shaders. `--width` and `--height` select render resolution;
`--region X Y` selects the procedural region to inspect.

In Recoil, check slow and fast loads, both map spellings, pause, Escape,
window resizing, interface restoration and tutorial audio. Check city assembly
and frame timing on the 1050 Ti. These in-game and hardware checks remain pending.
