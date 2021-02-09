function gadget:GetInfo()
    return {
        name = "Zeppelin Physics",
        desc = "Forces Zeppelin-type units to obey their cruisealt and prevents them from pitching",
        author = "Анархид",
        date = "2.2.2009",
        license = "GPL2.1",
        layer = 50,
        enabled = true
    }
end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

zeppelins = {
    [UnitDefNames["satellitescan"].id] = true,
    [UnitDefNames["satellitegodrod"].id] = true,
    [UnitDefNames["satelliteanti"].id] = true,
    [UnitDefNames["satelliteshrapnell"].id] = true
}
zeppelin = {}
zeppelin_waiting = {}

-- SYNCED
if (gadgetHandler:IsSyncedCode()) then

    function gadget:Initialize()
        Spring.Echo(GetInfo().name .. " Initialization started")
        for id, unitDef in pairs(UnitDefs) do
            if unitDef.myGravity == 0 and unitDef.maxElevator == 0 then
                Spring.Echo(unitDef.name .. " is a zeppelin with cruisealt " ..
                                unitDef.wantedHeight)
                zeppelins[id] = {
                    pitch = unitDef.maxPitch,
                    alt = unitDef.wantedHeight,
                    name = unitDef.name
                }
            end
        end
        Spring.Echo(GetInfo().name .. " Initialization ended")
    end

    function gadget:UnitCreated(UnitID, whatever)
        local types = Spring.GetUnitDefID(UnitID);
        if zeppelins[type] then zeppelin_waiting[UnitID] = types end
    end

    function gadget:UnitDestroyed(UnitID, whatever)
        local type = Spring.GetUnitDefID(UnitID);
        if zeppelins[type] then zeppelin[UnitID] = nil end
    end

    local function sign(num)
        if num < 0 then return -1 end
        return 1
    end

    local spGetUnitVector = Spring.GetUnitVectors
    local spGetUnitPosition = Spring.GetUnitPosition
    local spGetUnitVelocity = Spring.GetUnitVelocity
    local spGetUnitDirection = Spring.GetUnitDirection
    local spGetGroundHeight = Spring.GetGroundHeight
    local spSetUnitVelocity = Spring.SetUnitVelocity
    local spSetUnitRotation = Spring.SetUnitRotation

    function gadget:GameFrame(f)
        if f % 30 == 0 then
            for id, types in pairs(zeppelin_waiting) do
                if doesUnitExistAlive(id) == true then
                    hp, mHp, pD, cP, buildProgress = Spring.GetUnitHealth(id)
                    if buildProgress and buildProgress >= 1.0 then
                        zeppelin[id] = types
                        zeppelin_waiting[id] = nil
                    end
                else
                    zeppelin_waiting[id] = nil
                end
            end
        end

        if f % 20 < 1 then
            for zid, zepp in pairs(zeppelin) do
                local x, y, z = spGetUnitVectors(zid)
                local ux, uy, uz = spGetUnitPosition(zid)
                local vx, vy, vz = spGetUnitVelocity(zid)
                local dx, dy, dz = spGetUnitDirection(zid)
                local altitude = uy - spGetGroundHeight(ux, uz)
                local wanted = zeppelins[zepp].alt
                if math.abs(altitude - wanted) > 10 then
                    spSetUnitVelocity(zid, vx, vy + sign(wanted - altitude), vz)
                end

                if dy > 0 then
                    local h = math.asin(-dx / math.sqrt(dx * dx + dz * dz))
                    spSetUnitRotation(zid, 0, h, 0)
                end
            end -- for
        end -- iff
    end -- fn

end -- sync
