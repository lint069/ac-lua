local scenario = {
    name = "1wall4targets",
    maxActiveTargets = 4,
    duration = 30.0,
    score = 0,
    hits = 0,
    misses = 0,
    shots = 0,
}

local radius = 0.30
local minX, maxX = -3.5, 3.5
local minY, maxY = 0.8, 4.5
local wallZ = 14.3

local minSpacing = radius * 2.2
local minSpacingSq = minSpacing * minSpacing

local targets = {}

local function randomPos(rng)
    local x = minX + rng:next() * (maxX - minX)
    local y = minY + rng:next() * (maxY - minY)
    return vec3(x, y, wallZ)
end

local function isValidPos(pos, ignoreTarget, previousPos)
    if previousPos then
        local dx = pos.x - previousPos.x
        local dy = pos.y - previousPos.y
        if (dx * dx + dy * dy) < minSpacingSq then
            return false
        end
    end

    for i = 1, #targets do
        local t = targets[i]
        if t ~= ignoreTarget then
            local dx = pos.x - t.position.x
            local dy = pos.y - t.position.y
            if (dx * dx + dy * dy) < minSpacingSq then
                return false
            end
        end
    end
    return true
end

local function pickValidPos(rng, ignoreTarget, previousPos)
    for _ = 1, 50 do
        local candidate = randomPos(rng)
        if isValidPos(candidate, ignoreTarget, previousPos) then
            return candidate
        end
    end
    return randomPos(rng)
end

---resets scenario state and spawns 4 non-overlapping targets on the wall
---@param world table
---@param rng table
function scenario.reset(world, rng)
    scenario.score = 0
    scenario.hits = 0
    scenario.misses = 0
    scenario.shots = 0

    world.clearTargets()
    table.clear(targets)

    for _ = 1, scenario.maxActiveTargets do
        local pos = pickValidPos(rng, nil, nil)
        local t = world.addTarget(pos, radius)
        targets[#targets + 1] = t
    end
end

---@param world table
---@param target table
---@param rng table
function scenario.onHit(world, target, rng)
    scenario.shots = scenario.shots + 1
    scenario.hits = scenario.hits + 1
    scenario.score = scenario.score + 1

    local oldPos = vec3(target.position.x, target.position.y, target.position.z)
    local newPos = pickValidPos(rng, target, oldPos)
    target.position:set(newPos)
end

---records missed shot
---@param world table
---@param rng table
function scenario.onMiss(world, rng)
    scenario.shots = scenario.shots + 1
    scenario.misses = scenario.misses + 1
end

---returns final metrics for a completed run
---@return table
function scenario.getResult()
    local accuracy = scenario.shots > 0 and (scenario.hits / scenario.shots * 100) or 0.0
    return {
        score = scenario.score,
        hits = scenario.hits,
        misses = scenario.misses,
        shots = scenario.shots,
        accuracy = accuracy,
    }
end

return scenario
