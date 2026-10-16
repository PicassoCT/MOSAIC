-- Run from the repository root with Lua 5.1.
local function read(path)
    local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end
local function evaluate(path, env)
    local fn=assert(loadstring(read(path),"@"..path)); setfenv(fn,env); return fn()
end
local e=setmetatable({}, {__index=_G})
e.VFS={Include=function(path) return evaluate(path,e) end}

local triz=evaluate("scripts/lib_civilian_triz_dialogue.lua",e)
local dialogue=evaluate("scripts/lib_civilian_dialogue.lua",e)
local catalogue=triz.catalogue()
assert(catalogue.inventivePrinciples==40,"all 40 inventive principles must be present")
assert(catalogue.separationPrinciples==4,"all four separation principles must be present")
assert(catalogue.evolutionLaws==8,"all eight classical evolution laws must be present")
assert(catalogue.suFieldStandardSolutionClasses==5 and catalogue.standardSolutionCorpusSize==76,
    "Su-Field/76-standard-solution method coverage lost")
assert(catalogue.extendedMethods==7,"extended TRIZ method set incomplete")

for i=1,20 do
    assert(dialogue.contextFreeSelected(i,5,false)==(i%5==0),"every-fifth cadence drift")
    assert(not dialogue.contextFreeSelected(i,5,true),"urgent event must never be displaced")
end

local memory={kind="shopping",place="on Test Street"}
local forced,kind,forcedMeta=dialogue.build(123,memory,{forceContextFree=true,turns=8})
assert(kind=="contextfree" and #forced>=8,"forced context-free routing failed")
assert(not table.concat(forced,"\n"):find("Test Street",1,true),"context-free thread inherited a world anchor")
assert(type(forcedMeta)=="table","context-free metadata missing")

math.randomseed(881); local expected=math.random()
math.randomseed(881); triz.build(99); assert(math.random()==expected,"TRIZ dialogue consumed gameplay RNG")

local seenPrinciples,seenSeparations,seenSu,seenEvolution,seenExtended={},{},{},{},{}
local methodSeen={}
local noAnchor,withAnchor,withRebuttal=false,false,false
local anchors,rebuttals,anchorOpportunities=0,0,0
local examples={}
for seed=1,5000 do
    local lines,meta=triz.build(seed)
    assert(#lines>=7 and #lines<=21,"context-free thread length out of bounds")
    for _,line in ipairs(lines) do assert(type(line)=="string" and #line>0,"empty context-free turn") end
    local lines2,meta2=triz.build(seed)
    assert(table.concat(lines,"\n")==table.concat(lines2,"\n"),"context-free dialogue is nondeterministic")
    assert(meta.anchorCount==meta2.anchorCount and meta.rebuttalCount==meta2.rebuttalCount,
        "context-free metadata is nondeterministic")
    anchorOpportunities=anchorOpportunities+meta.anchorOpportunities
    anchors=anchors+meta.anchorCount
    rebuttals=rebuttals+meta.rebuttalCount
    noAnchor=noAnchor or meta.anchorCount==0
    withAnchor=withAnchor or meta.anchorCount>0
    withRebuttal=withRebuttal or meta.rebuttalCount>0
    for k in pairs(meta.principles) do seenPrinciples[k]=true end
    for k in pairs(meta.separations) do seenSeparations[k]=true end
    for k in pairs(meta.suFieldClasses) do seenSu[k]=true end
    for k in pairs(meta.evolution) do seenEvolution[k]=true end
    for k in pairs(meta.extended) do seenExtended[k]=true end
    for k in pairs(meta.methods) do methodSeen[k]=true end
    if meta.rebuttalCount>0 and not examples.rebuttal then examples.rebuttal=table.concat(lines,"\n") end
end

local function count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
assert(count(seenPrinciples)==40,"not all inventive principles are reachable")
assert(count(seenSeparations)==4,"not all separation principles are reachable")
assert(count(seenSu)==5,"not all Su-Field standard-solution classes are reachable")
assert(count(seenEvolution)==8,"not all evolution laws are reachable")
assert(count(seenExtended)==7,"not all extended methods are reachable")
assert(methodSeen.matrix and methodSeen.principles and methodSeen.separation and methodSeen.ariz and
    methodSeen.sufield and methodSeen.evolution and methodSeen.ideality and methodSeen.dwarfs and
    methodSeen.scurve and methodSeen.extended,"one or more TRIZ method families are unreachable")
assert(noAnchor and withAnchor and withRebuttal,"anchorless/anchored/rebuttal states must all be reachable")

local anchorRate=anchors/anchorOpportunities
local rebuttalRate=rebuttals/anchors
assert(anchorRate>0.18 and anchorRate<0.22,"anchor probability drift: "..anchorRate)
assert(rebuttalRate>0.27 and rebuttalRate<0.39,"rebuttal probability drift: "..rebuttalRate)

print("PASS context-free TRIZ dialogue: 1/5 cadence, 1/5 anchors, 1/3 rebuttals, determinism, RNG isolation, full method reachability")
if examples.rebuttal then print("--- example with anchor rebuttal ---\n"..examples.rebuttal) end
