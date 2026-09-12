local rng = require('_rng')

local engine = {
    STATE = {
        IDLE = 'IDLE',
        COUNTDOWN = 'COUNTDOWN',
        RUNNING = 'RUNNING',
        PAUSED = 'PAUSED',
        FINISHED = 'FINISHED',
    },
    state = 'IDLE',
    result = nil,
    seed = 1,
    countdown = 0.0,
    elapsed = 0.0,
    duration = 30.0,
}

local runRng = nil

local FIXED_DT = 1 / 120
local MAX_STEPS = 8
local accumulator = 0

---Begins run starting with a countdown.
---@param world table
---@param scenario table
function engine.start(world, scenario)
    scenario.reset(world, runRng)
    runRng = rng.new(engine.seed)

    accumulator = 0

    engine.duration = scenario.duration
    engine.result = nil
    engine.countdown = 3.0
    engine.elapsed = 0.0
    engine.state = engine.STATE.COUNTDOWN
end

function engine.pause()
    if engine.state == engine.STATE.RUNNING then
        engine.state = engine.STATE.PAUSED
    end
end

function engine.resume()
    if engine.state == engine.STATE.PAUSED then
        engine.state = engine.STATE.RUNNING
    end
end

---Restarts scenario from countdown.
---@param world table
---@param scenario table
function engine.restart(world, scenario)
    engine.start(world, scenario)
end

---Reset lifecycle back to IDLE and clear any previous run results.
function engine.reset()
    engine.state = engine.STATE.IDLE
    engine.result = nil
    engine.countdown = 0.0
    engine.elapsed = 0.0

    accumulator = 0
end

---Analytic ray-sphere intersection test.
---https://how-to-3d.twodee.org/interaction/ray-sphere-intersection.html
---@param ro vec3
---@param rd vec3
---@param target table
---@return number distance
local function raySphereHit(ro, rd, target)
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

---Casts ray from camera into world targets and notifies scenario.
---@param world table
---@param camera table
---@param scenario table
function engine.shot(world, camera, scenario)
    if engine.state ~= engine.STATE.RUNNING then
        return
    end

    local ro = camera.position
    local rd = camera.look

    local bestDist = 1e9
    local hitTarget = nil

    for i = 1, #world.targets do
        local target = world.targets[i]
        local dist = raySphereHit(ro, rd, target)

        if dist > 0 and dist < bestDist then
            bestDist = dist
            hitTarget = target
        end
    end

    if hitTarget then
        if scenario.onHit then
            scenario.onHit(world, hitTarget, runRng)
        end
    else
        if scenario.onMiss then
            scenario.onMiss(world, runRng)
        end
    end
end

---Advances simulation by fixed timesteps.
---@param dt number @Delta Time
---@param world table
---@param scenario table
function engine.update(dt, world, scenario)
    if engine.state == engine.STATE.COUNTDOWN then
        engine.countdown = engine.countdown - dt

        if engine.countdown <= 0.0 then
            engine.countdown = 0.0
            engine.state = engine.STATE.RUNNING
        end

        return
    end

    if engine.state ~= engine.STATE.RUNNING then
        return
    end

    engine.elapsed = engine.elapsed + dt

    if engine.elapsed >= engine.duration then
        engine.elapsed = engine.duration
        engine.state = engine.STATE.FINISHED
        engine.result = {
            completed = true,
            duration = engine.elapsed,
            seed = engine.seed,
            scenario = scenario.getResult and scenario.getResult() or nil,
        }

        return
    end

    accumulator = accumulator + dt

    local steps = 0
    while accumulator >= FIXED_DT and steps < MAX_STEPS do
        if scenario.fixedUpdate then
            scenario.fixedUpdate(world, FIXED_DT, runRng)
        end

        accumulator = accumulator - FIXED_DT
        steps = steps + 1
    end

    --discard excess time if hitch exceeded maximum steps
    if accumulator >= FIXED_DT then
        accumulator = 0
    end
end

return engine
