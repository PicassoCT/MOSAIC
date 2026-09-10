----------------------------------------------------------------------------------------------------
-- Temporal dilation post process
----------------------------------------------------------------------------------------------------
function widget:GetInfo()
    return {
        name      = "SlowMo Shader",
        desc      = "Visualizes Hivemind / AI-Core temporal dilation",
        author    = "PicassoCT",
        date      = "September 2026",
        license   = "GNU GPL, v2 or later",
        layer     = math.huge,
        handler   = true,
        enabled   = true,
        hidden    = true,
    }
end

local SHADER_PATH = "luaui/widgets_mosaic/shaders/slowmo/"

local vsx, vsy = 1, 1
local screencopy
local shaderProgram

local targetActive = false
local targetPrivilege = false
local targetSpeed = 0.40
local slowAmount = 0.0

local startTimer
local activationTimer

local resolutionLoc
local realTimeLoc
local slowAmountLoc
local privilegeLoc
local activationAgeLoc

local glUseShader = gl.UseShader
local glCopyToTexture = gl.CopyToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glUniform = gl.Uniform

local function clamp01(value)
    return math.max(0.0, math.min(1.0, value or 0.0))
end

local function setUniform(location, ...)
    if location and location >= 0 then
        glUniform(location, ...)
    end
end

local function deleteScreenTexture()
    if screencopy then
        gl.DeleteTexture(screencopy)
        screencopy = nil
    end
end

local function createScreenTexture()
    deleteScreenTexture()

    screencopy = gl.CreateTexture(vsx, vsy, {
        border = false,
        min_filter = GL.LINEAR,
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE,
        wrap_t = GL.CLAMP_TO_EDGE,
    })

    return screencopy ~= nil
end

function widget:ViewResize(viewSizeX, viewSizeY)
    if not viewSizeX or not viewSizeY then
        viewSizeX, viewSizeY = Spring.GetViewGeometry()
    end

    vsx = math.max(1, viewSizeX)
    vsy = math.max(1, viewSizeY)
    createScreenTexture()
end

function widget:Initialize()
    vsx, vsy = Spring.GetViewGeometry()
    startTimer = Spring.GetTimer()
    activationTimer = startTimer

    if not createScreenTexture() then
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "Unable to create screen texture")
        widgetHandler:RemoveWidget(self)
        return
    end

    local vertexShader = VFS.LoadFile(SHADER_PATH .. "slowmo.vert")
    local fragmentShader = VFS.LoadFile(SHADER_PATH .. "slowmo.frag")

    if not vertexShader or not fragmentShader then
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "Unable to load slow-motion shader files")
        widgetHandler:RemoveWidget(self)
        return
    end

    shaderProgram = gl.CreateShader({
        vertex = vertexShader,
        fragment = fragmentShader,
        uniformInt = {
            screencopy = 0,
        },
        uniformFloat = {
            resolution = {vsx, vsy},
            realTime = 0.0,
            slowAmount = 0.0,
            temporalPrivilege = 0.0,
            activationAge = 10.0,
        },
    })

    if not shaderProgram then
        Spring.Log(widget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    end

    resolutionLoc = gl.GetUniformLocation(shaderProgram, "resolution")
    realTimeLoc = gl.GetUniformLocation(shaderProgram, "realTime")
    slowAmountLoc = gl.GetUniformLocation(shaderProgram, "slowAmount")
    privilegeLoc = gl.GetUniformLocation(shaderProgram, "temporalPrivilege")
    activationAgeLoc = gl.GetUniformLocation(shaderProgram, "activationAge")
end

function widget:Shutdown()
    deleteScreenTexture()

    if shaderProgram then
        gl.DeleteShader(shaderProgram)
        shaderProgram = nil
    end
end

local function setTemporalState(active, privileged, newTargetSpeed)
    local wasActive = targetActive

    targetActive = active == true
    targetPrivilege = privileged == true
    targetSpeed = tonumber(newTargetSpeed) or targetSpeed

    if targetSpeed >= 1.0 then
        targetSpeed = 0.40
    end

    if targetActive and not wasActive then
        activationTimer = Spring.GetTimer()
    end
end

function widget:RecvLuaMsg(msg, playerID)
    if type(msg) ~= "string" then
        return
    end

    local active, privileged, newTargetSpeed = string.match(
        msg,
        "^SlowMoShader|([01])|([01])|([%d%.%-]+)$"
    )

    if active then
        setTemporalState(
            active == "1",
            privileged == "1",
            tonumber(newTargetSpeed)
        )
        return
    end

    -- Backwards compatibility while old replays / gadgets still emit the
    -- pre-2026 binary messages.
    if msg == "SlowMoShader_Active" then
        setTemporalState(true, true, 0.40)
    elseif msg == "SlowMoShader_Deactivated" then
        setTemporalState(false, false, 0.40)
    end
end

function widget:Update(dt)
    local desiredAmount = 0.0

    if targetActive then
        local _, actualSpeed = Spring.GetGameSpeed()
        actualSpeed = tonumber(actualSpeed) or 1.0

        local denominator = math.max(0.001, 1.0 - targetSpeed)
        desiredAmount = clamp01((1.0 - actualSpeed) / denominator)

        -- Give immediate visual acknowledgement while the engine converges
        -- toward the requested speed.
        desiredAmount = math.max(0.12, desiredAmount)
    end

    local blend = math.min(1.0, math.max(0.0, (dt or 0.0) * 7.0))
    slowAmount = slowAmount + (desiredAmount - slowAmount) * blend

    if not targetActive and slowAmount < 0.001 then
        slowAmount = 0.0
    end
end

function widget:DrawScreenEffects()
    if not shaderProgram or not screencopy then
        return
    end

    if not targetActive and slowAmount <= 0.001 then
        return
    end

    glCopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)
    glTexture(0, screencopy)
    glUseShader(shaderProgram)

    local now = Spring.GetTimer()
    local realTime = Spring.DiffTimers(now, startTimer)
    local activationAge = targetActive
        and Spring.DiffTimers(now, activationTimer)
        or 10.0

    setUniform(resolutionLoc, vsx, vsy)
    setUniform(realTimeLoc, realTime)
    setUniform(slowAmountLoc, slowAmount)
    setUniform(privilegeLoc, targetPrivilege and 1.0 or 0.0)
    setUniform(activationAgeLoc, activationAge)

    glTexRect(0, vsy, vsx, 0)

    glUseShader(0)
    glTexture(0, false)
end
