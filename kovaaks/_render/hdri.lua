local sh = require('_render/sh')

local hdri = {}
local cache = {}

---fallback while readback is computing
local function makeDefaultSH()
    local t = {}
    for i = 1, 9 do
        t[i] = { r = (i == 1) and 1.0 or 0.0, g = (i == 1) and 1.0 or 0.0, b = (i == 1) and 1.0 or 0.0 }
    end
    return t
end

---loads HDRI asset, downsamples for SH projection, and caches result
---@param name string name of the HDR file inside hdris/ (e.g. "default")
---@return table { texture: string|any, sh: table[], dirty: boolean }
function hdri.load(name)
    if cache[name] then
        return cache[name]
    end

    local texturePath = string.format("hdris/%s.hdr", name)

    local asset = {
        name = name,
        texture = texturePath,
        sh = makeDefaultSH(),
        dirty = true
    }
    cache[name] = asset

    local W, H = 64, 32
    local canvas = ui.ExtraCanvas(vec2(W, H), 1, render.TextureFormat.R16G16B16A16.Float)
    canvas:copyFrom(texturePath)

    canvas:accessData(function(err, data)
        if err or not data then
            ac.warn("[hdri] failed to read canvas data: " .. tostring(err))
            canvas:dispose()
            return
        end

        local function getPixelRGB(x, y)
            local col = data:color(x, y)
            return col.r, col.g, col.b
        end

        local coeffs = sh.compute(W, H, getPixelRGB)
        canvas:dispose()

        asset.sh = coeffs
        asset.dirty = true
    end)

    return asset
end

return hdri
