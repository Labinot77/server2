Config = {}

-- Default camera when a model has no Camera of its own (offsets from the prop).
Config.Camera = {
    Offset = vector3(0.0, -0.55, 0.30), -- where the camera sits
    LookAt = vector3(0.0, 0.05, 0.13),  -- the middle of the screen
    Fov = 42.0,
    Transition = 600,
}

Config.CursorSensitivity = 14.0

-- Holding a key while typing on a screen: first repeat after Delay ms, then one every Rate ms.
Config.KeyRepeat = { Delay = 550, Rate = 130 }

-- Screens registered with Mirror = true: players within this range see what the user does on it.
Config.MirrorDistance = 20.0

--[[
    How the page gets onto each model's screen:
      Texture      = screen texture to replace (Dict = its .ytd, defaults to the model name)
      RenderTarget = named render target (script_rt_<name>) instead of a texture
      Resolution   = DUI page size, keep the screen's aspect ratio
      Camera       = optional { Offset, LookAt, Fov, Transition }

      Variant      = a copy of the model with its own screen texture name (e.g. 'prop_fleeca_atm_dui').
                     The prop showing the page is swapped to the copy (map props: CreateModelSwap,
                     fw-admin props: respawned in the same frame), so the same model next to it keeps
                     its normal screen. With a Variant, Dict / Texture are the copy's (Dict defaults to
                     the Variant name). One copy per model is enough, however many props you place.

    Without a Variant, AddReplaceTexture changes the texture on every prop of that model.

      Specular     = the screen's specular map (in the same .ytd). Replaced with flat black while the page
                     shows, so sun and lights don't glare on the screen. For a screen that also looks the
                     same day and night, give the screen material of the copy an emissive shader (see README).
]]
Config.Models = {
    -- Laptops (fw-bennys)
    ['prop_laptop_jimmy'] = { Texture = 'prop_jimmy_screen', Resolution = { 1280, 800 } },
    ['prop_laptop_lester2'] = { RenderTarget = 'tvscreen', Resolution = { 1280, 640 } },
    ['as_prop_as_laptop_01a'] = { Texture = 'prop_moniter_desktop_01', Resolution = { 1280, 800 } },
    ['custom_laptop_01'] = { Variant = 'custom_laptop_01', Texture = 'laptop_custom_screen_01', Specular = 'laptop_custom_screen_01_dui_s', Resolution = { 1280, 800 } },

    -- House computers (one per house, all the same model)
    ['house_monitor_01'] = { Variant = 'house_monitor_01_dui', Texture = 'house_monitor_screen_01_dui', Specular = 'house_monitor_screen_01_dui_s', Resolution = { 1280, 720 } },

    -- Fleeca lobby terminal (fw-heists, advanced Fleeca). fw-heists spawns the _dui copy directly, so only that
    -- monitor shows the page (same idea as the ATMs). The copy's screen texture is prop_moniter_dekstop_01_dui.
    ['prop_monitor_01a'] = {
        Variant = 'prop_monitor_01a_dui', Texture = 'prop_monitor_desktop_01_dui', Resolution = { 1280, 960 },
        Camera = { Offset = vector3(0.0, -0.62, 0.26), LookAt = vector3(0.0, 0.0, 0.24), Fov = 40.0, Transition = 600 },
    },

    -- Fleeca staff door keypad (fw-heists). Only the display is the page, typing is on the keyboard.
    -- Still the normal LOCKED display? The texture is in another .ytd or has another name: find the display
    -- material in CodeWalker and test it live with /duitex fleeca_keypad <texture> <dict>, then set Texture / Dict.
    ['hei_prop_hei_keypad_01'] = {
        Texture = 'hei_keypad_screen_dui', Resolution = { 512, 256 },
        Camera = { Offset = vector3(0.0, -0.4, 0.02), LookAt = vector3(0.0, 0.0, 0.02), Fov = 35.0, Transition = 500 },
    },

    -- Fleeca security panels next to the vault doors (fw-heists, advanced Fleeca). Already a DUI prop, no copy needed.
    ['v_corp_bk_secpanel_dui_01'] = {
        Texture = 'secpanel_screen_dui', Resolution = { 512, 384 },
        Camera = { Offset = vector3(0.0, -0.45, 0.05), LookAt = vector3(0.0, 0.0, 0.05), Fov = 35.0, Transition = 500 },
    },

    -- ATMs (fw-financials)
    ['prop_fleeca_atm'] = {
        -- The copy has its own screen material + texture (the signs keep prop_fleece_emis). See README "ATM screen".
        Variant = 'prop_fleeca_atm_dui', Texture = 'prop_fleeca_atm_screen_dui', Resolution = { 1326, 948 }, -- screen is ~1.4 : 1
        Camera = { Offset = vector3(-0.1205, -0.415, 1.2125), LookAt = vector3(-0.1205, 0.085, 1.1425), Fov = 40.0, Transition = 500 },
    },
    ['prop_atm_01'] = {
        Variant = 'prop_atm_01_dui', Texture = 'prop_atm_01_screen_dui', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.053, -0.62, 1.15), LookAt = vector3(-0.053, -0.12, 1.08), Fov = 40.0, Transition = 500 },
    },
    ['prop_atm_02'] = {
        Variant = 'prop_atm_02_dui', Texture = 'prop_atm_02_screen_dui', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.1205, -0.415, 1.21), LookAt = vector3(-0.1205, 0.085, 1.14), Fov = 30.0, Transition = 500 },
    },
    ['prop_atm_03'] = {
        Variant = 'prop_atm_03_dui', Texture = 'prop_atm_03_screen_dui', Specular = 'prop_atm_03_screen_dui_s', Resolution = { 1326, 1004 },
        Camera = { Offset = vector3(-0.1205, -0.43, 1.21), LookAt = vector3(-0.1205, 0.07, 1.14), Fov = 30.0, Transition = 500 },
    },
}
