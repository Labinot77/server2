Config = Config or {}

--[[
    MLO HOUSES
    ----------
    Every entry below becomes a normal row in `player_houses` (created automatically on resource start),
    so the phone Housing app, realtor sales, keys, garage, spawn selection and selling all work as usual.

    Differences from shell houses:
      * No teleport. The real MLO door(s) are locked/unlocked with the house lock state.
      * Players with access can decorate anywhere inside `Zone` (validated client AND server side).

    Fields:
      Label        Address shown in the phone / contracts.
      Price        Sale price while nobody owns it (kept in sync with the DB while unowned).
      Class        Realtor class (see Config.PricesPerClass).
      Entrance     vector4 outside the front door. Used for the radial "lock" option, the phone GPS & spawn.
      Spawn        (optional) vector4 inside the house, used when the player spawns at this house.
      Doors        The physical MLO doors. Use /mlodoor while looking at a door to get Model + Coords.
      Zone         The interior PolyZone (points, minZ, maxZ).
      Stash        (optional) Default stash position + size. Owners can still move it with the phone.
      Wardrobe     (optional) Default wardrobe position.
      MaxDecorations  Max number of placed furniture objects.
]]

Config.MLOHouses = {
    ['test'] = {
        Label = 'Test MLO House',
        Price = 250000,
        Class = 2,

        -- TODO: stand right outside the front door and use /mlodoor (prints your position too).
        Entrance = vector4(426.30, -1842.60, 28.46, 225.0),
        Spawn = vector4(423.20, -1837.40, 28.46, 45.0),

        -- TODO: look at the front door in-game and run /mlodoor, then paste the printed line here.
        -- Example:
        -- { Model = 'v_ilev_trevtraildr', Coords = vector3(426.85, -1842.35, 28.55) },
        -- { Model = 224373542, Coords = vector3(426.55, -1841.95, 28.57) },
        Doors = {
    { Model = 224373542, Coords = vector3(426.55, -1841.95, 28.57) }, -- front door
        },

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
            -- Your recorded floor height is ~28.0. Raise maxZ if the MLO has an upstairs.
            minZ = 26.8,
            maxZ = 32.5,
        },

        Stash = { Coords = false, Slots = 40, Weight = 1000 },
        Wardrobe = false,

        MaxDecorations = 100,
    },
}

-- Distance (from the zone centre) at which decorations are streamed in for nearby players.
Config.MLODecorLoadDistance = 60.0

-- Remove all furniture when the owner sells the house.
Config.MLOClearDecorOnSell = true

Config.Decorate = {
    KeyholdersCanDecorate = true, -- false = only the owner can decorate
    ChargeMoney = true,           -- charge the catalog Price from the player's bank account
    RefundPercentage = 50,        -- % refunded when an object is removed (0 to disable)
    MaxRayDistance = 8.0,         -- how far from the camera an object can be placed
    RotateStep = 5.0,             -- degrees per scroll tick (hold SHIFT for 1 degree)
    HeightStep = 0.01,            -- metres per frame while holding arrow up/down
    ShellMaxDistance = 40.0,      -- for shell houses: max distance from the shell origin
}

