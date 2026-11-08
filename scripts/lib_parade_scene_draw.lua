-- Shared world-space geometry for the visible parade scene and its radiance.
-- Raw appended mesh coordinates deliberately bypass the payload import matrix.
return function(gl, queue, beforePiece)
    local function drawPiece(object, piece, opacity)
        if beforePiece then beforePiece(object, piece, opacity)
        else gl.Color(1, 1, 1, opacity) end
        gl.UnitPiece(object.id, piece)
    end
    for _, object in ipairs(queue) do
        local pose, template = object.pose, object.template
        gl.PushPopMatrix(function()
            gl.Translate(pose.x, pose.y, pose.z)
            gl.Rotate(pose.yaw, 0, 1, 0)
            gl.Rotate(pose.tilt, 1, 0, 0)
            if pose.roll then gl.Rotate(pose.roll, 0, 0, 1) end
            local opacity = object.opacity
            if template.piece ~= nil then
                drawPiece(object, template.piece, opacity)
                for _, wing in ipairs(template.wings or {}) do
                    gl.PushPopMatrix(function()
                        local p, axis = wing.pivot, wing.axis
                        gl.Translate(p[1], p[2], p[3])
                        gl.Rotate((pose.wingFlap or 0) * wing.sign, axis[1], axis[2], axis[3])
                        gl.Translate(-p[1], -p[2], -p[3])
                        drawPiece(object, wing.piece, opacity)
                    end)
                end
            else
                drawPiece(object, template.body, opacity)
                gl.PushPopMatrix(function()
                    local pivot = template.headPivot
                    gl.Translate(pivot[1], pivot[2], pivot[3])
                    gl.Rotate(pose.headTilt, 0, 0, 1)
                    gl.Translate(-pivot[1], -pivot[2], -pivot[3])
                    drawPiece(object, template.head, opacity)
                    opacity = math.min(1, object.opacity * 1.12)
                    drawPiece(object, template.mask, opacity)
                end)
            end
        end)
    end
end
