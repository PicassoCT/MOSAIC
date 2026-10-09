# Hologram pixel interludes and TigLil playback

Normal adverts remain the main display. Asian holograms use their existing RGB
pieces for brief scan-line errors and occasional miniature animations:

- Conway's Game of Life, with gliders and a blinker.
- Falling tetrominoes with collision, settling, and line clearing.
- A scanning corporate eye that breaks into static.
- Falling RGB code trails.
- A very rare rain-only slow-motion ground splash: falling drop, held crown,
  detached beads, and expanding ripple, inspired by the supplied crown photograph.

Interludes last roughly 4–6 seconds. Each sign tries one every 210–420 seconds
after a staggered initial delay. A city-wide cooldown allows at most one playful
interlude to start every 60–100 seconds, with at most two pixel effects active.
Dry errors last about 0.7 seconds and recur every 80–180 seconds; natural rain
adds falling corruption and shortens the interval to 18–45 seconds. Contention
can make all these gaps longer. Rain does not accelerate the playful interludes.

The ground splash lasts about six seconds and uses at most 48 pixels. Its first
attempt is staggered 3–6 minutes into rain, with a city-wide cooldown of 6–10
minutes and a 15–30 minute retry interval per sign. It searches four sides of the
sign for unoccupied dry ground, follows the sampled terrain height, and cancels
when rain stops. It shares the ordinary interlude budget; it does not add another
concurrent animation. The crown is a short procedural animation, not a fluid
simulation. Reference: https://assets.mitmuseum.mit.edu/iiifimg3/78053419/full/800,/0/default.jpg

The controller uses a private deterministic PRNG and at most an 8-by-8 board.
Pieces are allocated without replacement, positioned using their native size,
and hidden/reset afterwards. Effects yield between frames and sleep between
attempts. Daylight, blackout, and emergency state suppress pixel interludes.

TigLil retains the night-time performances and a limit of three performers per
western hologram type. Expiring reservations free capacity after destruction or
interruption. Both models now receive the previously inaccessible drum/ball
routines, and business/casino poses receive the techno flag. Hair, gestures and
other child threads stop with the performance. Renderer visibility is dirtied
on membership changes, including changes occurring in the same game frame.

## In-game verification still required

Source and diff review do not establish Recoil playback or visual quality.
On a city with Asian and western holograms, inspect a natural dry night and a
natural rainy night. Allow several minutes for the intentionally rare sequences;
verify pixel alignment/size and that normal adverts continue. Check the falling
blocks clear their first completed row and Life advances through generations.
On a natural rainy night, also check the rare splash at ground level, including
rotated signs, slopes, water rejection, and no pixels remaining after the ripple.

Observe business/casino and brothel TigLil performances, then trigger blackout
and emergency transitions and wait for dawn. Check that props and child animation
threads disappear and that performances can resume. Destroy a performing
hologram and check that another eligible one can use its slot. Inspect infolog
for missing piece IDs, signal errors, and animation errors; compare frame time
in a dense city before/after, and verify the same replay on two clients.

`/weatherman on` is a local rain-rendering override. It does not change synced
weather, so it cannot force these synced pixel/rain schedules. No shader rain
uniforms were re-enabled; the previous uniform-warning fix remains intact.
