-- Exercise the production synced API and unsynced receiver with the same wire args.
local f=assert(io.open('luarules/gadgets/gfx_neonHolograms.lua'))
local source=f:read('*a');f:close()
local function section(first,last)
    local a=assert(source:find(first,1,true))
    local b=assert(source:find(last,a+#first,true))
    return source:sub(a,b-1)
end
local receiver=assert(loadstring('local objectiveRadiancePieces={}\n'..
    section('    local function setObjectiveRadiancePiece(', '    local function setUnitNeonLuaDraw(')..
    '\nreturn setObjectiveRadiancePiece,unsetObjectiveRadianceUnit,objectiveRadiancePieces'))
local receive,remove,records=receiver()
local frame,sends=100,0
local env=setmetatable({GG={},Spring={GetGameFrame=function()return frame end},
    SendToUnsynced=function(action,...)
        sends=sends+1;assert(action=='setObjectiveRadiancePiece');receive(action,...)
    end},{__index=_G})
local chunk=assert(loadstring('local objectiveRadiancePieces={}\n'..
    section('    function GG.SetObjectiveRadiancePieceVisible(', '    -- TODO: Add bloomstage')))
setfenv(chunk,env);chunk()
local show=env.GG.SetObjectiveRadiancePieceVisible
show(42,7,true,'cloud','gasExplosion')
assert(records[42][7].piece==7 and records[42][7].preset=='gasExplosion' and records[42][7].born==100)
frame=200;show(42,7,true,'cloud','gasExplosion')
assert(sends==1 and records[42][7].born==100,'repeated Show restarted the cooling curve')
show(42,8,true,'material');assert(records[42][8].mode=='material')
show(42,9,true);assert(records[42][9].mode=='diffuse')
show(42,7,false);assert(not records[42][7] and records[42][8])
show(42,7,true,'cloud','gasExplosion');assert(records[42][7].born==200,'new launch reused old lifetime')
frame=300;show(42,7,true,'cloud','risingSmoke')
assert(records[42][7].preset=='risingSmoke' and records[42][7].born==300)
show(42,7,false);show(42,8,false);show(42,9,false);assert(not records[42])
local count=sends;show(42,9,false);assert(sends==count)
show(42,7,true,'cloud','gasExplosion');remove(nil,42);assert(not records[42])
print('PASS: objective mode/preset/clock transfer, repeated Show, new launch, preset switch, hide and unit removal')
