local camera = {
    position = vec3(0, 1.65, 0),
    look = vec3(0, 0, 1),
    right = vec3(1, 0, 0),
    up = vec3(0, 1, 0),

    yaw = 0,
    pitch = 0
}

local settings = require('_settings')
local aim = require('_aim')

local WORLD_UP = vec3(0, 1, 0)
local cam = nil


---@param mouseDelta vec2
function camera.update(mouseDelta)
    if not cam then cam = ac.grabCamera('kovaaks') end
    local profile = aim.resolve(
        settings.aim_game,
        settings.aim_sensitivity,
        settings.aim_fov
    )

    if mouseDelta then
        local degreesPerCount = profile.degreesPerCount

        camera.yaw = (camera.yaw - mouseDelta.x * degreesPerCount) % 360
        camera.pitch = math.clamp(camera.pitch - mouseDelta.y * degreesPerCount, -89, 89)

        local p_rad = math.rad(camera.pitch)
        local y_rad = math.rad(camera.yaw)
        camera.look:set(
            math.sin(y_rad) * math.cos(p_rad),
            math.sin(p_rad),
            math.cos(y_rad) * math.cos(p_rad)
        )

        camera.right:setCrossNormalized(WORLD_UP, camera.look)
        camera.up:setCrossNormalized(camera.look, camera.right)
    end

    if cam then
        cam.ownShare = 1.0
        cam.fov = profile.cameraFov
        --hopefully will help with compute
        --ilia suggested moving ac's physical camera far away
        --which would unload track chunks and other optimisations
        --i cant really tell if it works to be honest with u
        cam.transform.position:set(50000000, 500000000, 500000000)
        cam.transform.look:set(camera.look)
        cam.transform.side:set(camera.right)
        cam.transform.up:set(camera.up)
        cam:normalize()
    end
end

return camera
