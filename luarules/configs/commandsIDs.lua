--  Proposed Command ID Ranges:
--
--  all negative:  Engine (build commands)
--     0 -   999:  Engine
--  1000 -  9999:  Group AI
-- 10000 - 19999:  LuaUI
-- 20000 - 29999:  LuaCob
-- 30000 - 39999:  LuaRules 
 
CMD_SCATTER = 33658 -- future unit_scatter gadget
CMD_BUILDSPEED = 33455 -- future unit_buildspeed gadget

-- 36000 - 36999:  AI related
-- dynamically injected

CMD_ASSET_ROOFTOP = 33456 -- queued asset roof movement

CMD_STICKY_BUILD = 33457 -- immediate carried bomb production
CMD_STICKY_PLANT = 33458 -- explicit unit target for planting
CMD_INVESTIGATE = 33459 -- operative investigates another unit
CMD_ACTIVATE_NETWORK = 33460 -- handler activates a compromised hub/individual
CMD_CIVILIAN_BLEND = 34971 -- explicit civilian cover movement and idle activity
