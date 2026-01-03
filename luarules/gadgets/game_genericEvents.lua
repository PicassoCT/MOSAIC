function gadget:GetInfo()
    return {
        name    = "Generic Event",
        desc    = "UnitScript Call Reflection",
        author  = "PicassoCT",
        date    = "3rd of May 2025",
        license = "GPL3",
        layer   = 0,
        version = 1,
        enabled = false
    }
end

local callbacks = {
    "UnitCreated",
    "UnitFinished",
    "UnitReverseBuilt",
    "UnitFromFactory",
    "UnitDestroyed",
    "RenderUnitDestroyed",
    "UnitExperience",
    "UnitIdle",
    "UnitCmdDone",
    "UnitPreDamaged",
    "UnitDamaged",
    "UnitStunned",
    "UnitTaken",
    "UnitGiven",
    "UnitEnteredRadar",
    "UnitEnteredLos",
    "UnitLeftRadar",
    "UnitLeftLos",
    "UnitSeismicPing",
    "UnitLoaded",
    "UnitUnloaded",
    "UnitCloaked",
    "UnitDecloaked",
}

local callBackEventMap = {}

if gadgetHandler:IsSyncedCode() then

    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    function gadget:Initialize()
        for _, v in ipairs(callbacks) do
            local eventName = "on" .. v .. "Event"
            GG[eventName] = {}
            callBackEventMap[v] = eventName
        end
    end

    -------------------------------------------------------------------------
    -- Generic dispatcher
    -------------------------------------------------------------------------
    local function DispatchUnitEvent(eventKey, unitID, ...)
        if not unitID then return end
        local ggEvent = callBackEventMap[eventKey]
        if ggEvent and GG[ggEvent] then
            genericCallUnitFunctionPassArgs(unitID, ggEvent, ...)
        end
    end

    -------------------------------------------------------------------------
    -- Generated gadget callback stubs
    -------------------------------------------------------------------------

    function gadget:UnitCreated(unitID, ...)
        DispatchUnitEvent("UnitCreated", unitID, ...)
    end

    function gadget:UnitFinished(unitID, ...)
        DispatchUnitEvent("UnitFinished", unitID, ...)
    end

    function gadget:UnitReverseBuilt(unitID, ...)
        DispatchUnitEvent("UnitReverseBuilt", unitID, ...)
    end

    function gadget:UnitFromFactory(unitID, ...)
        DispatchUnitEvent("UnitFromFactory", unitID, ...)
    end

    function gadget:UnitDestroyed(unitID, ...)
        DispatchUnitEvent("UnitDestroyed", unitID, ...)
    end

    function gadget:RenderUnitDestroyed(unitID, ...)
        DispatchUnitEvent("RenderUnitDestroyed", unitID, ...)
    end

    function gadget:UnitExperience(unitID, ...)
        DispatchUnitEvent("UnitExperience", unitID, ...)
    end

    function gadget:UnitIdle(unitID, ...)
        DispatchUnitEvent("UnitIdle", unitID, ...)
    end

    function gadget:UnitCmdDone(unitID, ...)
        DispatchUnitEvent("UnitCmdDone", unitID, ...)
    end

    function gadget:UnitPreDamaged(unitID, ...)
        DispatchUnitEvent("UnitPreDamaged", unitID, ...)
    end

    function gadget:UnitDamaged(unitID, ...)
        DispatchUnitEvent("UnitDamaged", unitID, ...)
    end

    function gadget:UnitStunned(unitID, ...)
        DispatchUnitEvent("UnitStunned", unitID, ...)
    end

    function gadget:UnitTaken(unitID, ...)
        DispatchUnitEvent("UnitTaken", unitID, ...)
    end

    function gadget:UnitGiven(unitID, ...)
        DispatchUnitEvent("UnitGiven", unitID, ...)
    end

    function gadget:UnitEnteredRadar(unitID, ...)
        DispatchUnitEvent("UnitEnteredRadar", unitID, ...)
    end

    function gadget:UnitEnteredLos(unitID, ...)
        DispatchUnitEvent("UnitEnteredLos", unitID, ...)
    end

    function gadget:UnitLeftRadar(unitID, ...)
        DispatchUnitEvent("UnitLeftRadar", unitID, ...)
    end

    function gadget:UnitLeftLos(unitID, ...)
        DispatchUnitEvent("UnitLeftLos", unitID, ...)
    end

    function gadget:UnitSeismicPing(unitID, ...)
        DispatchUnitEvent("UnitSeismicPing", unitID, ...)
    end

    function gadget:UnitLoaded(unitID, ...)
        DispatchUnitEvent("UnitLoaded", unitID, ...)
    end

    function gadget:UnitUnloaded(unitID, ...)
        DispatchUnitEvent("UnitUnloaded", unitID, ...)
    end

    function gadget:UnitCloaked(unitID, ...)
        DispatchUnitEvent("UnitCloaked", unitID, ...)
    end

    function gadget:UnitDecloaked(unitID, ...)
        DispatchUnitEvent("UnitDecloaked", unitID, ...)
    end
end
