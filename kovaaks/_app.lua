local input = require('_input')
local camera = require('_camera')
local run = require('_run')
local audio = require('_audio')
local renderer = require('_render/init')
local world = require('_world')

local scenarios = {
    require('scenarios/gridshot'),
    require('scenarios/1w4t'),
}

local scenario
local app = {
    scenarios = scenarios,
    scenarioIndex = 1,
    mode = "CHALLENGE", -- CHALLENGE | FREEPLAY
}

function app.selectScenario(index)
    local selected = scenarios[index]
    if not selected then
        ac.error('invalid scenario index: ' .. tostring(index))
    end

    run.reset()
    world.clearTargets()

    app.scenarioIndex = index
    scenario = selected
    renderer.setTargetCapacity(scenario.maxActiveTargets)
end

function app.start()
    run.start(world, scenario, app.mode)
end

function app.render()
    renderer.draw(world, camera)
end

app.selectScenario(1)

local function shoot()
    local hit = run.shot(world, camera, scenario)

    if hit == true then
        audio.playHit()
    elseif hit == false then
        audio.playMiss()
    end
end

---@param dt number
function app.update(dt)
    input.update()

    if input.capturePressed then
        input.setCaptured(not input.captured)
    end

    camera.update(input.captured and input.mouseDelta or nil)

    if input.captured and input.shootPressed then
        shoot()
    end

    run.update(dt, scenario)
end

return app
