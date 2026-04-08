--[[
    - log file?
]]

local colors = require 'colors'

--#region Tables

local log = {
    lastString = '',
    lastStatus = '',
    lines = {},
}

--#endregion

--#region Helper Function

local function drawBlock()
    
end

--#endregion

--#region Drawing Functions

local function drawBackground()
    ui.drawRectFilled(vec2(0, 0), ui.windowSize(), colors.background)
end

local function drawDebugText()
    local windowSize = ui.windowSize()
    local loadingCanvas ---@type ui.ExtraCanvas

    if not loadingCanvas or loadingCanvas:size().x ~= windowSize.x then
        loadingCanvas = ui.ExtraCanvas(vec2(windowSize.x, windowSize.y))
    end

    loadingCanvas:clear(rgbm.colors.transparent):update(function()
        local status = loading.status()
        local details = loading.details()

        if status and status ~= log.lastStatus and status ~= '' then
            if log.lastStatus ~= '' then
                table.insert(log.lines, '')
            end

            log.lastStatus = status
            if details and details ~= log.lastString and details ~= '' then
                log.lastString = details
                table.insert(log.lines, status)
                table.insert(log.lines, '\t' .. details)
            else
                table.insert(log.lines, status)
            end
        else
            if details and details ~= log.lastString and details ~= '' then
                log.lastString = details
                table.insert(log.lines, '\t' .. details)
            end
        end
    end)

    local spinnerPos = 20
    local spinnerSize = 34
    ui.drawLoadingSpinner(spinnerPos, spinnerPos + spinnerSize, colors.statusText)

    ui.offsetCursor(vec2(100, 20))
    ui.dwriteText(loading.status(), 22, colors.statusText)

    local detailsFontSize = 14
    local maxLines = math.floor((windowSize.y - 100) / ui.measureDWriteText('A', detailsFontSize).y)
    local startIndex = math.max(1, #log.lines - maxLines)
    local cutString = table.concat(log.lines, '\n', startIndex, #log.lines)

    ui.setCursorX(100)
    ui.dwriteText(cutString, detailsFontSize, colors.detailsText)

    ui.drawImage(loadingCanvas, vec2(0, 0), loadingCanvas:size())
end

local function drawProgressBar()
    local windowSize = ui.windowSize()
    ui.drawRectFilled(vec2(0, 0), vec2(windowSize.x * loading.progress(), windowSize.y), colors.progressBarForeground)
end

local function drawVersions()
    local windowSize = ui.windowSize()
    ui.dwriteDrawText(loading.version(), 12, vec2(10, windowSize.y - 24), colors.versionText)
end

--#endregion

--#region Main

function script.update()
    drawBackground()
    drawProgressBar()
    drawDebugText()
    drawVersions()
end

--#endregion