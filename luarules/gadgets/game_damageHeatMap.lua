function gadget:GetInfo()
    return {
        name = "Damage HeatMap Gadget",
        desc = "Keeps Track of Damage and Danger ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 4,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

local GameConfig = getGameConfig()

local function getDangerAtLocation(self, x,z) 
    local zoneSeperatorSize = math.min(Game.mapSizeX, Game.mapSizeZ)/12
    if zoneSeperatorSize < 350 then zoneSeperatorSize = 350 end
    local ox,oz = math.floor(x/zoneSeperatorSize)+1, math.floor(z/zoneSeperatorSize)+1
    if not self.map[ox] then self.map[ox] = {} end
    if not self.map[ox][oz] then self.map[ox][oz] = 0 end

    return self.map[ox][oz]/self.normalizationValue
 end

 local function addDamageAtLocation(self, x,z, damage) 
    local zoneSeperatorSize = math.min(Game.mapSizeX, Game.mapSizeZ)/12
    if zoneSeperatorSize < 350 then zoneSeperatorSize = 350 end
    local ox,oz = math.floor(x/zoneSeperatorSize)+1, math.floor(z/zoneSeperatorSize)+1
    if not self.map[ox] then self.map[ox] = {} end
    if not self.map[ox][oz] then self.map[ox][oz] = 0 end

    self.map[ox][oz] = self.map[ox][oz] + damage

    if self.map[ox][oz] > self.normalizationValue then
        self.normalizationValue = self.map[ox][oz] 
    end
 end

if GG.DamageHeatMap == nil then
    GG.DamageHeatMap = {map= {}, 
                        normalizationValue = 0,
                        addDamageAtLocation = addDamageAtLocation,
                        getDangerAtLocation = getDangerAtLocation}
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
    x,y,z = Spring.GetUnitPosition(unitID)
    GG.DamageHeatMap:addDamageAtLocation(x,z, damage)
end

function gadget:Initialize()
    GG.DamageHeatMap = {map= {}, 
                        normalizationValue = 0,
                        addDamageAtLocation = addDamageAtLocation,
                        getDangerAtLocation = getDangerAtLocation
                    }
end

