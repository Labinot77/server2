Config = Config or {}

--[[
    MLO HOUSES
    ----------
    Every entry below becomes a normal row in `player_houses` (created/updated automatically on resource start,
    linked by the `mlo` column), so keys, the phone Housing app, selling and the fw-vehicles garage all keep working.

    Differences from shell houses:
      * No teleport. The real MLO door(s) are locked/unlocked through `interact` + the GTA door system.
      * Furniture is streamed by the PolyZone: entering the zone spawns it, leaving the zone deletes it.
      * Decorating is only possible inside `Zone` (checked on the client AND the server).
      * The garage can only be placed outside the zone, within `Config.MLOGarage.MaxDistanceFromZone` of its edge.

    Fields:
      Label           Address shown in the phone / contracts. Must be unique.
      Price           Sale price while nobody owns it.
      Class           Realtor class (see Config.PricesPerClass).
      Spawn           (optional) vector4 inside the house, used when the player spawns at this house.
      FrontDoor       Required. The physical front door.
      BackDoor        Optional. Same format as FrontDoor, set to false / remove it if the MLO has none.
        Coords          Where the [E] prompt is drawn (usually the door centre).
        Doors           The door entities. Use /mlodoor while looking at a door to print Model + Coords.
                        Add two entries for a double door.
      Zone            The interior PolyZone (points, minZ, maxZ). Only the inside of the house!
      Stash           Size of the house stash. The position is set by the owner via the phone (like shells).
      MaxDecorations  Max number of placed objects (furniture + walls + doors).
]]

Config.MLOHouses = {
    ['test'] = {
        Label = 'Grove Street MLO 1',
        Price = 250000,
        Class = 2,

        Spawn = vector4(423.20, -1837.40, 28.46, 45.0),

        FrontDoor = {
            Coords = vector3(426.55, -1841.95, 28.57),
            Doors = {
                { Model = 224373542, Coords = vector3(426.55, -1841.95, 28.57) },
            },
        },

        -- Optional back door. Stand at the door, run /mlodoor and paste the output here.
        BackDoor = false,
        -- BackDoor = {
        --     Coords = vector3(0.0, 0.0, 0.0),
        --     Doors = {
        --         { Model = 0, Coords = vector3(0.0, 0.0, 0.0) },
        --     },
        -- },

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
            debug = true, -- true = draw the zone in-game
        },

        Stash = { Slots = 40, Weight = 1000 },
        MaxDecorations = 100,
    },
}

Config.MLOTest = {
    Enabled = true,          -- registers /buymlo and /sellmlo
    Permission = 'admin',    -- fw-core permission for the test commands ('user' = everyone)
    ChargeMoney = true,      -- /buymlo takes the price from the player's bank account
}

Config.MLOGarage = {
    MaxDistanceFromZone = 12.0, -- metres from the closest edge of the house zone
    MaxHeightDifference = 4.0,  -- metres above/below the zone floor (stops rooftop / bridge garages)
}

Config.MLOClearDecorOnSell = true -- remove all furniture + the garage when the house is sold

Config.Decorate = {
    KeyholdersCanDecorate = true, -- false = only the owner can decorate
    ChargeMoney = false,          -- test menu: free. Set true to charge the catalog Price from the bank
    RefundPercentage = 50,        -- % refunded when an object is removed (only when ChargeMoney = true)
    MaxRayDistance = 8.0,         -- how far from the camera an object can be placed
    RotateStep = 5.0,             -- degrees per scroll tick (hold SHIFT for 1 degree)
    HeightStep = 0.01,            -- metres per frame while holding arrow up/down
    SnapAngle = 90.0,             -- [G] toggles heading snapping (handy for walls/doors)
}

