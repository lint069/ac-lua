local colors = {}

--#region custom

---@param hex string @#RRGGBBAA
---@return rgbm
local function hexToRgbm(hex)
	local r, g, b, a = hex:match('(%x%x)(%x%x)(%x%x)(%x%x)')

	local red = (tonumber(r, 16) or 0) / 255
	local green = (tonumber(g, 16) or 0) / 255
	local blue = (tonumber(b, 16) or 0) / 255
	local alpha = (tonumber(a, 16) or 0) / 255

	return rgbm(red, green, blue, alpha)
end

-- maybe use a for loop if more big
local ini = ac.INIConfig.load('./config.ini', ac.INIFormat.Extended)
local custom_background = ini:get('style', 'background', '00000000')
local custom_accent = ini:get('style', 'accent', '00000000')
local custom_text = ini:get('style', 'text', '00000000')
local custom_version_text = ini:get('style', 'version_text', '00000000')

colors.custom = {
    background = hexToRgbm(custom_background),
    accent = hexToRgbm(custom_accent),
    text = hexToRgbm(custom_text),
    versionText = hexToRgbm(custom_version_text),
}

--#endregion

--#region random

math.randomseed(os.time())

---@param m number @`0..1`
---@param n number @`0..1`
---@return rgbm
local function makeRandomColor(m, n)
    m = math.floor(m * 255)
    n = math.floor(n * 255)
    return rgbm(math.random(m, n) / 255, math.random(m, n) / 255, math.random(m, n) / 255, 1)
end

colors.random = {
    background = makeRandomColor(0, 0.25),
    accent = makeRandomColor(0.3, 1),
    text = makeRandomColor(0.6, 1),
    versionText = makeRandomColor(0.4, 0.75),
}

--#endregion

--#region preconfigured themes

colors.arch = {
    background = rgbm(0.047, 0.05, 0.066, 1),
    accent = rgbm(0.494, 0.729, 0.709, 1),
    text = rgbm(0.964, 0.96, 0.96, 1),
    versionText = rgbm(0.764, 0.76, 0.76, 1),
}

colors.ayu_mirage = {
    background = rgbm(0.129, 0.152, 0.2, 1),
    accent = rgbm(1, 0.8, 0.4, 1),
    text = rgbm(0.78, 0.78, 0.78, 1),
    versionText = rgbm(0.68, 0.68, 0.68, 1),
}

colors.catppuccin_frappe = {
    background = rgbm(0.188, 0.203, 0.274, 1),
    accent = rgbm(0.796, 0.69, 0.968, 1),
    text = rgbm(0.709, 0.749, 0.886, 1),
    versionText = rgbm(0.609, 0.649, 0.786, 1),
}

colors.catppuccin_macchiato = {
    background = rgbm(0.078, 0.09, 0.121, 1),
    accent = rgbm(0.656, 0.49, 0.838, 1),
    text = rgbm(0.721, 0.752, 0.878, 1),
    versionText = rgbm(0.621, 0.652, 0.778, 1),
}

colors.catppuccin_mocha = {
    background = rgbm(0.117, 0.117, 0.18, 1),
    accent = rgbm(0.796, 0.650, 0.968, 1),
    text = rgbm(0.729, 0.76, 0.87, 1),
    versionText = rgbm(0.629, 0.66, 0.77, 1),
}

colors.cherry_blossom = {
    background = rgbm(0.196, 0.203, 0.215, 1),
    accent = rgbm(0.839, 0.36, 0.8, 1),
    text = rgbm(0.819, 0.815, 0.772, 1),
    versionText = rgbm(0.719, 0.715, 0.672, 1),
}

colors.comfy = {
    background = rgbm(0.07, 0.067, 0.057, 1),
    accent = rgbm(0.721, 0.435, 0.466, 1),
    text = rgbm(0.917, 0.909, 0.917, 1),
    versionText = rgbm(0.717, 0.709, 0.717, 1),
}