--[[
    Furniture catalog. Only models in this list can be placed (enforced server side).
    Add/remove anything you like, any streamed prop works.
]]
Config.Furniture = {
    {
        Category = 'Seating', Icon = 'couch',
        Items = {
            { Model = 'prop_couch_01',     Label = 'Couch (brown)',     Price = 1200 },
            { Model = 'prop_couch_03',     Label = 'Couch (leather)',   Price = 1500 },
            { Model = 'prop_couch_04',     Label = 'Couch (grey)',      Price = 1500 },
            { Model = 'v_res_mp_sofa',     Label = 'Modern sofa',       Price = 2200 },
            { Model = 'prop_armchair_01',  Label = 'Armchair',          Price = 600 },
            { Model = 'v_res_m_armchair',  Label = 'Armchair (modern)', Price = 900 },
            { Model = 'prop_chair_01a',    Label = 'Wooden chair',      Price = 150 },
            { Model = 'prop_chair_04a',    Label = 'Dining chair',      Price = 250 },
            { Model = 'prop_off_chair_01', Label = 'Office chair',      Price = 400 },
            { Model = 'prop_bar_stool_01', Label = 'Bar stool',         Price = 200 },
        },
    },
    {
        Category = 'Tables', Icon = 'table',
        Items = {
            { Model = 'prop_table_01',   Label = 'Table (small)',   Price = 300 },
            { Model = 'prop_table_02',   Label = 'Table (round)',   Price = 350 },
            { Model = 'prop_table_03',   Label = 'Table (wooden)',  Price = 400 },
            { Model = 'prop_table_04',   Label = 'Table (dining)',  Price = 500 },
            { Model = 'v_res_m_dinetble', Label = 'Dining table',   Price = 900 },
            { Model = 'v_res_fh_coftablea', Label = 'Coffee table', Price = 450 },
        },
    },
    {
        Category = 'Beds', Icon = 'bed',
        Items = {
            { Model = 'v_res_msonbed',  Label = 'Double bed',     Price = 1800 },
            { Model = 'v_res_tre_bed1', Label = 'Single bed',     Price = 900 },
            { Model = 'v_res_d_bed',    Label = 'Luxury bed',     Price = 3000 },
            { Model = 'p_lestersbed_s', Label = 'Old bed',        Price = 500 },
        },
    },
    {
        Category = 'Storage', Icon = 'archive',
        Items = {
            { Model = 'v_res_tre_wardrobe', Label = 'Wardrobe',  Price = 800 },
            { Model = 'v_res_mddresser',    Label = 'Dresser',   Price = 700 },
            { Model = 'v_res_cabinet',      Label = 'Cabinet',   Price = 600 },
            { Model = 'v_res_tre_storageunit', Label = 'Storage unit', Price = 650 },
        },
    },
    {
        Category = 'Electronics', Icon = 'tv',
        Items = {
            { Model = 'prop_tv_flat_01',  Label = 'Flat TV (large)',  Price = 2500 },
            { Model = 'prop_tv_flat_02',  Label = 'Flat TV (medium)', Price = 1500 },
            { Model = 'prop_tv_flat_03',  Label = 'Flat TV (small)',  Price = 900 },
            { Model = 'prop_laptop_01a',  Label = 'Laptop',           Price = 1200 },
            { Model = 'prop_monitor_01a', Label = 'Monitor',          Price = 400 },
            { Model = 'prop_speaker_06',  Label = 'Speaker',          Price = 350 },
            { Model = 'prop_boombox_01',  Label = 'Boombox',          Price = 250 },
        },
    },
    {
        Category = 'Kitchen', Icon = 'utensils',
        Items = {
            { Model = 'prop_fridge_01',     Label = 'Fridge',         Price = 1100 },
            { Model = 'prop_cooker_03',     Label = 'Cooker',         Price = 900 },
            { Model = 'prop_micro_01',      Label = 'Microwave',      Price = 200 },
            { Model = 'prop_coffee_mac_02', Label = 'Coffee machine', Price = 300 },
        },
    },
    {
        Category = 'Decoration', Icon = 'seedling',
        Items = {
            { Model = 'prop_plant_int_01a', Label = 'Plant (tall)',   Price = 120 },
            { Model = 'prop_plant_int_02a', Label = 'Plant (bush)',   Price = 120 },
            { Model = 'prop_plant_int_03a', Label = 'Plant (palm)',   Price = 150 },
            { Model = 'prop_pot_plant_01a', Label = 'Potted plant',   Price = 90 },
            { Model = 'v_res_m_lampstand',  Label = 'Standing lamp',  Price = 250 },
            { Model = 'v_res_d_lampa',      Label = 'Table lamp',     Price = 150 },
        },
    },
}

-- Built once: Model -> catalog item (used for validation + labels).
Config.FurnitureByModel = {}
for _, Category in ipairs(Config.Furniture) do
    for _, Item in ipairs(Category.Items) do
        Config.FurnitureByModel[Item.Model] = Item
    end
end

-- Pre-compute zone centres (used for streaming + entrance fallback).
for Key, Mlo in pairs(Config.MLOHouses) do
    local X, Y = 0.0, 0.0
    for _, P in ipairs(Mlo.Zone.points) do X, Y = X + P.x, Y + P.y end
    local Count = #Mlo.Zone.points
    Mlo.Center = vector3(X / Count, Y / Count, (Mlo.Zone.minZ + Mlo.Zone.maxZ) / 2)
    Mlo.Key = Key
end

-- Plain point-in-polygon (used server side, PolyZone is client-only).
function IsPointInMloZone(Key, Coords)
    local Mlo = Config.MLOHouses[Key]
    if not Mlo then return false end

    local Zone = Mlo.Zone
    if Coords.z < Zone.minZ or Coords.z > Zone.maxZ then return false end

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
