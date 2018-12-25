function getCommandTable(boolQueueOverride)
	returnT={}
	local alt, ctrl, shift, right = Spring.GetModKeyState()
	
	if alt then table.insert(returnT,"alt")end
	if ctrl then table.insert(returnT,"ctrl")end
	if shift or (boolQueueOverride and boolQueueOverride ==true )then table.insert(returnT,"shift")end
	if right then table.insert(returnT,"right")end
	return returnT
end


function upByRow(str,num)
	for i=1,num do
		str=str.."\n"
	end
	return str
end

 function GetModKeys()
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	
	if Spring.GetInvertQueueKey() then -- Shift inversion
		shift = not shift
	end
	
	return alt, ctrl, meta, shift
end

 function GetCmdOpts(alt, ctrl, meta, shift, right)
	
	local opts = { alt=alt, ctrl=ctrl, meta=meta, shift=shift, right=right }
	local coded = 0
	
	if alt then coded = coded + CMD_OPT_ALT end
	if ctrl then coded = coded + CMD_OPT_CTRL end
	if meta then coded = coded + CMD_OPT_META end
	if shift then coded = coded + CMD_OPT_SHIFT end
	if right then coded = coded + CMD_OPT_RIGHT end
	
	opts.coded = coded
	return opts
end
