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

    Spring.Echo("{ name = 'decoBuilding', x ="..args[1]..", z ="..args[3].." , rot = \"0\" ,scale = 1.000000 },")


end