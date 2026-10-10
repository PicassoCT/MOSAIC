-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--[[
This file defines the following global functions:

In SYNCED code:

function gadget:Initialize()
function gadget:GameFrame(f)
function gadget:RecvLuaMsg(msg, player)

In UNSYNCED code:

function gadget:Initialize()
function GiveOrderToUnit(unitID, cmd, params, options, betrayalOrder)
TODO: function GiveOrderToUnitMap(...)
TODO: function GiveOrderToUnitArray(...)
TODO: function GiveOrderArrayToUnitMap(...)
TODO: function GiveOrderArrayToUnitArray(...)

This framework automatically chains it's gadget methods with user defined
gadget methods, so effectively both get called. In other words, you can safely
define your own (synced/unsynced) gadget:GameFrame, this framework work ensure
both it's own code as your code gets called.

Additionally, the framework examines the team list and tries to kill the gadget
whenever there are no AI teams or (for the unsynced part) when there are no AI
teams with the current player as team leader.

For this to work, the framework needs to be included at the end of the main
gadget file, and the result of the include statement needs to be returned to
the gadgetHandler.

Example:

if (not gadgetHandler:IsSyncedCode()) then

-- Your own unsynced LUA AI callins and code.
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	Spring.Echo("UnitCreated: " .. UnitDefs[unitDefID].humanName)
end

end

-- Set up LUA AI framework.
callInList = {
	"UnitCreated",
}
return include("LuaRules/Gadgets/.../framework.lua")
]]--


local function Log(...)
	--uncomment to debug LUA AI framework code
	--Spring.Echo("LUA AI: " .. table.concat{...})
end

local warnings={}
local function Warning(reason, detail)
    warnings[reason]=(warnings[reason] or 0)+1
    -- Bound errors by category, not by unit ID or command signature.
    if warnings[reason]<=5 then
        Spring.Log("Prometheus bridge", "warning", reason..(detail and ": "..detail or ""))
    end
end

local function Error(...)
	Spring.Log("C.R.A.I.G. framework", "error", table.concat{...})
end


if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  SYNCED
--

--speedups
local bit_and = math.bit_and
local GiveOrderToUnit = Spring.GiveOrderToUnit
local ValidUnitID = Spring.ValidUnitID
local GetUnitTeam = Spring.GetUnitTeam

-- globals
local numMessages = 0
local messageQueue = {}
--local allowedPlayers = {}
local allowedTeams = {}
local audit={}
local function record(team,field)
    if not team then return end
    audit[team]=audit[team] or {dispatched=0,rejected=0,unconfirmed=0}
    audit[team][field]=audit[team][field]+1
end
gadget.commandAudit=audit

gadget.team = allowedTeams


-- If no AIs are in the game, ask for a quiet death.
do
	local name = gadget:GetInfo().name
	local count = 0
	for _,t in ipairs(Spring.GetTeamList()) do
		if Spring.GetTeamLuaAI(t) == name then
			--local _,leader,_,_,_,_ = Spring.GetTeamInfo(t)
			--allowedPlayers[leader] = true
			--Log("SYNCED: allowed player: ", leader)
			allowedTeams[t] = true
			Log("SYNCED: allowed team: ", t)
			count = count + 1
		end
	end
	if count == 0 then return false end
end


