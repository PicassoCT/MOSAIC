--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not (Spring.GetConfigInt("LuaSocketEnabled", 0) == 1) then
	Spring.Echo("LuaSocketEnabled is configurationally challenged")
	return false
end

function widget:GetInfo()
	return {
		name = "Spring Augmented Reality Plugin",
		desc = "Allows to view the Spring-Engine via Cardbord AR on your phone",
		author = "PicassoCT",
		version = "2.0",
		date = "YearOfTheGNU on a to hot morning between Dubai and Shanghai",
		license = "GNU GPL, v2 or later",
		layer = math.huge,
		hidden = false,
		handler = true,
		enabled = false -- loaded by default?
	}
end
--include("scripts/lib_type.lua" ) 
-- ARDevice --> Broadcast 
-- Host --> Broadcast his IP
-- ARDevice --> Send CFG to HostIP
-- HostWaits for Matrice DATA

local Chili, Screen0
local socket = socket
local message =""
--test
local recieveBroadcastHeader = "SPRINGAR;BROADCAST;ARDEVICE"	
local recieveResetHeader = "SPRINGAR;RESET;"	
local recievedCFGHeader = "SPRINGAR;CFG;"		
local sendBroadCastRecievedMessage	 = "sendBroadCastRecievedMessage"			
local recievedMatriceDataHeader = "SPRINGAR;DATA;CAMERA="	
local QuaternionHeader = "ROTATION="	
local nextStateToGo = recieveBroadcastHeader		
local sendMSGHeader 	= "SPRINGAR;DATA="					
local sendHostmessage = "SPRINGAR;REPLY;HOSTIP="
local sendResetCompleteMessage ="SPRINGAR;RESET_COMPLETE;"
local sendCFGRecievedMsg = "SPRINGAR;CFG;RECIEVED;"
local comSocket
local broadcast
local udp
local BroadcastIpAddress = '*'

local BroadcastSendFromAdress = "255.255.255.255"
local ARDeviceIpAddress = ""
local hostIPAddress = "192.168.178.20"
local TIME_FRAME_IN_MS = 30 
local BR_port = 9000 
local segmentSize = 8000
local watchdogGameFrame= Spring.GetGameFrame()
local TIMEOUT_WATCHDOG = 30 * 60 --seconds

local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ
local springUp_vec = {0,0,-1}
local SIZE_SPRING_SQUARE = 2 -- meters, cause no english-american foolin around with cocklengths and gods-toes or other shennanigans
local SET_ARCAM_COMMAND ="viewar"

local fileBufferDesc = {} 
fileName= "ARBuffer"
fileBufferDesc[1] = {
	filePathName = "luaui/ar/"..fileName.."1"..".png",
	boolActive = false,	-- is currently a socket writing from this buffer?
	boolNotValid = false	-- is currently a write Process activ on this buffer?
	
}
fileBufferDesc[2] = {
	filePathName = "luaui/ar/"..fileName.."2"..".png",
	boolActive = false,	-- is currently a socket writing from this buffer?
	boolNotValid = false	-- is currently a write Process activ on this buffer?
	
}


-----------------------> Library End
function vecToEuler( vec)

ex = sqrt(vec[1]*vec[1] + vec[2]*vec[2] + vec[3]*vec[3])
ey = arctan(vec[2]/vec[1])
ez = arccos(vec[3]/ey)
return {ex,ey,ez}
end



