-- Run from the game root: lua tests/operative_animation_arguments_test.lua
-- Execute real callback-bearing call sites against each script's real setter.
local paths = {
    'scripts/operativePropagatorScript.lua',
    'scripts/operativeInvestigatorScript.lua',
    'scripts/operativeassetscript.lua',
}
local compile = loadstring or load
local count = 0
for _,path in ipairs(paths) do
    local file = assert(io.open(path))
    local source = file:read('*a'); file:close()
    local setter = assert(source:match('(function setOverrideAnimationState%([^\n]*\n.-\nend)'))
    local env = setmetatable({
        eAnimState = {fighting='fighting',walking='walking',standing='standing',slaved='slaved',riding='riding'},
        boolInClosedCombat = true,
        unitID = 1,
        isTransported = function() return true end,
    }, {__index = _G})
    local function run(code)
        if setfenv then
            return setfenv(assert(compile(code,path)),env)()
        end
        return assert(load(code,path,'t',env))()
    end
    run(setter)
    for line in source:gmatch('[^\n]+') do
        if line:find('setOverrideAnimationState%(') and line:find('function%(') then
            run(line)
            assert(type(env.locConditionFunction)=='function',path..': missing callback')
            assert(env.locConditionFunction()==true,path..': callback was lost')
            assert(env.boolDecoupled==false,path..': decoupling argument shifted')
            count = count+1
        end
    end
    run('setOverrideAnimationState("aiming","walking",true,nil,false,{[1]=true},{[2]=true})')
    assert(env.upperOverrideMask[1] and env.lowerOverrideMask[2],path..': masks lost')
    local ok = pcall(run,'setOverrideAnimationState("aiming","walking",true,nil,false,false)')
    assert(not ok,path..': invalid mask must still be rejected')
end
assert(count == 8,'expected all eight combat/transport call sites')
print('PASS: eight real callback call sites, valid masks, invalid mask rejection')