--[[
    Decoration catalog. Only models in this list can be placed (enforced server side).
    Type:
      furniture  static object
      wall       static object, placed flush on the floor (use SNAP to line them up)
      door       static object that players with access can open/close (rotates 90 degrees around its hinge)

    NOTE (test menu): GTA has no real "wall panel" props, the walls below are vanilla placeholders.
    Models that don't exist in your game build are hidden from the menu automatically (see F8).
    For the advanced version, stream your own wall / door props and add them here.
]]
Config.DecorCatalog = {
    {
        Category = 'Seating', Icon = 'couch', Type = 'furniture',
        Items = {
            { Model = 'prop_couch_01',     Label = 'Couch (brown)',     Price = 1200 },
            { Model = 'prop_couch_03',     Label = 'Couch (leather)',   Price = 1500 },
            { Model = 'v_res_mp_sofa',     Label = 'Modern sofa',       Price = 2200 },
            { Model = 'prop_armchair_01',  Label = 'Armchair',          Price = 600 },
            { Model = 'prop_chair_01a',    Label = 'Wooden chair',      Price = 150 },
            { Model = 'prop_off_chair_01', Label = 'Office chair',      Price = 400 },
            { Model = 'prop_bar_stool_01', Label = 'Bar stool',         Price = 200 },
        },
    },
    {
        Category = 'Tables', Icon = 'table', Type = 'furniture',
        Items = {
            { Model = 'prop_table_01',      Label = 'Table (small)', Price = 300 },
            { Model = 'prop_table_03',      Label = 'Table (wooden)', Price = 400 },
            { Model = 'v_res_m_dinetble',   Label = 'Dining table',  Price = 900 },
            { Model = 'v_res_fh_coftablea', Label = 'Coffee table',  Price = 450 },
        },
    },
    {
        Category = 'Beds & Storage', Icon = 'bed', Type = 'furniture',
        Items = {
            { Model = 'v_res_msonbed',      Label = 'Double bed', Price = 1800 },
            { Model = 'v_res_tre_bed1',     Label = 'Single bed', Price = 900 },
            { Model = 'v_res_tre_wardrobe', Label = 'Wardrobe',   Price = 800 },
            { Model = 'v_res_mddresser',    Label = 'Dresser',    Price = 700 },
        },
    },
    {
        Category = 'Electronics & Kitchen', Icon = 'tv', Type = 'furniture',
        Items = {
            { Model = 'prop_tv_flat_01',    Label = 'Flat TV (large)', Price = 2500 },
            { Model = 'prop_tv_flat_03',    Label = 'Flat TV (small)', Price = 900 },
            { Model = 'prop_laptop_01a',    Label = 'Laptop',          Price = 1200 },
            { Model = 'prop_fridge_01',     Label = 'Fridge',          Price = 1100 },
            { Model = 'prop_cooker_03',     Label = 'Cooker',          Price = 900 },
            { Model = 'prop_micro_01',      Label = 'Microwave',       Price = 200 },
        },
    },
    {
        Category = 'Decoration', Icon = 'seedling', Type = 'furniture',
        Items = {
            { Model = 'prop_plant_int_01a', Label = 'Plant (tall)',  Price = 120 },
            { Model = 'prop_plant_int_03a', Label = 'Plant (palm)',  Price = 150 },
            { Model = 'v_res_m_lampstand',  Label = 'Standing lamp', Price = 250 },
            { Model = 'v_res_d_lampa',      Label = 'Table lamp',    Price = 150 },
        },
    },
    {
        Category = 'Walls', Icon = 'border-all', Type = 'wall',
        Items = {
            { Model = 'prop_ld_fragwall_01a', Label = 'Plaster wall',      Price = 300 },
            { Model = 'prop_cons_ply01',      Label = 'Plywood panel',     Price = 150 },
            { Model = 'prop_cons_ply02',      Label = 'Plywood panel (2)', Price = 150 },
            { Model = 'prop_ld_balcfnc_01a',  Label = 'Low railing',       Price = 200 },
        },
    },
    {
        Category = 'Doors', Icon = 'door-open', Type = 'door',
        Items = {
            { Model = 'v_ilev_fh_frontdoor',      Label = 'Wooden door',     Price = 500 },
            { Model = 'v_ilev_trevtraildr',       Label = 'Trailer door',    Price = 250 },
            { Model = 'v_ilev_janitor_frontdoor', Label = 'Plain door',      Price = 350 },
            { Model = 'v_ilev_lester_doorfront',  Label = 'Old wooden door', Price = 300 },
            { Model = 'v_ilev_fa_frontdoor',      Label = 'Panel door',      Price = 450 },
            { Model = 'v_ilev_mm_doorm_l',        Label = 'Luxury door',     Price = 900 },
        },
    },
}

-- // Derived data (don't edit) \\ --

Config.DecorByModel = {}
for _, Category in ipairs(Config.DecorCatalog) do
    for _, Item in ipairs(Category.Items) do
        Item.Type = Category.Type
        Config.DecorByModel[Item.Model] = Item
    end
end

for Key, Mlo in pairs(Config.MLOHouses) do
    local X, Y = 0.0, 0.0
    for _, P in ipairs(Mlo.Zone.points) do X, Y = X + P.x, Y + P.y end
    local Count = #Mlo.Zone.points
    Mlo.Key = Key
    Mlo.Center = vector3(X / Count, Y / Count, Mlo.Zone.minZ or 0.0)
end

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

-- Every configured door of a house as { Key = 'Front'|'Back', Data = {...} }
function GetMloDoorList(Key)
    local Mlo, List = GetMloConfig(Key), {}
    if not Mlo then return List end
    if Mlo.FrontDoor then List[#List + 1] = { Key = 'Front', Data = Mlo.FrontDoor } end
    if Mlo.BackDoor then List[#List + 1] = { Key = 'Back', Data = Mlo.BackDoor } end
    return List
end
