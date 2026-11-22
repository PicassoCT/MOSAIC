-- Synced frames (30 Hz). These policies never change vehicle physics.
return {
    pollFrames = 15,
    arrivalRadius = 100,
    stoppedSpeed = 0.15, -- elmos/frame; wait for native braking to finish
    approachTimeout = 45 * 30,
    maxParked = 24,
    maxParkedFraction = 0.30,
    departureSpacing = 5,
    parkingClearance = 100,
    profiles = {
        car = {chance=20, min=60*30, max=180*30, activity="parked"},
        sport = {chance=20, min=45*30, max=120*30, activity="parked"},
        van = {chance=25, min=45*30, max=150*30, activity="parked"},
        limousine = {chance=20, min=60*30, max=180*30, activity="parked"},
        bus = {chance=20, min=12*30, max=22*30, activity="parked"},
        motorcycle = {chance=15, min=30*30, max=90*30, activity="parked"},
        rigid = {chance=50, activity="unloading", freight=true},
        heavy = {chance=50, activity="unloading", freight=true},
        articulated = {chance=50, activity="unloading", freight=true},
    },
    -- Only a bounded subset of junctions is controlled, but every ambient
    -- vehicle routed through one follows its stop/clearance protocol.
    junctionFraction = 0.25,
    maxJunctions = 12,
    junctionRadius = 100,
    stopOffset = 240,
    corridorWidth = 80,
    laneOffset = 64,
    exitClearance = 48,
    queueDistance = 600,
    junctionStopFrames = 2 * 30,
    junctionHeadway = 2 * 30,
    crossingTimeout = 30 * 30,
}
