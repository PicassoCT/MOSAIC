-- Run from the repository root: lua5.1 tests/orbital_arrival_survey.lua
-- Independent forward camera transforms verify the production inverse fit;
-- renderer spies then verify real map API calls, caching and optional failure.
local function read(path)
  local file=assert(io.open(path)); local source=file:read('*a'); file:close(); return source
end
local A=assert(loadstring(read('luaui/widgets_mosaic/include/orbital_arrival.lua')))()
local function near(a,b,message)
  assert(math.abs(a-b)<1e-7,(message or 'projection mismatch')..': '..tostring(a)..' / '..tostring(b))
end
local function forward(matrix,u,v)
  local denominator=matrix[7]*u+matrix[8]*v+matrix[9]
  return (matrix[1]*u+matrix[2]*v+matrix[3])/denominator,
    (matrix[4]*u+matrix[5]*v+matrix[6])/denominator
end
local mapCorners={{0,0},{1,0},{1,1},{0,1}}
local transforms={
  {1,0,0,0,1,0,0,0,1},                         -- identical screen/map axes
  {1,0,0,0,-1,1,0,0,1},                        -- common north-up ground view
  {0,-1,1,1,0,0,0,0,1},                        -- quarter-turn camera
  {0.68,0.22,-0.13,-0.17,0.54,0.32,0,0,1},      -- scale, shear and offscreen corner
  {1.2,0.35,0.08,-0.08,0.78,0.12,0.45,0.18,1},  -- perspective camera
  {-0.81,0.25,0.87,-0.21,-0.71,0.94,-0.26,0.13,1},
}
local function checkInverse(rows,matrix)
  for uIndex=0,8 do for vIndex=0,8 do
    local u,v=uIndex/8,vIndex/8
    local x,y=forward(matrix,u,v)
    local denominator=rows[3][1]*x+rows[3][2]*y+rows[3][3]
    near((rows[1][1]*x+rows[1][2]*y+rows[1][3])/denominator,u,'map U at interior sample')
    near((rows[2][1]*x+rows[2][2]*y+rows[2][3])/denominator,v,'map V at interior sample')
  end end
