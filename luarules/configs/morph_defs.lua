--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local devolution = (-1 > 0)


local morphDefs = {}

-- let's append all the side's morphing units to the list
-- first find all the subtables
Spring.Log('morph defs', 'info', "Loading side starting unit tables...")
local SideFiles = VFS.DirList("luarules/configs/side_morph_defs", "*.lua")
Spring.Log('morph defs', 'info', "Found "..#SideFiles.." tables")
-- then add their contents to the main table
for _, SideFile in pairs(SideFiles) do
	Spring.Log('morph defs', 'info', " - Processing "..SideFile)
	local tmpTable = VFS.Include(SideFile)
	if tmpTable then
		local tmpCount = 0
		for morphName, subTable in pairs(tmpTable) do
			if morphDefs[morphName] == nil then
				morphDefs[morphName] = {}
			end
			local tmpSubTable = morphDefs[morphName]
			-- add everything to it
			for paramName, param in pairs(subTable) do
				if paramName then
					tmpSubTable[paramName] = param
				else
					table.insert(tmpSubTable, param)
				end
			end
			tmpCount = tmpCount + 1
		end
		Spring.Log('morph defs', 'info', " -- Added "..tmpCount.." entries")
		tmpTable = nil
	end
end


--
-- Here's an example of why active configuration
-- scripts are better then static TDF files...
--

--
-- devolution, babe  (useful for testing)
--
if (devolution) then
  local devoDefs = {}
  for src,data in pairs(morphDefs) do
    devoDefs[data.into] = { into = src, time = 10, metal = 1, energy = 1 }
  end
  for src,data in pairs(devoDefs) do
    morphDefs[src] = data
  end
end


return morphDefs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
