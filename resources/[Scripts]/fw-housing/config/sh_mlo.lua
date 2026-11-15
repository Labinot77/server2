Config = Config or {}

--[[
    MLO HOUSES
      FrontDoor / BackDoor  Doors = { { Model, Coords } } (two entries = double door). Registered in fw-doors as
                            HOUSE_<key>_<Front|Back>_<n>; owner + keyholders with door access get the keys.
      Zone                  Interior PolyZone. Decorate / house menu (fw-menu) only work inside it.
      Surfaces              Textures of the MLO's .ytd that the owner can recolour (Walls / Floor / Ceiling).
                            Find names with OpenIV / CodeWalker (texture dictionary of the interior).
      Stash                 Storage crates placed in decorate mode: Crates = how many, Slots / Weight = per crate.
]]

Config.MLOHouses = {
    ['test'] = {
        Label = 'Grove Street MLO 1',
        Price = 250000,
        Class = 2,
        Spawn = vector4(423.20, -1837.40, 28.46, 45.0),

        FrontDoor = { Doors = { { Model = 224373542, Coords = vector3(426.548, -1841.948, 28.523) } } },
        BackDoor = { Doors = { { Model = -496675514, Coords = vector3(418.475, -1832.568, 28.539) } } },

        Zone = {
            points = {
                vector2(427.5217590332, -1843.0806884766),
                vector2(426.33529663086, -1841.8986816406),
                vector2(425.27160644531, -1845.2868652344),
                vector2(416.919921875, -1836.5169677734),
                vector2(419.83209228516, -1833.7668457031),
                vector2(417.11373901367, -1831.0266113281),
                vector2(419.87286376953, -1828.2680664062),
                vector2(429.45004272461, -1838.1335449219),
                vector2(427.1897277832, -1840.4588623047),
                vector2(427.46789550781, -1840.7495117188),
                vector2(425.71939086914, -1840.8917236328),
            },
            -- Floor is ~28.0. Keep minZ slightly under the floor, raise maxZ if the MLO has an upstairs.
            minZ = 27.0,
            maxZ = 33.0,
            debug = false, -- true = draw the zone in-game
        },

        Surfaces = {
            Txd = 'mloqf3_tex',
            Walls = { 'mloqf3_plaster_white', 'mloqf3_brick_cream' },
            Floor = { 'mloqf3_plaster_grey' },
            Ceiling = { 'mloqf3_metal_sheet' },
        },

        Stash = { Crates = 2, Slots = 40, Weight = 1000 },
        MaxDecorations = 150,
    },
}

Config.MLOTest = { Enabled = true, Permission = 'admin', ChargeMoney = true } -- /buymlo /sellmlo

-- Garage (F1 menu > Place garage): inside the house or within MaxDistanceFromZone of it, around floor height.
Config.MLOGarage = { MaxDistanceFromZone = 12.0, MaxHeightDifference = 4.0 }

