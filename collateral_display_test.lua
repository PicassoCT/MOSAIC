-- Run from repository root: texlua tests/collateral_display_test.lua
-- Optional first argument selects an earlier gadget to reproduce the defect.
local path=(arg and arg[1]) or 'luarules/gadgets/game_collateral.lua'
local frame,actions,drawn=30,{},{}
local function loadGadget(env)
    setmetatable(env,{__index=_G})
    env.gadget={}
    local chunk
    if setfenv then chunk=setfenv(assert(loadfile(path)),env)
    else chunk=assert(loadfile(path,'t',env)) end
    chunk()
    return env.gadget
end
local ui={
    gadgetHandler={
        IsSyncedCode=function() return false end,
        AddSyncAction=function(_,name,callback) actions[name]=callback end,
    },
    GetInfo=function() return {name='Collateral display test'} end,
    Spring={
        GetGameFrame=function() return frame end,
        GetLocalTeamID=function() return 1 end,
        GetGaiaTeamID=function() return 0 end,
        GetAllUnits=function() return {17} end,
        GetUnitTeam=function() return 0 end,
        GetUnitPosition=function() return 100,0,100 end,
        WorldToScreenCoords=function(x,y) return x,y end,
        Echo=function() end,
    },
    gl={
        Color=function() end,
        Text=function(text,x,y,size,format)
            drawn[#drawn+1]={text=text,size=size,format=format}
        end,
    },
}
local renderer=loadGadget(ui)
renderer:Initialize()
local function display(message)
    drawn={}
    actions.DisplaytAtUnit('DisplaytAtUnit',17,1,message,1,1,1,1)
    renderer:DrawScreenEffects()
    assert(#drawn==1,'floating message did not reach gl.Text exactly once')
    return drawn[1]
end
local red='\255\255\34\12 $ '
local green='\255\171\236\183 $ '
for _,case in ipairs({
    {-540.00201,red..'-540'}, -- exact magnitude reported in the screenshot
    {-540.99999,red..'-540'}, -- truncate magnitude, do not increase the fine
    {540.99999,green..'540'},
    {-1.25,red..'-1'},
    {-.75,red..'0'},          -- keep debit color without rendering "-0"
    {.75,green..'0'},
    {0,green..'0'},
    {-540,red..'-540'},
    {1250000.99,green..'1250000'},
}) do
    local result=display(case[1])
    assert(result.text==case[2],
        'floating amount '..case[1]..' expected '..case[2]..', got '..result.text)
    assert(result.size==16 and result.format=='od','money label style changed')
end
local explanation='Collateral: -13 HP'
local notice=display(explanation)
assert(notice.text==explanation and notice.size==10,
    'non-monetary messages were parsed or reformatted')

-- Exercise the real synced gadget entry points through the unsynced receiver.
-- Collector accounting is spied at its Charge boundary; the formatter must
-- not round the damage passed there, bank credits, or per-second aggregation.
local charges,credits,events={},{},{}
local synced={
    GG={},UnitDefs={},UnitDefNames={},
    gadgetHandler={IsSyncedCode=function() return true end},
    getGameConfig=function()
        return {economy={propaganda={serverMultiplier=.1},
            collateral={houseDestructionMoney=500}}}
    end,
    getExemptFromRefundTypes=function() return {} end,
    getCultureUnitModelNames_Dict_DefIDName=function() return {} end,
    getChemTrailInfluencedTypes=function() return {} end,
    getChemTrailTypes=function() return {} end,
    VFS={Include=function(name)
        if name=='luarules/configs/collateral.lua' then
            return {collectionIntervalFrames=5}
        elseif name=='luarules/gadgets/include/collateral_collection.lua' then
            return function()
                return {
                    Initialize=function() end,
                    Collect=function() end,
                    Charge=function(_,team,amount,source)
                        charges[#charges+1]={team=team,amount=amount,source=source}
                    end,
                }
            end
        end
        -- Game utility functions above are isolated from unrelated systems.
    end},
    Spring={
        GetGameFrame=function() return frame end,
        GetGaiaTeamID=function() return 0 end,
        GetTeamList=function() return {0,1,2} end,
        AreTeamsAllied=function(a,b) return a==b end,
        AddTeamResource=function(team,resource,amount)
            credits[#credits+1]={team=team,amount=amount}
        end,
    },
    SendToUnsynced=function(name,id,team,amount,...)
        events[#events+1]={name=name,id=id,team=team,amount=amount,args={...}}
    end,
}
local bank=loadGadget(synced)
bank:Initialize()
bank:UnitDamaged(17,13,0,270.001005,false,1,nil,88,20,1)
bank:UnitDamaged(17,13,0,270.001005,false,1,nil,88,20,1)
synced.GG.Bank:TransferToTeam(12.987,1,22)
synced.GG.Bank:TransferToTeam(-12.987,1,23)
bank:GameFrame(frame)
assert(charges[1].amount==270.001005 and charges[2].amount==270.001005
    and charges[3].amount==12.987,'display rounding changed the assessed fine')
assert(credits[3].amount==12.987,'display rounding changed the credited bank transfer')
local sawDamage,sawCredit,sawDebit=false,false,false
for _,event in ipairs(events) do
    if event.team==1 and event.id==17 then
        assert(math.abs(event.amount+540.00201)<.00000001,
            'damage aggregation lost fractional precision before presentation')
        assert(display(event.amount).text==red..'-540',
            'actual accumulated damage did not render as the requested integer')
        sawDamage=true
    elseif event.team==1 and event.id==22 then
        assert(event.amount==12.987 and display(event.amount).text==green..'12',
            'bank credit failed to preserve precise accounting and integer display')
        sawCredit=true
    elseif event.team==1 and event.id==23 then
        assert(event.amount==-12.987 and display(event.amount).text==red..'-12',
            'bank debit failed to preserve precise accounting and integer display')
        sawDebit=true
    end
end
assert(sawDamage and sawCredit and sawDebit,'synced damage or bank event did not reach display')
print('PASS: signed integer money labels, exact screenshot amount, no negative zero, preserved messages and precise damage/bank accounting')
