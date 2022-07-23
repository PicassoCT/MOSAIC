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
local function getHighestDangerLocation(self)    
    highestValues = {x=Game.mapSizeX*(math.random(25,50)/50),z = Game.mapSizeZ*(math.random(25,50)/50), value = math.huge*-1}
    if #self.map > 0 then      
        for x=1, #self.map do
            if self.map[x] then
                for z=1 #self.map[x] do
                    if self.map[x][z] and self.map[x][z] > highestValues.value then
                        highestValues = {x=x,z = z, value = self.map[x][z]}
                    end
                end
            end
        end
    end
    return highestValues.x, highestValues.z
end

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
                        getDangerAtLocation = getDangerAtLocation,
                        getHighestDangerLocation = getHighestDangerLocation
                    }
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

