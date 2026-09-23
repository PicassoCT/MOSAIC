# Repeatable rain screenshots

Position the camera near a steady light, wait for the desired time of day, and enter:

```
/rainsnap
```

This pauses the simulation at its current time, holds the camera, and saves **11 PNGs**:
a dry reference and rain amounts 0.1 through 1.0. Each image gets a two-second settling
period and at least two rendered frames. The sequence takes approximately 22 seconds
plus file-writing time. Previous rain/debug settings, camera and pause state are
restored on completion, cancellation or a detected failure.

```
/rainsnap 2 3
```

This saves **33 PNGs**, three per intensity. Rain shader phases are exactly 30.00,
30.25 and 30.50 seconds for every intensity, making adjacent images a short motion
sequence. Increase the last number up to 10 for more phases. The first argument is
the wall-clock settling period per image (0.25-30 seconds). The default single frame
always uses phase 30.00. Animation time is held at each phase during settling;
this is deterministic sampling, not a real-time video recording.

```
/rainsnap cancel
```

Output is under the engine's writable data directory:

```
screenshots/rain_YYYYMMDD_HHMMSS_f<gameframe>_<run>/
    rain_000_frame_01.png
    rain_010_frame_01.png
    ...
    rain_100_frame_01.png
    manifest.txt
```

The manifest records map, camera, viewport, game frame, rain shader time of day,
sun/sky colour, sun direction, glitter setting and each successful image's intensity
and animation phase. It also records the water revision and an Adler-32 fingerprint
of the compiled fragment/vertex shader sources. Captures temporarily hide the
interface, including the console overlay, and restore its previous visibility on
completion, cancellation or failure. Keep resolution, graphics settings and the light
source unchanged between runs. Supply the whole directory when comparing results.

This is a **local rain-renderer override**, not a synced weather command. The dry
reference disables this rain widget and its shared headlight wetness; it does not
remove independent hologram rain or other water effects. Simulation-driven lighting
and units are frozen by pause. Other widgets with real-time animation, such as
animated adverts, are not globally frozen. Use a stationary, steady light for a
controlled comparison. No changes are made to exposure, bloom or shader appearance.

In multiplayer, pause the game before using the command; it will not automatically
pause a running game with another active human player. An already-paused game stays
paused afterward. Resuming the simulation or resizing the viewport aborts the run.
The command checks screenshot-write results and reports partial runs in the manifest.

Validation: `lua tests/rain_capture_lifecycle.lua` checks the capture lifecycle with
mocked engine APIs. Actual framebuffer contents and engine pause/camera behaviour
still require an in-game run.


## Engine screenshot backend

Capture now invokes the engine `screenshot png` command (the F12 capture path).
It waits for a new PNG with a complete end chunk before copying it into the labelled
run directory and advancing to the next intensity. The original `screen*.png` file
also remains in the normal lowercase `screenshots/` directory. Avoid pressing F12
manually during a sequence, since new engine screenshot files identify each capture.
The manifest records the corresponding engine filename.

`/rainsnap status` reports progress and the output directory. Each verified save
prints `saved N/11` (or the requested sequence total). Failed writes, a missing render
callback, or an engine PNG that does not complete within 15 seconds abort with an
explicit message and restore the previous state. Timers use the real-time engine
clock, independently of the paused simulation's update delta.

The previous implementation saved through `gl.SaveImage` into uppercase `Screenshots/`,
which is a separate directory on Linux. Those old files, if any, remain there.
