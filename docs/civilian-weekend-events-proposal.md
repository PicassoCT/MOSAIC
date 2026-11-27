# Civilian weekend events proposal

Status: design proposal, not implemented. Add public gatherings that assemble
gradually, respond to weather and danger, and release civilians back into their
daily routines. Preserve existing player-triggered protests and the city parade.

## Calendar and weather

Use one shared seven-day calendar for gatherings and the existing seventh-evening
parade. Proposed initial gathering day: Sunday. A simulation day currently lasts
28,800 frames, or 16 minutes at 30 fps; a week therefore lasts 112 minutes at normal
speed. Starting the calendar on Saturday is a proposed pacing option so the first
weekend can occur within a shorter match.

Outdoor events require daylight, dry weather, acceptable visibility, and no
sandstorm or heavy smog. Use deterministic simulation weather and rain, never
local graphics settings. Sustained bad weather stops recruitment and sends people
toward shelter. Use hysteresis to prevent repeated assembly and dispersal during
brief transitions. Coordinate population, venue and road reservations with the
existing parade.

## Protest days

Select one surviving, accessible objective: the governor's palace
(`objective_presidentialpalace`), UNATO Arcology (`objective_westhemhq`), or refugee
camp (`objective_refugeecamp`). Define entrance anchors and assembly areas outside
the building footprint, with pedestrian clearance and an escape route. Do not
route the crowd toward the building center.

Organizers arrive in the morning. Small groups approach from different streets
through late morning, with an afternoon peak and gradual departure before evening.
An initial tuning range is 16–32 participants recruited mainly from existing
civilians. Roles include organizers, sign holders, chanters, speakers, onlookers,
and people filming. Use loose clusters, varied gestures and staggered departures.

The existing peaceful-protest script follows a social-engineer unit. Add an event
destination and lifecycle for scheduled protests without removing that behaviour.
Demonstrators with a mask piece wear it while participating. Departure removes
only the protest mask reason; weather and outfit reasons continue to apply.

Keep ordinary demonstrations predominantly peaceful. Throwing is a distinct
escalation involving a minority of participants. Preserve Molotov behaviour as a
more severe escalation rather than making it the ordinary protest projectile.

## Other gatherings

- Weddings: a couple, guests in a loose semicircle, greetings, applause,
  photographs, staggered arrivals, and an optional departure convoy.
- Celebratory car convoy: interpret the requested car-coursus as an Autokorso.
  Start with three to six ordinary cars, a short validated road route, spaced
  departures, occasional horns and spectators. Reuse parade routing and traffic
  clearance.
- Outdoor yoga: an instructor and six to twelve civilians on flat open ground.
  Begin with slow standing stretches and small timing differences. Floor poses
  and mats can follow after ground-contact animation validation.

Initially allow one main gathering and, where population permits, one small
activity elsewhere. Proposed counts and times remain configurable tuning values.

## Throwable props and settled stones

Use hand-sized stones, small cans or plastic bottles. An optional hidden `stone1`
piece should follow a hand with matching local axes; one reusable mesh and a
matching projectile model are sufficient. Civilians without the piece can still
chant or watch. Throwers need a free hand: avoid conflicts with bags, babies,
trolleys and placards.

Show the prop during preparation, release a projectile from the hand at the
animation's release beat, then hide the held prop. Use short range, gravity,
inaccuracy and building collisions. Stones have modest direct-impact damage,
without explosive splash or fire.

Use native projectile ground bounce, already demonstrated by
`weapons/teargasgrenade.lua`: two or three diminishing bounces, limited sliding,
and clattering sounds. Native bounce alone does not leave permanent clutter.
When a stone settles, replace the projectile with a matching non-blocking feature
at its final valid ground position. Suppress explosion effects and duplicate
impact damage. Cap debris counts and gradually remove older stones. Handle water,
unit/building impacts and projectile expiration separately so they cannot leave
floating debris or duplicate features. Wall ricochets are not implied by the
engine's terrain-bounce support.

## Implementation and validation

1. Add a shared calendar and event controller with configurable event profiles,
   weather eligibility, participant reservations and objective entrance anchors.
2. Implement protest recruitment, roles, masks, dispersal and danger interruption.
3. Add weddings and yoga, then the car convoy using existing route helpers.
4. Add throwing props, release timing, bouncing projectiles and bounded debris.

Panic, injury, death, transport and player-controlled activities take priority.
Cleanup releases only state owned by the event and must not overwrite a newer
activity. Keep movement under normal engine orders and reuse existing civilian
activity ownership and interruption patterns.

Test calendar boundaries, weather changes, destroyed objectives, blocked entrances,
participant interruption, mask restoration, carrying compatibility, save/reload,
and event/parade conflicts. Check animations and prop axes across all civilian
rigs. Test projectile release, declining bounce energy, final placement, damage
counting, debris caps and cleanup. Provide developer start/stop/status commands so
each event can be tested without waiting a simulation week.
