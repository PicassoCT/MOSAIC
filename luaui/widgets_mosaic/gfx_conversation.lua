--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_team_platter.lua
--  brief:   team colored platter for all visible units, teamcolour altered depending on player who last ordered them
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Conversation",
    desc      = "Creates in text conversations  between civilians",
    author    = "some ancient horror",
    date      = "june 25, 2023",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local intialPrompt = "Chat GPT for this task, you will generate a conversation between two people inside the city. You will assign them gender, a job and a living situation and a interaction reason, which may or may not be time dependent.\
					  Previous conversations will be concatenated to this prompt and serve as additional context. The generated snippet will contain 3 lines. \
					  Each time you generate a conversation, you will recieve a street as location, and the name of two people. Each conversation line will start with the name, followed by a : and end with a ü."

local context = intialPrompt
local seperator = "ü"
local function splitConversationAndSay(conversation, aPersonID, bPersonID)
	lines = split(conversation, seperator)
	for i=1, #lines do
		local convo=  split(line, ":")[2]
		if i%2 == 0 then
			say(convo, 2500, { r = 1.0, g = 0.0, b = 0.0 }, { r = 1.0, g = 0.0, b = 0.0 }, "", aPersonID)
		else
			say(convo, 2500, { r = 1.0, g = 0.0, b = 0.0 }, { r = 1.0, g = 0.0, b = 0.0 }, "", bPersonID)		
		end                            
	end
	
end
				  
local function GenerateConversation(locationName, aPersonID, bPersonID)
	dayTime= getDayTime()
	aPersonName, bPersonName = Spring.GetUnitInfo(aPersonID), Spring.GetUnitInfo(bPersonID)
	request = "A 3 line conversation between: ".. aPersonName.." and ".. bPersonName.." at "..locationName.. " at time ".. dayTime 
	--TODO Generate Conversation via ChatGPT+
	local resultingConversationSnippet = callChatGPT(context)
	context = context.. resultingConversationSnippet
	splitConversationAndSay(resultingConversationSnippet)	
end

function getCityName()
--TODO getDeterministicCityName
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeamID, attackerID, attackerDefID)
if contextRelevantUnitType[unitDefID] then
	context = context .. "/n A person named ".. Spring.GetUnitInfo(unitID).." of type "..UnitDefs[unitDefID].name ..". Possible suspect "..Spring.GetUnitInfo(attackerID)
end

end
function widget:UnitCreated(unitID, unitDefID)

if contextRelevantUnitType[unitDefID] then
	context = context .. "/n A person named ".. Spring.GetUnitInfo(unitID).." of type "..UnitDefs[unitDefID].name .." has entered the city."
end

end
					  
function widget:Initialize()
	local cityName = getCityName()
	context = context.. " The storysnippets takes place in the city of ".. cityName.. "."
end


function widget:Shutdown()
end


