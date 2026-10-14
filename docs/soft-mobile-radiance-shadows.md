# Soft mobile shadows and visible-surface receiving

Boxes and oriented ellipsoids remain the only mobile shadow geometry. Static
building occupancy, CEG rendering, physics and unit collision shapes are not
changed by this patch.

## Soft edges

A virtual emitter radius of 3 elmos defines a receiver-to-light cone. At position
t on the source-to-receiver segment its width is `radius * (1-t)`: contact
shadows stay narrow, and a more distant blocker produces a wider penumbra on
the receiver. A smoothstep transition retains a fully occluded core.

The box uses a bounded analytic minimum across six face planes; the ellipsoid
uses a first-order distance estimate at closest approach. This is an artistic
soft-shadow approximation, not exact integration over an area light. There is
no random sampling, temporal accumulation, screen blur, extra texture, or
per-object shadow map. Existing 128-caster / 16-per-cell limits remain. Repeated
grid encounters combine by minimum, not multiplication, so the same proxy
cannot darken its own edge repeatedly.

`softness` in `include/mobile_shadow_field.lua` is the shared CPU/GPU tuning
value (default 3, clamped to 0-8). Zero selects the original hard-ray test. A
conservative halo expands CPU discovery, grid coverage and the height envelope,
so soft edges are not cut off at the hard proxy bounds. Restart/reload after
editing the tuning value; no new chat command is introduced.

## The object receives light at its visible mesh surface

The scene already reconstructs the nearest visible world-space receiver from
depth and decodes its surface normal and albedo. For model pixels inside/near a
mobile proxy, local direct light and local cascade light now use the real
surface normal's cosine with the direction toward their retained light source.
Lamp-facing faces brighten; back-facing faces receive none of that contribution.
This does not darken the engine's ambient lighting or other independent lights.

The large building-wall exterior sampling offset is not used for these mobile
receivers: the lookup stays near the actual depth position. The proxy's one-elmo
outer feather prevents a sharp transition at small protruding mesh details.
Terrain pixels are excluded when deferred model/map buffers distinguish them.
The pre-existing depth-only fallback uses derivative normals and cannot identify
model pixels as precisely.

Exact lamp-owner exclusion and receiver containment still keep oversized proxy
geometry from blackening its own object. Other proxies remain occluders. A
normal/depth buffer describes visible surfaces, not hidden geometry: concave
self-shadowing and precise body identification in overlapping proxies remain
approximations. A retained representative source also approximates mixed light.
Strategic views outside the local lighting region retain their existing path.

## Validation

From the repository root:

```
texlua tests/mobile_shadow_field_lifecycle.lua
python3 tests/soft_mobile_shadows_gpu.py
```

The GPU test compiles and executes the actual helper and scene shader with
Mesa EGL/OpenGL (ctypes, no extra Python packages), including the ordinary
fallback shader. It checks hard compatibility, smooth box/ellipsoid edges,
contact-distance widening, rotation, large coordinates, grid continuity, exact
owner handling, normal response, neighboring blockers and terrain isolation.
Lua checks cover the real upload, halo coverage, bounded resources and failures.
Tested here using Lua 5.3 and software llvmpipe, not Recoil or a GTX 1050 Ti.

In a fresh game, place `/give policetruck` beside `/give truck_western1` on open
road. At a close camera compare `/radiancelight shadows off` and
`/radiancelight shadows on`, then record `/radiancelight shadows stats`.
Check the neighboring car's lamp-facing side and the road behind it, repeat
with a pedestrian and from a second camera angle, and measure target-hardware
frame time. Shader/unit tests are not visual or performance sign-off.
