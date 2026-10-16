-- Context-free civilian dialogue built from TRIZ-style transformations.
-- It deliberately starts without a subject. Anchors may be injected by the
-- listener later; even then the following turns continue to operate on the
-- abstract relation rather than becoming a conventional topic conversation.
local M = {}

local function generator(seed)
    seed = math.floor(tonumber(seed) or 1) % 2147483647
    if seed == 0 then seed = 1 end
    return function(n)
        seed = (seed * 48271) % 2147483647
        return seed % n + 1
    end
end

local function pick(t, random) return t[random(#t)] end

local contradictions = {
    {"more open", "more controlled"}, {"more permanent", "easier to change"},
    {"faster", "gentler"}, {"cheaper", "more reliable"},
    {"closer", "more independent"}, {"simpler", "more capable"},
    {"more visible", "more private"}, {"more stable", "more adaptable"},
    {"larger", "less intrusive"}, {"more precise", "less fragile"},
    {"more available", "harder to misuse"}, {"more uniform", "more local"},
}

local abstractThings = {
    "the thing", "that part", "the arrangement", "the process", "the middle bit",
    "the boundary", "the expensive part", "the part that keeps failing", "the useful part",
    "the part nobody wants to touch", "the bit between them", "the whole setup",
}

local resources = {
    "the gap", "the delay", "the waste", "the surrounding space", "the idle time",
    "the thing already carrying the load", "the unwanted side-effect", "the leftover heat",
    "the repetition", "the difference between the two sides", "the thing you were going to remove",
}

-- All 40 classical inventive principles are represented explicitly. The lines
-- are phrased as ordinary opaque conversation rather than as engineering advice.
local principles = {
    {"Segmentation", "Break {thing} into parts and stop asking every part to obey the same rule."},
    {"Taking out", "Take the troublesome bit out of {thing}; keep only the part that actually has to be there."},
    {"Local quality", "Why should every part be the same? Make each place good at the one thing it does there."},
    {"Asymmetry", "If symmetry is what traps you, make one side deliberately different."},
    {"Merging", "Put the things that keep meeting into one operation instead of making them find each other every time."},
    {"Universality", "Make one part do the second job too, then you can throw the extra part away."},
    {"Nested doll", "Put one inside the other. Or put the difficult part inside the part that already protects it."},
    {"Anti-weight", "Let something else carry the burden. It does not have to support itself in the obvious way."},
    {"Preliminary anti-action", "Do the opposite damage in advance, so the real action only brings it back to neutral."},
    {"Preliminary action", "Do the awkward part beforehand, while nobody is waiting for it."},
    {"Beforehand cushioning", "Assume it will fail and place the soft landing before it gets the chance."},
    {"Equipotentiality", "Stop making it climb and fall through the problem. Keep it on one level if you can."},
    {"The other way round", "Reverse it. Make the fixed part move, or make the result cause the action."},
    {"Spheroidality", "The corner may be the problem. Curve the path, roll it, bend the straight assumption."},
    {"Dynamics", "Do not make {thing} choose one shape forever. Let it change while it is being used."},
    {"Partial or excessive action", "If the exact amount is impossible, deliberately do too much or too little and correct the remainder."},
    {"Another dimension", "You are solving it on one line. Move the conflict into another direction or stack the parts."},
    {"Mechanical vibration", "Make it pulse, shake, or resonate instead of forcing it continuously."},
    {"Periodic action", "It does not need to happen all the time. Let the pauses do part of the work."},
    {"Continuity of useful action", "But if the useful part keeps stopping, remove the dead time and keep that part running."},
    {"Skipping", "Pass through the dangerous stage quickly enough that it barely has time to matter."},
    {"Blessing in disguise", "Use the nuisance as the resource. If it is already hurting you, make it pay rent."},
    {"Feedback", "Let the result change the next action instead of deciding everything in advance."},
    {"Intermediary", "Put a temporary middleman between them. The middleman can disappear afterward."},
    {"Self-service", "Make {thing} maintain itself with the waste or motion it already produces."},
    {"Copying", "Do it to a copy, a shadow, a model, or a signal instead of touching the original."},
    {"Cheap short-living objects", "Stop protecting the disposable part. Make it cheap enough to die on schedule."},
    {"Mechanics substitution", "Replace contact with a field, a signal, light, sound, anything that does not need the same mechanism."},
    {"Pneumatics and hydraulics", "Let pressure or flow take the shape instead of building a rigid answer."},
    {"Flexible shells and thin films", "Use a skin instead of a wall. It only needs to separate, not become a monument."},
    {"Porous materials", "Put empty space inside it on purpose. The holes can be the useful part."},
    {"Color changes", "Make the state announce itself. If you can see the change, you do not need another measurement."},
    {"Homogeneity", "Make the contacting parts more alike so the boundary stops being the weak point."},
    {"Discarding and recovering", "Throw away the part once it has done its job, or let it come back only when needed."},
    {"Parameter changes", "Change the degree, concentration, flexibility, temperature, or timing before you change the whole design."},
    {"Phase transitions", "Use the moment it changes state. The transition itself can do the work."},
    {"Thermal expansion", "Let expansion or contraction provide the motion instead of adding another mechanism."},
    {"Strong oxidants", "Change the medium so the reaction becomes easier rather than forcing the old one harder."},
    {"Inert atmosphere", "Or remove the reactive surroundings entirely and let it happen in a quiet medium."},
    {"Composite materials", "Stop asking one material or one rule to do everything. Combine unlike parts deliberately."},
}

local separations = {
    {"space", "It can be both things if the two demands live in different places."},
    {"time", "It can be both things if they are true at different times."},
    {"parts-whole", "Let the parts have one property and the whole have the opposite property."},
    {"condition", "Make the rule change with the condition instead of pretending one rule fits every case."},
}

local ariz = {
    "Strip it down to the smallest version of the problem. What two things are actually fighting?",
    "Push the conflict to the absurd extreme. If it still makes sense there, you found the real contradiction.",
    "Where exactly does the conflict happen? Not the whole world -- the small zone where both demands collide.",
    "And when does it happen? The timing may be the resource you are ignoring.",
    "The best result is the function happening with almost nothing added. Start from that and work backward.",
    "Use what is already present before you import another part. {resource} is still a resource.",
    "State both opposite requirements at once. If you soften either one too early, you are just bargaining.",
    "If the first problem refuses to move, replace it with the problem underneath it and solve that instead.",
    "Afterward, check what new harm the solution creates. A clever answer that moves the damage is not finished.",
}

-- Su-Field / 76-standard-solution coverage is represented by all five classical
-- classes. The exact standards are solution templates inside these classes; for
-- dialogue we abstract them to relation transforms rather than technical jargon.
local suFieldClasses = {
    {"build-or-destroy", "If the interaction is missing, complete it. If the interaction is harmful, interrupt it with a third thing or a counter-action."},
    {"develop", "If the interaction exists but is weak, make it more controllable, more structured, more dynamic, or better timed."},
    {"supersystem-microlevel", "If local changes are exhausted, go one level up and combine systems, or one level down and change the smallest working parts."},
    {"measure-detect", "If you cannot measure it directly, measure a copy, a change, a resonance, or redesign it so measurement is unnecessary."},
    {"helpers", "Introduce nothing if nothing will do: use a void, an existing field, the environment, a temporary additive, or a phase change."},
}

local evolution = {
    {"completeness", "Maybe it is not broken; maybe one necessary part of the loop was never there."},
    {"energy conductivity", "Something has to carry the effect through every part. Find where the flow stops."},
    {"rhythm coordination", "The parts may be fine and simply out of rhythm. Match their timing before replacing anything."},
    {"increasing ideality", "Every generation should do more useful work with less baggage. If it grows heavier, ask why."},
    {"uneven development", "One part has evolved faster than the others. The old part is now the bottleneck."},
    {"transition to supersystem", "When the thing itself is mature, the next change happens in the larger system around it."},
    {"macro to micro", "When shape stops helping, move the work down into smaller structure."},
    {"more field interactions", "Eventually the crude contact gives way to something controlled at a distance or through a field."},
}

local ideality = {
    "The ideal version is the one where the job still happens after the apparatus disappears.",
    "Remove the supporting function. Then remove the part that existed only to support it.",
    "Make it serve itself before adding another servant.",
    "Replace the part, then ask whether the replacement can also disappear.",
    "Change the principle of operation instead of polishing the old mechanism forever.",
    "Use {resource}; paying twice for a resource you already own is the least ideal answer.",
}

local dwarfs = {
    "Pretend {thing} is made of a crowd of tiny workers. What single rule should each one follow?",
    "Imagine every speck can move independently. The shape you need might emerge without a central instruction.",
    "Do not picture the object. Picture thousands of little agents passing the effect from one to the next.",
}

local extendedMethods = {
    {"innovation-questionnaire", "Before solving it, list what must not change, what may change, what failed before, and what a successful answer would make unnecessary."},
    {"function-structure", "Forget the objects for a moment. Who acts on whom, and which action is useful, harmful, missing, or excessive?"},
    {"SAO", "Say it as subject, action, object. If you cannot name those three, you are still talking around the problem."},
    {"process-analysis", "Walk through the sequence. The waste may be between steps rather than inside any one step."},
    {"size-time-cost", "Now imagine it at zero size, infinite size, zero time, infinite time, free, and impossibly expensive. Which assumption breaks first?"},
    {"anticipatory-failure", "Instead of asking how to make it work, ask how you would guarantee failure. Then stop doing those things."},
    {"resource-checklist", "Count the unused space, time, motion, heat, information, materials, differences, and side-effects before buying anything new."},
}

local sCurves = {
    "Maybe you are treating something mature as though it is still in its first growth phase.",
    "If improvement is flattening out, pushing harder may be worse than jumping to the next principle.",
    "Early on, every small effort looks useless. Later, the same effort compounds. Which part of the curve are you actually on?",
}

local anchors = {
    "my brother's custody arrangement", "my aunt moving in with us", "my daughter's school transfer",
    "my father selling the old place", "my cousin's wedding debt", "my mother's care rota",
    "the fridge I bought second-hand", "that cheap phone I ordered", "the heat pump in the flat",
    "the replacement battery I bought", "that sofa warranty", "the kitchen printer",
    "the co-op shares", "the rooftop solar scheme", "the freight bond", "the neighborhood battery pool",
    "the clinic franchise", "the micro-flat deposit", "whether I should move districts", "taking the night shift",
    "quitting my contract", "getting married", "going back to school", "letting a friend stay for a month",
    "the landlord's buyout offer", "the insurance settlement", "the rent increase", "the job transfer",
}

local anchorPhrases = {
    "I'm talking about {anchor}.",
    "That's what I mean about {anchor}.",
    "You know this is about {anchor}, right?",
    "Apply that to {anchor} and it stops sounding abstract.",
    "For me, this is {anchor}.",
}

local rebuttals = {
    "No, no, I actually meant {anchor}.",
    "No. You're anchoring it wrong -- I meant {anchor}.",
    "Not that. I meant {anchor}.",
    "No, forget the first example. I was talking about {anchor}.",
}

local openers = {
    "You're still treating the contradiction like a compromise.",
    "The obvious version only looks obvious because you named it too early.",
    "It can satisfy both conditions. Just not in the same way at the same moment.",
    "You're solving the object. I'm talking about the relation.",
    "The part you call a drawback may be the only free resource in the whole thing.",
}

local replies = {
    "That sounds neat, but what changes first?",
    "All right. Keep going.",
    "Only if you can do it without adding another dependency.",
    "You're hiding the cost in the word 'just'.",
    "Then the boundary matters more than the thing itself.",
    "I can see the inversion. I don't know if I buy it yet.",
}

local function render(s, slots)
    return (s:gsub("{(%w+)}", function(k) return tostring(slots[k] or "") end))
end

local function differentAnchor(random, previous)
    if #anchors <= 1 then return anchors[1] end
    local a = pick(anchors, random)
    local guard = 0
    while a == previous and guard < 8 do a = pick(anchors, random); guard = guard + 1 end
    return a
end

local function principleLine(random, slots, meta)
    local p = pick(principles, random)
    meta.principles[p[1]] = true
    return render(p[2], slots)
end

local function methodLine(random, slots, meta)
    local family = random(9)
    if family <= 3 then
        meta.methods.principles = true
        return principleLine(random, slots, meta)
    elseif family == 4 then
        meta.methods.separation = true
        local s = pick(separations, random); meta.separations[s[1]] = true; return s[2]
    elseif family == 5 then
        meta.methods.ariz = true
        return render(pick(ariz, random), slots)
    elseif family == 6 then
        meta.methods.sufield = true
        local s = pick(suFieldClasses, random); meta.suFieldClasses[s[1]] = true; return s[2]
    elseif family == 7 then
        meta.methods.evolution = true
        local s = pick(evolution, random); meta.evolution[s[1]] = true; return s[2]
    elseif family == 8 then
        meta.methods.ideality = true
        if random(4) == 1 then meta.methods.dwarfs = true; return render(pick(dwarfs, random), slots) end
        return render(pick(ideality, random), slots)
    else
        if random(3) == 1 then meta.methods.scurve = true; return pick(sCurves, random) end
        meta.methods.extended = true
        local s = pick(extendedMethods, random); meta.extended[s[1]] = true; return s[2]
    end
end

function M.build(seed, options)
    options = options or {}
    local random = generator(seed)
    local pair = pick(contradictions, random)
    local slots = {
        thing = pick(abstractThings, random), resource = pick(resources, random),
        improve = pair[1], protect = pair[2],
    }
    local meta = {
        anchorCount = 0, rebuttalCount = 0, principles = {}, separations = {},
        methods = {matrix=true}, suFieldClasses = {}, evolution = {}, extended = {},
    }
    local turns = options.turns or (6 + random(5)) -- 7..11 turns
    turns = math.max(4, math.min(16, math.floor(turns)))
    local lines = {pick(openers, random).." You want it "..slots.improve.." and "..slots.protect.." at once."}
    local pendingRebuttal, lastAnchor
    for i = 2, turns do
        local parts = {}
        if pendingRebuttal then
            local alternative = differentAnchor(random, lastAnchor)
            parts[#parts+1] = render(pick(rebuttals, random), {anchor=alternative})
            meta.rebuttalCount = meta.rebuttalCount + 1
            lastAnchor = alternative
            pendingRebuttal = false
        elseif random(5) == 1 then
            lastAnchor = differentAnchor(random, lastAnchor)
            parts[#parts+1] = render(pick(anchorPhrases, random), {anchor=lastAnchor})
            meta.anchorCount = meta.anchorCount + 1
            if random(3) == 1 then pendingRebuttal = true end
        elseif random(4) == 1 then
            parts[#parts+1] = pick(replies, random)
        end
        parts[#parts+1] = methodLine(random, slots, meta)
        lines[#lines+1] = table.concat(parts, " ")
    end
    -- An anchor on the final planned turn still gets the same one-in-three
    -- rebuttal chance; extend the exchange by one turn rather than silently
    -- dropping that state transition.
    if pendingRebuttal then
        local alternative = differentAnchor(random, lastAnchor)
        local prefix = render(pick(rebuttals, random), {anchor=alternative})
        meta.rebuttalCount = meta.rebuttalCount + 1
        lines[#lines+1] = prefix.." "..methodLine(random, slots, meta)
    end
    return lines, meta
end

function M.catalogue()
    return {
        inventivePrinciples = #principles,
        separationPrinciples = #separations,
        evolutionLaws = #evolution,
        arizMoves = #ariz,
        suFieldStandardSolutionClasses = #suFieldClasses,
        standardSolutionCorpusSize = 76,
        idealityRoutes = #ideality,
        dwarfModelMoves = #dwarfs,
        sCurveMoves = #sCurves,
        extendedMethods = #extendedMethods,
    }
end

return M
