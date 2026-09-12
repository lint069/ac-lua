local input = {
    captured = false,
    mouseDelta = vec2(0, 0),

    shootPressed = false,
    capturePressed = false,

    binds = {
        --potentially also shoot

        pause = ac.ControlButton("kovaaks/pause", { keyboard = { key = ui.KeyIndex.Tab } }),
        restart = ac.ControlButton("kovaaks/restart", { keyboard = { key = ui.KeyIndex.R } }),
    }
}

local burnFrame = false

---sets cursor capture state explicitly
---@param value boolean
function input.setCaptured(value)
    if input.captured == value then return end

    input.captured = value
    burnFrame = value

    if not value then
        input.mouseDelta:set(0, 0)
    end
end

--poll input once per frame
function input.update()
    input.shootPressed = false
    input.mouseDelta:set(0, 0)
    input.capturePressed = input.binds.pause:pressed()

    if not input.captured then return end

    local delta = ac.accessMouseDelta(true, true, true)
    input.mouseDelta:set(delta)

    if burnFrame then
        input.mouseDelta:set(0, 0)
        burnFrame = false
    end

    input.shootPressed = ac.isKeyPressed(ui.KeyIndex.LeftButton)
end

return input
