local aim = {}

local root = ac.getFolder(ac.FolderID.ScriptOrigin)
--taken from steamapps\common\FPSAimTrainer\FPSAimTrainer\Saved\SaveGames
local path = root .. '/data/FovSensConfig.json'
local profiles = JSON.parse(io.load(path, '[]')) or {}

local byName = {}
for i = 1, #profiles do
    local profile = profiles[i]
    if profile.ScaleName then
        byName[profile.ScaleName] = profile
    end
end

local function horizontal2vertical(fov, aspect)
    return math.deg(
        2.0 * math.atan(
            math.tan(math.rad(fov) * 0.5) / aspect
        )
    )
end

---resolves a game profile into values usable by the trainer
---@param game string
---@param sensitivity number
---@param fov number?
---@return table
function aim.resolve(game, sensitivity, fov)
    local source = byName[game]

    if not source then
        error('unknown aim profile: ' .. tostring(game))
    end

    local fovMin = (source.FOV and source.FOV.SliderMin) or 60
    local fovMax = (source.FOV and source.FOV.SliderMax) or 140
    local currentFov = math.clamp(fov or fovMin, fovMin, fovMax)

    --for now
    --valorant is the only supported profile
    if game == 'Valorant' then
        local sensitivityScale = 0.06996
        return {
            degreesPerCount = sensitivity * sensitivityScale,
            displayFov = currentFov,
            cameraFov = horizontal2vertical(currentFov, 16.0 / 9.0),
            fovMin = fovMin,
            fovMax = fovMax,
        }
    end

    ac.error('unsupported aim profile: ' .. tostring(game))
end

return aim
