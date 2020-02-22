
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
    --  {
	--	key  = 'classic',
	--	name = 'Classic',
	--	desc = 'An older pathfinding system without turninplace or reverse',
    --  }
    },
  },


}

--// add key-name to the description (so you can easier manage modoptions in springie)
for i=1,#options do
  local opt = options[i]
  opt.desc = opt.desc .. '\nkey: ' .. opt.key
end

return options
