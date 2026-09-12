local settings = require('_settings')
local aim = require('_aim')
local audio = require('_audio')

local settingsUI = {}

local SSAA_OPTIONS = { 1, 2, 4, 8 }
local HDRI_OPTIONS = {
    'citrus_orchard',
    'farm_field',
    'fireplace',
    'immenstadter_8k',
    'immenstadter',
    'moonless_golf'
}
local LABEL_WIDTH = 95

---Full-width color swatch button spanning remaining line width
---@param id string
---@param color rgbm
---@param onSave fun(newColor: rgbm)
local function colorPicker(id, color, onSave)
    ui.colorButton('##btn_' .. id, color, ui.ColorPickerFlags.PickerHueBar, vec2(ui.availableSpaceX(), 22))
    ui.itemPopup('popup_' .. id, ui.MouseButton.Left, function()
        if ui.colorPicker('##picker_' .. id, color, ui.ColorPickerFlags.NoAlpha) then
            onSave(color:clone())
        end
    end)
end

---Mode segment button fitting half width
---@param label string
---@param targetMode string
---@param width number
local function modeButton(label, targetMode, width)
    local isActive = (settings.graphics_presentation == targetMode)
    if isActive then
        ui.pushStyleColor(ui.StyleColor.Button, ui.styleColor(ui.StyleColor.ButtonActive))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm.colors.white)
    else
        ui.pushStyleColor(ui.StyleColor.Button, ui.styleColor(ui.StyleColor.Button))
        ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.6, 0.6, 0.6, 1.0))
    end

    if ui.button(label .. "##pres_" .. targetMode, vec2(width, 24)) and not isActive then
        settings.graphics_presentation = targetMode
    end
    ui.popStyleColor(2)
end

local function drawAim()
    ui.dummy(vec2(0, 4))
    local profile = aim.resolve(settings.aim_game, settings.aim_sensitivity, settings.aim_fov)

    ui.alignTextToFramePadding()
    ui.text("Profile:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX())
    if ui.beginCombo("##game_profile", settings.aim_game) then
        if ui.selectable("Valorant", settings.aim_game == "Valorant") then
            settings.aim_game = "Valorant"
        end
        ui.endCombo()
    end

    ui.alignTextToFramePadding()
    ui.text("Sensitivity:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX())
    local sens, sensChanged = ui.slider('##sens', settings.aim_sensitivity, 0.01, 2.0, '%.3f')
    if sensChanged then
        settings.aim_sensitivity = sens
    end

    ui.alignTextToFramePadding()
    ui.text("FOV:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX())
    local fov, fovChanged = ui.slider('##fov', settings.aim_fov, profile.fovMin, profile.fovMax, '%.1f°')
    if fovChanged then
        settings.aim_fov = fov
    end
end

local function drawAudio()
    ui.dummy(vec2(0, 4))

    local btnW = 24

    ui.alignTextToFramePadding()
    ui.text("Hit volume:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX() - btnW - 4)
    local hitDisplay = math.round(settings.audio_hit_volume * 100)
    local newHit, hitChanged = ui.slider('##hit_vol', hitDisplay, 0, 100, '%.0f%%')
    if hitChanged then
        settings.audio_hit_volume = newHit / 100
    end
    ui.sameLine(0, 4)
    if ui.iconButton(ui.Icons.Speaker, vec2(btnW, 22), rgbm(0.8, 0.8, 0.8, 1.0)) then
        audio.playHit()
    end

    ui.alignTextToFramePadding()
    ui.text("Miss volume:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX() - btnW - 4)
    local missDisplay = math.round(settings.audio_miss_volume * 100)
    local newMiss, missChanged = ui.slider('##miss_vol', missDisplay, 0, 100, '%.0f%%')
    if missChanged then
        settings.audio_miss_volume = newMiss / 100
    end
    ui.sameLine(0, 4)
    if ui.iconButton(ui.Icons.Speaker, vec2(btnW, 22), rgbm(0.8, 0.8, 0.8, 1.0)) then
        audio.playMiss()
    end
end

local function drawGraphics()
    ui.dummy(vec2(0, 4))

    ui.alignTextToFramePadding()
    ui.text("Mode:")
    ui.sameLine(LABEL_WIDTH)
    local modeW = (ui.availableSpaceX() - 4) * 0.5
    modeButton("Scenic", "SCENIC", modeW)
    ui.sameLine(0, 4)
    modeButton("Competitive", "COMPETITIVE", modeW)

    ui.alignTextToFramePadding()
    ui.text("SSAA:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX())
    local ssaaLabel = tostring(settings.graphics_ssaa) .. "x"
    if ui.beginCombo("##ssaa_combo", ssaaLabel) then
        for i = 1, #SSAA_OPTIONS do
            local opt = SSAA_OPTIONS[i]
            if ui.selectable(opt .. "x", opt == settings.graphics_ssaa) then
                settings.graphics_ssaa = opt
            end
        end
        ui.endCombo()
    end

    ui.alignTextToFramePadding()
    ui.text("HDRI:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX())
    if ui.beginCombo("##hdri_combo", settings.graphics_hdri) then
        for i = 1, #HDRI_OPTIONS do
            local h = HDRI_OPTIONS[i]
            if ui.selectable(h, h == settings.graphics_hdri) then
                settings.graphics_hdri = h
            end
        end
        ui.endCombo()
    end

    ui.dummy(vec2(0, 4))
    ui.separator()
    ui.dummy(vec2(0, 4))

    ui.alignTextToFramePadding()
    ui.text("Target:")
    ui.sameLine(LABEL_WIDTH)
    colorPicker('target_col', settings.graphics_target_color, function(c)
        settings.graphics_target_color = c
    end)

    ui.alignTextToFramePadding()
    ui.text("Emission:")
    ui.sameLine(LABEL_WIDTH)
    ui.setNextItemWidth(ui.availableSpaceX())
    local em, emChanged = ui.slider('##emission', settings.graphics_target_emission, 0.0, 1.0, '%.2f')
    if emChanged then
        settings.graphics_target_emission = em
    end

    ui.alignTextToFramePadding()
    ui.text("Clear:")
    ui.sameLine(LABEL_WIDTH)
    colorPicker('clear_col', settings.graphics_clear_color, function(c)
        settings.graphics_clear_color = c
    end)
end

settingsUI.drawAim = drawAim
settingsUI.drawAudio = drawAudio
settingsUI.drawGraphics = drawGraphics

function settingsUI.draw(dt)
    ui.tabBar('settings_tabs', function()
        ui.tabItem('Aim', drawAim)
        ui.tabItem('Audio', drawAudio)
        ui.tabItem('Graphics', drawGraphics)
    end)
end

return settingsUI
