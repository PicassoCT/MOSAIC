include("colors.h.lua")
include("keysym.h.lua")
include("utils.lua")

function widget:GetInfo()
  return {
    name      = "Action Finder2",--(action finder)
    desc      = "(Focuses,smooth and join the camera to the places of the map with a lot of action caught.)",
    author    = "latest author: cntrlll 1sitecode@gmail.com (original author: xyz)",
    date      = "june 2, 2013",--(26 mai 2009)
    license   = "GNU GPL, v2 or later",--("GNU GPL, v2 or later",)
    version   = "2.0",--(1.5)
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
  --http://webcache.googleusercontent.com/search?q=cache:T5Y3qhqGIo8J:code.metager.de/source/xref/SpringRTS/spring/cont/LuaUI/Headers/keysym.h.lua+&cd=1&hl=fr&ct=clnk&gl=be
  --THE SCRIPT IS BASED ON DOZEN OF OTHERS, SPECIALY FROM ACTION FINDER BY AUTHOR XYZ.
  
  --PLEASE DEACTIVATE ALL SCRIPTS FOR SMOOTHING THE CAMERA, ITS VERY IMPORTANT.(smoothcam ,camerascroll,...) look in luaui/widgets folder.

  --U MUST WAIT SOME ACTION IN GAME TO BEGIN USE O, mousebutton5 key, or T.

  --PLEASE READ THE MANUAL BELOW TO NOT FORGET THE MOST IMPORTANT KEYS, U CAN CHANGE THEM IN FUNCTION widget:KeyPress and  widget:MousePress
  --THE KEY BUTTON5 IN MOUSE FUNCTION, JOIN A CAMERA VIEW TO ANOTHER, U CAN USE A KEYBOARD KEY LIKE O.
  --I AM NOT SURE HOW USE SPECIAL KEYS LIKE ,;:= FOR FR KEYBOARD, THEY ARE NOT IN KEYSYM.h
  --I NEED MORE TIME TO FIND A SOLUTION TO USE ALL KEYBOARD AND CERTAINLY NEED ANOTHER FUNCTION FROM OTHER LUA SCRIPTS

  --shift + < with ahk to enable script OR /luaui attractmode

  --minus Back to the point where u started the script with shift + < (i suggest u to go in fps mode with ctrl + backspace(key combinaison or command) then activate the script looking ur base)
  --t Deliver a wide and slow descending view of map and finish above units(recommand u to select unit before do it and dont choose any others actions to like the remain of all of them)
  --x Set One of two predefined positions
  --c Exactly , x or c have same behavior, record x,y coordinates point always and rarely catch an event near prefered location and record the point
  --v Go to the point x and time decreased to go there
  --b Idem for c
  --s Set a place with freemode view.(u turn around the mouse)the record point is in this script but for the function, u need my version of Hybrid Overhead camera
  --  provided in the package, u can change the key but in both script.
  --n Go to the location saved with s in freemode.(disable some smooth of camera to go faster, canceled by auto or manual action move)
  --m stop or restart auto move of cameras(not functions)

  --o GREAT BUTTON, ITS A SURPRISE TRY IT MUCH AS U WANT!

  --NOT IMPORTANT
  --_______________
  --f Decrease all the maj variables
  --g All the maj variables normal values
  --not assigned Reset some settings like speed of detection, rarely usefull
  --u and y
  --r Let you modify time var maybe for wait until an action is ended

  --START WITH SHIFT + > (used in ahk script to write /luaui attractmode on in spring process, not needed in spec but can fix if problem occur during the using.)
end
--------------------------------------------------------------------------------
local spGetCameraState    = Spring.GetCameraState
local spSetCameraState    = Spring.SetCameraState
local cammove=1
local activescroll=1.065
local lastactivescroll=activescroll

--------------------------------------------------------------------------------
--your vars !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--------------------------------------------------------------------------------
local CAM_MODE = 5
local TRANSITION_DURATION     			= 1

local MIDDLEPAUSE=0

local CAMERA_IDLE_RESPONSE     			= 5
local CAMERA_FIGHT_RESPONSE 			= 4
local FORCE_ECONOMY_VIEW				= 50      -- show some economy stuff *after* this many events
local USER_IDLE_RESUME         			= 3
local RESUME = 0

--------------------------------------------------------------------------------
local thiscam=1
local active = 1
--------------------------------------------------------------------------------

local lastMove = 0
local lastUserMove = 0
local eventsCount = 0

local fracScale = 50
local healthScale = 0 -- 0.001

local paraFracScale = fracScale * 0.25
local paraHealthScale = healthScale * 0

-- Automatically generated local definitions
local spGetFrameTimeOffset   = Spring.GetFrameTimeOffset
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitAllied         = Spring.IsUnitAllied

--------------------------------------------------------------------------------
local revents = {}
--------------------------------------------------------------------------------

local inSpecMode = false
local inAttractMode = true
local wasSpecMode = false

local eventScale = 0.02

local lastMouseX = 0
local lastMouseY = 0

local WantedX,WantedZ,WantedID

local DEATH_EVENT            = 2
local TAKE_EVENT             = 3
local CREATE_EVENT           = 1
local CREATE_START_EVENT     = 0
local STOCKPILE_EVENTS       = 4
local DAMAGE_EVENTS          = 5
local PARALYZE_EVENT         = 6

local limit = 0.0025

--------------------------------------------------------------------------------

local gameSecs = 0

--------------------------------------------------------------------------------
local TKUN = 0
--------------------------------------------------------------------------------

local eventMap  = {}

local damageMap = {}

local SavedInitialCameraState = nil

local ChangeModCounter = 1

--------------------------------------------------------------------------------
local middlemousevar=0
--------------------------------------------------------------------------------

local function clearTrackingMode()
  if WantedID and Spring.ValidUnitID(WantedID) then
    Spring.SelectUnitArray({WantedID})
    Spring.SendCommands("trackoff")
    Spring.SelectUnitArray({})
	WantedID = nil
  end
  
  Spring.SendCommands("trackoff")
end

--------------------------------------------------------------------------------

local function enableTrackingMode(id)
  --clearTrackingMode()
  
  WantedID = id
  
  Spring.SelectUnitArray({id})
  Spring.SendCommands("track")
  Spring.SelectUnitArray({})
end

--------------------------------------------------------------------------------

local function PickCameraMode(x,z,id)
  lastMove = gameSecs
  WantedX=x
  WantedZ=z
  
  --clearTrackingMode()
  --Spring.Echo("MOD???")
  ChangeModCounter=math.random(0,4)
  Spring.SelectUnitArray({})
  local RandomMode=math.random(2,5)
  -- Total war, close to ground
  if CAM_MODE > 0 then
    RandomMode=CAM_MODE
  end
  if RandomMode==1 then
    thiscam=1
    Spring.SetCameraState({name=tw,mode=2,rz=0,rx=math.random(-100,0)/100,ry=math.random(-50,50)/10,px=x,py=0,pz=z},TRANSITION_DURATION)
    Spring.Echo("spring mode 1")
  -- FPS, tracking
  elseif (RandomMode==2 and id) or (RandomMode==3 and id) or (RandomMode==4 and id) then
    --if not Spring.GetUnitIsDead(id) or Spring.ValidUnitID(id) then
    --  PickCameraMode(x-6,z)
    --end
    if not Spring.GetUnitIsDead(id) then
      local vx,vy,vz=Spring.GetUnitVelocity(id)
      if vx and vy and vz and vx^2+vy^2+vz^2>0.1^2 then
        --activescroll=6
        Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+400,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)--change +200 by +700 in zerok engine, the new panoramic fps viewmode
        Spring.Echo("spring mode 2")
        enableTrackingMode(id)
        thiscam=1

        --Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+20,pz=z,rz=0,dx=0,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=999},0)

        WantedX=nil
        WantedZ=nil
      end
    end
  -- TA Overview
  elseif RandomMode >4 then
    Spring.Echo("spring mode 3")
    Spring.SetCameraState({name=ta,mode=1,px=x,py=0,pz=z,flipped=-1,dy=-0.9,zscale=0.5,height=999,dx=0,dz=-0.45},TRANSITION_DURATION)
    
    thiscam=0
  end
