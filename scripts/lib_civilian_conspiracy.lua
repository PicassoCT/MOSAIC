-- Shared conspiracy vocabulary. All legacy worries, theories and connectors
-- are retained; the legacy API and civilian exchanges use the same pools.
local M = {}
    local worries = {
      "financial stability",
      "losing a job",
      "not having enough savings",
      "retirement planning",
      "paying off debt",
      "affording healthcare",
      "cost of education",
      "housing costs",
      "unexpected expenses",
      "inflation and rising prices",
      "personal health issues",
      "the health of family members",
      "developing chronic illness",
      "mental health struggles",
      "weight and body image",
      "aging and losing independence",
      "accidents or injuries",
      "access to proper healthcare",
      "pandemic or epidemic outbreaks",
      "sleep problems",
      "relationship conflicts",
      "marriage stability",
      "divorce or breakup",
      "loneliness",
      "family expectations",
      "children’s future",
      "parenting struggles",
      "social rejection",
      "friendships fading",
      "not finding a partner",
      "career growth",
      "job performance",
      "lack of recognition at work",
      "work–life balance",
      "office politics",
      "changing careers",
      "not being skilled enough",
      "public speaking",
      "meeting deadlines",
      "job interviews",
      "safety and crime",
      "natural disasters",
      "political instability",
      "war or terrorism",
      "climate change",
      "losing important documents",
      "travel safety",
      "online privacy and data theft",
      "technology replacing jobs",
      "the uncertainty of the future"
    }

    local theories = {
      "the Illuminati quietly steering world events",
      "a looming New World Order",
      "chemtrails tweaking the populace",
      "5G towers whispering mind-control signals",
      "HAARP nudging the weather like a thermostat",
      "the Earth being flat and maps being lies",
      "the moon landing staged on a soundstage",
      "reptilian shapeshifters smiling on TV",
      "engineered storms disguised as ‘natural’ disasters",
      "crisis actors choreographing the nightly news",
      "a shadowy Deep State pulling the strings",
      "the Mandela Effect rewriting our memories",
      "time travelers patching the timeline on weekends",
      "the Philadelphia Experiment tearing little rips in space",
      "CERN opening portals to who-knows-where",
      "a hollow Earth with VIP parking inside",
      "a Bigfoot cover-up bigger than Bigfoot",
      "UFO reverse-engineering hidden in plain sight",
      "ancient aliens building all the monuments",
      "suppressed free energy gathering dust in a vault",
      "fluoridation as a compliance cocktail",
      "microchips lurking in everyday jabs and gadgets",
      "a planned global currency reset by a cabal",
      "MK-inspired media psyops on loop",
      "psychic warfare and remote viewing think tanks",
      "Bermuda Triangle field tests gone wrong",
      "UFOs rebranded as weather balloons (again)",
      "pharma burying simple natural cures",
      "Templar-level secret societies swapping passwords",
      "numerology codes steering the stock market",
      "crop circles as memo pads from beyond",
      "staged pandemics as levers of control",
      "leaders replaced by deepfake doubles",
      "a creeping global social credit grid",
      "smart fridges moonlighting as spies",
      "a simulation run by bored elites",
      "an AI overlord already calling the shots",
      "ancient underground cities beneath our feet",
      "food additives tuned for docility",
      "mind-reading satellites orbiting overhead",
      "archaeology timelines quietly airbrushed",
      "secret bases on the far side of the Moon",
      "Antarctica cordoned off for hidden stuff",
      "weather insurance schemes profiting on storms",
      "‘ghost frequencies’ nudging public mood",
      "celebrity occult parties with odd dress codes",
      "tunnels under cities connecting everything",
      "lottery numbers being gently steered",
      "cloud seeding as a cash machine",
      "directed-energy beams starting suspicious fires"
    }

    local openers = {
      "Listen, it all connects:",
      "You ever notice the pattern?",
      "Okay, so here’s what they don’t want you to map out:",
      "Call me wild, but the dots line up:",
      "I did the math on a napkin and—boom—",
      "They might call me crazy but -"
    }

    local links = {
      "which obviously loops back to",
      "and that’s precisely why it’s tied to",
      "and if you trace the paperwork, you hit",
      "which the headlines ‘forget’ to mention is part of",
      "and the timing always exposes",
      "and every breadcrumb points straight at",
      "so of course it intersects with",
      "and the pattern screams",
      "is obviously in on it with",
      "and did you ever notice how that rhymes with"
    }

    local pivots = {
      "Then it gets weirder:",
      "But wait—there’s a twist:",
      "Here’s the kicker:",
      "And just when you think you’ve got it:",
      "Naturally, the rabbit hole deepens:"
    }


    -- Utility: shallow copy + Fisher–Yates shuffle
    local function shuffled(t, random)
      local c = {}
      for i = 1, #t do c[i] = t[i] end
      for i = #c, 2, 1 do
        local j = random(i)
        c[i], c[j] = c[j], c[i]
      end
      return c
    end