local function DeserializeAndProcessMessage(msg, player)
    local cursor, orders = 2, {}
    local wide=msg:byte(1)==214
    local function uint32()
        local a,b,c,d=msg:byte(cursor,cursor+3);cursor=cursor+4
        return ((a*256+b)*256+c)*256+d
    end
    -- Validate the entire packet first. Truncation must not partly execute a batch.
    while cursor <= #msg do
        local id,cmd,options,count
        if wide then
            if cursor+9>#msg then return false end
            id=uint32();cmd=uint32()-2147483648
            options,count=msg:byte(cursor,cursor+1);cursor=cursor+2
        else
            if cursor+4>#msg then return false end
            local u1,u2,c1,c2,flags=msg:byte(cursor,cursor+4);cursor=cursor+5
            id=u1*256+u2;cmd=c1*256+c2-32768
            count=flags%16;options=flags-count
        end
        if count>15 or cursor+count*(wide and 4 or 2)-1>#msg then return false end
        local params={}
        for i=1,count do
            if wide then params[i]=uint32()-2147483648
            else
                local a,b=msg:byte(cursor,cursor+1);cursor=cursor+2
                params[i]=a*256+b-32768
            end
        end
        orders[#orders+1]={id=id,cmd=cmd,params=params,options=options}
    end
    for _,order in ipairs(orders) do
        if ValidUnitID(order.id) then
            local team=GetUnitTeam(order.id)
            local _,leader=Spring.GetTeamInfo(team)
            -- Check ownership when executing too: a queued order may predate defection.
            if allowedTeams[team] and leader==player and
                Spring.GetUnitRulesParam(order.id,"betrayal_runner")~=1 then
                local ok,result=pcall(GiveOrderToUnit,order.id,order.cmd,order.params,order.options)
                if not ok or result==false then
                    record(team,"rejected");Warning("Engine rejected AI order")
                elseif result==nil then record(team,"unconfirmed")
                else record(team,"dispatched") end
            else
                record(team,"rejected");Warning("AI order rejected: ownership, leader or betrayal runner")
            end
        end
    end
    return true
end

--------------------------------------------------------------------------------
--
--  The call-in routines
--

local function Initialize(self)
	Log("SYNCED: Initialize")
	-- Set up the forwarding calls to the unsynced part of the gadget.
	local SendToUnsynced = SendToUnsynced
	for _,callIn in pairs(callInList) do
		local fun = gadget[callIn]
		if (fun ~= nil) then
			gadget[callIn] = function(self, ...) fun(self, ...) SendToUnsynced("Prometheus_"..callIn, ...) end
		else
			gadget[callIn] = function(self, ...) SendToUnsynced("Prometheus_"..callIn, ...) end
		end
		gadgetHandler:UpdateCallIn(callIn)
	end
end


local reportCount=0
local function GameFrame(self,f)
    local queue=messageQueue
    messageQueue={};numMessages=0
    for _,entry in ipairs(queue) do
        local ok,valid=pcall(DeserializeAndProcessMessage,entry.msg,entry.player)
        if not ok or not valid then Warning("Dropped malformed AI command packet") end
    end
    if f and f%900==0 then
        reportCount=reportCount+1
        for team,c in pairs(audit) do
            if Spring.SetTeamRulesParam then
                for field,n in pairs(c) do Spring.SetTeamRulesParam(team,"prometheus_orders_"..field,n,{public=true}) end
            end
            if reportCount<=5 and Spring.Echo then
                Spring.Echo("Prometheus bridge team "..team..": dispatched="..c.dispatched.." rejected="..c.rejected.." unconfirmed="..c.unconfirmed)
            end
        end
    end
end

local function RecvLuaMsg(self, msg, player)
    if msg:byte()~=213 and msg:byte()~=214 then return false end
    if #msg>8192 or numMessages>=256 then return true end
    local authorized=false
    for team in pairs(allowedTeams) do
        local _,leader=Spring.GetTeamInfo(team)
        if leader==player then authorized=true;break end
    end
    if not authorized then return true end
    numMessages=numMessages+1
    messageQueue[numMessages]={msg=msg,player=player}
    return true
end

--------------------------------------------------------------------------------

if gadget.Initialize then
	local fun = gadget.Initialize
	gadget.Initialize = function(self) Initialize(self) return fun(self) end
else
	gadget.Initialize = Initialize
end

if gadget.GameFrame then
	local fun = gadget.GameFrame
	gadget.GameFrame = function(self, f) GameFrame(self, f) return fun(self, f) end
else
	gadget.GameFrame = GameFrame
end

if gadget.RecvLuaMsg then
	local fun = gadget.RecvLuaMsg
	gadget.RecvLuaMsg = function(self, msg, player)
		if RecvLuaMsg(self, msg, player) then return true end
		return fun(self, msg, player)
	end
else
	gadget.RecvLuaMsg = RecvLuaMsg
end

else

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  UNSYNCED
--

-- If we are not teamLeader of an AI team, ask for a quiet death.
do
	local count = 0
	local name = gadget:GetInfo().name
	local myPlayerID = Spring.GetMyPlayerID()
	for _,t in ipairs(Spring.GetTeamList()) do
		if Spring.GetTeamLuaAI(t) == name then
			local _,leader,_,_,_,_ = Spring.GetTeamInfo(t)
			if (leader == myPlayerID) then count = count + 1 end
		end
	end
	if count == 0 then return false end
end


--globals
local optionStringToNumber = {
	alt   = CMD.OPT_ALT,
	ctrl  = CMD.OPT_CTRL,
	shift = CMD.OPT_SHIFT,
	right = CMD.OPT_RIGHT,
}
local bufferSize, bufferBytes = 1, 1
local messageBuffer = {string.char(214)}


local function SerializeOrder(unitID, cmd, params, options)
    params,options=params or {},options or 0
    local function integer(n,lo,hi)
        return type(n)=="number" and n==n and n>=lo and n<=hi and n==math.floor(n)
    end
    assert(type(params)=="table" and #params<=15,
        "expected at most 15 numeric command parameters")
    assert(integer(unitID,0,2147483647), "unit ID must be a 31-bit integer")
    assert(integer(cmd,-2147483648,2147483647), "command ID must be a signed 32-bit integer")
    if type(options)=="table" then
        local value=0
        for _,opt in ipairs(options) do value=value+(optionStringToNumber[opt] or 0) end
        options=value
    end
    assert(integer(options,0,255), "command option mask must be an integer byte")
    local b={}
    local function uint32(n)
        b[#b+1]=math.floor(n/16777216)%256
        b[#b+1]=math.floor(n/65536)%256
        b[#b+1]=math.floor(n/256)%256
        b[#b+1]=n%256
    end
    uint32(unitID);uint32(cmd+2147483648)
    b[#b+1]=options;b[#b+1]=#params
    for i,param in ipairs(params) do
        assert(type(param)=="number" and param==param and param>=-2147483648 and param<=2147483647,
            "parameter "..i.." must be a finite signed 32-bit number")
        -- The bridge transports 32-bit integer coordinates, rounded once here.
        -- Negative halves round symmetrically, rather than towards positive infinity.
        local rounded = param < 0 and -math.floor(-param+0.5) or math.floor(param+0.5)
        uint32(rounded+2147483648)
    end
    return string.char(unpack(b))
end


function GiveOrderToUnit(unitID, cmd, params, options, betrayalOrder)
    if Spring.GetUnitRulesParam(unitID,"betrayal_runner")==1 then return false end
    if gadget.betrayalContacts and gadget.betrayalContacts[unitID] and not betrayalOrder then return false end
    if cmd==CMD.CLOAK and Spring.GetUnitRulesParam(unitID,"betrayal_defector")==1 then return false end
	--Log("UNSYNCED: GiveOrderToUnit ", unitID)
    local status, msg = pcall(SerializeOrder, unitID, cmd, params, options)
    if not status or not msg then
        -- Diagnostics must name the bad field and order. Returning false keeps
        -- strategy counters honest: nothing was queued for the synced bridge.
        Warning("Failed to serialize AI command", "unit="..tostring(unitID)
            .." cmd="..tostring(cmd).." reason="..tostring(msg))
        return false
    end
    if bufferBytes+#msg>8192 then
        Spring.SendLuaRulesMsg(table.concat(messageBuffer))
        bufferSize,bufferBytes=1,1;messageBuffer={string.char(214)}
    end
    bufferBytes=bufferBytes+#msg
	bufferSize = bufferSize + 1
	messageBuffer[bufferSize] = msg
    return true -- queued; synced audit distinguishes dispatch/rejection
end

--------------------------------------------------------------------------------
--
--  The call-in routines
--

local function Initialize(self)
	Log("UNSYNCED: Initialize")
	for _,callIn in pairs(callInList) do
		local fun = gadget[callIn]
		--uncomment this to trace all callIn calls
		--fun = function(name, ...) Spring.Echo("UNSYNCED: " .. name) gadget[callIn](name, ...) end
		gadgetHandler:AddSyncAction("Prometheus_"..callIn, function(_, ...) return fun(gadget, ...) end)
	end
end


local oldShutdown=gadget.Shutdown
function gadget:Shutdown()
    for _,callIn in ipairs(callInList) do gadgetHandler:RemoveSyncAction("Prometheus_"..callIn) end
    if oldShutdown then oldShutdown(self) end
end

local function GameFrame(self, f)
	if (bufferSize ~= 1) then
		Log("UNSYNCED: GameFrame: sending ", bufferSize - 1, " orders")
		Spring.SendLuaRulesMsg(table.concat(messageBuffer))
		bufferSize,bufferBytes = 1,1
		messageBuffer = {string.char(214)}
	end
end

--------------------------------------------------------------------------------

if gadget.Initialize then
	local fun = gadget.Initialize
	gadget.Initialize = function(self) Initialize(self) return fun(self) end
else
	gadget.Initialize = Initialize
end

if gadget.GameFrame then
	local fun = gadget.GameFrame
	-- Call the user GameFrame first, and only then the framework GameFrame.
	-- This way as much orders can be combined into a single message as possible,
	-- assuming sometime orders will be given from inside the user GameFrame.
	gadget.GameFrame = function(self, f) fun(self, f) return GameFrame(self, f) end
else
	gadget.GameFrame = GameFrame
end

end
