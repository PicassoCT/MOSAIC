
-- $Id: ModOptions.lua 4642 2009-05-22 05:32:36Z carrepairer $


--  Custom Options Definition Table format
--  NOTES:
--  - using an enumerated table lets you specify the options order

--
--  These keywords must be lowercase for LuaParser to read them.
--
--  key:      the string used in the script.txt
--  name:     the displayed name
--  desc:     the description (could be used as a tooltip)
--  type:     the option type ('list','string','number','bool')
--  def:      the default value
--  min:      minimum value for number options
--  max:      maximum value for number options
--  step:     quantization step, aligned to the def value
--  maxlen:   the maximum string length for string options
--  items:    array of item strings for list options
--  section:  so lobbies can order options in categories/panels
--  scope:    'all', 'player', 'team', 'allyteam'      <<< not supported yet >>>
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Example ModOptions.lua
--

local options = {
    -- do deployment and tactics even work?
    {
        key    = 'gamemode',
        name   = 'Game Mode Configuration',
        desc   = 'Configure game settings.',
        type   = 'section',
    },

    {
        key    = 'startconds',
        name   = 'Start',
        desc   = 'Start condition settings.',
        type   = 'section',
    },
    {
        key    = 'mapsettings',
        name   = 'Map',
        desc   = 'Map settings.',
        type   = 'section',
    },
    {
        key		= "disabledunits",
        name	= "Disable units",
        desc	= "Prevents specified units from being built ingame. Specify multiple units by using + ",
        section	= 'startconds',
        type	= "string",
        def		= "",
    },
    {
        key = 'globallos',
        name = 'Full visibility',
        desc = 'No fog of war, everyone can see the entire map.',
        type = 'bool',
        section = 'startconds',
        def = false,
    },


    {
        key		= "pathfinder",
        name	= "Pathfinder type",
        desc	= "Sets the pathfinding system used by units.",
        type	= "list",
        def		= "standard",
        section	= "experimental",
        items  = {
            {
                key  = 'standard',
                name = 'Standard',
                desc = 'Standard pathfinder',
            },
            {
                key  = 'qtpfs',
                name = 'QTPFS',
                desc = 'New Quadtree Pathfinding System (experimental)',
            },
        },
    },
    {
        key    = "shuffle",
        name   = "Start Boxes",
        desc   = "Start box settings.",
        type   = "list",
        section= 'startconds',
        def    = "auto",
        items  = {
            {
                key  = "off",
                name = "Fixed",
                desc = "Startboxes have a fixed correspondence to teams.",
            },
            {
                key  = "shuffle",
                name = "Shuffle",
                desc = "Shuffle among boxes that would be used.",
            },
            {
                key  = "allshuffle",
                name = "All Shuffle",
                desc = "Shuffle all present boxes.",
            },
            {
                key  = "auto",
                name = "Autodetect",
                desc = "Shuffle if FFA.",
            },
            {
                key  = "disable",
                name = "Start Anywhere",
                desc = "Allow to place anywhere. Boxes are still drawn for reference but are not obligatory.",
            },
        },
    },
    {
        key='setaispawns',
        name='Set AI Spawns',
        desc='Allow players to set the start positions of AIs.',
        type='bool',
        section= 'startconds',
        def=true,
    },
    { -- Might cause desync, check if they occur.
        key    = 'waterlevel',
        name   = 'Manual Water Level',
        desc   = 'How much to raise water level, in elmos.',
        type   = 'number',
        section= 'mapsettings',
        def    = 0,
        min    = -2000,
        max    = 2000,
        step   = 1,
    },

    {
        key    = 'waterpreset',
        name   = 'Water Level',
        desc   = 'Adjusts the water level of the map',
        type   = "list",
        section= 'mapsettings',
        def    = 'manual',
        items  = {
            {
                key  = "manual",
                name = "Manual",
                desc = "Input height manually",
            },
            {
                key  = "dry",
                name = "Dry",
                desc = "Drain the map of water",
            },
            {
                key  = "flooded",
                name = "Flooded",
                desc = "Cover half the map area with water",
            },
        },
    },

}

--// add key-name to the description (so you can easier manage modoptions in springie)
for i=1,#options do
    local opt = options[i]
    opt.desc = opt.desc .. '\nkey: ' .. opt.key
end

return options
