local settings = require('_settings')
local audio = {}

--[[
    custom audio from https://kvk-hub.app/sounds
    and some from the original game (steamapps\common\FPSAimTrainer\FPSAimTrainer\sounds)
]]

local hitPath = ac.findFile(settings.audio_hit_sound)
local missPath = ac.findFile(settings.audio_miss_sound)

local function play(path, volume)
    if not path or path == '' then return end

    local event = ac.AudioEvent.fromFile({
        filename = path,
        use3D = false,
        loop = false
    }, false)

    if event then
        event.volume = volume
        event:start()
    end
end

function audio.playHit()
    play(hitPath, settings.audio_hit_volume)
end

function audio.playMiss()
    play(missPath, settings.audio_miss_volume)
end

return audio
