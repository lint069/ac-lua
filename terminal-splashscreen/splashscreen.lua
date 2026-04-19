local colors = require 'colors'
local configINI = ac.INIConfig.load('config.ini', ac.INIFormat.Extended)
local colorscheme = configINI:get('style', 'colorscheme', 'default')

--#region Tables

local log = {
    lastString = '',
    lastStatus = '',
    lines = {},
}

local font = {
    regular = ui.DWriteFont('Cousine Nerd Font Mono', './assets/CousineNerdFontMono-Regular.ttf')
}

--#endregion

--#region Helper Functions

---@param value number @value to be scaled
---@return integer
local function scale(value)
    local scaleFactor = ui.windowSize().x / 1920

    return math.floor(value * scaleFactor)
end

---@return string
local function loadAscii()
    local asciiFile = __dirname .. '/' .. configINI:get('ascii', 'path', '')

    local file, err = io.open(asciiFile, 'r')
    if not file then
        ac.log('Error: ', err)
        return ('Error: ' .. err)
    end

    local asciiArt = file:read('*a')
    file:close()

    return asciiArt
end

--#endregion

--#region Drawing Functions

local function drawBackground()
    ui.drawRectFilled(vec2(0, 0), ui.windowSize(), colors[colorscheme].background)
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
    local detailsFontSize = scale(12)
    local maxLines = math.floor((windowSize.y - 75) / ui.measureDWriteText('A', detailsFontSize).y)
    local startIndex = math.max(1, #log.lines - maxLines)
    local cutString = table.concat(log.lines, '\n', startIndex, #log.lines)

    ui.setCursor(vec2(scale(20), scale(20)))
    ui.dwriteText(cutString, detailsFontSize, colors[colorscheme].text)
    ui.popDWriteFont()

    ui.drawImage(loadingCanvas, vec2(0, 0), loadingCanvas:size())
end

---@param emptyChar string @Character that is the empty part of the progress bar.
---@param fillChar string @Character that fills the progress bar.
local function drawProgressBar(emptyChar, fillChar)
    local progress = loading.progress()

    -- https://gist.github.com/asika32764/19956edcc5e893b2cbe3768e91590cf1
    local spinnerChars = {'-', '\\', '|', '/'}
    local spinIndex = (math.floor(os.preciseClock() * 6) % #spinnerChars) + 1
    local spinChar = progress < 0.9 and spinnerChars[spinIndex] or '#'

    local total = 42
    local filled = progress > 0.9 and total or math.floor(progress * total)
    local emptyCount = math.max(0, total - filled - 1)
    local bar = '[' .. fillChar:rep(filled) .. spinChar .. emptyChar:rep(emptyCount) .. ']'
    local percentage = progress > 0.99 and ' 100%' or string.format(' %.2f%%', progress * 100)

    ui.pushDWriteFont(font.regular)

    local fontSize = scale(14)
    local padding = scale(20)
    local textHeight = ui.measureDWriteText('A', fontSize).y
    ui.dwriteDrawText(bar .. percentage, fontSize, vec2(scale(25), (ui.windowSize().y - textHeight) - padding), colors[colorscheme].text)

    ui.popDWriteFont()
end

local function drawVersions()
    local windowSize = ui.windowSize()

    local fontSize = scale(12)
    local padding = scale(15)
    local version = loading.version()

    local textSize = ui.measureDWriteText(version, fontSize)
    ui.dwriteDrawText(version, fontSize, vec2((windowSize.x - textSize.x) - padding, (windowSize.y - textSize.y) - padding), colors[colorscheme].versionText)
end

local asciiArt = loadAscii()
local function drawAscii()
    ui.pushDWriteFont(font.regular)
    local windowSize = ui.windowSize()
    local fontSize = scale(12)
    local asciiSize = ui.measureDWriteText(asciiArt, fontSize)

    -- ((P1 + P2) / 2) - (imagesize.x / 2)
    ui.dwriteDrawText(asciiArt, fontSize, vec2((((windowSize.x / 2.7) + (windowSize.x - 15)) / 2) - (asciiSize.x / 2), (windowSize.y / 2) - (asciiSize.y / 2)), colors[colorscheme].accent)
    ui.popDWriteFont()

    -- ui.drawCircleFilled(vec2(windowSize.x / 2.7, windowSize.y / 2), 3, rgbm(1, 0, 0, 1))
    -- ui.drawCircleFilled(vec2((windowSize.x - 15), windowSize.y / 2), 3, rgbm(1, 0, 0, 1))
end

--#endregion

--#region Main

local asciiEnabled = configINI:get('ascii', 'enabled', 'false')

function script.update()
    drawBackground()
    drawDebugText()
    drawVersions()
    drawProgressBar('.', '#')

    if asciiEnabled == 'true' then
        drawAscii()
    end
end

--#endregion