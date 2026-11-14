Config = {}

-- Default camera when a model has no Camera of its own (offsets from the prop).
Config.Camera = {
    Offset = vector3(0.0, -0.55, 0.30), -- where the camera sits
    LookAt = vector3(0.0, 0.05, 0.13),  -- the middle of the screen
    Fov = 42.0,
    Transition = 600,
}

Config.CursorSensitivity = 14.0
-- Called with true / false when a screen gets / loses focus, for HUDs that need an export call to hide, e.g.
-- Config.OnFocus = function(Focused) exports['pdwatch']:SetVisible(not Focused) end
Config.OnFocus = nil

-- Holding a key while typing on a screen: first repeat after Delay ms, then one every Rate ms.
Config.KeyRepeat = { Delay = 550, Rate = 130 }

-- Players within this range see what the user does on a screen (Mirror).
Config.MirrorDistance = 20.0

-- Location pools (models with Variants, see below). A variant is free at a prop when no other prop of that model
-- within PoolRadius uses it, so the same two copies are reused at every location on the map.
-- PoolRadius must be more than twice PoolRenderDistance: one client then never sees the same variant twice.
Config.PoolRadius = 80.0
Config.PoolRenderDistance = 35.0 -- in-use props within this range get their copy + page on your client
Config.PoolLeaveDistance = 15.0  -- the user walked this far from the prop (for 10s): the variant is freed
Config.IdleDistance = 20.0       -- idle pages (Idle = true) only render while a prop of the model is this close

-- DUIs are created on use and destroyed after (no idle browsers). The fly-in is timed to end when the page is
-- loaded, using how long that model took last time; this is the guess for the first open (ms).
Config.LoadEstimate = 1500

