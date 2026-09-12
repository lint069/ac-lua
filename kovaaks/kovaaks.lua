local settingsUI = require('_gui/settings')
local mainUI = require('_gui/main')
local app = require('_app')
local settings = require('_settings')

local sim = ac.getSim()

local function drawCrosshair()
    local window = sim.windowSize
    local size = settings.crosshair_size
    local col = settings.crosshair_color
    ui.transparentWindow('crosshair', vec2((window.x - size) / 2, (window.y - size) / 2), vec2(size, size), true, function()
        ui.drawRectFilled(vec2(4, 2), vec2(6, 8), col)
        ui.drawRectFilled(vec2(2, 4), vec2(8, 6), col)
    end)
end

function script.update(dt)
    app.update(dt)
end

render.on('main.root.transparent', function()
    app.render()
end)

function script.windowSettings(dt)
    settingsUI.draw(dt)
end

function script.windowMain(dt)
    drawCrosshair()
    mainUI.draw(dt)
end
