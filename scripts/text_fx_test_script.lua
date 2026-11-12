include 'lib_OS.lua'
include 'lib_mosaic.lua'
include 'lib_UnitScript.lua'
include 'lib_Animation.lua'
include 'lib_textFx.lua'

-- Ordinary engine model drawing: never register pieces with the neon gadget.
local groups, glyphs, visibleGlyphs = {}, {}, {}
local SIG_EFFECT=1
-- Match the shared performer's signal layout, separate from the text cycle.
SIG_CORE,SIG_HAIR,SIG_INCIRCLE,SIG_TALKHEAD,SIG_GESTE=2,4,8,16,32
SIG_ONTHEMOVE,SIG_TIGLIL,SIG_FLICKER=64,128,256
DirectionArcPoint=piece('DirectionArcPoint')
BallArcPoint=piece('BallArcPoint')
handr,handl,ball=piece('handr'),piece('handl'),piece('ball')
local message='Lorem Ipsum'
textSpinner=piece('text_spin')
sizeSpacingLetter,sizeDownLetter=321,350
function ShowReg(id) if id then Show(id);visibleGlyphs[id]=true end end
function HideReg(id) if id then Hide(id);visibleGlyphs[id]=nil end end
function showTReg(ids) for _,id in ipairs(ids) do ShowReg(id) end end
function hideTReg(ids) for _,id in ipairs(ids) do HideReg(id) end end
function hideResetAllLetters()
    hardResetHologramLetters(glyphs)
end
function restoreMessageOriginalPosition(ids,pos)
    hideResetAllLetters()
    for _,id in ipairs(ids) do
        for axis=1,3 do Move(id,axis,pos[id][axis],0) end
    end
    transitionHologramText(ids,pos,true,400)
end

local tiglilAnimations=include('tigLilAnimation.lua')
local function dance()
    SetSignalMask(SIG_CORE+SIG_TIGLIL)
    local routines={idle_stance_10,idle_stance17,idle_stance_12,tiglilAnimations.idle_stance11}
    while true do
        for _,routine in ipairs(routines) do
            Signal(SIG_HAIR);Signal(SIG_GESTE);Signal(SIG_TALKHEAD);Signal(SIG_INCIRCLE)
            TigLilSetup()
            -- Always present, including daytime and text cleanup/hold periods.
            routine()
        end
    end
end

local function layout(upright,speed)
    hideResetAllLetters();reset(textSpinner,0)
    local slots,leases=allocateHologramSlots(message,groups)
    local ids,pos={}, {unitID=unitID,myMessage=message,messages={message,'Ipsum Lorem'},
        TriLetters=groups,spacing=slots,leases=leases,slotByPiece={},slotPositions={},
        boolUpright=upright,spinnerSpeed=speed~=0 and speed or nil}
    pos.debugTextFx=function(detail) Spring.Echo(string.format('[Text FX test %d] %s',unitID,detail)) end
    for i,id in ipairs(slots) do
        local position={0,upright and 0 or -(i-1)*sizeSpacingLetter,upright and -(i-1)*sizeDownLetter or 0}
        pos.slotPositions[i]=position
        if id~=' ' then
            ids[#ids+1]=id;pos[id]=position;pos.slotByPiece[id]=i
            for axis=1,3 do Move(id,axis,position[axis],0) end
            ShowReg(id)
        end
    end
    -- Match the production upright layout's ground-clearance adjustment.
    if upright and #slots>10 then Move(textSpinner,2,(#slots-10)*sizeDownLetter,0) end
    if speed~=0 then Spin(textSpinner,textSpinnerAxis,speed,0) end
    return ids,pos
end

local function cycle()
    SetSignalMask(SIG_EFFECT)
    local effects=getAllTextFx()
    local cases={{name='plain',upright=false},{name='plain',upright=true}}
    local names={}
    for name in pairs(effects) do names[#names+1]=name end
    table.sort(names)
    for _,name in ipairs(names) do
        cases[#cases+1]={name=name,upright=name=='matrixTextFx' or name=='archProject'}
        if name=='dnaHelix' then cases[#cases+1]={name=name,upright=true} end
    end
    while true do
        for _,degrees in ipairs({0,20,-20}) do
            for _,case in ipairs(cases) do
                local ids,pos=layout(case.upright,math.rad(degrees))
                local note=''
                if case.name=='personalProject' or case.name=='civilianCongaText' then note='; needs a nearby civilian' end
                if case.name=='randomFLickerLetters' then note='; night-only effect' end
                if case.name=='achromaticShivering' then note='; shared effect skips repeated letters in Lorem Ipsum' end
                if case.name=='dnaHelix' then note='; upright back-to-back pairs; uses 20 deg/s when parent rotation is zero' end
                if case.name=='spiralProject' then note='; upright spiral, independent of starting layout' end
                if case.name=='meteorCraterText' then note='; diagonal meteor wake, impact, debris and a terrain-following crater ring' end
                if case.name=='letterTornado' then note='; widening upright cone; letters orbit at least 60 deg/s' end
                if case.name=='heartMonitor' then note='; two travelling ECG pulses, upright letters on one baseline' end
                if case.name=='matrixTextFx' then note='; three fast upright console sweeps' end
                Spring.Echo(string.format('[Text FX test %d] %s | %s | parent Y %d deg/s | full animation, then 5 seconds%s',
                    unitID,case.name,case.upright and 'upright' or 'horizontal',degrees,note))
                Spring.SetUnitRulesParam(unitID,'text_fx_test_mode',case.name,{public=true})
                Spring.SetUnitRulesParam(unitID,'text_fx_test_rotation',degrees,{public=true})
                local effect=effects[case.name]
                if effect then effect(ids,pos,groups) end
                -- Active effects still run to completion. Cleanup gets at
                -- most five seconds; already-hidden glyphs reset immediately.
                if not waitHologramTextCleanup(glyphs,visibleGlyphs,5000) then
                    pos.debugTextFx('cleanup exceeded 5 seconds; letters hidden and hard-reset')
                end
                holdHologramText(ids,pos,5000)
            end
        end
    end
end

function script.Create()
    Spring.SetUnitBlocking(unitID,false)
    Spring.SetUnitNeutral(unitID,true)
    groups=getPieceTableByNameGroups(false,true)
    local ids={}
    for _,id in pairs(Spring.GetUnitPieceMap(unitID)) do ids[#ids+1]=id end
    table.sort(ids)
    for _,id in ipairs(ids) do Hide(id);reset(id,0) end
    for code=65,90 do
        for _,id in ipairs(groups[string.char(code)] or {}) do glyphs[#glyphs+1]=id end
    end
    StartThread(cycle)
    StartThread(dance)
end
function script.Killed()
    Signal(SIG_EFFECT);Signal(SIG_CORE)
    TigLilStopSmoothing()
    return 0
end
