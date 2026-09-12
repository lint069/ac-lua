local app = require('_app')
local run = require('_run')
local input = require('_input')

local mainUI = {}

---@param label string
---@param targetMode string
local function modeButton(label, targetMode, width)
    local isActive = (app.mode == targetMode)
    if isActive then
        ui.pushStyleColor(ui.StyleColor.Button, ui.styleColor(ui.StyleColor.ButtonActive))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm.colors.white)
    else
        ui.pushStyleColor(ui.StyleColor.Button, ui.styleColor(ui.StyleColor.Button))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.6, 0.6, 0.6, 1.0))
    end

    if ui.button(label .. "##mode_" .. targetMode, vec2(width, 24)) and not isActive then
        app.mode = targetMode
    end

    ui.popStyleColor(2)
end

local function drawIdle()
    ui.alignTextToFramePadding()
    ui.text("Scenario:")
    ui.sameLine(75)
    ui.setNextItemWidth(ui.availableSpaceX())

    local currentScenario = app.scenarios[app.scenarioIndex]
    local displayName = string.format("%s (%ds)", currentScenario.name, math.floor(currentScenario.duration))
    if ui.beginCombo("##scenario_combo", displayName) then
        for i = 1, #app.scenarios do
            local s = app.scenarios[i]
            local name = string.format("%s (%ds)", s.name, math.floor(s.duration))
            if ui.selectable(name, i == app.scenarioIndex) then
                app.selectScenario(i)
            end
        end

        ui.endCombo()
    end

    ui.alignTextToFramePadding()
    ui.text("Mode:")
    ui.sameLine(75)

    local modeWidth = (ui.availableSpaceX() - 4) * 0.5
    modeButton("Challenge", "CHALLENGE", modeWidth)
    ui.sameLine(0, 4)
    modeButton("Freeplay", "FREEPLAY", modeWidth)

    --ui.dummy(vec2(0, 4))

    if ui.button("Start", vec2(ui.availableSpaceX(), 28)) then
        app.start()
        input.setCaptured(true)
    end
end

local function drawRunning()
    local currentScenario = app.scenarios[app.scenarioIndex]
    ui.text(currentScenario.name)
    ui.separator()

    if run.state == run.STATE.COUNTDOWN then
        ui.text(string.format("Starting in: %.1fs", run.countdown))
    else
        local timeLeft = (app.mode == "FREEPLAY") and run.elapsed or math.max(0, run.duration - run.elapsed)
        local label = (app.mode == "FREEPLAY") and "Elapsed:" or "Time left:"
        ui.text(string.format("%s %.1fs", label, timeLeft))
        ui.text(string.format("Score: %d   Hits: %d   Misses: %d", currentScenario.score, currentScenario.hits, currentScenario.misses))
        local acc = currentScenario.shots > 0 and (currentScenario.hits / currentScenario.shots * 100) or 0
        ui.text(string.format("Accuracy: %.1f%%", acc))
    end

    ui.dummy(vec2(0, 4))
    local halfW = (ui.availableSpaceX() - 4) * 0.5
    if ui.button("Restart (R)", vec2(halfW, 26)) or input.binds.restart:pressed() then
        app.start()
        input.setCaptured(true)
    end

    ui.sameLine(0, 4)

    if ui.button("Pause", vec2(halfW, 26)) or input.binds.pause:pressed() then
        run.pause()
        input.setCaptured(false)
    end
end

local function drawPaused()
    ui.text("Paused")
    ui.separator()

    local currentScenario = app.scenarios[app.scenarioIndex]
    local acc = currentScenario.shots > 0 and (currentScenario.hits / currentScenario.shots * 100) or 0
    ui.text(string.format("Score: %d   Accuracy: %.1f%%", currentScenario.score, acc))

    ui.dummy(vec2(0, 4))

    if ui.button("Resume", vec2(ui.availableSpaceX(), 26)) or input.binds.pause:pressed() then
        run.resume()
        input.setCaptured(true)
    end

    local halfW = (ui.availableSpaceX() - 4) * 0.5

    if ui.button("Restart (R)", vec2(halfW, 24)) or input.binds.restart:pressed() then
        app.start()
        input.setCaptured(true)
    end

    ui.sameLine(0, 4)

    if ui.button("Stop", vec2(halfW, 24)) then
        run.reset()
        input.setCaptured(false)
    end
end

local function drawFinished()
    local res = run.result.scenario
    ui.text("Run complete")
    ui.separator()

    ui.text(string.format("Final score: %d", res.score))
    ui.text(string.format("Accuracy: %.1f%%", res.accuracy))
    ui.text(string.format("Hits / misses: %d / %d (Shots: %d)", res.hits, res.misses, res.shots))

    ui.dummy(vec2(0, 4))
    local halfW = (ui.availableSpaceX() - 4) * 0.5

    if ui.button("Play again", vec2(halfW, 26)) or input.binds.restart:pressed() then
        app.start()
        input.setCaptured(true)
    end

    ui.sameLine(0, 4)

    if ui.button("Back", vec2(halfW, 26)) then
        run.reset()
    end
end

function mainUI.draw(dt)
    if run.state == run.STATE.IDLE then
        drawIdle()
    elseif run.state == run.STATE.COUNTDOWN or run.state == run.STATE.RUNNING then
        drawRunning()
    elseif run.state == run.STATE.PAUSED then
        drawPaused()
    elseif run.state == run.STATE.FINISHED and run.result then
        drawFinished()
    end
end

return mainUI
