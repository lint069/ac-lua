local rng = require('_rng')
local run = {
    STATE = {
        IDLE = "IDLE",
        COUNTDOWN = "COUNTDOWN",
        RUNNING = "RUNNING",
        PAUSED = "PAUSED",
        FINISHED = "FINISHED",
    },
    state = "IDLE",
    result = nil,
    seed = 1,
    countdown = 0.0,
    elapsed = 0.0,
    duration = 30.0,
}

local runRng = nil

---begins run starting with a countdown
---@param world table
---@param scenario table
---@param mode string?
function run.start(world, scenario, mode)
    run.mode = mode or "CHALLENGE"
    run.duration = (run.mode == "FREEPLAY") and math.huge or scenario.duration
    run.result = nil
    runRng = rng.new(run.seed)
    scenario.reset(world, runRng)
    run.countdown = 3.0
    run.elapsed = 0.0
    run.state = run.STATE.COUNTDOWN
end

function run.pause()
    if run.state == run.STATE.RUNNING then
        run.state = run.STATE.PAUSED
    end
end

function run.resume()
    if run.state == run.STATE.PAUSED then
        run.state = run.STATE.RUNNING
    end
end

---reset lifecycle back to IDLE and clear any previous run results
function run.reset()
    run.state = run.STATE.IDLE
    run.result = nil
    run.countdown = 0.0
    run.elapsed = 0.0
end

---casts ray from camera into world targets and notifies scenario
---@param world table
---@param camera table
---@param scenario table
function run.shot(world, camera, scenario)
    if run.state ~= run.STATE.RUNNING then
        return nil
    end

    local hitTarget = world.raycastTarget(
        camera.position,
        camera.look
    )

    if hitTarget then
        scenario.onHit(world, hitTarget, runRng)
        return true
    end

    scenario.onMiss(world, runRng)
    return false
end

---advances simulation
---@param dt number
---@param scenario table
function run.update(dt, scenario)
    if run.state == run.STATE.COUNTDOWN then
        run.countdown = run.countdown - dt
        if run.countdown <= 0.0 then
            run.countdown = 0.0
            run.state = run.STATE.RUNNING
        end
        return
    end

    if run.state ~= run.STATE.RUNNING then
        return
    end

    run.elapsed = run.elapsed + dt
    if run.elapsed >= run.duration then
        run.elapsed = run.duration
        run.state = run.STATE.FINISHED
        run.result = {
            duration = run.elapsed,
            seed = run.seed,
            scenario = scenario.getResult(),
        }
    end
end

return run
