-- The unsynced scenery renderer supplies the exact world poses it displayed.
-- Reuse its mesh transforms; do not capture the hidden authoring layout.
return function(Spring, gl, drawGeometry)
    local scene, definition, received = {}, nil, -100
    local api = {}
    function api.Receive(queue, defID)
        scene, definition, received = queue or {}, defID, Spring.GetGameFrame()
    end
    function api.Capture(propagation)
        if not propagation or not definition or #scene == 0
            or Spring.GetGameFrame() - received > 30 then return end
        local queue, checked = {}, {}
        local _, fullView = Spring.GetSpectatingState()
        for _, object in ipairs(scene) do
            local parent = object.parent
            if parent and checked[parent] == nil then
                local los = Spring.GetUnitLosState(parent, Spring.GetMyAllyTeamID())
                checked[parent] = Spring.ValidUnitID(parent) and not Spring.GetUnitIsDead(parent)
                    and not Spring.GetUnitNoDraw(parent) and not Spring.GetUnitIsCloaked(parent)
                    and (Spring.GetUnitRulesParam(parent, 'city_parade_retiring') or 0) == 0
                    and (fullView or (los and los.los)) or false
            end
            if checked[parent] and Spring.ValidUnitID(object.id) and not Spring.GetUnitIsDead(object.id)
                and Spring.GetUnitTransporter(object.id) == parent then
                queue[#queue + 1] = object
            end
        end
        if #queue == 0 then return end
        local diffuse = gl.Texture(0, string.format('%%%d:0', definition))
        local material = gl.Texture(1, string.format('%%%d:1', definition))
        if diffuse and material then
            gl.UniformInt(propagation.projectToBandLoc, 1)
            gl.UniformInt(propagation.texturedLoc, 1)
            gl.UniformInt(propagation.materialMaskedLoc, 1)
            gl.Color(1, 1, 1, 1)
            drawGeometry(gl, queue, function(_, _, opacity)
                gl.Uniform(propagation.emissionStrengthLoc, opacity)
            end)
        end
        gl.Texture(0, false); gl.Texture(1, false)
    end
    return api
end
