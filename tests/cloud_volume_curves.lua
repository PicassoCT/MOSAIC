local C=dofile('luarules/gadgets/include/cloud_volume_config.lua')
local keys={{0,0},{2,1},{4,.5}}
assert(C.Curve(keys,-1,9)==0 and C.Curve(keys,1,9)==.5)
assert(C.Curve(keys,99,9)==.5 and C.Curve(nil,0,3)==3)
for name,p in pairs(C.presets) do
    for _,field in ipairs({'opacityCurve','densityCurve','emissionCurve','expansionCurve'}) do
        local last=-1
        for _,key in ipairs(p[field] or {}) do
            assert(key[1]>last and key[2]>=0,name..' invalid '..field);last=key[1]
        end
    end
end
local a,d,e=C.Appearance(C.presets.gasExplosion,3)
assert(a>0 and d>0 and e==0,'gas must cool to smoke before disappearing')
assert(C.Appearance(C.presets.gasExplosion,4)==0)
assert(C.Appearance(C.presets.soot,18)>0,'pump smoke must outlast fire')
assert(C.Appearance(C.presets.steam,30)>0,'launch vapour must linger')
assert(C.Appearance(C.presets.steam,45)==0)
assert(C.Appearance(C.presets.fire,999)>0,'steady pump flame must hold')
assert(C.PumpPreset('Smoke12')=='risingSmoke')
local _,_,hot=C.Appearance(C.presets.risingSmoke,2)
local soot,_,cold=C.Appearance(C.presets.risingSmoke,18)
assert(hot>0 and cold==0 and soot>0,'rising smoke must glow, cool, then linger')
assert(C.PumpPreset('Explosion12')=='gasExplosion')
assert(C.PumpPreset('FlameA12')=='flameTongue')
print('PASS: curve interpolation, endpoints, hold, cooling, distinct use-case lifetimes')
