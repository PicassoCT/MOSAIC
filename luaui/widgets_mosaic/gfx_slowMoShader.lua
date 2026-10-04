function widget:GetInfo()
    return {
        name = "SlowMo Shader",
        desc = "Hivemind cognition and world-anchored water ripples during temporal dilation",
        author = "PicassoCT", date = "October 2026", license = "GNU GPL, v2 or later",
        layer = math.huge, enabled = true, hidden = true,
    }
end

local SHADER_PATH = "luaui/widgets_mosaic/shaders/slowmo/"
local Cognition = VFS.Include("luaui/widgets_mosaic/include/hivemind_cognition.lua")
local cognition
local vsx, vsy, vpx, vpy = 1, 1, 0, 0
local screencopy, depthcopy, shaderProgram
local targetActive, targetPrivilege = false, false
local targetSpeed, slowAmount = .40, 0
local previewID, previewLeft
local loc, sourceLoc = {}, {}

local function clamp01(v) return math.max(0,math.min(1,v)) end
local function uniform(name,...)
    if loc[name] and loc[name] >= 0 then gl.Uniform(loc[name],...) end
end
local function deleteTextures()
    if screencopy then gl.DeleteTexture(screencopy);screencopy=nil end
    if depthcopy then gl.DeleteTexture(depthcopy);depthcopy=nil end
end
local function ensureTextures()
    if screencopy then return true end
    screencopy = gl.CreateTexture(vsx,vsy,{
        min_filter=GL.LINEAR,mag_filter=GL.LINEAR,
        wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,
    })
    depthcopy = gl.CreateTexture(vsx,vsy,{
        format=GL.DEPTH_COMPONENT24 or 0x81A6,
        min_filter=GL.NEAREST,mag_filter=GL.NEAREST,
        wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,
    })
    if not screencopy or not depthcopy then
        deleteTextures()
        Spring.Log("SlowMo Shader",LOG.ERROR,"Unable to allocate temporal color/depth textures")
        widgetHandler:RemoveWidget(widget)
        return false
    end
    return true
end

function widget:ViewResize()
    vsx,vsy,vpx,vpy = Spring.GetViewGeometry()
    vsx,vsy,vpx,vpy = math.max(1,vsx),math.max(1,vsy),vpx or 0,vpy or 0
    deleteTextures() -- Allocate lazily only when the effect next draws.
end

function widget:Initialize()
    self:ViewResize()
    cognition = Cognition.New()
    shaderProgram = gl.CreateShader({
        vertex = VFS.LoadFile(SHADER_PATH.."slowmo.vert"),
        fragment = VFS.LoadFile(SHADER_PATH.."slowmo.frag"),
        uniformInt = {screencopy=0,depthcopy=1,sourceCount=0},
        uniformFloat = {
            resolution={vsx,vsy},realTime=0,slowAmount=0,temporalPrivilege=0,
            clipZeroToOne=(Platform and Platform.glSupportClipSpaceControl) and 1 or 0,
        },
    })
    if not shaderProgram then
        Spring.Log("SlowMo Shader",LOG.ERROR,gl.GetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    end
    for _,name in ipairs({"resolution","realTime","slowAmount","temporalPrivilege","sourceCount","viewProjectionInv"}) do
        loc[name] = gl.GetUniformLocation(shaderProgram,name)
    end
    for i=1,Cognition.maxSources do
        sourceLoc[i] = gl.GetUniformLocation(shaderProgram,"rippleSources["..(i-1).."]")
    end
end

function widget:Shutdown()
    deleteTextures()
    if shaderProgram then gl.DeleteShader(shaderProgram);shaderProgram=nil end
end

function widget:UnitCreated(id,defID) if cognition then cognition:UnitCreated(id,defID) end end
function widget:UnitEnteredLos(id) if cognition then cognition:UnitCreated(id) end end
function widget:UnitDestroyed(id) if cognition then cognition:UnitDestroyed(id) end end

function widget:RecvLuaMsg(msg)
    if type(msg) ~= "string" then return end
    local active,privileged,speed=msg:match("^SlowMoShader|([01])|([01])|([%d%.%-]+)$")
    if active then
        targetActive,targetPrivilege=active=="1",privileged=="1"
        targetSpeed=tonumber(speed) or .40
    end
end

function widget:TextCommand(command)
    if command ~= "hivefx" and not command:match("^hivefx%s") then return false end
    local arg=command:match("^hivefx%s+(%S+)")
    if arg=="off" then previewID,previewLeft=nil,nil;return true end
    for _,id in ipairs(Spring.GetSelectedUnits() or {}) do
        if cognition and cognition.known[id] then
            previewID,previewLeft=id,math.max(1,math.min(60,tonumber(arg) or 15))
            Spring.Echo("Hivemind visual preview: "..previewLeft.."s (local effects only). /hivefx off to stop.")
            return true
        end
    end
    Spring.Echo("Select a Hivemind or AI-Core, then /hivefx [seconds].")
    return true
end

function widget:Update(dt)
    if not cognition then return end
    local _,actualSpeed,paused=Spring.GetGameSpeed()
    dt=paused and 0 or math.max(0,dt or 0)
    -- Rules params are the authority and survive a LuaUI reload/missed message.
    local active=Spring.GetGameRulesParam("slowMoActive")
    if active ~= nil then
        targetActive=active==1
        targetPrivilege=Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"slowMoPrivileged")==1
        targetSpeed=tonumber(Spring.GetGameRulesParam("slowMoTargetSpeed")) or .40
    end
    if previewLeft then
        previewLeft=previewLeft-dt
        if previewLeft<=0 then previewID,previewLeft=nil,nil end
    end
    local desired=0
    if previewID then desired=1
    elseif targetActive then
        desired=math.max(.12,clamp01((1-(tonumber(actualSpeed) or 1))/math.max(.001,1-targetSpeed)))
    end
    slowAmount=slowAmount+(desired-slowAmount)*math.min(1,dt*7)
    if desired==0 and slowAmount<.001 then slowAmount=0 end
    cognition:Update(dt,targetActive or previewID~=nil,previewID)
end

function widget:DrawWorld()
    if cognition and slowAmount>.001 then cognition:Draw(slowAmount) end
end

function widget:DrawScreenEffects()
    if slowAmount<=.001 or not shaderProgram or not cognition then return end
    if not ensureTextures() then return end
    local sources=cognition:Collect()
    gl.CopyToTexture(screencopy,0,0,vpx,vpy,vsx,vsy)
    gl.CopyToTexture(depthcopy,0,0,vpx,vpy,vsx,vsy)
    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.Blending(false);gl.DepthTest(false);gl.DepthMask(false)
    gl.Texture(0,screencopy);gl.Texture(1,depthcopy)
    gl.UseShader(shaderProgram)
    uniform("resolution",vsx,vsy)
    uniform("realTime",cognition.clock)
    uniform("slowAmount",slowAmount)
    uniform("temporalPrivilege",(targetPrivilege or previewID) and 1 or 0)
    gl.UniformInt(loc.sourceCount,#sources)
    gl.UniformMatrix(loc.viewProjectionInv,"viewprojectioninverse")
    for i,r in ipairs(sources) do gl.Uniform(sourceLoc[i],r.x,r.y,r.z,r.age) end
    gl.TexRect(0,0,vsx,vsy,0,0,1,1)
    gl.UseShader(0)
    gl.Texture(1,false);gl.Texture(0,false)
    gl.PopAttrib()
end
