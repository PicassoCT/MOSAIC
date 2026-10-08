function gadget:GetInfo()
    return {name="Antagon human shields",desc="Stock civilian shields; hostile destruction yields propaganda money",
        author="MOSAIC contributors",license="GPL v2",layer=0,enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return end

local SAFEHOUSE = UnitDefNames.antagonsafehouse.id
local CIVILIAN = UnitDefNames.civilianagent.id
local citizen = UnitDefs[CIVILIAN]
local METAL_COST = citizen.metalCost or citizen.buildCostMetal or 500
local ENERGY_COST = citizen.energyCost or citizen.buildCostEnergy or 150
local CMD_SHIELD = 34587
local MAX_STOCK = 3
local PURCHASE_COOLDOWN = 30 * (Game.gameSpeed or 30)
local MAX_PAYOUT = 2400
local lastPurchase = {}
local REWARD = METAL_COST * 1.5
local stock = {}
local gaia = Spring.GetGaiaTeamID()
local visibility={allied=true}

local function update(id)
    local n=stock[id] or 0
    Spring.SetUnitRulesParam(id,"human_shield_stock",n,visibility)
    local idx=Spring.FindUnitCmdDesc(id,CMD_SHIELD)
    if idx then Spring.EditUnitCmdDesc(id,idx,{
        name="Human shield ("..n.."/"..MAX_STOCK..")",
        tooltip="Purchase one captive civilian for "..METAL_COST.." money / "..ENERGY_COST..
            " supply. Max "..MAX_STOCK..". When enemies destroy this safehouse, stored shields generate propaganda money.",
    }) end
end
function gadget:UnitCreated(id,defID)
    if defID~=SAFEHOUSE or stock[id]~=nil then return end
    stock[id]=0
    Spring.InsertUnitCmdDesc(id,{id=CMD_SHIELD,type=CMDTYPE.ICON,
        name="Human shield (0/"..MAX_STOCK..")",action="buyhumanshield",
        tooltip="Stock a civilian human shield at civilian-agent cost."})
    update(id)
end
function gadget:Initialize()
    gadgetHandler:RegisterCMDID(CMD_SHIELD)
    for _,id in ipairs(Spring.GetAllUnits()) do
        self:UnitCreated(id,Spring.GetUnitDefID(id))
    end
end
function gadget:AllowCommand(id,defID,team,cmd,params)
    if cmd~=CMD_SHIELD then return true end
    if defID~=SAFEHOUSE or stock[id]==nil or stock[id]>=MAX_STOCK
       or Spring.GetUnitIsDead(id) or team==gaia then return false end
    local frame=Spring.GetGameFrame()
    if lastPurchase[id] and frame-lastPurchase[id]<PURCHASE_COOLDOWN then return false end
    if not Spring.UseTeamResource(team,"metal",METAL_COST) then return false end
    if not Spring.UseTeamResource(team,"energy",ENERGY_COST) then
        Spring.AddTeamResource(team,"metal",METAL_COST)
        return false
    end
    stock[id]=stock[id]+1
    lastPurchase[id]=frame
    update(id)
    return false
end
function gadget:UnitDestroyed(id,defID,team,attackerID,attackerDefID,attackerTeam)
    if defID~=SAFEHOUSE then return end
    local n=stock[id] or 0
    stock[id]=nil -- consume exactly once, including replayed destruction callbacks
    lastPurchase[id]=nil
    if n==0 or not attackerTeam or attackerTeam==gaia
       or Spring.AreTeamsAllied(team,attackerTeam) then return end
    -- Respect the existing economy configuration and bound extreme propaganda scaling.
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")
    local cfg=getGameConfig()
    local serverMultiplier=cfg and cfg.economy and cfg.economy.propaganda
        and cfg.economy.propaganda.serverMultiplier or 0
    local servers=GG.Propgandaservers and GG.Propgandaservers[team] or 0
    local payout=math.min(MAX_PAYOUT,math.ceil(n*REWARD*(1+servers*serverMultiplier)))
    Spring.AddTeamResource(team,"metal",payout)
end
function gadget:UnitTaken(id,defID)
    if defID==SAFEHOUSE then stock[id]=0;lastPurchase[id]=nil;update(id) end
end
function gadget:UnitGiven(id,defID)
    if defID==SAFEHOUSE and stock[id]==nil then stock[id]=0;update(id) end
end
