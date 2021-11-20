--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
    return {
        name	= "mapCoords",
        desc	= "Shows the mouse pos of allied players",
        author	= "Floris,jK,TheFatController",
        date	= "31 may 2015",
        license	= "GNU GPL, v2 or later",
        layer	= 5,
        enabled	= true,
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------

function widget:MousePress(x,y,button)

    desc, args = Spring.TraceScreenRay(x,y)
    if desc == "ground" then
        Spring.Echo("{ name = 'decoBuilding', x ="..args[1]..", z ="..args[3].." , rot = \"0\" ,scale = 1.000000 },")
    end

end


function widget:FeatureCreated(id)
    local fdefID= Spring.GetFeatureDefID(id)
    if string.find(FeatureDefs[fdefID].name ,"ad0_") then
        Spring.Echo("fdef: { name = '"..FeatureDefs[fdefID].name .."', x ="..args[1]..", z ="..args[3].." , rot = \"0\" ,scale = 1.000000 },")
    end

end