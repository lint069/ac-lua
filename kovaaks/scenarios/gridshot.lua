local gridshot = {
    name = "Gridshot 3x3",
    maxActiveTargets = 3,
    duration = 120.0,
    score = 0,
    hits = 0,
    misses = 0,
    shots = 0,
}

local radius = 0.5
local slots = {
    vec3(-1.5, 1.0, 14.3), vec3(0.0, 1.0, 14.3), vec3(1.5, 1.0, 14.3),
    vec3(-1.5, 2.5, 14.3), vec3(0.0, 2.5, 14.3), vec3(1.5, 2.5, 14.3),
    vec3(-1.5, 4.0, 14.3), vec3(0.0, 4.0, 14.3), vec3(1.5, 4.0, 14.3),
}

local targetSlots = {}

---resets scenario state and populates initial world targets
---@param world table
---@param rng table
function gridshot.reset(world, rng)
    gridshot.score = 0
    gridshot.hits = 0
    gridshot.misses = 0
    gridshot.shots = 0

    world.clearTargets()
    table.clear(targetSlots)

    local initial = { 2, 4, 9 }
    for i = 1, 3 do
        local slotIdx = initial[i]
        local target = world.addTarget(slots[slotIdx], radius)
        targetSlots[target] = slotIdx
    end
end

---@param world table
---@param target table
---@param rng table
function gridshot.onHit(world, target, rng)
    gridshot.shots = gridshot.shots + 1
    gridshot.hits = gridshot.hits + 1
    gridshot.score = gridshot.score + 1

    local oldSlot = targetSlots[target]

    local occupied = {}
    for _, slotIdx in pairs(targetSlots) do
        occupied[slotIdx] = true
    end

    local free = {}
    for s = 1, #slots do
        if not occupied[s] and s ~= oldSlot then
            free[#free + 1] = s
        end
    end

    local newSlot = free[rng:int(1, #free)]
    targetSlots[target] = newSlot
    target.position:set(slots[newSlot])
end

function gridshot.onMiss(world, rng)
    gridshot.shots = gridshot.shots + 1
    gridshot.misses = gridshot.misses + 1
end

---returns snapshot of results for completed run
---@return table
function gridshot.getResult()
    local accuracy = gridshot.shots > 0 and (gridshot.hits / gridshot.shots * 100) or 0.0
    return {
        score = gridshot.score,
        hits = gridshot.hits,
        misses = gridshot.misses,
        shots = gridshot.shots,
        accuracy = accuracy,
    }
end

return gridshot
