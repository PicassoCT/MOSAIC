-- Existing everyday exchanges plus combinatorial conspiracy threads. Dialogue
-- has its own deterministic random stream and never queries hidden game intel.
local M = {}
local conspiracy = VFS.Include("scripts/lib_civilian_conspiracy.lua")
local function choose(t, seed) return t[(seed % #t) + 1] end
local openers = {"Listen,", "For real,", "Look,", "Yo,", "Mate,", "No joke,"}
local reactions = {"That's rough.", "Man, this city.", "You're telling me.", "Yeah. I hear you.", "What a mess."}
local endings = {"Keep your head down, yeah?", "Get home in one piece.", "Catch you later. Stay sharp.", "We'll talk when it's quieter."}
local addresses = {"mate", "fam", "choom", "my friend", "boss"}
local hustles = {"make rent", "get a quiet minute", "get ahead", "keep my head above water"}
local systems = {"the landlord", "the billing bot", "the employment app", "some platform middleman"}
local fees = {"a convenience fee", "another subscription", "my last bit of money", "a premium upgrade"}
local events = {
    gunfire = {
        {"Something got hit {place}. Right by me. Left my whole day behind.", "You still out there?", "Those errands can wait. I'm getting clear.", "{ending}"},
        {"{opener} I was {place} when it kicked off. Still shaking.", "Sit somewhere safe for a minute.", "Trying. Every sudden noise sets me off again.", "Let me know when you're clear."},
    },
    injured = {{"Got hit {place}. I'm still here, but it hurts.", "Forget the errands. Find cover.", "That's the plan. Nothing I had to do was worth this.", "{ending}"}},
    home_lost = {{"My building's gone. Where am I supposed to go now?", "Have you got somewhere to stay?", "One step at a time. I haven't worked out the next one.", "We'll work something out."}},
    companion_lost = {{"The person I was walking with didn't make it.", "I'm here. You don't have to talk.", "We were just going about our day. That's all.", "Stay on the line."}},
    shopping = {
        {"Finally got my shopping done {place}.", "Worth the trip?", "I've got a bag in my hand. Calling that a win today.", "Small wins count, mate."},
        {"{opener} one errand finished. Bag acquired. Civilisation restored.", "Don't get ambitious. You still have to get it home.", "Let me enjoy these ten seconds, yeah?", "Fair. Carry on, big spender."},
    },
    luggage = {{"Finished up {place}. Now I'm dragging this bag around.", "You got a lift?", "Still sorting that out. This bag's getting heavier by the street.", "{ending}"}},
    returned_home = {{"Dropped my bags at home. Finally.", "You staying in?", "Tempting. Outside keeps finding new ways to be expensive.", "Put your feet up while you can."}},
    vehicle_exit = {{"Just got out of {vehicle} {place}.", "And now?", "Walking the rest. At least I know where my feet are taking me.", "Luxury transport: legs. No subscription yet."}},
    brothel = {
        {"I've been hanging about by that brothel {place}.", "Waiting for somebody?", "Still deciding whether to go in, if you must know.", "Your evening, mate. Mind the cameras."},
        {"The brothel's got me loitering outside like I forgot my own name.", "Go in or go home. You're wearing out the pavement.", "Since when did you become my life coach?", "Since you called me from the pavement."},
    },
    rain = {{"Got caught in the rain. Found somewhere to shelter.", "How's the grand adventure?", "Wet. Standing still. Character-building, apparently.", "Don't let them charge you for the character."}},
    detour = {{"Had to change my route. Trouble {place}.", "Better late than caught in it.", "Yeah. Wish the rest of my day understood that.", "{ending}"}},
    reunited = {{"Caught up with my people again.", "Good. Stick together.", "We are. Somebody's always stopping to look at something.", "Better waiting for them than looking for them."}},
}
local smallTalk = {
    {"Every camera on this street works. Every lift in my block doesn't.", "Different maintenance budget.", "Yeah. One keeps us safe, apparently.", "Guess which one they mean."},
    {"You reckon a machine can get sick of its job?", "Why?", "Want to know if my replacement will hate it as much as I do.", "Then you'll have something in common."},
    {"Double or Nothing. That's a threat disguised as a business name.", "You putting money down?", "I've got enough riding on surviving the actual day.", "For once, a sensible investment."},
    {"My landlord calls it a living space.", "It is, though.", "So is the space under a bus. Doesn't make it premium.", "Don't give them ideas."},
    {"They keep saying this district's coming up.", "It might be.", "Yeah. The rent. Straight up. Like a godrod in reverse.", "At least one of those eventually comes down."},
    {"Imagine owning your own face outright.", "I do own my face.", "You read the camera company's terms?", "I'm hanging up before you ruin mirrors for me."},
    {"I want a quiet night. Food, music, nobody explaining history at gunpoint.", "High standards.", "I'm a demanding customer.", "Put it in the suggestion box. The armoured one."},
    {"Every job ad says we're a family.", "Maybe they're close-knit.", "Then why am I the only relative on probation?", "Ask at the next compulsory bonding session."},
    {"One day I'm going to live somewhere boring.", "You'll miss the excitement.", "I'll watch the news with the sound off. Same view, cheaper windows.", "Save me a room."},
    {"Whole city online and nobody can tell me when the bus is coming.", "The bus has privacy rights.", "Good for the bus. Happy for it.", "We should all aspire to be a bus."},
    {"{opener} I need a holiday from being reachable.", "Turn your phone off.", "Then how do I complain to you about being reachable?", "We've found the flaw in the plan."},
    {"You still chasing that promotion?", "Chasing is generous. It's driving away.", "Run faster, they say.", "Yeah, and pay for the road while you're at it."},
    {"{opener} every time I try to {hustle}, {system} wants {fee}.", "That's the hustle, {address}. Just not your hustle.", "Can I at least get a receipt for being played?", "Paper costs extra."},
    {"All I want is to {hustle}. Apparently that's a luxury lifestyle now.", "{reaction}", "Meanwhile {system} calls me a valued partner.", "Valued at whatever's left in your account, {address}."},
}
function M.build(seed, memory, options)
    options = options or {}
    local elaborate = options.forceConspiracy or
        conspiracy.selected(seed, options.conspiracyChance)
    local pool = memory and events[memory.kind] or smallTalk
    pool = pool or smallTalk
    local template = choose(pool, seed)
    local slots = {
        opener = choose(openers, math.floor(seed / 7)),
        reaction = choose(reactions, math.floor(seed / 13)),
        ending = choose(endings, math.floor(seed / 17)),
        address = choose(addresses, math.floor(seed / 19)),
        hustle = choose(hustles, math.floor(seed / 23)),
        system = choose(systems, math.floor(seed / 29)),
        fee = choose(fees, math.floor(seed / 31)),
        place = memory and memory.place or "round the corner",
        vehicle = memory and memory.vehicle or "the car",
    }
    local result = {}
    for i = 1, #template do
        result[i] = template[i]:gsub("{(%w+)}", function(key) return slots[key] or "" end)
    end
    if elaborate then
        -- Preserve the full personal-event exchange before spinning a theory
        -- around it. Without an event, start directly at the conspiracy opener.
        if not memory then result = {} end
        local rant = conspiracy.build(seed, memory, options)
        for i=1,#rant do result[#result+1] = rant[i] end
        return result, "conspiracy"
    end
    return result
end

function M.lineFrames(text, base)
    -- Long claims need reading time; short acknowledgements keep the old pace.
    return math.max(base or 150, math.min(12*30, math.ceil(#text / 22)*30))
end
return M
