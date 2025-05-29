function gadget:GetInfo()
    return {
        name = "Debug",
        desc = "This gadget surveils memory conditions",
        author = "Picasso",
        date = "Sep. 2022",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = false
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_debug.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    --Optimization
    local _recursiveCheckTable = recursiveCheckTable
    local _getSizeInByte = getSizeInByte

    function getUnitScriptEnvSize(unitID, maxDepth)
        env = Spring.UnitScript.GetScriptEnv(unitID)
        if env then return _getSizeInByte(env, maxDepth) end
        return 0
    end

    local growthRatesDefIDPerUnit = {}
    for id,def in pairs (UnitDefs) do
        growthRatesDefIDPerUnit[id] = {}
    end

    function printUnitDefMemoryGrowth()
        echo("")
        echo("==================UnitDefs Average MemoryGrowth Data==================")
        for defID, data in pairs(growthRatesDefIDPerUnit) do
            name = UnitDefs[defID].name
            accumulatedFactor = 0
            for i,udata in pairs(data) do
                accumulatedFactor = accumulatedFactor + udata.rate
            end
            echo(name..":"..(accumulatedFactor/count(data)))
        end
        echo("======================================================================")
    end

    function checkUnitScriptEnvironmentSize(frame)
        if frame % 301 ~= 0 then return end
        local units = Spring.GetAllUnits ( ) 
        local spGetUnitDefID = Spring.GetUnitDefID

         for i=1, #units do
            id = units[i]
                    defID = spGetUnitDefID(id)
                    envSize = getUnitScriptEnvSize(id, 2)
                    if not growthRatesDefIDPerUnit[defID][id] then growthRatesDefIDPerUnit[defID][id] = {size=envSize, rate=0} end
                    growthRate = envSize/growthRatesDefIDPerUnit[defID][id].size
                    growthRatesDefIDPerUnit[defID][id].rate = growthRate
                    growthRatesDefIDPerUnit[defID][id].size = envSize
        end
        printUnitDefMemoryGrowth()
    end

    function checkGlobalTable(frame)
        if frame % 100 == 0 then
        echo("")
        echo("==================GlobalGameTable Data==================")
        nrElments = _recursiveCheckTable(GG, 8192, false)--frame % 1000 == 0)
        echo("GG contains "..nrElments.." elements")
         sizeInByte= _getSizeInByte(GG, 12)
           echo("GG is of size ".. sizeInByte.." bytes")
            echo("==========================================================")
       echo("")
       end
      
    end

    function gadget:GameFrame(frame)
        checkGlobalTable(frame)
        checkUnitScriptEnvironmentSize(frame)
    end
end