function M.legacyRant(lines)
    -- Create shuffled copies so every run feels fresh
    local W = shuffled(worries, math.random)
    local T = shuffled(theories, math.random)

    -- Builder
    local parts = {}
    parts[#parts+1] = openers[math.random(#openers)] .. " "

    -- Start with the first pair
    parts[#parts+1] = ("I’m worried about %s, %s %s. "):format(
      W[1],
      links[math.random(#links)],
      T[1]
    )

    -- Chain the rest, weaving previous -> next
    for i = 2, math.min(#W, #T) do
      -- sprinkle pivots occasionally
      if i % 5 == 0 then
        parts[#parts+1] = pivots[math.random(#pivots)] .. " "
      end
      parts[#parts+1] = ("Then %s connects to %s, %s %s.  "):format(
        W[i-1],
        W[i],
        links[math.random(#links)],
        T[i]
      )
    end
    parts = {unpack(parts, 1, math.min(lines, #parts))}
    -- Grand “ta-da”
    parts[#parts+1] = ("So yeah, by the time you zoom out - its all connected."):format(math.min(#W, #T))

    return parts
end

-- Park-Miller arithmetic stays exact in Lua's double representation. Creating
-- dialogue must not consume the simulation's global math.random stream.
local function generator(seed)
    seed = math.floor(tonumber(seed) or 1) % 2147483647
    if seed == 0 then seed = 1 end
    return function(n)
        seed = (seed * 48271) % 2147483647
        return seed % n + 1
    end
end
local function pick(pool, random) return pool[random(#pool)] end
local evidence = {
    "my cousin's voice message", "a receipt with the wrong date",
    "a deleted forum post", "three identical vans outside my block",
    "a maintenance notice nobody signed", "the numbers on a broken billboard",
    "a delivery driver who wouldn't give his name", "a late-night pirate broadcast",
    "a screenshot of a screenshot", "the fine print on my water bill",
    "a bloke arguing with the ticket machine", "a password written inside a lift",
}
local motives = {
    "sell us the cure for a problem they manufactured",
    "make us pay rent on our own memories", "keep the whole district too tired to ask questions",
    "buy the land after everyone leaves", "train the machines on our panic",
    "make the emergency permanent", "turn every favour into a subscription",
    "get us to police each other for free", "privatise coincidence itself",
}
local challenges = {
    "How does %s prove anything about %s?",
    "You got from %s to %s without stopping for evidence?",
    "Couldn't %s just be somebody being incompetent?",
    "Yesterday you said %s was a distraction. Now it's the whole plan?",
    "And your source for %s is still that fucking screenshot?",
}
local conspiratorialReplies = {
    "Hang on. I heard about %s too. Different source. Unless it wasn't.",
    "If %s is one end, who's collecting at the other?",
    "So %s is only the cover story? Go on.",
    "That explains the thing with %s. I knew that wasn't random.",
}
local deflections = {
    "That's what makes the cover work.", "Exactly. It looks accidental if you don't follow the money.",
    "The contradiction is the signal, mate.", "They want us arguing about that bit.",
    "All right, that part could be bullshit. But listen to the next part.",
}
local experience = {
    gunfire="what happened when the shooting started", injured="how I got hurt",
    home_lost="my building getting destroyed", companion_lost="losing the person I was walking with",
    shopping="that shopping trip", luggage="the journey with my bag",
    returned_home="getting back home", vehicle_exit="that ride",
    brothel="what I saw outside the brothel", rain="getting caught in that rain",
    detour="having to change my route", reunited="finding my people again",
}

-- A complete argument, generated once and delivered in readable chapters by
-- civilian_daily_life. Replies affect the next claim instead of being filler.
-- No unit searches or secret game facts: these are the characters' allegations.
function M.build(seed, memory, options)
    options = options or {}
    local random = generator(seed)
    local W, T = shuffled(worries, random), shuffled(theories, random)
    local steps = options.links or (random(8) == 1 and (15 + random(5)) or (3 + random(5)))
    steps = math.max(2, math.min(20, math.floor(steps)))
    local lines, source, motive = {}, pick(evidence, random), pick(motives, random)
    local function pair(claim, reply)
        lines[#lines+1], lines[#lines+2] = claim, reply
    end
    local root = memory and experience[memory.kind] or W[1]
    if memory and experience[memory.kind] and memory.place then root = root.." "..memory.place end
    local believer = (options.listenerSeed or seed) % 3 == 0
    pair(pick(openers, random).." "..root.." connects to "..T[1]..". I found it in "..source..".",
        believer and "Wait. Start there. Who benefits?" or "That's a hell of a jump. Walk me through it.")
    local previous = T[1]
    for i=2,steps do
        local claim
        local branch = random(4)
        if branch == 1 then
            claim = pick(deflections, random).." Follow "..previous..": "..W[i].." "..
                pick(links, random).." "..T[i]..". The point is to "..motive.."."
        elseif branch == 2 then
            claim = pick(pivots, random).." "..previous.." is a front for "..T[i]..
                ". That's why "..W[i].." keeps coming up in "..source.."."
        elseif branch == 3 then
            local earlier = T[random(i-1)]
            claim = "Remember "..earlier.."? Put it next to "..T[i]..". "..
                "Two routes back to "..root..". Same people trying to "..motive.."."
        else
            claim = "Maybe I've got "..previous.." backwards. Suppose "..T[i]..
                " is running it, and "..W[i].." is how they recruit people. "..
                "That still takes us back to "..root.."."
        end
        local reply
        if believer then
            reply = pick(conspiratorialReplies, random):format(T[i])
        else
            local challenge = random(#challenges)
            reply = challenges[challenge]:format(challenge == 1 and source or T[i], T[i-1])
        end
        pair(claim, reply)
        -- Listener can be drawn in, or spot a contradiction and become sceptical.
        if random(4) == 1 then believer = not believer end
        previous = T[i]
    end
    pair("So "..root..", "..T[1]..", and now "..previous..". "..
        "All so they can "..motive..". By the time you zoom out, it's all connected.",
        believer and "Send me that thread. The original, before somebody edits it again." or
        "You started with one problem and came back with a government for the entire fucking universe.")
    return lines
end

function M.selected(seed, chance)
    return generator(seed)(100) <= (chance or 3)
end
return M
