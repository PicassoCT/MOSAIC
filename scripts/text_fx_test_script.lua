include 'lib_OS.lua'
include 'lib_mosaic.lua'
include 'lib_UnitScript.lua'
include 'lib_Animation.lua'
include 'lib_textFx.lua'

-- Ordinary engine model drawing: never register pieces with the neon gadget.
local groups, glyphs = {}, {}
local SIG_EFFECT=1
local message='Lorem Ipsum'
textSpinner=piece('text_spin')
sizeSpacingLetter,sizeDownLetter=300,350
function ShowReg(id) if id then Show(id) end end
function HideReg(id) if id then Hide(id) end end
function showTReg(ids) for _,id in ipairs(ids) do ShowReg(id) end end
function hideTReg(ids) for _,id in ipairs(ids) do HideReg(id) end end
function hideResetAllLetters()
    for _,id in ipairs(glyphs) do Hide(id);reset(id,0) end
end
function restoreMessageOriginalPosition(ids,pos)
    hideResetAllLetters()
    for _,id in ipairs(ids) do
        for axis=1,3 do Move(id,axis,pos[id][axis],0) end
    end
    transitionHologramText(ids,pos,true,400)
end

local function layout(upright,speed)
    hideResetAllLetters();reset(textSpinner,0)
    local slots,leases=allocateHologramSlots(message,groups)
    local ids,pos={}, {unitID=unitID,myMessage=message,messages={message,'Ipsum Lorem'},
        TriLetters=groups,spacing=slots,leases=leases,slotByPiece={},slotPositions={},
        boolUpright=upright,spinnerSpeed=speed~=0 and speed or nil}
    for i,id in ipairs(slots) do
        local position={0,upright and 0 or -(i-1)*sizeSpacingLetter,upright and -(i-1)*sizeDownLetter or 0}
        pos.slotPositions[i]=position
        if id~=' ' then
            ids[#ids+1]=id;pos[id]=position;pos.slotByPiece[id]=i
            for axis=1,3 do Move(id,axis,position[axis],0) end
            Show(id)
        end
    end
    -- Match the production upright layout's ground-clearance adjustment.
    if upright and #slots>10 then Move(textSpinner,2,(#slots-10)*sizeDownLetter,0) end
    if speed~=0 then Spin(textSpinner,textSpinnerAxis,speed,0) end
    return ids,pos
end

local function runEffect(effect,ids,pos)
    SetSignalMask(SIG_EFFECT)
    if effect then effect(ids,pos,groups) end
    while true do holdHologramText(ids,pos,500) end
end

local function cycle()
    local effects=getAllTextFx()
    local cases={{name='plain',upright=false},{name='plain',upright=true}}
    local names={}
    for name in pairs(effects) do names[#names+1]=name end
    table.sort(names)
    for _,name in ipairs(names) do
        cases[#cases+1]={name=name,upright=name=='matrixTextFx' or name=='archProject'}
        if name=='dnaHelix' or name=='spiralProject' then cases[#cases+1]={name=name,upright=true} end
    end
    while true do
        for _,degrees in ipairs({0,20,-20}) do
            for _,case in ipairs(cases) do
                Signal(SIG_EFFECT)
                local ids,pos=layout(case.upright,math.rad(degrees))
                local note=''
                if case.name=='personalProject' or case.name=='civilianCongaText' then note='; needs a nearby civilian' end
                if case.name=='randomFLickerLetters' then note='; night-only effect' end
                if case.name=='achromaticShivering' then note='; shared effect skips repeated letters in Lorem Ipsum' end
                Spring.Echo(string.format('[Text FX test %d] %s | %s | parent Y %d deg/s | 5 seconds%s',
                    unitID,case.name,case.upright and 'upright' or 'horizontal',degrees,note))
                Spring.SetUnitRulesParam(unitID,'text_fx_test_mode',case.name,{public=true})
                Spring.SetUnitRulesParam(unitID,'text_fx_test_rotation',degrees,{public=true})
                StartThread(runEffect,effects[case.name],ids,pos)
                -- Effects can contain long sleeps. Cancel their worker at the
                -- deadline, then reset every glyph/spin before the next case.
                Sleep(5000)
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
end
function script.Killed() Signal(SIG_EFFECT);return 0 end
