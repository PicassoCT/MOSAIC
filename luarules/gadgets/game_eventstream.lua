function gadget:GetInfo()
    return {
        name = "EventStream",
        desc = "This gadget streams eventsfunctions until they get deactivated or remove themselves",
        author = "This one, no, this one shall not pass. He shall remain outside, for he is evil, mending riddles to problems that need no solving. Answering questions we did not have.",
        date = "Sep. 2014",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true
    }
end

-- A Explanation:
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
    local EventStreamID = 0
    local function DeactivateEvent(self, evtID)
        if type(evtID) ~= "number" or self[evtID] == nil then return false end
        -- Queued IDs are skipped at dispatch; release the persistent data now.
        self[evtID] = nil
        return true
    end

    local function ScheduleFrame(requested, current)
        assert(type(requested) == "number" and requested == requested
            and requested > -math.huge and requested < math.huge,
            "EventStream requires a finite frame number")
        -- The current frame may already be dispatching or have finished.
        return math.max(current + 1, math.ceil(requested))
    end

    local function QueueEvent(id, frame)
        if not Events[frame] then Events[frame] = {} end
        Events[frame][#Events[frame] + 1] = id
    end

    local function CreateEvent(self, action, persPack, startFrame)
        assert(type(action) == "function", "EventStream requires a callback")
        startFrame = ScheduleFrame(startFrame, Spring.GetGameFrame())
        local myID = EventStreamID
        EventStreamID = EventStreamID + 1
        self[myID] = {
            id = myID,
            action = action,
            persPack = persPack,
            startFrame = startFrame
        }
        QueueEvent(myID, startFrame)
        return myID
    end

    if GG.EventStream == nil then
        GG.EventStream = {
            CreateEvent = CreateEvent,
            DeactivateEvent = DeactivateEvent
        }
    end
    if GG.EventStreamDeactivate == nil then GG.EventStreamDeactivate = {} end


    function gadget:GameFrame(frame)
        local due = Events[frame]
        Events[frame] = nil
        if not due then return end
        for i = 1, #due do
            local evtID = due[i]
            local event = GG.EventStream[evtID]
            if event then
                local nextFrame, persPack = event.action(evtID, frame,
                    event.persPack, event.startFrame)
                -- A callback may cancel itself or another queued event.
                if GG.EventStream[evtID] == event then
                    if nextFrame then
                        nextFrame = ScheduleFrame(nextFrame, frame)
                        event.persPack = persPack
                        QueueEvent(evtID, nextFrame)
                    else
                        GG.EventStream[evtID] = nil
                    end
                end
            end
        end
    end
end
