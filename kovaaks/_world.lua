local world = {
    environment = {
        backdrop = {
            z = 15.0,
            bounds = vec4(-4.5, 0.0, 4.5, 5.5)
        },
    },
    targets = {},
}

---analytic ray-sphere intersection test.
---https://how-to-3d.twodee.org/interaction/ray-sphere-intersection.html
---@param ro vec3
---@param rd vec3
---@param target table
---@return number distance
local function raySphere(ro, rd, target)
    local oc = ro - target.position
    local b = oc:dot(rd)
    local c = oc:dot(oc) - target.radius * target.radius
    local disc = b * b - c

    if disc < 0 then
        return -1
    end

    local t = -b - math.sqrt(disc)
    return t > 0 and t or -1
end

---clears all active targets from world
function world.clearTargets()
    table.clear(world.targets)
end

---adds geometric sphere target to world
---@param position vec3
---@param radius number
---@return table target
function world.addTarget(position, radius)
    local target = {
        position = vec3(position.x, position.y, position.z),
        radius = radius,
    }
    world.targets[#world.targets + 1] = target
    return target
end

---@param ro vec3
---@param rd vec3
---@return table|nil target
function world.raycastTarget(ro, rd)
    local closest = nil
    local closestDistance = math.huge

    for i = 1, #world.targets do
        local target = world.targets[i]
        local distance = raySphere(ro, rd, target)

        if distance > 0 and distance < closestDistance then
            closest = target
            closestDistance = distance
        end
    end

    return closest
end

return world
