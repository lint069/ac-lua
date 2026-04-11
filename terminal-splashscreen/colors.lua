local colors = {}

math.randomseed(os.time())

---@param m number @`0..1`
---@param n number @`0..1`
---@return rgbm
local function makeRandomColor(m, n)
    m = math.floor(m * 255)
    n = math.floor(n * 255)
    return rgbm(math.random(m, n) / 255, math.random(m, n) / 255, math.random(m, n) / 255, 1)
end

local randomTextColor = makeRandomColor(0.6, 1)
colors.random = {
    background = makeRandomColor(0, 0.25),
    text = randomTextColor,
    versionText = rgbm(randomTextColor.r, randomTextColor.g, randomTextColor.b, 0.75),
}

colors.default = {
    background = rgbm(0.02, 0.02, 0.03, 1),
    text = rgbm(0.85, 0.85, 0.85, 1),
    versionText = rgbm(0.5, 0.5, 0.5, 1),
}

colors.cattpuccin_macchiato = {
    background = rgbm(0.078, 0.09, 0.121, 1),
    text = rgbm(0.721, 0.752, 0.878, 1),
    versionText = rgbm(0.621, 0.652, 0.778, 1),
}

colors.cattpuccin_mocha = {
    background = rgbm(0.117, 0.117, 0.18, 1),
    text = rgbm(0.729, 0.76, 0.87, 1),
    versionText = rgbm(0.629, 0.66, 0.77, 1),
}

colors.cattpuccin_frappe = {
    background = rgbm(0.188, 0.203, 0.274, 1),
    text = rgbm(0.709, 0.749, 0.886, 1),
    versionText = rgbm(0.609, 0.649, 0.786, 1),
}

colors.ayu_mirage = {
    background = rgbm(0.129, 0.152, 0.2, 1),
    text = rgbm(0.78, 0.78, 0.78, 1),
    versionText = rgbm(0.68, 0.68, 0.68, 1),
}

colors.nord = {
    background = rgbm(0.11, 0.14, 0.18, 1),
    text = rgbm(0.81, 0.84, 0.89, 1),
    versionText = rgbm(0.71, 0.74, 0.79, 1),
}

colors.arch = {
    background = rgbm(0.047, 0.05, 0.066, 1),
    text = rgbm(0.964, 0.96, 0.96, 1),
    versionText = rgbm(0.764, 0.76, 0.76, 1),
}

colors.matrix = {
    background = rgbm(0.05, 0.05, 0.05, 1),
    text = rgbm(0.3, 1, 0.3, 1),
    versionText = rgbm(0.1, 0.7, 0.1, 1),
}

colors.kanagawa_dragon = {
    background = rgbm(0.18, 0.203, 0.25, 1),
    text = rgbm(0.898, 0.913, 0.941, 1),
    versionText = rgbm(0.798, 0.813, 0.841, 1),
}

colors.purple = {
    background = rgbm(0.133, 0.125, 0.211, 1),
    text = rgbm(0.76, 0.666, 0.901, 1),
    versionText = rgbm(0.66, 0.566, 0.801, 1),
}

return colors