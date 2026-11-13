-- Use the float32 native scheduler, forcing both musical variants and sways.
local f=assert(io.open('tests/tiglil_precision_test.lua'));local source=f:read('*a');f:close()
source=source:sub(1,assert(source:find('local routines={',1,true))-1)
source=source..[=[
local poses=dofile('scripts/lib_tiglil_flute.lua')
local visible,seen={},{}
function ShowReg(id) visible[id]=true end
function HideReg(id) visible[id]=nil end
local function settledPose()
    if not visible[pieceIDs.tlflute] then return end
    for name,pose in pairs(poses) do
        local matches=true
        for pieceName,angles in pairs(pose) do
            local id=pieceIDs[pieceName]
            for axis=1,3 do
                if math.abs(delta(math.rad(angles[axis]),rotations[id][axis],true))>1e-5 then matches=false end
                assert(math.abs((translations[id] or {0,0,0})[axis])<1e-5,'flute grip detached a shoulder or mouthpiece')
            end
        end
        if matches then seen[name]=true end
    end
end
for _,variant in ipairs({1,0}) do
    local choices=0
    math.random=function(lo,hi)
        if lo==0 and hi==2 then return 1 end -- flute branch
        if lo==0 and hi==1 then
            choices=choices+1
            if choices==1 then return variant end
            return choices%2 -- alternate down/up
        end
        return lo
    end
    local complete=false
    StartThread(function() TigLilSetup();library.idle_stance11();complete=true end)
    local deadline=frame+30*120
    while next(threads) do
        assert(frame<deadline,'flute routine stalled');tick();settledPose()
    end
    assert(complete and not visible[pieceIDs.tlflute],'flute did not finish/hide')
end
for name in pairs(poses) do assert(seen[name],'flute variation never reached: '..name) end
print('PASS: both flute routines reach all five settled grips, keep shoulders attached and clean up')
]=]
assert(loadstring(source))()