end

--------------------------------------------------------------------------------

function EnterSpecMode()
  Spring.Echo("Start spec mode / action finder")
  active=1
  --Spring.SetCameraTarget(Game.mapSizeX/2, 0,Game.mapSizeZ/2, TRANSITION_DURATION)
  inSpecMode = true
end

--------------------------------------------------------------------------------

function EnterAttractMode()
  active=1
  if not inSpecMode then
    EnterSpecMode()
  else
    wasSpecMode = true
  end
 
  Spring.Echo("Attract mode camera style ON")
  --Spring.Echo(Spring.GetPlayerControlledUnit())
  Spring.Echo(Spring.GetPlayerRoster())
  
  inAttractMode = true
  --PickCameraMode(Game.mapSizeX/2,Game.mapSizeZ/2)
end

--------------------------------------------------------------------------------

function LeaveSpecMode()
  Spring.Echo("End spec mode / action finder")
  inSpecMode = false
  
  if inAttractMode then
    LeaveAttractMode()
  end
end

--------------------------------------------------------------------------------

function LeaveAttractMode()
  Spring.Echo("Attract mode camera style OFF")
  
  inAttractMode = false
  
  if SavedInitialCameraState then
    Spring.SetCameraState(SavedInitialCameraState,TRANSITION_DURATION)
    Spring.Echo("spring mode 4")
    --SavedInitialCameraState=nil
  end
  
  if not wasSpecMode then
    LeaveSpecMode()
	wasSpecMode = false
  end