colors.default = {
    background = rgbm(0.02, 0.02, 0.03, 1),
    accent = rgbm(0.69, 0.69, 0.682, 1),
    text = rgbm(0.85, 0.85, 0.85, 1),
    versionText = rgbm(0.5, 0.5, 0.5, 1),
}

colors.drowning = {
    background = rgbm(0.098, 0.094, 0.149, 1),
    accent = rgbm(0.29, 0.435, 0.709, 1),
    text = rgbm(0.576, 0.576, 0.654, 1),
    versionText = rgbm(0.476, 0.476, 0.554, 1),
}

colors.iceberg_dark = {
    background = rgbm(0.086, 0.094, 0.129, 1),
    accent = rgbm(0.517, 0.627, 0.776, 1),
    text = rgbm(0.776, 0.784, 0.819, 1),
    versionText = rgbm(0.676, 0.684, 0.719, 1),
}

colors.iceberg_light = {
    background = rgbm(0.909, 0.913, 0.925, 1),
    accent = rgbm(0.176, 0.325, 0.619, 1),
    text = rgbm(0.2, 0.215, 0.298, 1),
    versionText = rgbm(0.3, 0.315, 0.398, 1),
}

colors.kanagawa_dragon = {
    background = rgbm(0.094, 0.086, 0.086, 1),
    accent = rgbm(0.537, 0.631, 0.678, 1),
    text = rgbm(0.784, 0.752, 0.576, 1),
    versionText = rgbm(0.684, 0.652, 0.476, 1),
}

colors.matrix = {
    background = rgbm(0.05, 0.05, 0.05, 1),
    accent = rgbm(0.2, 1, 0.2, 1),
    text = rgbm(0.2, 1, 0.2, 1),
    versionText = rgbm(0.1, 0.8, 0.1, 1),
}

colors.midnight = {
    background = rgbm(0.043, 0.055, 0.074, 1),
    accent = rgbm(0.376, 0.459, 0.623, 1),
    text = rgbm(0.623, 0.678, 0.776, 1),
    versionText = rgbm(0.523, 0.578, 0.676, 1),
}

colors.moonlight = {
    background = rgbm(0.098, 0.121, 0.156, 1),
    accent = rgbm(0.776, 0.623, 0.407, 1),
    text = rgbm(0.8, 0.8, 0.709, 1),
    versionText = rgbm(0.7, 0.7, 0.609, 1),
}

colors.nord = {
    background = rgbm(0.11, 0.14, 0.18, 1),
    accent = rgbm(0.709, 0.564, 0.682, 1),
    text = rgbm(0.81, 0.84, 0.89, 1),
    versionText = rgbm(0.71, 0.74, 0.79, 1),
}

colors.norse = {
    background = rgbm(0.141, 0.141, 0.145, 1),
    accent = rgbm(0.168, 0.372, 0.427, 1),
    text = rgbm(0.8, 0.76, 0.694, 1),
    versionText = rgbm(0.7, 0.66, 0.594, 1),
}

colors.peach_blossom = {
    background = rgbm(0.16, 0.16, 0.16, 1),
    accent = rgbm(0.6, 0.721, 0.596, 1),
    text = rgbm(0.996, 0.807, 0.658, 1),
    versionText = rgbm(0.896, 0.707, 0.558, 1),
}

colors.shadow = {
    background = rgbm(0, 0, 0, 1),
    accent = rgbm(0.549, 0.196, 0.188, 1),
    text = rgbm(0.333, 0.49, 0.552, 1),
    versionText = rgbm(0.233, 0.39, 0.452, 1)
}

colors.sunset = {
    background = rgbm(0.129, 0.118, 0.141, 1),
    accent = rgbm(0.968, 0.592, 0.466, 1),
    text = rgbm(0.957, 0.878, 0.788, 1),
    versionText = rgbm(0.857, 0.778, 0.688, 1),
}

--#endregion

return colors