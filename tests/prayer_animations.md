# Indexed civilian prayers

`callToPrayerN.ogg` selects style N for the civilians responding to that call.
The numeric filename suffix is used, not the position returned by `VFS.DirList`.

| Index | Gesture |
| --- | --- |
| 1 | Original prayer, retaining only its upper-body turns |
| 2 | Hands gathered near the chest, small bow |
| 3 | Open-handed offering |
| 4 | Raised invocation |
| 5 | Hand over heart, outward offering |
| 6 | Contemplation, hands near the face |
| 7 | Open arms, drawing hands inward |
| 8 | Alternating left/right hand emphasis |

Arabic currently has calls 1–6; international has 1–8. Unknown or missing indices
fall back to style 1. The forearms position the hands; the civilian rig exposes
no independent finger joints.

## Implementation

- `scripts/animations_civilian_prayers.lua` registers source-axis animation data
  before each civilian script's existing `setupAnimation`. Y/Z are swapped once
  by that setup. Do not pre-swap these poses or add another axis conversion.
- Only `Head1`, `UpBody`, `UpArm1/2`, and `LowArm1/2` receive turn commands. The
  original prayer is copied with an allowlist, without center/leg commands.
  Prayer playback no longer rotates the unit or translates its center.
- The upper animation state machine waits during prayer. Starting prayer replaces
  an existing upper idle thread; lower animation playback cannot overwrite prayer
  pieces. Normal completion or clearing the shared prayer state releases the wait.
- Sunshine chooses once at the beginning of each dawn/dusk prayer window and
  publishes `GG.ActivePrayerCall` in synced code. The existing 50% call chance and
  50% civilian participation chance remain. No call means no call-triggered prayer.
- Both cultures use these windows, on subsequent days as well as the first day.
  Calls now play at the window's start (2.5% of a day before dawn/dusk), aligned
  with the civilian participation window. Prayer duration is unchanged.

## Validation

Run `lua tests/prayer_animations_test.lua` from the repository root. This checks
all eight selections in both scripts, command restrictions, actual setup-axis
conversion, prayer completion/speed restoration, and call selection across windows.

In game, check both civilian models/cultures: arms should bend forward, opposite
arms should spread in opposite directions, feet and unit heading should remain
unchanged by the prayer. Confirm that damage/fleeing interrupts normally and
walking/idle resumes. Engine rendering is required to judge mesh intersections
and the final appearance of each hand pose.
