-- Exercise world-space mesh capture and carrier mood light without a GL context.
local frame,hidden,cloaked,los,dead,attached,retiring,missing=10,false,false,true,false,true,false,false
local uniforms,draws,transforms={},{},{}
local color
local function record(name,...) transforms[#transforms+1]={name,...} end
local S={GetGameFrame=function()return frame end,
 GetSpectatingState=function()return false,false end,GetMyAllyTeamID=function()return 0 end,
 GetUnitLosState=function()return {los=los} end,ValidUnitID=function()return true end,
 GetUnitIsDead=function()return dead end,GetUnitNoDraw=function()return hidden end,
 GetUnitIsCloaked=function()return cloaked end,
 GetUnitRulesParam=function(_,key)return key=='city_parade_vehicle' and 1 or (retiring and 1 or 0) end,
 GetUnitTransporter=function()return attached and 20 or nil end,
 GetUnitViewPosition=function()return 100+frame,10,300 end,
 GetUnitCollisionVolumeData=function()return 40,30,70 end}
local G={Texture=function(slot)return not (slot==1 and missing) end,
 UniformInt=function(k,v)uniforms[k]=v end,Uniform=function(k,v)uniforms[k]=v end,
 Color=function(...)color={...}end,PushPopMatrix=function(fn)fn()end,
 Scale=function(...)record('scale',...)end,
 Translate=function(...)record('translate',...)end,Rotate=function(...)record('rotate',...)end,
 UnitPiece=function(id,piece)draws[#draws+1]={id=id,piece=piece,strength=uniforms.gain,color=color}end}
local geometry=dofile('scripts/lib_parade_scene_draw.lua')
local capture=dofile('luaui/widgets_mosaic/include/parade_radiance_scene.lua')(S,G,geometry)
local shader={projectToBandLoc='project',texturedLoc='texture',materialMaskedLoc='mask',emissionStrengthLoc='gain'}
local objects={{id=5,parent=20,opacity=.6,color={1,.78,.52},pose={scale=1.6,x=100,y=70,z=300,yaw=30,tilt=5,wingFlap=40},
 template={piece=2,wings={{piece=3,pivot={1,2,3},axis={1,0,0},sign=-1}}}}}
capture.Receive(objects,7);capture.Capture(shader)
assert(#draws==2 and draws[1].strength==.6 and uniforms.mask==1 and uniforms.project==1)
assert(draws[1].color[1]==1 and draws[1].color[2]==.78 and draws[1].color[3]==.52)
local scaled=false;for _,t in ipairs(transforms)do if t[1]=='scale' then assert(t[2]==1.6 and t[3]==1.6 and t[4]==1.6);scaled=true end end
assert(scaled,'sky lantern scale missing from radiance capture')
local capturedTransforms=transforms;transforms={};geometry(G,objects)
assert(#transforms==#capturedTransforms)
for i,t in ipairs(transforms)do for j,v in ipairs(t)do assert(v==capturedTransforms[i][j],'capture pose differs from visible pose')end end
-- Head gaze is shared with radiance just like articulated wings and scale.
local spirit={{id=5,parent=20,opacity=.7,pose={x=0,y=28,z=4,yaw=90,tilt=0,headYaw=-25,headTilt=3},
 template={body=10,head=11,mask=12,headPivot={0,8,0}}}}
capture.Receive(spirit,7);transforms={};capture.Capture(shader)
local gaze=false
for _,t in ipairs(transforms)do if t[1]=='rotate' and t[2]==-25 and t[3]==0 and t[4]==1 then gaze=true end end
assert(gaze,'AI head gaze was omitted from radiance capture')
local visibleTransforms=transforms;transforms={};geometry(G,spirit)
assert(#transforms==#visibleTransforms)
for i,t in ipairs(transforms)do for j,v in ipairs(t)do assert(v==visibleTransforms[i][j])end end
local function empty()draws={};capture.Capture(shader);assert(#draws==0,'hidden/stale source emitted')end
hidden=true;empty();hidden=false
cloaked=true;empty();cloaked=false
los=false;empty();los=true
dead=true;empty();dead=false
attached=false;empty();attached=true
retiring=true;empty();retiring=false
missing=true;empty();missing=false
frame=41;empty();frame=10
capture.Receive({},7);empty()
-- The mood source follows the carrier render position and remains restrained.
local env=setmetatable({Spring=S,gl=G},{__index=_G})
local chunk
if setfenv then chunk=assert(loadfile('luaui/widgets_mosaic/include/radiance_objective_sources.lua'));setfenv(chunk,env)
else chunk=assert(loadfile('luaui/widgets_mosaic/include/radiance_objective_sources.lua','t',env))end
local sources=chunk()
local light=assert(sources.AttachedLights(5,1,'parade_procession',frame)[1])
assert(light.x==110 and light.y>40 and light.range==126 and light.unitID==20)
assert(light.color[1]>light.color[2]*2 and light.color[2]>light.color[3]*2)
assert(light.gain<1 and light.strength<.3,'mood light overwhelms scene')
frame=20;assert(sources.AttachedLights(5,1,'parade_procession',frame)[1].x==120)
for _,mode in ipairs({'hidden','cloaked','los','dead','attached'}) do
 hidden=mode=='hidden';cloaked=mode=='cloaked';los=mode~='los';dead=mode=='dead';attached=mode~='attached'
 assert(#sources.AttachedLights(5,1,'parade_procession',frame)==0,'mood source leaked: '..mode)
end
print('PASS exact scenery capture poses, masked/faded emission, lifecycle and restrained moving amber light')
