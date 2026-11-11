Config = {}

Config.DevMode = false            -- enables /duicalib
Config.DrawDistance = 25.0        -- screens further than this from the camera aren't drawn
Config.Brightness = 235           -- 0-255, screen brightness (stable, not affected by lights)
Config.DefaultResolution = { 1280, 720 }

--[[
    Screens per prop model. Offsets are relative to the prop (use /duicalib to find them):
      TL / TR / BL = top-left, top-right, bottom-left corner of the visible screen.

    With corners the page is drawn on that ONE entity, unlit (no glare, no copies on other props).
    Without corners it falls back to the old global modes (every prop of the model, game lighting):
      Texture = 'name' (+ Dict, defaults to the model)  -> AddReplaceTexture
      RenderTarget = 'name'                             -> named render target

    Resolution = DUI page size, keep it the screen's aspect ratio (/duicalib prints one).
]]
Config.Models = {
    -- Laptops (fw-bennys). Corners not calibrated yet -> texture/render target fallback until you run /duicalib.
    ['prop_laptop_jimmy'] = { Resolution = { 1280, 800 }, Texture = 'prop_jimmy_screen' },
    ['prop_laptop_01a'] = { Resolution = { 1280, 640 }, RenderTarget = 'prop_moniter_desktop' },
    ['as_prop_as_laptop_01a'] = { Resolution = { 1280, 800 }, Texture = 'prop_moniter_desktop_01' },

    -- ATMs (osm-atmdui). Corners from the old osm screen offsets, fine-tune with /duicalib.
    ['prop_fleeca_atm'] = { Resolution = { 1326, 1004 }, TL = vec3(-0.306, 0.085, 1.23), TR = vec3(0.065, 0.085, 1.23), BL = vec3(-0.306, 0.085, 1.055) },
    ['prop_atm_01'] = { Resolution = { 1326, 1004 }, TL = vec3(-0.19, -0.12, 1.14), TR = vec3(0.084, -0.12, 1.14), BL = vec3(-0.19, -0.12, 1.02) },
    ['prop_atm_02'] = { Resolution = { 1326, 1004 }, TL = vec3(-0.306, 0.085, 1.23), TR = vec3(0.065, 0.085, 1.23), BL = vec3(-0.306, 0.085, 1.05) },
    ['prop_atm_03'] = { Resolution = { 1326, 1004 }, TL = vec3(-0.306, 0.07, 1.23), TR = vec3(0.065, 0.07, 1.23), BL = vec3(-0.306, 0.07, 1.05) },
}

--[[
    Always-on screens (idle monitors, info boards, ...). Shown while you're near, one DUI each.
      PropId = id from fw-props (/placeprop prints it)   OR   Model + Coords of a map prop
      Url    = page to show (nui://resource/file.html or https://...)
      Data   = sent to the page as { action = 'data', data = Data }
]]
Config.Screens = {
    -- { PropId = 12, Url = 'nui://fw-dui/html/idle.html', Data = { Title = 'Hayes Repairs', Text = 'Log in to see work orders' } },
}
