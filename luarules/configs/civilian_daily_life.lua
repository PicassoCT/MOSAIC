-- All timings are simulation frames (30 fps), independent of rendering/observers.
local area = VFS.Include('luarules/configs/city_area.lua')
return {
    groupChance = 38, groupRadius = 300, groupMax = 4,
    groupWaitDistance = 240, groupBreakDistance = 1100,
    visitMin = 12 * 30, visitMax = 28 * 30,
    lingerMin = 25 * 30, lingerMax = 65 * 30, lingerChance = 28,
    venueRadius = 2400,
    dangerRadius = area.dangerRadius, dangerMemory = area.quietFrames,
    refugeMin = 8 * 30, refugeMax = 20 * 30,
    vehicleInterval = 20 * 30, vehicleCooldown = 150 * 30,
    vehicleChance = 12, vehicleStoppedFrames = 4 * 30,
    vehicleParkChance = 20, vehicleParkMin = 12 * 30, vehicleParkMax = 22 * 30,
    vehicleBoardDistance = 180, vehicleDoorDistance = 55,
    memoryLimit = 6, memoryLifetime = 12 * 60 * 30,
    phoneMin = 55 * 30, phoneMax = 110 * 30,
    lineFrames = 5 * 30,
}
