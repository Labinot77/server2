Config = {}

-- Default camera when a model has no Camera of its own (offsets from the prop).
Config.Camera = {
    Offset = vector3(0.0, -0.55, 0.30), -- where the camera sits
    LookAt = vector3(0.0, 0.05, 0.13),  -- the middle of the screen
    Fov = 42.0,
    Transition = 600,
}

Config.CursorSensitivity = 14.0

-- Screens registered with Mirror = true: players within this range see what the user does on it.
Config.MirrorDistance = 20.0

--[[
    How the page gets onto each model's screen:
      Texture      = screen texture to replace (Dict = its .ytd, defaults to the model name)
      RenderTarget = named render target (script_rt_<name>) instead of a texture
      Resolution   = DUI page size, keep the screen's aspect ratio
      Camera       = optional { Offset, LookAt, Fov, Transition }

    AddReplaceTexture changes the texture on every prop of that model, so give each prop that
    may show a different page at the same time its own model + texture name.
]]
Config.Models = {
    -- Laptops (fw-bennys)
    ['prop_laptop_jimmy'] = { Texture = 'prop_jimmy_screen', Resolution = { 1280, 800 } },
    ['prop_laptop_lester2'] = { RenderTarget = 'tvscreen', Resolution = { 1280, 640 } },
    ['as_prop_as_laptop_01a'] = { Texture = 'prop_moniter_desktop_01', Resolution = { 1280, 800 } },
    ['custom_laptop_01'] = { Texture = 'laptop_custom_screen_01', Resolution = { 1280, 800 } },

    -- ATMs (fw-financials)
    ['prop_fleeca_atm'] = {
        Dict = 'prop_fleeca_atm', Texture = 'prop_fleece_emis', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.1205, -0.415, 1.2125), LookAt = vector3(-0.1205, 0.085, 1.1425), Fov = 30.0, Transition = 500 },
    },
    ['prop_atm_01'] = {
        Dict = 'prop_atm_01', Texture = 'prop_cashpoint_screen', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.053, -0.62, 1.15), LookAt = vector3(-0.053, -0.12, 1.08), Fov = 30.0, Transition = 500 },
    },
    ['prop_atm_02'] = {
        Dict = 'prop_atm_02', Texture = 'prop_cashpoint_screen', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.1205, -0.415, 1.21), LookAt = vector3(-0.1205, 0.085, 1.14), Fov = 30.0, Transition = 500 },
    },
    ['prop_atm_03'] = {
        Dict = 'prop_atm_03', Texture = 'prop_cashpoint_screen', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.1205, -0.43, 1.21), LookAt = vector3(-0.1205, 0.07, 1.14), Fov = 30.0, Transition = 500 },
    },
}