end

--------------------------------------------------------------------------------
local function UserAction()
    --if RESUME ==1 then
    --Spring.Echo("coucouuu")
    if MouseMoved() then
        --if spGetFrameTimeOffset() then
        --  local gs = GetGameSecs()
        --  lastUserMove = gs
        --end
      
      --Spring.Echo(gs)
      ChangeModCounter=0
      lastMove = gameSecs
      USER_IDLE_RESUME = 3
  
  
  
  
      --local x, y, lmb, mmb, rmb = Spring.GetMouseState()
  
      --WantedX=x
      --WantedZ=y
      --WantedZ=y
    --else
    --  ChangeModCounter=CAM_MODE
    end
  




    --clearTrackingMode()
  --end
end

--------------------------------------------------------------------------------

local function GetGameSecs()
  return spGetGameSeconds() + spGetFrameTimeOffset()
end

--------------------------------------------------------------------------------

local function UpdateCamera(pozX, pozZ, Uid)
  lastMove = gameSecs
	
	if inAttractMode then
	    if (ChangeModCounter > 0) then
	      ChangeModCounter=ChangeModCounter-1
	      if WantedID and Spring.ValidUnitID(WantedID) then
	        local x,_,z=Spring.GetUnitPosition(WantedID)
	        if middlemousevar == 0 and WantedX and WantedZ and x==WantedX and z==WantedZ and not MouseMoved() then
	          PickCameraMode(pozX,pozZ, Uid)
	        end
	      else
	        WantedX=pozX
	        WantedZ=pozZ
			
			--clearTrackingMode()
			
	        Spring.SetCameraTarget(pozX, 0, pozZ, TRANSITION_DURATION)
          Spring.Echo("spring mode 5")
          --Spring.Echo(ChangeModCounter)
	      end
	    else
        if middlemousevar == 0 and not MouseMoved() then
	       PickCameraMode(pozX,pozZ,Uid)
        end
	    end
	else
	  --clearTrackingMode()
	  Spring.SetCameraTarget(pozX, 0, pozZ, TRANSITION_DURATION)
    Spring.Echo("spring mode 6")
	end
end

--------------------------------------------------------------------------------

function widget:TextCommand(command)
--Specmode
  if (command == 'specmode' or command == 'specmode 1' or command == 'autocamera'  or command == 'autocamera 1' or command == 'actionfinder' or command == 'actionfinder 1')
        and not inSpecMode then
    EnterSpecMode()
    return false
  elseif (command == 'specmode' or command == 'specmode 0' or command == 'autocamera'  or command == 'autocamera 0' or command == 'actionfinder' or command == 'actionfinder 0')
        and inSpecMode then
    LeaveSpecMode()
  end
  
--AttractMode
  if (command == 'actionfinder' or command == 'actionfinder 1' or command == 'attractmode' or command == 'attractmode 1')
        and not inAttractMode then
    SavedInitialCameraState = Spring.GetCameraState()
    EnterAttractMode()
    return false
  elseif (command == 'actionfinder' or command == 'actionfinder 0' or command == 'attractmode' or command == 'attractmode 0')
        and inSpecMode then
    LeaveAttractMode()
  end
  
  local cmd = string.sub(command, 10)
  return true
end

--------------------------------------------------------------------------------

