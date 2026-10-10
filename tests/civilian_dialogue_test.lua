-- The synced civilian conversation builder must never abort a GameFrame.
local dialogue = assert(loadfile("scripts/lib_civilian_dialogue.lua"))()
local function check(seed, memory)
    local lines=dialogue.build(seed, memory)
    assert(type(lines)=="table" and #lines>=2, "conversation must contain lines")
    for i,line in ipairs(lines) do
        assert(type(line)=="string" and #line>0, "non-text conversation line "..i)
        assert(not line:find("{%w+}"), "unfilled dialogue slot")
    end
    return lines
end
for _,kind in ipairs({
    "gunfire", "injured", "home_lost", "companion_lost",
    "shopping", "luggage", "returned_home", "vehicle_exit",
    "brothel", "rain", "detour", "reunited", "unknown_memento",
}) do
    check(12345, {kind=kind,place="on Salm Street",vehicle="the taxi"})
end
check(1,nil);check(0,{});check(-1,{kind="rain"})
check(0/0,{kind="gunfire",place=7})
check(math.huge,{kind="unknown",place={}})
assert(table.concat(check(100,{kind="gunfire",place="at the mosque"})," "):find("mosque"))
assert(table.concat(check(100,{kind="gunfire",place="at the mosque"})," ") ==
    table.concat(check(100,{kind="gunfire",place="at the mosque"})," "),
    "dialogue selection must remain deterministic")
print("PASS civilian dialogue: events, slang slots, missing templates, malformed memories, seeded determinism")
