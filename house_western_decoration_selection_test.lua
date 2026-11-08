-- Run from the repository root with Lua 5.1+. Exercise production selection,
-- placement and child lookup; candidate-list indices deliberately differ from
-- the model names. No dependency on a particular model export or piece IDs.
local f=assert(io.open('scripts/house_western_script.lua'))
local source=f:read('*a');f:close()
local function section(first,last)
    local a=assert(source:find(first,1,true))
    return source:sub(a,assert(source:find(last,a+#first,true))-1)
end
local function compile(code,env)
    if setfenv then local fn=assert(loadstring(code));setfenv(fn,env);return fn end
    return assert(load(code,'western decoration test','t',env))
end
local function fixture(chooseOne)
    local names,ids,groups,moves,spins={}, {}, {}, {}, {}
    local function piece(name)
        if not ids[name] then ids[name]=#names+1;names[#names+1]=name end
        return ids[name]
    end
    local function children(name,n)
        local t={};for i=1,n do t[i]=piece(name..i)end;groups[name]=t;return t
    end
    local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
    local env=setmetatable({unitID=1,ToShowTable={},AlreadyUsedPiece={},
        pieceNames=names,pieceIDs=ids,groups=groups,
        count=count,randSign=function()return 1 end,
        math=setmetatable({random=function(a,b)
            if a==0 and b==10 then return chooseOne and 8 or 0 end
            if a==1 and b==32 then return 31 end
            return a
        end},{__index=math}),
        Move=function(p,a,v)assert(p);moves[p]=moves[p] or {};moves[p][a]=v end,
        Turn=function(p)assert(p)end,Spin=function(p)assert(p);spins[p]=true end,
        Sleep=function()end,Show=function()error('assembly should queue reveal')end,
        foreach=function(t,fn)local r={};for _,v in ipairs(t)do local x=fn(v);if x then r[#r+1]=x end end;return r end,
        centerP={x=100,z=200},
    },{__index=_G})
    local code='local TablesOfPiecesGroups=groups;local pieceNr_pieceName=pieceNames;local pieceName_pieceNr=pieceIDs;\n'..
        'local _x_axis,_y_axis,_z_axis=1,2,3;local y_axis=3;local cubeDim={heigth=50,length=10};\n'..
        section('function showOne(T, bNotDelayd)','function showDeployRobot()')..
        section('function removeElementFromBuildMaterial(','function selectGroundBuildMaterial(')..
        section('function DecorateBlockWall(','NotInPlanIndeces = {}')..
        section('function buildDecorateGroundLvl()','function buildDecorateLvl(')..
        section('function decorateBackYard(','logoPiecesToHide = {')
    compile(code,env)()
    local function queued(name)
        local n=0;for _,p in ipairs(env.ToShowTable)do if p==ids[name]then n=n+1 end end;return n
    end
    return env,piece,children,queued,moves,spins
end

-- Reproduce the original offset: slot 31 is Door30 because a material-specific
-- door precedes Door1..Door31. Selecting Door30 must never reveal Door31's logos.
for _,one in ipairs({false,true})do
    local e,p,children,queued,moves=fixture(one)
    local pool={p('ClassicGhetto_Door1')}
    for i=1,31 do pool[#pool+1]=p('Door'..i)end
    children('Door30Sub',2);children('Door31Sub',4)
    local street=p('Classic_Street_Floor_Deco10');children('Classic_Street_Floor_Deco10Sub',1)
    local deco=p('Classic_Street_Floor_DoorDeco20');children('Classic_Street_Floor_DoorDeco20Sub',1)
    local floor=p('ClassicFloorBlock1')
    e.selectGroundBuildMaterial=function()return 'Classic'end
    e.getMaterialElementsContaingNotContaining=function(_,required)
        local key=table.concat(required,',')
        if key=='Street,Floor,Deco' then return {street}end
        if key=='Door' then return pool end
        if key=='Door,Deco' then return {deco}end
        if key=='Block' then return {floor}end
        return {}
    end
    e.decoChances={grafiti=0,street=1,door=1,yard=0}
    e.getOutsideFacingRotationOfBlockFromPlan=function()return 90 end
    e.getLocationInPlan=function(i)return i==1,2,3 end
    e.isBackYardWall=function()return false end
    e.addShadowVoxel=function()end
    e.houseAddDestructionTable=function(t)return t end
    e.LevelPieces={}
    e.buildDecorateGroundLvl()
    assert(queued('Door30')==1 and moves[p('Door30')][1]==-80 and moves[p('Door30')][3]==-170)
    assert(queued('Door31')==0 and not moves[p('Door31')])
    for i=1,4 do assert(queued('Door31Sub'..i)==0,'orphan restaurant logo was selected')end
    local first,second=queued('Door30Sub1'),queued('Door30Sub2')
    assert(first<=1 and second<=1 and first+second==(one and 1 or 2),'child selection policy changed or ran twice')
    assert(queued('Classic_Street_Floor_Deco10Sub1')==1,'street lookup used reversed piece map')
    assert(queued('Classic_Street_Floor_DoorDeco20Sub1')==1,'door-decoration lookup used reversed piece map')
end

-- A sparse/reordered backyard pool must use the selected parent's name too.
do
    local e,p,children,queued,moves=fixture(false)
    children('Yard30Sub',2);children('Yard1Sub',1)
    e.decorateBackYard(1,2,3,{[7]=p('Yard30')},2)
    assert(queued('Yard30')==1 and queued('Yard30Sub1')==1 and queued('Yard30Sub2')==1)
    assert(queued('Yard1Sub1')==0 and moves[p('Yard30')][2]==100)
end

-- Preserve meaningful zeros, normalize padding, retain digits within prefixes,
-- and use the actual singleton spin piece ID when no grouped entry exists.
do
    local e,p,children,queued,_,spins=fixture(false)
    for _,name in ipairs({'Door1','Door10','Door20','Door30','Module10Door20','Back10'})do
        p(name);children(name..'Sub',1)
    end
    for _,name in ipairs({'Door10','Door20','Door30','Module10Door20','Back010'})do
        e.showSubsAnimateSpinsByPiecename(name)
    end
    assert(queued('Door1Sub1')==0)
    for _,name in ipairs({'Door10','Door20','Door30','Module10Door20','Back10'})do
        assert(queued(name..'Sub1')==1,'numeric piece identity changed: '..name)
    end
    local spinner=p('Roof30Spin1')
    e.showSubsAnimateSpinsByPiecename('Roof30')
    assert(queued('Roof30Spin1')==1 and spins[spinner],'singleton spinner used a nonexistent parent name')
end
print('PASS Western decorations: actual ground-floor placement, orphan-logo regression, one/all choices, backyard indices, numeric names and singleton spinners')