function widget:KeyPress(key, mods, isRepeat)

  if (key == KEYSYMS.X) then--and mods.alt and mods.ctrl and not (mods.meta or mods.shift) then
	--if inSpecMode then
	--  LeaveSpecMode()
	--  return true
	--else
	--  EnterSpecMode()
	--  return true
	--end
   SavedInitialCameraState1 = Spring.GetCameraState()
   Spring.Echo(lastactivescroll,"---vs---",activescroll)
   activescroll=lastactivescroll

  end
  
  if (key == KEYSYMS.S) then--and mods.alt and mods.ctrl and not (mods.meta or mods.shift) then
    SavedInitialCameraState0 = Spring.GetCameraState()
    --RESUME=1
	--if inAttractMode then
	--  LeaveAttractMode()
	--  return true
	--else
	--  EnterAttractMode()
	--  return true
	--end

  end

  if (key == KEYSYMS.Y) then
    --ChangeModCounter=100
    --thiscam=1

    --if CREATE_EVENT==9 then
    --  inAttractMode = false
    --  Spring.Echo("eco only")
    --  CREATE_EVENT           = 0
    --  CREATE_START_EVENT     = 0
    --  inAttractMode = true
    --elseif CREATE_EVENT==0 then
    --  inAttractMode = false
    --  Spring.Echo("eco active")
    --  CREATE_EVENT           = 2
    --  CREATE_START_EVENT     = 3
    --  inAttractMode = true
    --elseif CREATE_EVENT==2 then
    --  inAttractMode = false
    --  Spring.Echo("almost no eco")
    --  CREATE_EVENT           = 9
    --  CREATE_START_EVENT     = 9
    --  inAttractMode = true
    --end


    if CAMERA_FIGHT_RESPONSE==3 then
      CAMERA_FIGHT_RESPONSE       = 1
      USER_IDLE_RESUME              = 1
      Spring.Echo("Fight response = 1")
    else
      CAMERA_FIGHT_RESPONSE       = 3
      USER_IDLE_RESUME              = 3
      Spring.Echo("Fight response = 3")
    end

  end
  if (key == KEYSYMS.M) then
    if (active==1) then
      --Spring.Echo("dddddd")
      active=0
      RESUME=0
      --CAM_MODE=5
    else
      --CAM_MODE=4
      active=1
      RESUME=1
    end
  end
  if (key == KEYSYMS.C) then
     SavedInitialCameraState2 = Spring.GetCameraState()
     activescroll=lastactivescroll
  end


  if (key == KEYSYMS.O) then
     --useless key
      ChangeModCounter=100
      CAM_MODE=4
      x=revents.x
      z=revents.z
      u=revents.u
      activescroll=7
      if next(damageMap) ==nil or revents.x ==nil then
        for unitID, d in pairs(eventMap) do
          if Spring.ValidUnitID(unitID) then
            x,y,z=spGetUnitPosition(unitID)
            Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            enableTrackingMode(unitID)
            break
          end
        end
      else
        revents.x=nil
        for unitID, d in pairs(damageMap) do
          if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
            x,y,z=spGetUnitPosition(unitID)
            Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            enableTrackingMode(unitID)
            break
          end
        end
      end
      thiscam=1

      WantedX=nil
      WantedZ=nil
      --assign new keys for reset some vars if a problem with T key
      --local CAMERA_IDLE_RESPONSE          = 5
      --local CAMERA_FIGHT_RESPONSE       = 4
      --local FORCE_ECONOMY_VIEW        = 5      -- show some economy stuff after this many events
      --local USER_IDLE_RESUME              = 3
      --local RESUME = 0
      --activescroll=3
  end

  if (key == KEYSYMS.MINUS) then
     activescroll=0
     Spring.SetCameraState(SavedInitialCameraState,TRANSITION_DURATION)
     activescroll=1.1
     active=0
     RESUME=0
  end
  if (key == KEYSYMS.R) then
      --Spring.Echo("STATUS OD ACTIVE IS:")
      --Spring.Echo(active)
      lastUserMove = gameSecs
      activescroll=1.065
      CAM_MODE=5
      thiscam=0
      ChangeModCounter=0
      
      x=revents.x
      z=revents.z
      u=revents.u
      --if next(damageMap) ==nil or revents.x ==nil then
        --for unitID, d in pairs(eventMap) do
        --  if Spring.ValidUnitID(unitID) then
        --    x,y,z=spGetUnitPosition(unitID)
        --    --Spring.SetCameraState({name=ta,mode=1,px=x,py=0,pz=z,flipped=-1,dy=-0.9,zscale=0.5,height=999,dx=0,dz=-0.45},TRANSITION_DURATION)
        --    --Spring.SetCameraState({name=ta,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
        --    Spring.SetCameraState({name=ta,mode=1,px=x,py=0,pz=z,flipped=-1,dy=-0.9,zscale=0.5,height=999,dx=0,dz=-0.45},TRANSITION_DURATION)
        --    --enableTrackingMode(unitID)
        --    break
        --  end
        --end
      --else
      --  revents.x=nil
      --if not next(damageMap) ==nil then--not x ==nil or 
        for unitID, d in pairs(damageMap) do
            Spring.Echo("STATUS OD ACTIVE IS:")
          --if Spring.ValidUnitID(unitID) then
            if Spring.GetUnitIsDead(unitID) then
              x=damageMap[unitID].dx
              z=damageMap[unitID].dz
            else
              x,y,z=spGetUnitPosition(unitID)
            end
            --Spring.SetCameraState({name=ta,mode=1,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            --Spring.SetCameraState({name=ta,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            Spring.SetCameraState({name=ta,mode=1,px=x,py=0,pz=z,flipped=-1,dy=-0.9,zscale=0.5,height=999,dx=0,dz=-0.45},TRANSITION_DURATION)
            --enableTrackingMode(unitID)
            break
          --end
        end
      --end
      --Spring.Echo("STATUS OD ACTIVE IS:")
      --Spring.Echo(active)
  end

  
  if (key == KEYSYMS.E) and mods["alt"] then
    Spring.Echo("alt i")
    widget:TextCommand("actionfinder")
  end
  if (key == KEYSYMS.T) then
      activescroll=10
      x=revents.x
      z=revents.z
      --name=fps--no more working making a large view planning the map
      Spring.SetCameraState({name=ta,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+550,pz=z,rz=100,dx=20,dy=40,ry=-50,rx=-1,dz=200,oldHeight=1500},TRANSITION_DURATION)
      
      if CAMERA_IDLE_RESPONSE==5 then
        CAMERA_IDLE_RESPONSE          = 3
        --CAMERA_FIGHT_RESPONSE       = 5
        FORCE_ECONOMY_VIEW        = 50     -- show some economy stuff after this many events
        --USER_IDLE_RESUME              = 3
        RESUME = 1
        Spring.Echo("fastmode and no eco events")
      elseif CAMERA_IDLE_RESPONSE==3 then
        CAMERA_IDLE_RESPONSE          = 5
        --CAMERA_FIGHT_RESPONSE       = 5
        FORCE_ECONOMY_VIEW        = 1      -- show some economy stuff *after* this many events
        --USER_IDLE_RESUME              = 2
        --RESUME = 0
        Spring.Echo("normal mode with eco events")
      end
      --enableTrackingMode(id)
      --lastUserMove = gameSecs
  end

  if (key == KEYSYMS.F) then
      CAM_MODE=0
      Spring.Echo("all viewmodes")
  end

  if (key == KEYSYMS.G) then
      CAM_MODE=5
      Spring.Echo("viewmode Ta active")
     --activescroll=activescroll-0.5
     --lastactivescroll=activescroll-------------
     --Spring.Echo(activescroll)
  end
  if (key == KEYSYMS.N) then
     Spring.SetCameraState(SavedInitialCameraState0,TRANSITION_DURATION)
     active=0
     RESUME=0
  end
  if (key == KEYSYMS.V) then
     activescroll=5
     Spring.SetCameraState(SavedInitialCameraState1,TRANSITION_DURATION)
     active=1
     TKUN=0
     RESUME=1
  end
  --SavedInitialCameraState1[0]

  if (key == KEYSYMS.B) then
     activescroll=5
     Spring.SetCameraState(SavedInitialCameraState2,TRANSITION_DURATION)
     active=1
     TKUN=0
     RESUME=1
  end


  return false
end

--------------------------------------------------------------------------------

function widget:Initialize()
  gameSecs = GetGameSecs()
  if Spring.GetSpectatingState() then
    EnterSpecMode()
  else
    LeaveSpecMode()
  end
end

--------------------------------------------------------------------------------

function widget:PlayerChanged(playerID)
--[[  if Spring.GetSpectatingState() then
    EnterSpecMode()
  else
    LeaveSpecMode()
  end
  ]]--
end

--------------------------------------------------------------------------------

function widget:Shutdown()
  if SavedInitialCameraState and inSpecMode then
    Spring.SetCameraState(SavedInitialCameraState,TRANSITION_DURATION)
  end
end

--------------------------------------------------------------------------------
function stopwhilemouseprocess()
  local x, y, lmb, mmb, rmb = Spring.GetMouseState()
  --if mmb then
    --aname,ascale=Spring.GetMouseCursor()
    --if middlemousevar==0 then
    --  middlemousevar=middlemousevar+1
    --else
    --  middlemousevar=0
    --end
    --Spring.Echo("mouse pressed",aname,ascale)
    --Spring.Echo("mouse pressed",aname,ascale)
    --return true
  --end

  if x ~= lastMouseX then
    lastMouseX = x
    USER_IDLE_RESUME=3
    local gs = GetGameSecs()
    --Spring.Echo(gs)
    --Spring.Echo(gameSecs)
    if (gs < gameSecs+3) then
        ChangeModCounter=0
    else
        ChangeModCounter=CAM_MODE
    end
    return true
  end

  if y ~= lastMouseY then
    lastMouseY = y
    USER_IDLE_RESUME=3
    local gs = GetGameSecs()
    if (gs < gameSecs+3) then
        ChangeModCounter=0
    else
        ChangeModCounter=CAM_MODE
    end
    return true
  end

  USER_IDLE_RESUME=0
  return false

end

function widget:MousePress(x, y, button)
  --if (button == 2) then
  --  if thiscam==1 then
  --    activescroll=1.1
  --  end
  --end
    ChangeModCounter=0
  if (button == 1) then
      middlemousevar=0
    end

  if (button == 2) then
    --Spring.Echo("activescroll22222")
      middlemousevar=1
    local x, y, lmb, mmb, rmb = Spring.GetMouseState()
    --if mmb then
      --aname,ascale=Spring.GetMouseCursor()
      --if middlemousevar==0 then
      --  middlemousevar=middlemousevar+1
      --else
      --  middlemousevar=0
      --end
      --Spring.Echo("mouse pressed",aname,ascale)
      --Spring.Echo("mouse pressed",aname,ascale)
      --return true
    --end

    if x ~= lastMouseX then
      lastMouseX = x
      lastMove = gameSecs
      USER_IDLE_RESUME=3
      local gs = GetGameSecs()
      --Spring.Echo(gs)
      --Spring.Echo(gameSecs)
      if (gs < gameSecs+3) then
          ChangeModCounter=0
      else
          ChangeModCounter=CAM_MODE
      end
      return
    end

    if y ~= lastMouseY then
      lastMove = gameSecs
      lastMouseY = y
      USER_IDLE_RESUME=3
      local gs = GetGameSecs()
      if (gs < gameSecs+3) then
          ChangeModCounter=0
      else
          ChangeModCounter=CAM_MODE
      end
      return
    end

    USER_IDLE_RESUME=0
    
  end

  if (button == 5) then
      --Spring.Echo(activescroll)
      if next(damageMap) ==nil or revents.x ==nil then
        for unitID, d in pairs(eventMap) do
          if Spring.ValidUnitID(unitID) then
            x,y,z=spGetUnitPosition(unitID)
            Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            enableTrackingMode(unitID)
            break
          end
        end
      else
        revents.x=nil
        for unitID, d in pairs(damageMap) do
          if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
            x,y,z=spGetUnitPosition(unitID)
            Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            enableTrackingMode(unitID)
            break
          end
        end
      end

      thiscam=1

      WantedX=nil
      WantedZ=nil
      WantedID=unitID
  end
  if CAM_MODE==4 then
     activescroll=1.5
  end
  --activescroll=2.0
  --if RESUME==0 then
  --  lastUserMove = gameSecs

end

--------------------------------------------------------------------------------

function widget:MouseMove(x, y, dx, dy, button)
  --UserAction()
  --return true
  return false
end

--------------------------------------------------------------------------------

function widget:MouseRelease(x, y, button)
  --UserAction()
  ChangeModCounter=0
  return true
end

--------------------------------------------------------------------------------

function widget:MouseWheel(up, value)
  ChangeModCounter=0
  if thiscam ==1 or CAM_MODE==4 then--CAM_MODE==5 
    if up then
      if activescroll<10.5 and activescroll< 50 then
        activescroll=activescroll+activescroll/8
      end
    end
    if not up then
      if activescroll >=2 and activescroll>1 then
        activescroll=activescroll-activescroll/4
      end
    end
  end
  return false
  --UserAction()
end

--------------------------------------------------------------------------------

local function DrawEvent(event)
  if gameSecs > lastMove + CAMERA_IDLE_RESPONSE then
    eventsCount = 0
    UpdateCamera(event.x, event.z)
  end
end

--------------------------------------------------------------------------------

local function DrawDamage(unitid,damage)
  local px, py, pz = spGetUnitViewPosition(unitid)
  if px == nil then
    px, py, pz = spGetUnitViewPosition(unitid)
    if px == nil then
      px,py,pz=spGetUnitPosition(unitid)
      if px== nil then
        return
      end
    end
  end
  local u=nil
  if not damage.u==nil and Spring.ValidUnitID(damage.u) then
    u=damage.u
  elseif not damage.u==nil and Spring.ValidUnitID(damage.a) then
    u=damage.a
  end
  if not damage.u == nil and Spring.ValidUnitID(damage.u) and not damage.u == nil then-- and not Spring.GetUnitIsDead(damage.u)
    local vx,vy,vz=Spring.GetUnitVelocity(damage.u)
    if vx and vy and vz and vx^2+vy^2+vz^2>0.1^2 then
      u=damage.u
    end
  end
  if not damage.a == nil and Spring.ValidUnitID(damage.a) and not damage.a == nil then
    local vx,vy,vz=Spring.GetUnitVelocity(damage.a)
    if vx and vy and vz and vx^2+vy^2+vz^2>0.1^2 then
      u=damage.a
    end
  end
  if u==nil then
    if unitid == nil then
      return 0
    else
      u=unitid
    end
    --adamage=pairs(damageMap)
    --DrawDamage(adamage[1])
    --for _,damage in pairs(damageMap) do
    --  DrawDamage(damage)
    --  break
    --  --if not damage.u==nil and Spring.ValidUnitID(damage.u) then
    --  --  u=damage.u
    --  --elseif not damage.u==nil and Spring.ValidUnitID(damage.a) then
    --  --  u=damage.a
    --  --end
    --  --if not damage.u == nil and Spring.ValidUnitID(damage.u) and not damage.u == nil and not Spring.GetUnitIsDead(damage.u) then
    --  --  local vx,vy,vz=Spring.GetUnitVelocity(damage.u)
    --  --  if vx and vy and vz and vx^2+vy^2+vz^2>0.1^2 then
    --  --    u=damage.u
    --  --  end
    --  --end
    --  --if not damage.a == nil and Spring.ValidUnitID(damage.a) and not damage.a == nil and not Spring.GetUnitIsDead(damage.a) then
    --  --  local vx,vy,vz=Spring.GetUnitVelocity(damage.a)
    --  --  if vx and vy and vz and vx^2+vy^2+vz^2>0.1^2 then
    --  --    u=damage.a
    --  --  end
    --  --end
    --  --if not u == nil
    --  --  DrawDamage(damage)
    --  --  break
    --end
  end
  if not Spring.ValidUnitID(u) then
    px,py,pz=spGetUnitPosition(u)
    if px== nil then
      return
    end
  end

  if (gameSecs > lastMove + CAMERA_FIGHT_RESPONSE) and (eventsCount < FORCE_ECONOMY_VIEW) then
    eventsCount = eventsCount + 1;
    --Spring.Echo(px)
    --Spring.Echo(pz)
    --Spring.Echo(u)
    UpdateCamera(px, pz, u)
  end
end

--------------------------------------------------------------------------------

function MouseMoved()
  local x, y, lmb, mmb, rmb = Spring.GetMouseState()
  --if mmb then
    --aname,ascale=Spring.GetMouseCursor()
    --if middlemousevar==0 then
    --  middlemousevar=middlemousevar+1
    --else
    --  middlemousevar=0
    --end
    --Spring"mouse pressed",aname,ascale)
    --Spring"mouse pressed",aname,ascale)
    --return true
  --end

  if x ~= lastMouseX then
    lastMouseX = x
    USER_IDLE_RESUME=3
    local gs = GetGameSecs()
    --Springgs)
    --SpringgameSecs)
    if (gs < gameSecs+3) then
        ChangeModCounter=0
    else
        ChangeModCounter=CAM_MODE
    end
    return true
  end

  if y ~= lastMouseY then
    lastMouseY = y
    USER_IDLE_RESUME=3
    local gs = GetGameSecs()
    if (gs < gameSecs+3) then
        ChangeModCounter=0
    else
        ChangeModCounter=CAM_MODE
    end
    return true
  end

  USER_IDLE_RESUME=0
  return false
end

--------------------------------------------------------------------------------

function widget:Update(dt)
  UserAction()
  if (cammove) then
    local cs = spGetCameraState()
    spSetCameraState(cs, activescroll)
  end

  --if (button == 4) then
        --Spring.SetActiveCommand("Patrol");
  --end

  if (active==1) then
    -- if specmode is not activated no need to update.
    --if not inSpecMode then
    --  return
    --end

    --don't update evey frame
    local gs = GetGameSecs()
    if (gs == gameSecs) then
      return
    end

    gameSecs = gs
    -- if user wants to take manual controll pause the scipt for   USER_IDLE_RESUME seconds

    --if MouseMoved() and (middlemousevar==1) then
    --  activescroll=1
    --  Spring"activescroll = 1")
    --end
    --if middlemousevar==0 then
    --  activescroll=lastactivescroll
      --UserAction()
      --return
    --end

    if gameSecs < lastUserMove + USER_IDLE_RESUME then
      return
    end

    local scale = (1 - (4 * dt))

    for unitID, d in pairs(eventMap) do
      local v = d.v
      v = v * scale
      if (v < limit) then
        eventMap[unitID] = nil
      else
        d.v = v
      end
    end

    for unitID, d in pairs(damageMap) do
        local v = d.v * scale
        local p = d.p * scale

        if (v > limit) then
          d.v = v
        else
          if (p > limit) then 
            d.v = 0
          else
            damageMap[unitID] = nil
          end
        end

        if (p > 1) then
          d.p = p
        else
          if (v > 1) then 
            d.p = 0
          else
            damageMap[unitID] = nil
          end
        end
    end
    
    if ((next(eventMap)  == nil) and
        (next(damageMap) == nil)) then
      return
    end

    -- draw damages before events
    for _,damage in pairs(damageMap) do
      DrawDamage(_,damage)
    end
    if CAMERA_IDLE_RESPONSE==5 then
      for _,event in pairs(eventMap) do
        DrawEvent(event)
      end
    end
  end
end

--------------------------------------------------------------------------------

local function AddEvent(unitID, unitDefID, color, cost)
  if (not spIsUnitAllied(unitID)) then
    return
  end
  local ud = UnitDefs[unitDefID]
  if ((ud == nil) or ud.isFeature) then
    return
  end
  local px, py, pz = spGetUnitPosition(unitID)
  if (px and pz) then
    eventMap[unitID] = {
      x = px,
      z = pz,
      v = cost or (ud.cost * eventScale),
      u = unitID,
      c = color,
  --  t = GetGameSeconds()
    }
  end
end

--------------------------------------------------------------------------------

function IsTerrainViewable(x1,z1)
  local y1=Spring.GetGroundHeight(x1,z1)
  local xs,ys=Spring.WorldToScreenCoords(x1,y1,z1)
  local _,pos=Spring.TraceScreenRay(xs,ys,true,false)
  if pos then
    local x2,y2,z2=unpack(pos)
    --Spring.Echo("e="..((x2-x1)^2+(y2-y1)^2+(z2-z1)^2))
    if ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)<22500 then
      return true
    else
      return false
    end
  else
    return nil
  end
