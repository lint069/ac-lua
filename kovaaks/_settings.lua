return ac.storage({
    --aim
    aim_fov = 103.0,
    aim_game = "Valorant",
    aim_sensitivity = 0.203,

    --audio
    audio_hit_sound = "sfx/osu-hit.wav",
    audio_hit_volume = 0.8,
    audio_miss_sound = "sfx/kick-deep.ogg",
    audio_miss_volume = 0.5,

    --crosshair
    crosshair_color = rgbm(1.0, 1.0, 1.0, 1.0),
    crosshair_size = 10,

    --graphics
    graphics_backdrop_color = rgbm(0.08, 0.08, 0.09, 1.0),
    graphics_clear_color = rgbm(0.05, 0.05, 0.05, 1.0),
    graphics_hdri = "farm_field",
    graphics_presentation = "SCENIC", -- COMPETITIVE | SCENIC
    graphics_ssaa = 4,
    graphics_target_color = rgbm(1.0, 0.1, 0.1, 1.0),
    graphics_target_emission = 0.25,
})
