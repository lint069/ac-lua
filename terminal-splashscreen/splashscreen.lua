--TODO: ASCII ART
-- maybe spinning ascii art. loading spinner ascii art. spinning skull. custom ascii art via .txt file.

local colors = require 'colors'

--#region Tables

local log = {
    lastString = '',
    lastStatus = '',
    lines = {},
}

local font = {
    regular = ui.DWriteFont('Cousine Nerd Font Mono', './assets/CousineNerdFontMono-Regular.ttf')
}

local Theme = ac.INIConfig.load('config.ini', ac.INIFormat.Extended):get('style', 'colorscheme', 'default')

--#endregion

--#region Drawing Functions

local function drawBackground()
    ui.drawRectFilled(vec2(0, 0), ui.windowSize(), colors[Theme].background)
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

    ui.pushDWriteFont(font.regular)
    local detailsFontSize = 12
    local maxLines = math.floor((windowSize.y - 75) / ui.measureDWriteText('A', detailsFontSize).y)
    local startIndex = math.max(1, #log.lines - maxLines)
    local cutString = table.concat(log.lines, '\n', startIndex, #log.lines)

    ui.setCursor(vec2(20, 20))
    ui.dwriteText(cutString, detailsFontSize, colors[Theme].text)
    ui.popDWriteFont()

    ui.drawImage(loadingCanvas, vec2(0, 0), loadingCanvas:size())
end

---@param emptyChar string @Character that is the empty part of the progress bar.
---@param fillChar string @Character that fills the progress bar.
local function drawProgressBar(emptyChar, fillChar)
    local progress = loading.progress()
    local total = 42
    local filled = progress > 0.9 and total or math.floor(progress * total)
    local bar = '[' .. fillChar:rep(filled) .. emptyChar:rep(total - filled) .. ']'
    local percentage = string.format(' %.2f%%', progress * 100)

    if progress > 0.9 then
        percentage = ' 100%'
    end

    ui.pushDWriteFont(font.regular)

    local fontSize = 14
    local padding = 20
    local textHeight = ui.measureDWriteText('A', fontSize).y
    ui.dwriteDrawText(bar .. percentage, fontSize, vec2(25, (ui.windowSize().y - textHeight) - padding), colors[Theme].text)

    ui.popDWriteFont()
end

local function drawVersions()
    local windowSize = ui.windowSize()

    local fontSize = 12
    local padding = 15
    local version = loading.version()

    local textSize = ui.measureDWriteText(version, fontSize)
    ui.dwriteDrawText(version, fontSize, vec2((windowSize.x - textSize.x) - padding, (windowSize.y - textSize.y) - padding), colors[Theme].versionText)
end

--#endregion

--#region Main

function script.update()
    drawBackground()
    drawDebugText()
    drawVersions()
    drawProgressBar('.', '#')
end

--#endregion