end

--------------------------------------------------------------------------------

function widget:DrawWorldPreUnit()
  if not inAttractMode then
  return
  end
  
  local gs = GetGameSecs()
  if (gs == gameSecs) then
    return
  end

  if WantedX and WantedZ and not WantedID then
    if (lastMove+TRANSITION_DURATION+0.2>gameSecs) then
      return
    elseif not IsTerrainViewable(WantedX,WantedZ) then
      --Spring.Echo("View blocked, redoing it.")
      --PickCameraMode(WantedX,WantedZ)
    end
  end
end

--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  AddEvent(unitID, unitDefID, CREATE_START_EVENT)
end

--------------------------------------------------------------------------------

function widget:UnitFinished(unitID, unitDefID, unitTeam)
  AddEvent(unitID, unitDefID, CREATE_EVENT)
end

--------------------------------------------------------------------------------

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  --revents.x, revents.y, revents.z = spGetUnitPosition(unitID)
  --revents.u=unitID
  
  --AddEvent(unitID, unitDefID, DEATH_EVENT)

  if unitID==WantedID and middlemousevar == 0 then
    damageMap[unitID] = nil
    x=revents.x
    z=revents.z
    u=revents.u
    --activescroll=7
    if next(damageMap) ==nil or revents.x ==nil then
      for unitID, d in pairs(eventMap) do
        if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
          x,y,z=spGetUnitPosition(unitID)
          if CAM_MODE==4 then
            Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            enableTrackingMode(unitID)
          end
          if CAM_MODE==5 then
            Spring.SetCameraState({name=ta,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
          end
          Spring.Echo("spring mode 7")
          break
        end
      end
    else
      revents.x=nil
      for unitID, d in pairs(damageMap) do
        if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID)then
          x,y,z=spGetUnitPosition(unitID)
          if CAM_MODE==4 then
            Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
            enableTrackingMode(unitID)
          end
          if CAM_MODE==5 then
            Spring.SetCameraState({name=ta,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+200,pz=z,rz=activescroll*20,dx=activescroll*20,dy=-1,ry=9,rx=-1,dz=-0.5,oldHeight=450},activescroll)
          end
          Spring.Echo("spring mode 8")
          break
        end
      end
    end
    WantedX=nil
    WantedZ=nil
    --clearTrackingMode()
    --local x,_,z=Spring.GetUnitPosition(unitID)
    --PickCameraMode(x-7,z)
    --Spring.SetCameraState({name=fps,mode=0,px=x,py=Spring.GetGroundHeight(x,z)+550,pz=z,rz=1000,dx=200,dy=4,ry=-50,rx=-1,dz=20,oldHeight=1500},TRANSITION_DURATION)
  end
end

--------------------------------------------------------------------------------

function widget:UnitTaken(unitID, unitDefID)
  revents.x, revents.y, revents.z = spGetUnitPosition(unitID)
  revents.u=unitID
  damageMap[unitID] = nil
  AddEvent(unitID, unitDefID, TAKE_EVENT)
end

--------------------------------------------------------------------------------

function widget:StockpileChanged(unitID, unitDefID, unitTeam,
                                 weaponNum, oldCount, newCount)
  if (newCount > oldCount) then
    AddEvent(unitID, unitDefID, STOCKPILE_EVENTS, 100)
  end
end

--------------------------------------------------------------------------------

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID)
  revents.x, revents.y, revents.z = spGetUnitPosition(unitID)
  revents.u=unitID
  if (not spIsUnitAllied(unitID)) then
    return
  end
  if (damage <= 0) then
    return
  end

  local ud = UnitDefs[unitDefID]
  if (ud == nil) then
    return
  end

  -- clamp the damage
  damage = math.min(ud.health, damage)

  -- scale the damage value
  if (paralyzer) then
    damage = (paraHealthScale * damage) +
             (paraFracScale   * (damage / ud.health)) 
  else
    damage = (healthScale * damage) +
             (fracScale   * (damage / ud.health)) 
  end


  local d = damageMap[unitID]
  if (d ~= nil) then
    d.a = attackerID
    if (paralyzer) then
      d.p = d.p + damage
    else
      d.v = d.v + damage
    end
  else
    d = {}
    d.u = unitID
    d.a = attackerID
--    d.t = GetGameSeconds()
    if (paralyzer) then
      d.v = 0
      d.p = math.max(1, damage)
    else
      d.v = math.max(1, damage)
      d.p = 0
    end
      d.dx=revents.x
      d.dz=revents.z
      damageMap[unitID] = d
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------