--[[
    How the page gets onto each model's screen:
      Variants     = copies of the model, each with its own screen texture (its own .ytd / embedded textures).
                     Idle props stay the original model. A prop someone uses is swapped to a free copy for every
                     player around it (server allocated per location), and that copy shows the user's page.
                     Two copies = two props of that model in use at once per location. Entries are the copy's model
                     name, or { Model = '...', Texture = '...', Dict = '...' } when a copy differs from Texture / Dict.
      Texture      = screen texture to replace (Dict = its .ytd, defaults to the model / copy name)
      RenderTarget = named render target (script_rt_<name>) instead of a texture
      Resolution   = DUI page size, keep the screen's aspect ratio
      Camera       = optional { Offset, LookAt, Fov, Transition }
      Specular     = the screen's specular map (same .ytd), replaced with flat black while the page shows (no glare)
      Idle         = true / { Texture, Dict }: props nobody uses show one shared idle page on the ORIGINAL model's
                     screen texture (computers: an empty desktop, ATMs: the idle screen). Defaults: Texture = the
                     model's Texture, Dict = the original model name. Wrong name = no idle page (harmless): find the
                     right one live with /duiidle <model> <texture> [dict]. A texture shared with other parts of the
                     prop (Fleeca ATM: prop_fleece_emis also has the signs) puts the page on those parts too.

    Without Variants the old way: the nearest prop in range shows the page, and AddReplaceTexture changes the
    texture on every prop of that model (fine for props that only exist once, like the bank keypads).
]]
Config.Models = {
       ['as_prop_as_laptop_01a'] = {
        Variants = { 'as_prop_as_laptop_01a_dui_01', 'as_prop_as_laptop_01a_dui_02' }, Texture = 'prop_moniter_desktop_01', Resolution = { 1280, 800 }, Idle = true,
    },
    ['v_res_lest_monitor'] = {
        Variants = { 'v_res_lest_monitor_dui_01', 'v_res_lest_monitor_dui_02' }, Texture = 'script_rt_tvscreen', Resolution = { 1280, 960 }, Idle = true,
        Camera = { Offset = vector3(0.016, -0.750, 0.419), LookAt = vector3(0.009, 0.000, 0.355), Fov = 45.0, Transition = 600 },
    },
    ['prop_monitor_01a'] = {
        Variants = { 'prop_monitor_01a_dui_01', 'prop_monitor_01a_dui_02' }, Texture = 'prop_moniter_desktop_01', Resolution = { 1280, 960 }, Idle = true,
        Camera = { Offset = vector3(0.007, -0.701, 0.400), LookAt = vector3(-0.001, 0.000, 0.301), Fov = 46.0, Transition = 600 },
        },
    ['prop_monitor_01b'] = {
        Variants = { 'prop_monitor_01b_dui_01', 'prop_monitor_01b_dui_02' }, Texture = 'script_rt_tvscreen', Resolution = { 1280, 960 }, Idle = true,
        Camera = { Offset = vector3(0.000, -0.627, 0.405), LookAt = vector3(-0.003, 0.000, 0.292), Fov = 56.0, Transition = 600 },
    },
    ['ch_prop_casino_keypad_02'] = {
        Variants = { 'ch_prop_casino_keypad_02_dui_01', 'ch_prop_casino_keypad_02_dui_02' }, Texture = 'prop_ld_keypad_01b_screen_dui_01',Resolution = { 512, 256 },
        Camera = { Offset = vector3(0.0, -0.4, 0.02), LookAt = vector3(0.0, 0.0, 0.02), Fov = 35.0, Transition = 500 },
    },
    ['v_corp_bk_secpanel'] = {
        Variants = { 'v_corp_bk_secpanel_dui_01', 'v_corp_bk_secpanel_dui_02' }, Texture = 'prop_ld_keypad_01b_screen_dui_01',  Resolution = { 512, 384 },
        Camera = { Offset = vector3(0.0, -0.45, 0.05), LookAt = vector3(0.0, 0.0, 0.05), Fov = 35.0, Transition = 500 },
    },

    ['prop_fleeca_atm'] = {
        Variants = { 'prop_fleeca_atm_dui_01', 'prop_fleeca_atm_dui_02' }, Texture = 'prop_fleeca_atm_screen_dui', Resolution = { 1326, 948 }, -- screen is ~1.4 : 1
        Idle = { Texture = 'prop_fleece_emis' },
        Camera = { Offset = vector3(-0.1205, -0.415, 1.2125), LookAt = vector3(-0.1205, 0.085, 1.1425), Fov = 40.0, Transition = 500 },
    },
    ['prop_atm_01'] = {
        Variants = { 'prop_atm_01_dui_01', 'prop_atm_01_dui_02' }, Texture = 'prop_cashpoint_screen', Resolution = { 1326, 1004 }, Idle = true,
        Camera = { Offset = vector3(-0.053, -0.62, 1.15), LookAt = vector3(-0.053, -0.12, 1.08), Fov = 40.0, Transition = 500 },
    },
    ['prop_atm_02'] = {
        Variants = { 'prop_atm_02_dui_01', 'prop_atm_02_dui_02' }, Texture = 'prop_atm_02_screen_dui', Resolution = { 1326, 1004 }, Idle = true,
        Camera = { Offset = vector3(-0.1205, -0.415, 1.21), LookAt = vector3(-0.1205, 0.085, 1.14), Fov = 30.0, Transition = 500 },
    },
    ['prop_atm_03'] = {
        Variants = { 'prop_atm_03_dui_01', 'prop_atm_03_dui_02' }, Texture = 'prop_cashpoint_screen', Resolution = { 1326, 1004 }, Idle = true,
        Camera = { Offset = vector3(-0.1205, -0.43, 1.21), LookAt = vector3(-0.1205, 0.07, 1.14), Fov = 30.0, Transition = 500 },
    },
}

-- ── Normalised (client + server) ───────────────────────────────────────────
-- Data.Name = base model, Data.Variants = { { Model, Hash, Texture, Dict }, ... } (nil = old way),
-- Config.ModelsByHash[hash of the base or any copy] = Data.
Config.ModelsByHash = {}
for Name, Data in pairs(Config.Models) do
    Data.Name = Name
    Data.Resolution = Data.Resolution or { 1280, 720 }
    Config.ModelsByHash[joaat(Name)] = Data
    if Data.Variants then
        for i, V in ipairs(Data.Variants) do
            V = type(V) == 'table' and V or { Model = V }
            V.Index, V.Hash = i, joaat(V.Model)
            V.Texture, V.Dict = V.Texture or Data.Texture, V.Dict or V.Model -- same texture name is fine: each copy has its own .ytd
            Data.Variants[i] = V
            Config.ModelsByHash[V.Hash] = Data
        end
        -- Idle page on the original model's texture (not when the copy is the model itself: same texture)
        if Data.Idle and Data.Variants[1].Model ~= Name then
            local I = type(Data.Idle) == 'table' and Data.Idle or {}
            Data.Idle = { Texture = I.Texture or Data.Texture, Dict = I.Dict or Name, Hash = joaat(Name) }
        else
            Data.Idle = nil
        end
    end
end