function getMinorMat(mat, row, col)
	sign= (-1)^(row+col)
	minor= matrix(#mat-1,#mat-1,0)
	for i=1,#minor do
		for j=1,#minor do
			ix,jx = i,j
			if ix >= row then ix = ix+1 end
			if jx >= col then jx = jx+1 end
			minor[i][j] = sign*mat[ix][jx]
		end
	end
	
	return minor
end

cam_type_switch ={
--TA Camera
["ta"]=	function (camState, pos_vec, rot_vec)
	camState.height = pos_vec[3]
	
	camState.dx = rot_vec[1]
	camState.dy = rot_vec[3]
	camState.dz = rot_vec[2]
	return camState
	end,
["spring"]=	function (camState, pos_vec, rot_vec)
	camState.height = pos_vec[3]
	
	rot_euler = vecToEuler(rot_vec)
	
	camState.rx = rot_euler[1]
	camState.rz = rot_euler[2]
	camState.ry = rot_euler[3]
	
	camState.dx = rot_vec[1]
	camState.dz = rot_vec[2]
	camState.dy = rot_vec[3]

	
	return camState
	end,
-- Spring Style Total War
["rot"]=	function (camState, pos_vec, rot_vec)
	camState.height = pos_vec[3]
	
	camState.dx = rot_vec[1] + springUp_vec[1]--x
	camState.dz = rot_vec[2] + springUp_vec[2]--y
	camState.dy = rot_vec[3] + springUp_vec[3]--z

	
	return camState
	end,
["fps"]=	function (camState, pos_vec, rot_vec)
	camState.height = pos_vec[3]
	
	camState.dx = rot_vec[1]
	camState.dz = rot_vec[2]
	camState.dy = rot_vec[3]

	
	return camState
	end,
}

ARCAM_NAME= "ar"
function setCameraType() 

	Camstate=Spring.GetCameraState()	
	if(Camstate. Name ~= ARCAM_NAME) then
		 Spring.SendCommands(SET_ARCAM_COMMAND)
	   
	end 
	
end
	
function setCamera(camPos, rot_vec)

	camState = Spring.GetCameraState()


	MAX_MAP_SIZE = math.max(mapSizeZ,mapSizeX)
	--Scalefactor = OriginalScale(1m)/TotalSizeOfSquareInReality (e.g. 2m)* biggest map size in Elmo
	scaleFactor = (SIZE_SPRING_SQUARE * MAX_MAP_SIZE)
	
	for i=1,4 do
		camPos[i]=camPos[i]*scaleFactor
	end
	
	camPos[1] =camPos[1] + MAX_MAP_SIZE/2
	camPos[2] =camPos[2] + MAX_MAP_SIZE/2	
	

	camState.px= camPos[1]
	camState.pz= camPos[2]
	camState.py= camPos[3]
	
	--Add Upvector

	
	camState = cam_type_switch[camState.name](camState, camPos, rot_vec)

	--extract the rotation from the quaternion
	Spring.SetCameraState(camState)
end
------------------------------ String Tools ------------------------------------

-->splits a string with seperators into a table of substrings
function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end
--> serializes a whole table to string
function tableToString(tab)
	PostFix = "}"
	PreFix = "{"
	conCat=""..PreFix
	for key, value in pairs(tab) do
		conCat= conCat.."["..toString(key).."] ="..toString(value)..","
	end
	
	return conCat..PostFix
end

--> converts a non-stringElement to String
function toString(element)
	typeE = type(element)
	
	if typeE == "boolean" then
		if element == true then 
			return "true"
		else 
			return "false"
		end 
	end
	if typeE == "number" then return ""..element end
	if typeE == "string" then return element end
	if typeE == "table" then return tableToString(element) end
end

-->removes whitespacecharacters from a string
function trim(s)
	return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

--> Echos the spring connection related settings out
local function dumpConfig()
	-- dump all luasocket related config settings to console
	for _, conf in ipairs({"TCPAllowConnect", "TCPAllowListen", "UDPAllowConnect", "UDPAllowListen" }) do
		Spring.Echo(conf .. " = " .. Spring.GetConfigString(conf, ""))
	end
end

--------------------- Data Transfer Logic for Buffer---------------------------

local deviceData={
	deviceName = 	'S8',
	viewWidth = 	60,
	viewHeigth = 	70,
	seperator = 	30
}

local tex = gl.CreateTexture(deviceData.viewWidth, deviceData.viewHeigth, {fbo=true}); 

function getActiveBuffer()
	if fileBufferDesc[1].boolActive == true then return fileBufferDesc[1], 1 end
	
	return fileBufferDesc[2], 2
end

function getWriteableBuffer()
	if fileBufferDesc[1].boolNotValid == true then return fileBufferDesc[1], 1 end
	
	return fileBufferDesc[2], 2
end

--> Handled by writing function once done- waiting for the sendeSemaphore to drop
function switchWriteBuffer()
	Spring.Echo("function switchWriteBuffer()")
	_, activeBufferNr = getActiveBuffer()
	_, writeBufferNr = getWriteableBuffer()
	while boolSendDataSemaphore == true do
		Sleep(1)
	end
	fileBufferDesc[activeBufferNr].boolActive = false
	fileBufferDesc[activeBufferNr].boolNotValid = true
	
	fileBufferDesc[writeBufferNr].boolActive = true
	fileBufferDesc[writeBufferNr].boolNotValid = false
end

boolDataInBufferValid = false
local coWriteBuffer

--> Drops a screenshot to file in a coroutine
function copyFrameToBuffer()
	Spring.Echo("function copyFrameToBuffer()")
	if not coWriteBuffer or coroutine.status(coWriteBuffer) == "dead" then
		-- socket is writeable
		
		coWriteBuffer=		coroutine.create(function()
			gl.CopyToTexture(tex, 0, 0, 0, 0, deviceData.viewWidth, deviceData.viewHeigth);
			gl.RenderToTexture(	tex, 
			gl.SaveImage,
			0,
			0,
			deviceData.viewWidth,
			deviceData.viewHeigth, 
			getWriteableBuffer().filePathName);
			
			switchWriteBuffer()										
		end
		)
		coroutine.resume(coWriteBuffer)
		
		
	end
end
--------------------------------------------------------------------------------

-->Creates and returns an unconnected UDP object. Unconnected objects support the sendto, 
-- receive, receivefrom, getsockname, setoption, settimeout, setpeername, setsockname, and close. 
-- The setpeername is used to connect the object.
function BroadcastConnect()
	Spring.Echo(" Broadcast SocketConnect("..BroadcastIpAddress..",".. BR_port..")")
	broadcast=socket.udp()
	assert(broadcast:settimeout(0))
	assert(broadcast:setoption('broadcast', true))
	--assert(broadcast:setoption('dontroute', true))
	success, errmsg =	broadcast:setsockname(BroadcastIpAddress, BR_port)
	if not success then Spring.Echo(errmsg) end
	return broadcast
end

--> opens a udpsocket
function UDPConnect(ip, peername, peerport)
	Spring.Echo(" UDPSocketConnect("..ip..",".. BR_port..")")
	if not udp then
		udp=socket.udp()
		assert(udp:settimeout(1/66))
		success, errmsg = udp:setsockname(ip, BR_port)
		assert(success, errmsg)
		
		if peername then -- changes a unconnected udp port into a connected udp-port
			assert(udp:setpeername(peername, peerport))
		end
	end
	return udp
end

function sendMessage(Socket, ip, port, data)
	assert(type(ip) == "string")
	assert(type(port) == "string" or type(port) == "number")
	assert(type(data) == "string")
	Spring.Echo("gui_arCam::sendMessage:" .. data .. " to " .. ip)
	if Socket then
		
		local	 success, e_msg = Socket:sendto(data, ip, port)
		
		if not success then
			Spring.Echo("Failed to send message " .. data .. " to " ..ip.." with error "..e_msg)
		end
	end
	return success, e_msg
end

function widget:Shutdown()
	if udp then udp:close() end
	if broadcast then broadcast:close() end
end
function widget:Initialize()	
	Spring.Echo("function widget:Initialize()")
	
	fileBufferDesc[1].boolNotValid = false
	fileBufferDesc[1].Active = true
	
	comSocket = BroadcastConnect()	
	nextStateToGo = recieveBroadcastHeader
	
end


local coSendData 
boolSendDataSemaphore = false
-- called when data can be written to a socket
local function transferDataToARDevice(ip)
	
	-- load image
	-- Spring.Echo("Sending test data to "..ARDeviceIpAddress)
	
	if nextStateToGo == recievedMatriceDataHeader then		
		
		if not coSendData or coroutine.status(coSendData) == "dead" then
			-- socket is writeable
			
			coSendData=		coroutine.create(function()
				
				data = VFS.LoadFile(getActiveBuffer().filePathName)				
				boolSendDataSemaphore = true
				numberOfSegments = data:len()/segmentSize
				
				for i=0, i < numberOfSegments, 1 do
					local segment = data:sub(i*segmentSize +1,(i+1)*segmentSize +1)
					
					local success, e_msg = nil, nil
					if i+1 < numberOfSegments then
						success, e_msg = udp:sendto(sendMSGHeader..i..";"..segment, ARDeviceIpAddress, BR_port)
					else
						success, e_msg = udp:sendto(sendMSGHeader.."LAST;"..segment, ARDeviceIpAddress, BR_port)
					end
					if not success then
						Spring.Echo("transferDataToARDevice"..e_msg)
					end
				end
				boolSendDataSemaphore = false
			end
			)
			if boolSendDataSemaphore == false then
				coroutine.resume(coSendData)
			end
		end
	end
end

oldState = nil
function whoWatchesTheWatchdog(newState)
	
	if newState == oldState and newState ~= recievedMatriceDataHeader then 
		
		if Spring.GetGameFrame() - watchdogGameFrame > TIMEOUT_WATCHDOG then
			nextStateToGo =recieveResetHeader
			watchdogGameFrame = Spring.GetGameFrame()
		end	
	end
	
	if newState ~= oldState then 
		Spring.Echo("Statemachine: "..newState)
		watchdogGameFrame = Spring.GetGameFrame()
	end
	
	oldState = newState
end

function RecieveConfigureARCameraMessage(configStr)
	Spring.Echo("RecieveConfigureARCameraMessage:"..configStr)
	configStr= configStr:gsub(recievedCFGHeader,"")
	arrayOfTokens = split(configStr,";")
	Spring.Echo(arrayOfTokens)
	if arrayOfTokens[5] then
		deviceData.deviceName = arrayOfTokens[1]:gsub("MODEL","") or "No model Name recieved"
		displayWidth= arrayOfTokens[2]:gsub("DISPLAYWIDTH=","")
		
		deviceData.viewWidth = tonumber(displayWidth)
		displayHeigth = arrayOfTokens[3]:gsub("DISPLAYHEIGTH=","")
		
		deviceData.viewHeigth = tonumber(displayHeigth)
		displayRatio = arrayOfTokens[4]:gsub("DISPLAYDIVIDE=","") 
		
		deviceData.seperator = math.min(100,math.max(1,tonumber(displayRatio)		or 50))
		ARDeviceIpAddress = arrayOfTokens[5]:gsub("IPADDRESS=","") 
		
		-- Spring.Echo(deviceData.viewWidth,deviceData.viewHeigth, ARDeviceIpAddress)
		tex = gl.CreateTexture(deviceData.viewWidth, deviceData.viewHeigth, {fbo=true}); 
		return true
	end
	return false
end


old_camPos ={0.0,0.0,0.0,0.0}
local oldrot_vec= {0.0,1.0,0.0}

function setCamMatriceFromMessage(recievedData)

		if recievedData then
		recievedData=recievedData:gsub(recievedMatriceDataHeader,'')
		recievedData=recievedData:gsub(QuaternionHeader,'')
		raw_data = split(recievedData, ";")

		boolCompleteCamMatrix= true
		camPos ={0,0,0,0}
		for i=1, 4 do
			mat_val = tonumber(raw_data[i])
			if false == (type(mat_val)=="number") then 
				boolCompleteCamMatrix = false
				break
			end
			camPos[i]= mat_val		
		end		
		if boolCompleteCamMatrix == true then
			old_camPos= camPos
		end

		boolCompleteRotVec = true
	local	newrot_vec = {0.0,0.0,0.0}
		i=4
		for q=i+1, i+3 do
			newrot_vec[q-i] = tonumber(raw_data[q])

			if false == (type(newrot_vec[q-i]) == "number") then 
				boolCompleteRotVec = false

				break
			end
			
		end	

		if boolCompleteRotVec == true then
			oldrot_vec= newrot_vec
		end
		
		setCamera(old_camPos, oldrot_vec)
	end
end

function widget:Update()

	
	data, ip, port = nil, nil, nil
	
	data, ip, port = comSocket:receivefrom()
	
	if data and ip then Spring.Echo("Recieved text " .. data .. " from " ..ip) end
	
	if data and data:find(recieveResetHeader) then
		nextStateToGo = recieveResetHeader
	end	
	--Spring.Echo("CurrentState:"..nextStateToGo)
	communicationStateMachine[nextStateToGo](data,ip,port)
	
	whoWatchesTheWatchdog(nextStateToGo)
	
	
	if nextStateToGo == recievedMatriceDataHeader and true == false  then
		--upate only on completed transfer
		if boolSendDataSemaphore == false then
			copyFrameToBuffer()
		end
		transferDataToARDevice(ARDeviceIpAddress)
	end
end

delay = 0
--> Simple Statemachine in Table
communicationStateMachine= 
{
	[recieveResetHeader] = function (data, ip, port)
		comSocket = broadcast
		local success, e_msg = sendMessage(comSocket, BroadcastSendFromAdress, BR_port, sendResetCompleteMessage )
		if success then
			nextStateToGo = recieveBroadcastHeader 	
		end		
	end,	
	[recieveBroadcastHeader] = function (data, ip, port)
		if data and data:find(recieveBroadcastHeader) then
			--Spring.Echo("recieveBroadcastHeader:"..data.." from "..ip)
			ARDeviceIpAddress = ip
			local success, e_msg=	sendMessage(comSocket, BroadcastSendFromAdress, BR_port, sendHostmessage..hostIPAddress)	
			--Spring.Echo("sendHostmessage "..sendHostmessage..hostIPAddress.." -> "..ARDeviceIpAddress..":"..BR_port)
			nextStateToGo = recievedCFGHeader 
			
		end
	end,		
	[recievedCFGHeader]= function (data, ip, port)
		if data and data:find(recievedCFGHeader) then
			comSocket = UDPConnect("192.168.178.20") --hostIPAddress
			if RecieveConfigureARCameraMessage(data) == true then	
				sendMessage(udp, ARDeviceIpAddress, BR_port, sendCFGRecievedMsg)						
				nextStateToGo = recievedMatriceDataHeader 
			end
		end			
	end,	
	
	[recievedMatriceDataHeader] = function (data, ip, port)		
		if data and data:find(recievedMatriceDataHeader) then
			setCamMatriceFromMessage(data)
		end
	end,
	
}