-- Storage is real furniture: crates are stashes (limit per house = Stash.Crates), wardrobes open outfits / sleep.
-- Tablet: placed in /housecreator (fixed, can't be moved), runs the House app (fw-dui desktop, copies _dui_01 / _dui_02).
Config.Storage = { Crate = 'm23_1_prop_m31_roostercrate_02a', Wardrobe = 'v_res_tre_wardrobe', Tablet = 'sf_prop_sf_tablet_01a' }

-- House app (tablet). Upgrades are bought once per house from the owner's bank account.
Config.HouseApp = {
    Keyholders = 5,               -- max keyholders, +5 with the Keyholder upgrade
    StorageBonus = { Slots = 20, Weight = 500 }, -- extra per crate with the Storage upgrade
    Fee = { Percent = 0.25, Days = 7 }, -- maintenance: % of the house price every X days, auto-withdrawn
    Upgrades = {
        { Id = 'storage', Label = 'Storage', Price = 12500, Desc = 'Gives you more storage slots inside your house.' },
        { Id = 'security', Label = 'Security', Price = 7500, Desc = 'You receive a notification when your house has been broken into.' },
        { Id = 'keyholder', Label = 'Keyholder Upgrade', Price = 7500, Desc = 'This upgrade allows you to add 5 more keyholders to your house.' },
        { Id = 'doors', Label = 'Door Upgrade', Price = 15000, Desc = 'Only people with door access can open the doors you place down.' },
        { Id = 'timecycle', Label = 'Timecycle', Price = 5000, Desc = 'Change the lighting mood inside your house from the settings.' },
        { Id = 'garage', Label = 'Shared Garage', Price = 10000, Desc = 'Keyholders can use your house garage too.' },
        { Id = 'electricity', Label = 'Electricity (10% Off)', Price = 5000, Desc = 'Efficient wiring: your house uses 10% less electricity.' },
    },
    Timecycles = {
        { Id = '', Label = 'Default' }, { Id = 'MP_Arena_theme_evening', Label = 'Warm Evening' }, { Id = 'mp_lad_night', Label = 'Night Club' },
        { Id = 'NG_filmic02', Label = 'Cinematic' }, { Id = 'MP_corona_heist_DOF', Label = 'Soft Focus' }, { Id = 'nightvision', Label = 'Green Night' },
    },
    -- Wall / floor / ceiling colours in the Settings tab (needs Surfaces textures in the house config).
    Colors = {
        '#FFFFFF', '#E8E1D9', '#D9C3A5', '#E3A766', '#7C93B5', '#7068D6', '#3E3A72', '#A0573F', '#E8344E', '#8A4A57', '#A7AD99', '#5E6B60',
        '#4B4466', '#D3A6DB', '#6B6B6B', '#2F2F33', '#C5CEDB', '#0F3B2B', '#4BE3E3', '#55B7E8', '#F06A6A', '#0A0A0A', '#F5DD7A', '#BFC4C9',
        '#123827', '#F08BBF', '#A5E38A', '#3C8C3C', '#7A0E0E', '#8A5A2B', '#D8F2B5', '#9B4DE8',
    },
}
Config.MLOClearDecorOnSell = true

Config.Decorate = {
    ChargeMoney = false,
    Price = 250,            -- price per object when ChargeMoney = true
    RefundPercentage = 50,
    MaxRayDistance = 8.0,
    UnloadDelay = 5,        -- seconds after leaving the zone before the furniture is deleted
    -- Prop thumbnails (%s = model). Uses kq_propplacer's images while that resource is started.
    Thumbnails = 'https://cfx-nui-kq_propplacer/nui/dist/assets/%s.webp',
    CamSpeed = 3.0,         -- freecam metres per second (SHIFT = x3)
    MaxSelect = 10,         -- CTRL + click multi-select
    Tints = 16,             -- Y cycles the prop texture variation 0 .. Tints - 1
    RotSteps = { 1, 5, 15, 45, 90 }, RotInc = 2,                 -- CTRL + scroll, default 5 degrees
    GridSteps = { 0.01, 0.05, 0.1, 0.25, 0.5, 1.0 }, GridInc = 3, -- ALT + scroll, G toggles grid snap
    -- Bottom bar buttons. Categories are the ones from sh_catalog.lua ('Build' = resizable wall), Entities = every prop in fw-dev.
    Groups = {
        { Name = 'Structure', Icon = 'grid', Categories = { 'Custom Walls', 'Build', 'Walls', 'Doors' } },
        { Name = 'Office', Icon = 'clipboard', Categories = { 'Office' } },
        { Name = 'Construction', Icon = 'tools', Categories = { 'Construction', 'Industrial', 'Garage', 'Equipment' } },
        { Name = 'Outdoor', Icon = 'tree', Categories = { 'Outdoor', 'Outdoor furniture', 'Plants' } },
        { Name = 'Interior', Icon = 'house', Categories = { 'Interior', 'Seating', 'Tables', 'Storage' } },
        { Name = 'Electrical', Icon = 'bolt', Categories = { 'Electrical', 'Lights' } },
        { Name = 'Plumbing', Icon = 'faucet', Categories = { 'Bathroom', 'Kitchen' } },
        { Name = 'Utility', Icon = 'plug', Categories = { 'Utility' } },
        { Name = 'Leisure', Icon = 'briefcase', Categories = { 'Bar', 'Recreational', 'Misc' } },
        { Name = 'Clutter', Icon = 'kit', Categories = { 'Bins', 'Trash', 'Clutter' } },
        { Name = 'Entities', Icon = 'E', Entities = true },
    },
}

-- Colours the owner can pick for walls / floor / ceiling. The first 16 are also the built walls' tint palette
-- (tools/make_wall_kit.py bakes them in the same order: change both together and rebuild the kit).
Config.SurfaceColors = {
    { 'White', '#F2F2F2' }, { 'Cream', '#EADDC4' }, { 'Beige', '#CDB891' }, { 'Light grey', '#B5B5B5' },
    { 'Dark grey', '#4A4A4A' }, { 'Black', '#161616' }, { 'Sage', '#9CAF88' }, { 'Forest', '#2F4B37' },
    { 'Sky', '#9EC5E0' }, { 'Navy', '#1F2E4D' }, { 'Terracotta', '#B5583B' }, { 'Blush', '#E3B5B0' },
    { 'Mustard', '#D4A63A' }, { 'Oak', '#8A6239' }, { 'Walnut', '#5A3D26' }, { 'Bordeaux', '#5C1F2A' },
}

-- Resizable walls, built from the fw_wall_<w>x<h> kit (w, h in cm: 25, 50, 100, 200). See README_WALLS.md.
Config.Walls = {
    Cell = 0.25,            -- grid size in metres (smallest kit piece)
    MaxLength = 8.0, MaxHeight = 4.0, MaxHoles = 4,
    Anchor = 'prop_golf_ball',                  -- invisible pivot (bottom centre of the wall)
    Texture = { 'fw_walls', 'fw_wall_plaster' }, -- recoloured with the owner's wall colour
    Presets = { Door = { W = 1.0, H = 2.25, Z = 0.0 }, Window = { W = 1.0, H = 1.0, Z = 1.0 } },
}

-- Custom walls (tools/make_custom_walls.py, resource fw-custom-walls): one prop per material and size, with collision.
-- Colourable: the paint bucket picks a row of TintColors (row 1 = white = the texture's own colours).
-- Model = fw_cw_<material>_<size>. Change materials / sizes / colours here AND in the script, then rebuild.
Config.CustomWalls = {
    Txd = 'fw_custom_walls',
    TintColors = {
        '#FFFFFF', '#EADDC4', '#CDB891', '#B5B5B5', '#6E6E6E', '#2B2B2B', '#9CAF88', '#2F4B37',
        '#9EC5E0', '#2E4A7D', '#B5583B', '#E3B5B0', '#D4A63A', '#8A6239', '#5A3D26', '#7A2633',
    },
    Materials = {
        { Id = 'plaster', Label = 'Plaster Wall Panel' }, { Id = 'woodlight', Label = 'Hardwood Wall Light' },
        { Id = 'wooddark', Label = 'Hardwood Wall Dark' }, { Id = 'tile', Label = 'Tile Wall Panel' },
        { Id = 'brick', Label = 'Brick Wall' }, { Id = 'brickred', Label = 'Brick Wall B' },
        { Id = 'stone', Label = 'Stone Wall' }, { Id = 'marble', Label = 'White Marble Wall' },
    },
    Sizes = { -- metres, 10 cm thick. Hole = opening { X = centre, Z = bottom, W, H } (no collision there)
        { Id = 'xs', Label = 'XS', W = 0.5, H = 0.5 }, { Id = 's', Label = 'Small', W = 1.0, H = 1.0 },
        { Id = 'm', Label = 'Medium', W = 1.0, H = 2.5 }, { Id = 'l', Label = 'Large', W = 2.0, H = 2.5 },
        { Id = 'xl', Label = 'XL', W = 3.0, H = 3.0 },
        { Id = 'door', Label = 'Door Frame', W = 1.5, H = 2.5, Hole = { X = 0.0, Z = 0.0, W = 1.0, H = 2.15 } },
        { Id = 'window', Label = 'Window Frame', W = 1.5, H = 2.5, Hole = { X = 0.0, Z = 0.9, W = 1.0, H = 1.1 } },
    },
}

-- // Derived (don't edit) \\ --

Config.DecorByModel = {}
for _, Cat in ipairs(Config.DecorCatalog) do
    for _, Item in ipairs(Cat.items) do
        Config.DecorByModel[Item.model] = { Type = Item.physics and 'door' or 'furniture', Category = Cat.category }
    end
end

Config.CustomWalls.List = {} -- { { Model, Label, Material, W, H } } in catalog order
for _, M in ipairs(Config.CustomWalls.Materials) do
    for _, S in ipairs(Config.CustomWalls.Sizes) do
        local Model = ('fw_cw_%s_%s'):format(M.Id, S.Id)
        Config.CustomWalls.List[#Config.CustomWalls.List + 1] = { Model = Model, Label = M.Label .. ' ' .. S.Label, Material = M.Id, W = S.W, H = S.H, Hole = S.Hole }
        Config.DecorByModel[Model] = { Type = 'furniture', Category = 'Custom Walls', Tint = true }
    end
end
Config.DecorByModel[Config.Storage.Crate] = { Type = 'crate', Category = 'Storage' }
Config.DecorByModel[Config.Storage.Wardrobe] = { Type = 'wardrobe', Category = 'Storage' }

-- Props from fw-dev (config/sh_entities.lua, { [hash] = name }): included by the manifest, else through its export.
local EntityList = nil
function GetEntityList()
    if EntityList == nil then
        local Ok, List = pcall(function() return Config.Entities or exports['fw-dev']:GetEntities() end)
        EntityList = Ok and type(List) == 'table' and List or {}
    end
    return EntityList
end

-- Lowercase names that aren't peds.
local PedPrefixes = { '^a_[cfm]_', '^[gsu]_[fm]_', '^cs_', '^csb_', '^ig_', '^hc_', '^mp_[fgms]_', '^player_' }
function IsEntityProp(Model)
    if type(Model) ~= 'string' or Model ~= Model:lower() or GetEntityList()[GetHashKey(Model)] ~= Model then return false end
    for _, P in ipairs(PedPrefixes) do if Model:find(P) then return false end end
    return true
end

-- { Type, Category } of anything that may be placed.
function GetDecorItem(Model)
    return Config.DecorByModel[Model] or (IsEntityProp(Model) and { Type = 'furniture', Category = 'Entities' }) or nil
end

-- Houses made in game (/housecreator) are stored in the `mlo_houses` table and go through the same functions.
local function V3(T) return T and vector3(T.x + 0.0, T.y + 0.0, T.z + 0.0) end

-- Adds / replaces (or removes with Def = nil) a house definition, from config, the database or the network.
function RegisterMloDef(Key, Def)
    if not Def then Config.MLOHouses[Key] = nil return end
    local Points, X, Y = {}, 0.0, 0.0
    for _, P in ipairs(Def.Zone.points) do
        Points[#Points + 1] = vector2(P.x + 0.0, P.y + 0.0)
        X, Y = X + P.x, Y + P.y
    end
    Def.Zone.points = Points
    for _, Side in ipairs({ 'FrontDoor', 'BackDoor' }) do
        for _, D in ipairs(Def[Side] and Def[Side].Doors or {}) do D.Coords, D.Model = V3(D.Coords), tonumber(D.Model) end
    end
    if Def.Spawn then Def.Spawn = vector4(Def.Spawn.x + 0.0, Def.Spawn.y + 0.0, Def.Spawn.z + 0.0, (Def.Spawn.w or 0.0) + 0.0) end
    Def.Key = Key
    Def.Center = vector3(X / #Points, Y / #Points, Def.Zone.minZ or 0.0)
    Config.MLOHouses[Key] = Def
end

-- Plain table (json / network safe) of a definition.
function MloDefToData(Def)
    local function T(V) return V and { x = V.x, y = V.y, z = V.z, w = V.w } or nil end
    local Data = {
        Label = Def.Label, Price = Def.Price, Class = Def.Class, Spawn = T(Def.Spawn), MaxDecorations = Def.MaxDecorations,
        Stash = Def.Stash, Surfaces = Def.Surfaces, Dynamic = Def.Dynamic,
        Zone = { minZ = Def.Zone.minZ, maxZ = Def.Zone.maxZ, points = {} },
        Tablet = Def.Tablet and { Coords = T(Def.Tablet.Coords), Rot = T(Def.Tablet.Rot) } or nil,
    }
    for _, P in ipairs(Def.Zone.points) do Data.Zone.points[#Data.Zone.points + 1] = { x = P.x, y = P.y } end
    for _, Side in ipairs({ 'FrontDoor', 'BackDoor' }) do
        if Def[Side] and Def[Side].Doors and #Def[Side].Doors > 0 then
            Data[Side] = { Doors = {} }
            for _, D in ipairs(Def[Side].Doors) do Data[Side].Doors[#Data[Side].Doors + 1] = { Model = D.Model, Coords = T(D.Coords) } end
        end
    end
    return Data
end

for Key, Mlo in pairs(Config.MLOHouses) do RegisterMloDef(Key, Mlo) end

function GetMloConfig(Key)
    return Key and Config.MLOHouses[Key] or nil
end

-- Point-in-polygon without PolyZone (PolyZone is client only, the server needs the same check).
function IsPointInMloZone(Key, Coords)
    local Mlo = GetMloConfig(Key)
    if not Mlo then return false end

    local Zone = Mlo.Zone
    if Zone.minZ and Coords.z < Zone.minZ then return false end
    if Zone.maxZ and Coords.z > Zone.maxZ then return false end

    local Inside, Points = false, Zone.points
    local J = #Points
    for I = 1, #Points do
        local Pi, Pj = Points[I], Points[J]
        if ((Pi.y > Coords.y) ~= (Pj.y > Coords.y)) and (Coords.x < (Pj.x - Pi.x) * (Coords.y - Pi.y) / (Pj.y - Pi.y) + Pi.x) then
            Inside = not Inside
        end
        J = I
    end

    return Inside
end

-- Shortest 2D distance from a point to the edge of the zone polygon.
function GetDistanceToMloZoneEdge(Key, Coords)
    local Mlo = GetMloConfig(Key)
    if not Mlo then return math.huge end

    local Best, Points = math.huge, Mlo.Zone.points
    local J = #Points
    for I = 1, #Points do
        local A, B = Points[J], Points[I]
        local Dx, Dy = B.x - A.x, B.y - A.y
        local LenSq = Dx * Dx + Dy * Dy
        local T = LenSq > 0 and (((Coords.x - A.x) * Dx + (Coords.y - A.y) * Dy) / LenSq) or 0.0
        T = math.max(0.0, math.min(1.0, T))
        local Px, Py = A.x + Dx * T, A.y + Dy * T
        local Dist = math.sqrt((Coords.x - Px) ^ 2 + (Coords.y - Py) ^ 2)
        if Dist < Best then Best = Dist end
        J = I
    end

    return Best
end

-- { { Info, Model, Coords, Side }, ... } for every physical door of a house.
function GetMloDoors(Key)
    local Mlo, List = GetMloConfig(Key), {}
    for _, Side in ipairs({ 'Front', 'Back' }) do
        local D = Mlo and Mlo[Side .. 'Door']
        for I, E in ipairs(D and D.Doors or {}) do
            List[#List + 1] = { Info = ('HOUSE_%s_%s_%d'):format(Key, Side, I), Model = E.Model, Coords = E.Coords, Side = Side }
        end
    end
    return List
end

local CustomWallLabels = {}
for _, W in ipairs(Config.CustomWalls.List) do CustomWallLabels[W.Model] = W.Label end

function GetItemLabel(Model)
    if Model == 'fw_wall' then return 'Wall' end
    if CustomWallLabels[Model] then return CustomWallLabels[Model] end
    if Model == Config.Storage.Crate then return 'Storage Crate' end
    if Model == Config.Storage.Wardrobe then return 'Wardrobe' end
    return (Model:gsub('^%a+_mp_h_', ''):gsub('^%a+_prop_', ''):gsub('^prop_', ''):gsub('^v_%a+_', ''):gsub('_', ' '):gsub('^%l', string.upper))
end

-- // Walls \\ --

Config.DecorByModel['fw_wall'] = { Type = 'wall', Category = 'Build' }

local function Cells(V) return math.floor((tonumber(V) or 0) / Config.Walls.Cell + 0.5) end
local function Clamp(V, Min, Max) return math.max(Min, math.min(Max, V)) end

-- Wall = { L, H, Holes = { { X = centre offset along the wall, Z = bottom, W, H } } }, everything on the grid.
function SanitizeWall(W)
    if type(W) ~= 'table' then return end
    local C, Cfg = Config.Walls.Cell, Config.Walls
    local L, H = Clamp(Cells(W.L), 2, Cells(Cfg.MaxLength)), Clamp(Cells(W.H), 2, Cells(Cfg.MaxHeight))
    local Wall = { L = L * C, H = H * C, Holes = {} }
    for I, Hole in ipairs(type(W.Holes) == 'table' and W.Holes or {}) do
        if I > Cfg.MaxHoles then break end
        local Hw, Hh = Clamp(Cells(Hole.W), 1, L), Clamp(Cells(Hole.H), 1, H)
        local Left = Clamp(Cells((tonumber(Hole.X) or 0) - Hw * C / 2 + Wall.L / 2), 0, L - Hw)
        local Bottom = Clamp(Cells(Hole.Z), 0, H - Hh)
        Wall.Holes[#Wall.Holes + 1] = { X = (Left + Hw / 2) * C - Wall.L / 2, Z = Bottom * C, W = Hw * C, H = Hh * C }
    end
    return Wall
end

-- Splits the wall (minus its holes) into as few kit pieces as possible: { { Model, X, Z } }.
function BuildWallPieces(W)
    local C, Sizes = Config.Walls.Cell, { 8, 4, 2, 1 }
    local Cols, Rows, Grid, Pieces = Cells(W.L), Cells(W.H), {}, {}
    local function Fit(N) for _, S in ipairs(Sizes) do if S <= N then return S end end end

    for R = 0, Rows - 1 do Grid[R] = {} for Col = 0, Cols - 1 do Grid[R][Col] = true end end
    for _, Hole in ipairs(W.Holes or {}) do
        local Left, Bottom = Cells(Hole.X - Hole.W / 2 + W.L / 2), Cells(Hole.Z)
        for R = Bottom, Bottom + Cells(Hole.H) - 1 do
            for Col = Left, Left + Cells(Hole.W) - 1 do if Grid[R] then Grid[R][Col] = nil end end
        end
    end

    for R = 0, Rows - 1 do
        for Col = 0, Cols - 1 do
            if Grid[R][Col] then
                local Wd, Ht = 0, 1
                while Wd < 8 and Grid[R][Col + Wd] do Wd = Wd + 1 end
                Wd = Fit(Wd)
                local function RowFree(Row)
                    if not Grid[Row] then return false end
                    for I = 0, Wd - 1 do if not Grid[Row][Col + I] then return false end end
                    return true
                end
                while Ht < 8 and RowFree(R + Ht) do Ht = Ht + 1 end
                Ht = Fit(Ht)
                for Y = R, R + Ht - 1 do for X = Col, Col + Wd - 1 do Grid[Y][X] = nil end end
                Pieces[#Pieces + 1] = { Model = ('fw_wall_%dx%d'):format(Wd * 25, Ht * 25), X = (Col + Wd / 2) * C - W.L / 2, Z = R * C }
            end
        end
    end
    return Pieces
end
