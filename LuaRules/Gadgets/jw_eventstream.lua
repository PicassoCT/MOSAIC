function gadget:GetInfo()
    return {
        name = "EventStream",
        desc = "This gadget streams eventsfunctions until they get deactivated or remove themselves",
        author = "This one, no, this one shall not pass. He shall remain outside, for he is evil, mending riddles to problems that need no solving. Answering questions we did not have.",
        date = "Sep. 2014",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
    }
end

--A Explanation:
--[[
Eventstreams are a attempt to optimize the number of necessary lua calls. Without the resorting to cumbersome if frame % magicnumber comparisons.
The Idea is simply- in every interesting case, there is a event that started it. And it knows best how to handle itself, 
what data to store, and when to remove itself from the world.

So for every event there is only a basic package needed - a function, a persistance table, and the frame in which it wants to be called..
	--Expected Tableformat:
	--GG.EventStream[nr] which contains Tables in the shape of"..
	--{id=id, Action = function(id,frame, persPack), persPack}"..
	-- 	Action handles the actual action, for example validation a unit still exists.
	--	It always returns a frameNr when it wants to be called Next, and the Persistance Package
	-- If it does not, the Action is considered done and is deleted after calling Final if that is defined -> Final(id, frame, PersPackage, startFrame)
	--adding the id of the action to GG.EventStreamDeactivate deletes the Action
	
	Once the function does not return a frame - the gadget recognizes the event as complete and delete the event. EventStreams are selfcontained and responsible for what they alter in the game world.
		
		Pros: Dezentralized and therefore Distributed Event management
		Cons: Not ideal for Situations where many Units have to interact with one another- in that case you need to write a manager function which 
			]]

if (gadgetHandler:IsSyncedCode()) then
    local Events = {}
    GG.EventStreamID = 0

    local function DeactivateEvent(self, evtID)
        boolRemovedFunction = false

        for frames, EventTables in ipairs(Events) do
            for i = #EventTables, 1, -1 do
                if EventTables[i] == evtID then
                    table.remove(Events[frames], evtID)
                    boolRemovedFunction = true
                end
            end
        end
        return boolRemovedFunction
    end


    local function CreateEvent(self, action, persPack, startFrame)
        startFrame = math.max(startFrame, Spring.GetGameFrame())
        --	Spring.Echo("Create event "..(GG.EventStreamID+1).. "waiting for frame  "..startFrame)
        myID = GG.EventStreamID
        GG.EventStreamID = GG.EventStreamID + 1
        self[myID] = { id = myID, action = action, persPack = persPack, startFrame = startFrame }
        if not Events[startFrame] then Events[startFrame] = {} end
        Events[startFrame][#Events[startFrame] + 1] = myID

        return myID
    end

    local function InjectCommand(self, ...)
        self[#self + 1] = { ... }
    end

    if GG.EventStream == nil then GG.EventStream = { CreateEvent = CreateEvent, DeactivateEvent = DeactivateEvent } end
    if GG.EventStreamDeactivate == nil then GG.EventStreamDeactivate = {} end

    function gadget:GameFrame(frame)

        if Events[frame] then
            for i = 1, #Events[frame] do
                evtID = Events[frame][i]

                if GG.EventStream[evtID] then

                    nextFrame, GG.EventStream[evtID].persPack = GG.EventStream[evtID].action(evtID, frame, GG.EventStream[evtID].persPack, GG.EventStream[evtID].startFrame)

                    if nextFrame then
                        if not Events[nextFrame] then Events[nextFrame] = {} end
                        Events[nextFrame][#Events[nextFrame] + 1] = evtID
                    else
                        --Spring.Echo("Event "..evtID .." is completed" )
                        GG.EventStream[evtID] = nil
                    end
                end
            end
        end

        --handle EventStream
        Events[frame] = nil
    end
end