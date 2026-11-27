# Civilian gatherings

Scheduled gatherings run only while `GG.GlobalGameState` equals the configured
normal/peace state. Starting a preview also requires peace. A state change stops
all gatherings; injury, nearby danger, destroyed venues, capture, transport and
newer civilian activities interrupt participation. Existing social-engineer
protests, Molotov/anarchy behaviour and the seventh-evening parade are preserved.

The shared calendar starts at Monday noon, keeping the existing parade timing.
Sunday daytime rotates the main event between a protest, wedding and celebratory
ordinary-car convoy. A sufficiently populated city can also hold yoga elsewhere.
This does not accelerate the week: with the default clock, Sunday morning is
about 94 minutes into the match. Counts, hours, weather grace periods, recruitment
range, spacing and escalation live in `luarules/configs/civilian_gatherings.lua`.

Participants come from existing ambient Gaia civilians. Organizers arrive first;
recruitment grows toward the peak, then departures are staggered. Protest roles
include signs, chanting, speeches, onlookers and filming. Weddings have two
central participants and guests; yoga has an instructor and standing stretches.
Car convoys reserve three to six empty ordinary cars, validate the road circuit
with the parade route helper, stagger departures and occasionally sound horns.
Spectators assemble beside the circuit. Reservations pause ordinary traffic and
population cleanup; the parade takes priority over gatherings.

Player social engineering can take over gathering and parade participants during
peace. The existing social-engineering scan invokes the civilian behaviour
dispatcher for reserved crowds, releasing the scheduled pose and starting the
existing follow-the-engineer protest. A live engineering claim also prevents
scheduled gathering recruitment from taking that civilian back. Engineer death clears only
its own claims. This takeover cannot override panic, another active player
activity, aerosol control, injury, stun, interrogation, close combat or transport.

Hostage incidents can frighten nearby gathering/parade participants and then
select them through the existing witness-filming flow. Aerosols, tear gas,
manual-aim panic, bomber panic, damage, hostage capture and transport retain their
existing script interruption paths. Active detention, close combat and stun also
exclude civilians from recruitment and stone release. Ordinary chatting and
scheduled prayer do not preempt a reserved gathering.

Protests use the configured front side of a surviving palace, UNATO arcology or
refugee camp, beyond the live collision footprint. Assembly points, pedestrian
paths and escape lanes must be traversable and clear of house footprints. A
blocked or inaccessible venue can cause an event to be skipped. These offsets
are initial tuning, not individually authored doorway coordinates.

Outdoor events require daylight and deterministic dry, sufficiently clear
weather. Recruitment stops immediately during unsuitable weather. After a grace
period, participants disperse and request ordinary daily-life shelter visits;
if no safe shelter is available, ordinary travel resumes. Weather/outfit masks
are independent of the protest mask reason. Carrying civilians can watch;
arm gestures, signs and throwing require free hands.

Most scheduled protests remain peaceful. The default escalation chance is 15%
of protest events, beginning at the afternoon peak. At most one eighth of the
currently arrived, non-departing participants can throw per cooldown, and only
eligible chanters do so. A crowd smaller than eight cannot throw. Escalation
uses stones; it does not replace or activate the existing Molotov behaviour.

Both installed stone variants are supported. The held prop appears during
preparation and is hidden at the release beat. The projectile starts at that
piece's world position; short range, ballistic gravity, aim scatter, three
native diminishing ground bounces and direct impact damage apply. Stones have
no splash damage, fire or explosion graphics. Ground-only terminal contacts
become matching nonblocking features. Unit/building/feature impacts, water and
airborne expiration do not produce ground debris. Cleanup limits debris to 96
stones and four minutes. Reload retires untracked flying stones, recovers tagged
debris and releases event reservations without clearing newer activities.

## Developer previews

Enable cheats and run these in the in-game console during peace and suitable
daylight/weather. Status does not require cheats.

```
/luarules gatherings status
/luarules gatherings start protest
/luarules gatherings start wedding
/luarules gatherings start yoga
/luarules gatherings start convoy
/luarules gatherings escalate
/luarules gatherings stop
```

Previews assemble over two minutes and last about four minutes plus staggered
cleanup. `escalate` affects an active protest; it still requires enough arrived,
free-handed chanters within throwing range. Previews retain population, weather,
path and peace checks. Starting can fail with an explanatory status message.

## Validation and remaining visual review

External regressions cover the shared calendar, peacetime gates, weather grace
periods, path rejection/timeouts, reservation cleanup, newer activity ownership,
transport, masks, convoy starts, reload, release timing and bounded debris.
Kinematic checks cover the new poses across all twelve installed civilian rigs.
These checks do not substitute for an in-engine visual and native-physics run.
Inspect crowd spacing, exact doorway alignment, sign/phone poses, stone flight
and bounce sounds in a fresh match. The known open-hand stone grip is unchanged.
Floor yoga poses, mats, additional can/bottle meshes and an automatic wedding
exit convoy remain optional follow-ups from the design proposal.

Tests and asset-generation tools remain outside the game checkout. The two new
`civilian_stone*.dae` projectile meshes are derived from installed held pieces,
with original triangle/UV data and matching scale; source civilian and native
Max files are untouched. To regenerate after a future stone edit, use
`/home/picasso/MosaicDev/Tools/civilian_stones/build_projectile_assets.py`.
