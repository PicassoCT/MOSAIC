-- Run from the repository root with Lua 5.1.
local function read(path)
    local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end
local function evaluate(path, env)
    local fn=assert(loadstring(read(path),"@"..path)); setfenv(fn,env); return fn()
end
local e=setmetatable({}, {__index=_G})
e.VFS={Include=function(path) return evaluate(path,e) end}
local dialogue=evaluate("scripts/lib_civilian_dialogue.lua",e)
local conspiracy=evaluate("scripts/lib_civilian_conspiracy.lua",e)
local memory={kind="shopping",place="on Test Street"}
local ordinary=dialogue.build(123,memory,{conspiracyChance=0})
local expanded,kind=dialogue.build(123,memory,{forceConspiracy=true,links=20})
assert(kind=="conspiracy" and #expanded==46,"long arguments must retain full event exchange")
for i=1,4 do assert(expanded[i]==ordinary[i],"existing personal-event content lost") end
local encoded=table.concat(expanded,"\n")
assert(encoded:find("Test Street",1,true) and not encoded:find("{%w+}"),"memory/slot integration")
assert(table.concat(dialogue.build(123,memory,{forceConspiracy=true,links=20}),"\n")==encoded,"nondeterministic dialogue")
assert(table.concat(dialogue.build(124,memory,{forceConspiracy=true,links=20}),"\n")~=encoded,"no variation")
math.randomseed(844); local expected=math.random()
math.randomseed(844); dialogue.build(77,memory,{forceConspiracy=true}); assert(math.random()==expected,"dialogue consumed gameplay RNG")
local natural,short,long,outputs=0,false,false,{}
for seed=1,1000 do
    local lines,mode=dialogue.build(seed,nil)
    if mode=="conspiracy" then natural=natural+1 end
    local rant=conspiracy.build(seed,nil)
    assert(#rant%2==0 and #rant>=10 and #rant<=42,"unbounded or malformed exchange")
    short=short or #rant<=18; long=long or #rant>=34
    for _,line in ipairs(rant) do assert(type(line)=="string" and #line>0,"empty turn") end
    outputs[table.concat(rant,"\n")]=true
end
assert(natural>0 and natural<100,"conspiracies should be occasional and reachable")
assert(short and long,"short and extended arguments must both be reachable")
local unique=0; for _ in pairs(outputs) do unique=unique+1 end
assert(unique>990,"procedural variety collapsed")
assert(#conspiracy.legacyRant(42)==43,"legacy long rant API lost")
assert(dialogue.lineFrames(string.rep("x",300),150)>150,"long lines require readable pacing")

-- Execute the actual life manager through expiry, danger and changed partners.
local frame,emitted,units=0,{}, {[10]=true,[11]=true,[12]=true}
local config=evaluate("luarules/configs/civilian_daily_life.lua",e)
config.conspiracyChance=100
local states={}
e.GG={CivilianTable={},BuildingTable={},BusesTable={},CivilianUnitInternalLogicActive=states,
    GlobalGameState="anarchy"} -- suppress automatic calls/vehicles while explicitly exercising sessions
e.Game={mapName="Conspiracy test",mapSizeX=2048,mapSizeZ=2048}
e.UnitDefs={}; e.CMD={}; e.CMD_CIVILIAN_BLEND=34971
e.Spring={GetGaiaTeamID=function()return 0 end,GetGameFrame=function()return frame end,
    ValidUnitID=function(id)return units[id] end,GetUnitIsDead=function(id)return not units[id] end,
    GetUnitPosition=function()return 100,0,100 end,
    UnitScript={GetScriptEnv=function()return nil end}}
e.SendToUnsynced=function(_,speaker,partner,text,rate)
    emitted[#emitted+1]={speaker=speaker,partner=partner,text=text,rate=rate}
end
e.VFS.Include=function(path)
    if path=="luarules/configs/civilian_daily_life.lua" then return config end
    if path=="scripts/lib_civilian_dialogue.lua" then return dialogue end
    if path=="luarules/configs/commandsIDs.lua" then return end
    return evaluate(path,e)
end
local context={gameConfig={game={states={normal="normal"}},civilians={activityStates={started="started"}}},walkers={},trucks={}}
local life=evaluate("luarules/gadgets/include/civilian_daily_life.lua",e)(context)
local function talking(id,behaviour) states[id]={state="started",behaviour=behaviour or "talk"} end
local function tick(seconds)
    for _=1,seconds do frame=frame+30; life:Frame(frame) end
end
talking(10); talking(11); talking(12)
life:Register(10); life:Register(11); life:Register(12)
life:Conversation(10,11,600)
local thread=assert(life.people[10].conspiracyThread)
local original=table.concat(thread.lines,"\n")
tick(1); assert(thread.next==2 and emitted[1].speaker==10,"first claim missing")
life:Interrupt(10)
local count=#emitted; tick(1); assert(#emitted==count,"interrupted conversation still emitted")
assert(life.people[10].conspiracyThread==thread and thread.next==2,"interruption dropped unheard reply")
-- Same speaker, new listener. Recap first; the pending reply belongs to listener.
life:Conversation(10,12,600); tick(1)
assert(emitted[#emitted].speaker==10 and emitted[#emitted].text:find("About what I was saying:",1,true))
local pending=thread.next; tick(13)
assert(thread.next>pending and emitted[#emitted].speaker==12,"speaker parity lost on continuation")
life:Interrupt(10)
local checkpoint=thread.next
life:Remember(10,"injured",100,100)
talking(10,"phone"); life:Conversation(10,nil,600); tick(20)
assert(thread.next==checkpoint,"fresh injury should interrupt, not overwrite, the argument")
assert(life.people[10].conspiracyThread==thread and table.concat(thread.lines,"\n")==original)
local resumed=false
for attempt=1,100 do
    if not life.people[10].conspiracyThread then break end
    talking(10,"phone"); life:Conversation(10,nil,600); tick(20)
    resumed=resumed or thread.next>checkpoint
end
assert(resumed and not life.people[10].conspiracyThread,"long argument never completes across short calls")
local delivered={}
for _,line in ipairs(emitted) do
    local text=line.text:gsub("^Phone: ","")
    if not text:find("About what I was saying:",1,true) then delivered[text]=(delivered[text] or 0)+1 end
end
for _,line in ipairs(thread.lines) do assert(delivered[line]==1,"lost or repeated authored turn: "..line) end

-- Non-speaking states must stop text even while their internal state is started.
talking(10); talking(11); life:Conversation(10,11,600); tick(1)
states[10].behaviour="fleeing"; count=#emitted; tick(10)
assert(#emitted==count,"speech continued during fleeing")
local surviving=life.people[10].conspiracyThread
assert(surviving,"fleeing erased pending content")
units[10]=nil; life:UnitDestroyed(10); assert(not life.people[10],"dead civilian retained thread")
print("PASS conspiracy dialogue: variation, determinism, retained event content, full legacy rant, readable pacing, interruption/resumption, speaker parity, and cleanup")
