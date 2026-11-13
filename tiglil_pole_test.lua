-- Run the actual pole sequence through Recoil-like float32 motion and waits.
local f=assert(io.open('tests/tiglil_precision_test.lua'));local source=f:read('*a');f:close()
source=source:sub(1,assert(source:find('local routines={',1,true))-1)
source=source:gsub("function include%(name%)return dofile%('scripts/'%.%.name%)end",[=[
local capture={}
function include(name)
    local module=dofile('scripts/'..name)
    if name=='lib_tiglil_pole.lua' then
        local play=module.play
        module.play=function(api,stage,rig)
            local original=api.apply
            api.phase=function(name)capture.phase=name end
            api.apply=function(p,ms)
                capture.pose,capture.active=p,ms<=100
                original(p,ms)
            end
            play(api,stage,rig)
            capture.active=false
        end
    end
    return module
end
]=])
source=source..[=[
local function rotation(a)
    local x,y,z=a[1],a[2],a[3]
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return {{cy*cz+sy*sx*sz,-cy*sz+sy*sx*cz,sy*cx},{cx*sz,cx*cz,-sx},{-sy*cz+cy*sx*sz,sy*sz+cy*sx*cz,cy*cx}}
end
local function apply(r,v)return {r[1][1]*v[1]+r[1][2]*v[2]+r[1][3]*v[3],r[2][1]*v[1]+r[2][2]*v[2]+r[2][3]*v[3],r[3][1]*v[1]+r[3][2]*v[2]+r[3][3]*v[3]}end
local visible,shows,hides={},0,0
function ShowReg(id)visible[id]=true;if id==pieceIDs.tlpole then shows=shows+1 end end
function HideReg(id)visible[id]=nil;if id==pieceIDs.tlpole then hides=hides+1 end end
local scale=11060.378906/12
local grips,samples,splitFrames=0,0,0
for _,entryYaw in ipairs({0,.7})do
    StartThread(TigLilSetup);drain(1000)
    rotations[pieceIDs.dancepivot]={0,0,entryYaw}
    translations[pieceIDs.tlpole]={0,0,123}
    local started=frame
    StartThread(dancePole)
    while next(threads)do
        assert(frame-started<30*40,'pole routine stalled');tick()
        if capture.active then
            samples=samples+1;assert(visible[pieceIDs.tlpole],'pole hidden during grip')
            local R=rotation(rotations[pieceIDs.tigLil])
            if capture.phase=='hold overhead split' then
                splitFrames=splitFrames+1
                assert(R[3][3]<-.999,'split torso is not inverted')
                local directions={}
                for _,name in ipairs({'tllegUp','tllegUpR'})do
                    directions[#directions+1]=apply(R,apply(rotation(rotations[pieceIDs[name]]),{0,0,-1}))
                end
                local a,b=directions[1],directions[2]
                assert(a[1]*b[1]+a[2]*b[2]+a[3]*b[3]<-.999,'legs never reach a full split')
                for _,name in ipairs({'tllegLow','tllegLowR'})do
                    near(delta(0,rotations[pieceIDs[name]][1],true),0,1e-5)
                end
                assert(capture.pose.contacts.tlarm and capture.pose.contacts.tlarmr,'split must keep both grips')
            end
            local move=translations[pieceIDs.tigLil]
            local center={.07735+move[1]/scale,.8718+move[2]/scale,12+move[3]/scale}
            local contacts=0
            for _,entry in ipairs({{'tlarm',1,1.86521},{'tlarmr',-1,-1.49415}})do
                local name,sign,shoulderX=entry[1],entry[2],entry[3]
                if capture.pose.contacts[name]then
                    local palm=apply(rotation(rotations[pieceIDs[name]]),{sign*5.1,-.2,.15})
                    local hand=apply(R,{palm[1]+shoulderX,palm[2]-.45105,palm[3]+4.57199})
                    local x,y,z=hand[1]+center[1],hand[2]+center[2],hand[3]+center[3]
                    local radius=math.sqrt((x-.063)^2+(y-1.34855)^2)
                    assert(math.abs(radius-.27124)<.22,'interpolated grip drifted off pole: '..radius)
                    assert(z>.3 and z<24.4,'hand left pole length')
                    contacts=contacts+1;grips=grips+1
                end
            end
            assert(contacts>=1,'no supporting hand')
            for axis=1,3 do near((rotations[pieceIDs.tldancedru]or{0,0,0})[axis],0,1e-5)end
        end
    end
    assert(not visible[pieceIDs.tlpole],'pole leaked after the dance')
    near(delta(entryYaw,rotations[pieceIDs.dancepivot][3],true),0,1e-5)
    near(translations[pieceIDs.tlpole][3],123,1e-5)
    assert(frame-started>30*15,'sequence ended before completing its choreography')
end
assert(samples>600 and grips>1000 and shows==2)
assert(splitFrames>=72,'overhead split did not hold for both performances')
-- The normal hologram stop must terminate this synchronous sequence as well.
unitID,unitDefID,GG=3,4,{}
Move,Turn,StopSpin=api.Move,api.Turn,api.StopSpin
function hideTReg()end
local ids={};for _,id in pairs(pieceIDs)do ids[#ids+1]=id end
local controller=dofile('scripts/lib_hologram_tiglil.lua')({pieces=ids,glowSticks={}})
StartThread(function()SetSignalMask(130);dancePole()end)
for i=1,70 do tick()end
controller.stop();for i=1,3 do tick()end
assert(not next(threads) and not visible[pieceIDs.tlpole],'cancelled pole dance left workers/prop alive')
print('PASS: native pole grips throughout motion, bounded choreography, stationary prop, parent restoration and cancellation')
]=]
assert(loadstring(source))()