end
for _,matrix in ipairs(transforms) do
  local corners={}
  -- Deliberately reorder the observations; the solver must fit their values,
  -- rather than assuming a particular winding or affine approximation.
  for _,index in ipairs({3,1,4,2}) do
    local uv=mapCorners[index]; local x,y=forward(matrix,uv[1],uv[2])
    corners[#corners+1]={x,y,uv[1],uv[2]}
  end
  local rows={A.surveyRows(corners)}
  assert(#rows==3,'valid rotated/perspective survey was rejected')
  checkInverse(rows,matrix)
end
assert(A.surveyRows(nil)==nil)
assert(A.surveyRows({{0,0,0,0}})==nil)
for _,corners in ipairs({
  {{0,0,0,0},{0,0,1,0},{0,0,1,1},{0,0,0,1}},
  {{0,0,0,0},{1,1,1,0},{2,2,1,1},{3,3,0,1}},
  {{0/0,0,0,0},{1,0,1,0},{1,1,1,1},{0,1,0,1}},
  {{0,0,0,0},{math.huge,0,1,0},{1,1,1,1},{0,1,0,1}},
}) do assert(A.surveyRows(corners)==nil,'invalid or degenerate projection was accepted') end

local noop=function() end
local function harness(config)
  config=config or {}
  local state={config=config,viewW=1920,viewH=1080,worldCalls={},groundCalls={},
    infoCalls=0,cameraCalls=0,textureAttempts=0,createdTextures={},deletedTextures={},
    createdShaders={},deletedShaders={},shaderKinds={},uniforms={},quadCalls={},
    surveyPasses=0,earthPasses=0,bindings={},matrixMode=4,matrixDepth={[3]=0,[4]=0},
    activeShader=0,blend=true,nextId=0}
  local function id() state.nextId=state.nextId+1; return state.nextId end
  local function forbiddenCamera()
    state.cameraCalls=state.cameraCalls+1; error('Unexpected camera access')
  end
  Game={mapName='Survey fixture',gameID='map-geometry-01',mapChecksum=392113,
    mapSizeX=8192,mapSizeZ=4096}
  if config.mapSizeX~=nil then Game.mapSizeX=config.mapSizeX end
  Spring={Echo=noop,
    GetCameraState=forbiddenCamera,GetCameraPosition=forbiddenCamera,
    GetCameraVectors=forbiddenCamera,GetCameraRotation=forbiddenCamera,
    SetCameraState=forbiddenCamera,SetCameraPosition=forbiddenCamera,
    GetViewGeometry=function() return state.viewW,state.viewH,137,61 end,
    GetGroundHeight=function(x,z)
      state.groundCalls[#state.groundCalls+1]={x,z}
      if config.groundError then error('ground API unavailable') end
      if config.groundInvalid then return 0/0 end
      return 67
    end,
    WorldToScreenCoords=function(x,y,z)
      state.worldCalls[#state.worldCalls+1]={x,y,z}
      if config.projectionError then error('projection API unavailable') end
      if config.degenerate then return 0,0 end
      if config.nonfinite then return math.huge,0 end
      local sx,sy=forward(config.forward or transforms[5],x/Game.mapSizeX,z/Game.mapSizeZ)
      -- These are viewport-local pixels. The nonzero window origin above must
      -- never be subtracted, and raw map V is positive world Z / mapSizeZ.
      return sx*state.viewW,sy*state.viewH,0.5
    end,
  }
  if config.noProjectionAPI then Spring.WorldToScreenCoords=nil end
  if config.noGroundAPI then Spring.GetGroundHeight=nil end
  VFS={LoadFile=function(path)
    if config.missingSurveySource and path=='luaui/widgets_mosaic/shaders/orbital_arrival_survey.frag' then return nil end
    return read(path)
  end}
  GL={LINEAR=1,CLAMP_TO_EDGE=2,PROJECTION=3,MODELVIEW=4}
  gl={
    CreateShader=function(options)
      local kind=options.uniformInt.mapTex~=nil and 'survey'
        or options.uniformInt.surveyTex~=nil and 'earth' or 'composite'
      if kind=='survey' then
        if config.shaderError then error('optional shader rejected') end
        if config.shaderMissing then return nil end
      end
      local shader=id(); state.createdShaders[shader]=true; state.shaderKinds[shader]=kind
      return shader
    end,
    DeleteShader=function(shader)
      assert(state.createdShaders[shader],'deleted an unowned shader')
      state.deletedShaders[shader]=(state.deletedShaders[shader] or 0)+1
    end,
    GetShaderLog=function() return 'test shader log' end,
    GetUniformLocation=function(shader,name) return tostring(shader)..'/'..name end,
    Uniform=function(location,...) state.uniforms[location]={...} end,
    UniformInt=function(location,...) state.uniforms[location]={...} end,
    CreateTexture=function(w,h,options)
      state.textureAttempts=state.textureAttempts+1
      if state.textureAttempts==2 then
        if config.textureError then error('optional target allocation rejected') end
        if config.textureMissing then return nil end
      end
      local texture=id(); state.createdTextures[texture]={w,h}; return texture
    end,
    DeleteTexture=function(texture)
      assert(state.createdTextures[texture],'deleted an engine-owned map texture')
      state.deletedTextures[texture]=(state.deletedTextures[texture] or 0)+1
    end,
    TextureInfo=function(texture)
      assert(texture=='$minimap','survey read an unexpected map/LOS/unit texture')
      state.infoCalls=state.infoCalls+1
      if config.infoError then error('map texture info unavailable') end
      if config.noMinimap then return nil end
      if config.emptyMinimap then return {xsize=0,ysize=0} end
      return {xsize=1024,ysize=1024}
    end,
    Texture=function(unit,texture)
      if texture=='$minimap' then
        if config.bindError then error('map texture binding rejected') end
        if config.bindFalse then return false end
      end
      state.bindings[unit]=texture
      -- nil is a normal void result in API-compatible harnesses.
      return nil
    end,
    RenderToTexture=function(texture,fn)
      local survey=texture~=state.renderer.orbitTexture
      if survey then
        state.surveyPasses=state.surveyPasses+1
        if config.fboError then error('optional framebuffer rejected') end
        if config.fboFalse then return false end
        if config.fboNoCallback then return nil end
      else state.earthPasses=state.earthPasses+1 end
      fn()
      if survey and config.fboFalseAfterDraw then return false end
      return nil
    end,
    MatrixMode=function(mode) state.matrixMode=mode end,
    PushMatrix=function() state.matrixDepth[state.matrixMode]=state.matrixDepth[state.matrixMode]+1 end,
    PopMatrix=function()
      assert(state.matrixDepth[state.matrixMode]>0,'optional render cleanup popped an unowned matrix')
      state.matrixDepth[state.matrixMode]=state.matrixDepth[state.matrixMode]-1
    end,
    LoadIdentity=noop,Clear=noop,Color=noop,
    Blending=function(value) state.blend=value end,
    UseShader=function(shader) state.activeShader=shader end,
    TexRect=function(...)
      local kind=state.shaderKinds[state.activeShader]
      if kind=='survey' and config.drawError then error('optional draw rejected') end
      state.quadCalls[#state.quadCalls+1]={kind=kind,args={...}}
    end,
  }
  if config.noTextureInfo then gl.TextureInfo=nil end
  local renderer=assert(A.newRenderer(),'optional map feature aborted renderer creation')
  state.renderer=renderer
  return state,renderer
end
local function verifyState(state)
  assert(state.matrixDepth[GL.MODELVIEW]==0 and state.matrixDepth[GL.PROJECTION]==0,
    'optional survey leaked a matrix stack')
  assert(state.matrixMode==GL.MODELVIEW and state.activeShader==0 and state.blend,
    'optional survey leaked active shader, matrix mode or blending')
  for unit=0,2 do assert(not state.bindings[unit],'map survey leaked a texture binding') end
  assert(state.cameraCalls==0,'survey read or changed the game camera state')
  for _,quad in ipairs(state.quadCalls) do
    assert(#quad.args==8,'renderer relied on implicit TexRect orientation')
    assert(quad.args[5]==0 and quad.args[6]==0 and quad.args[7]==1 and quad.args[8]==1,
      'survey/composite quad mirrored an explicit texture axis')
  end
end
local function dispose(state,renderer)
  renderer:destroy(); renderer:destroy()
  for texture in pairs(state.createdTextures) do
    assert(state.deletedTextures[texture]==1,'owned texture leaked or was deleted twice')
  end
  for shader in pairs(state.createdShaders) do
    assert(state.deletedShaders[shader]==1,'owned shader leaked or was deleted twice')
  end
end

local state,renderer=harness()
assert(renderer:draw(1920,1080,'',10,1,0,'clean-live-frame'))
assert(renderer.surveyTexture,'valid clean map survey was unavailable')
assert(state.uniforms[tostring(renderer.earth)..'/hasSurvey'][1]==1)
assert(#state.worldCalls==4 and #state.groundCalls==1 and state.infoCalls==1)
near(state.groundCalls[1][1],4096); near(state.groundCalls[1][2],2048)
local actualCorners={}
for _,call in ipairs(state.worldCalls) do
  near(call[2],67,'map corners were projected at different ground levels')
  actualCorners[tostring(call[1])..'/'..tostring(call[3])]=true
end
for _,uv in ipairs(mapCorners) do
  assert(actualCorners[tostring(uv[1]*8192)..'/'..tostring(uv[2]*4096)],'wrong raw map-world axes')
end
checkInverse({state.uniforms[tostring(renderer.survey)..'/mapRow0'],
  state.uniforms[tostring(renderer.survey)..'/mapRow1'],
  state.uniforms[tostring(renderer.survey)..'/mapRow2']},transforms[5])
local originalSurvey=renderer.surveyTexture
for i=1,12 do assert(renderer:draw(1920,1080,'',10+i/100,1,0,'clean-live-frame')) end
for stage=2,4 do
  local progress=(A.blendSeconds+(stage-1)*A.stepSeconds)/A.descentSeconds
  assert(renderer:draw(1920,1080,'',11+stage/10,1,progress,'clean-live-frame'))
end
assert(state.surveyPasses==1 and state.infoCalls==1 and #state.worldCalls==4,
  'held frames, post pass or optical cuts repeated map projection')
assert(renderer.surveyTexture==originalSurvey,'optical cuts changed the ground survey')

local oldOrbit=renderer.orbitTexture
state.viewW,state.viewH=1921,1080
assert(renderer:draw(state.viewW,state.viewH,'',12,1,0.5,'clean-live-frame'))
assert(#state.worldCalls==8 and state.surveyPasses==2,'viewport resize reused stale map projection')
assert(state.deletedTextures[originalSurvey]==1 and state.deletedTextures[oldOrbit]==1,
  'viewport resize leaked replaced render targets')
local resizedSurvey=renderer.surveyTexture
assert(renderer:draw(state.viewW,state.viewH,'',1,1,0,'clean-live-frame'))
assert(#state.worldCalls==12 and state.surveyPasses==3,'clock reset retained a stale map projection')
assert(state.deletedTextures[resizedSurvey]==1,'clock reset leaked its previous survey')
verifyState(state); dispose(state,renderer)

local failureCases={
  {name='projection API absent',noProjectionAPI=true},
  {name='ground API absent',noGroundAPI=true},
  {name='texture info API absent',noTextureInfo=true},
  {name='map width zero',mapSizeX=0},
  {name='map width invalid',mapSizeX=0/0},
  {name='survey source absent',missingSurveySource=true},
  {name='survey shader unavailable',shaderMissing=true},
  {name='survey shader throws',shaderError=true},
  {name='map texture unavailable',noMinimap=true},
  {name='map texture empty',emptyMinimap=true},
  {name='map texture info throws',infoError=true},
  {name='ground sample throws',groundError=true},
  {name='ground sample invalid',groundInvalid=true},
  {name='projection throws',projectionError=true},
  {name='projection degenerate',degenerate=true},
  {name='projection nonfinite',nonfinite=true},
  {name='optional target allocation fails',textureMissing=true},
  {name='optional target allocation throws',textureError=true},
  {name='minimap bind returns false',bindFalse=true},
  {name='minimap bind throws',bindError=true},
  {name='optional FBO returns false',fboFalse=true},
  {name='optional FBO throws',fboError=true},
  {name='optional FBO skips callback',fboNoCallback=true},
  {name='optional FBO fails after draw',fboFalseAfterDraw=true},
  {name='optional quad draw throws',drawError=true},
}
for _,config in ipairs(failureCases) do
  local s,r=harness(config)
  local ok,result=pcall(r.draw,r,1920,1080,'',1,1,0,'clean-live-frame')
  assert(ok and result,config.name..': optional map path aborted arrival: '..tostring(result))
  assert(not r.surveyTexture,config.name..': invalid survey was retained')
  assert(s.uniforms[tostring(r.earth)..'/hasSurvey'][1]==0,
    config.name..': procedural fallback was not selected')
  local attempts=s.textureAttempts; local passCount=s.surveyPasses
  assert(r:draw(1920,1080,'',1.01,1,0,'clean-live-frame'))
  assert(s.textureAttempts==attempts and s.surveyPasses==passCount,
    config.name..': failed optional survey retried on every display frame')
  verifyState(s); dispose(s,r)
end
print('PASS: inverse survey for 6 independent camera transforms and 486 grid samples, raw map/viewport coordinates, explicit UVs, once-per-viewport caching, resize/reset cleanup, 25 optional failure paths and no camera state access')
