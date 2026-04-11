-- (-ꞈ-マ

local colors = require 'colors'
local utf8 = require 'utf8'

--#region Tables

local log = {
    lastString = '',
    lastStatus = '',
    lines = {},
}

--#endregion

--#region Helper functions

---@param icon string|ui.Icons
---@param iconPadding number
---@param title string
---@param titleFontSize integer
---@param details? string
---@param detailsFontSize? integer
local function drawBlock(icon, iconPadding, title, titleFontSize, details, detailsFontSize)
    if title ~= '' then
        ui.offsetCursorY(40)
        ui.dummy(vec2(64, 64))

        local r1, r2 = ui.itemRect()
        ui.drawIcon(icon, r1 + iconPadding, r2 - iconPadding)

        ui.sameLine(0, 12)
        ui.dwriteText(title, titleFontSize, colors.statusText)

        if details then
			ui.offsetCursorX(64 + 12)
			ui.offsetCursorY(-38)

            ui.dwriteTextWrapped(details, detailsFontSize, colors.detailsText)
        end
    end
end

---Shortens a string and appends ...
---@param name string
---@param fontSize integer
---@param maxLength number
---@return string newName
local function truncateName(name, fontSize, maxLength)
    local nameLength = ui.measureDWriteText(name, fontSize).x

    if nameLength > maxLength then
        name = utf8.sub(name, 1, math.floor(utf8.len(name) * maxLength / nameLength)) .. '...'
    end

    return name
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
    local progress = loading.progress()

    if loading.progress() > 0.9 then
        progress = 1
    end

    ui.drawRectFilled(vec2(0, 0), vec2(windowSize.x * progress, windowSize.y), colors.progressBarForeground)
end

local function drawVersions()
    local windowSize = ui.windowSize()
    ui.dwriteDrawText(loading.version(), 12, vec2(10, windowSize.y - 24), colors.versionText)
end

local function drawSessionInfo()
    local groupWidth = 500
    local padding = 35

    ui.setCursor(vec2((ui.windowWidth() - groupWidth) - padding, -15))
    ui.beginGroup(groupWidth)
    using(function()
        local titleFontSize = 16

        local title, details = loading.warning()
        if title then
            drawBlock(ui.Icons.Warning, 20, 'Warning:' .. title, titleFontSize, details, 12)
        end

        local carName = loading.carName()
        local trackName = loading.trackName()
        carName = truncateName(carName, titleFontSize, (groupWidth - 100))
        trackName = truncateName(trackName, titleFontSize, (groupWidth - 100))

        -- replacing <br> with \n because of srp
        drawBlock('splashscreen::badge', 6, carName, titleFontSize, table.concat(table.map(loading.carHints(), function(item) return '- %s' % item end), '\n'), 12)
        drawBlock('splashscreen::track', 6, trackName, titleFontSize, table.concat(table.map(loading.trackHints(), function(item) return '- %s' % item:gsub('<br>', '\n') end), '\n'), 12)
    end, ui.endGroup)
end

--#endregion

--#region Main

function script.update()
    drawBackground()
    drawProgressBar()
    drawDebugText()
    drawVersions()
    drawSessionInfo()
end

--#endregion