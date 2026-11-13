Config = {}

--[[
    The custom map is drawn from html/tiles/: GTA's own pause-map textures
    (assets-replace/stream/[Minimap]/minimap_*.ytd) decoded and split into 512px tiles at 4 zoom levels.
    Only the tiles on screen are drawn, which keeps it smooth. If you change the streamed minimap textures,
    rebuild the tiles with tools/build_tiles.py.

    Ways to open it:
      * np-quickmenu: the MAP button opens it; ESC goes back to the quick menu
      * the default GTA pause menu: clicking INTO the map on the MAP tab (or ENTER) opens it instead of
        GTA's map; ESC goes back to the pause menu (only used when nothing replaces ESC)
      * exports['fw-mainmenu']:OpenMap()
]]

Config.Debug = false                 -- or toggle in game with /mapmenudebug (prints to F8)
Config.HideHud = true                -- hide fw-hud (health / armor / voice) while the map is open
Config.ReturnToPauseMenu = true      -- ESC in the custom map (opened from the pause menu): true = back to the pause menu, false = back to the game

-- Waypoint + route colour (custom map, and GTA's own waypoint / GPS line). false = keep GTA's purple in game.
Config.WaypointColor = { 62, 142, 247 }

-- GPS route on the custom map
Config.ShowRoute = true
Config.RouteUpdateInterval = 1000    -- how often the route is re-read while the map is open (ms)
Config.RouteStep = 20                -- metres between sampled route points
Config.RouteMaxPoints = 600          -- max points sampled along the route (600 x 20 m = 12 km)

-- Pause menu layout (fractions of the screen, measured on a 16:9 screen).
Config.Layout = {
    TabBarTop = 0.165, TabBarBottom = 0.222,      -- the MAP / GAME / INFO ... tab row
    MapTabLeft = 0.150, MapTabRight = 0.272,      -- the MAP tab button
    ContentLeft = 0.150, ContentRight = 0.845,    -- the small map preview under the tabs
    ContentTop = 0.225, ContentBottom = 0.835,
}
Config.PauseTabCount = 6             -- MAP, GAME, INFO, STATS, SETTINGS, GALLERY (used when cycling tabs with Q/E)

-- Optional: exact pause-menu screen id of the expanded map (shown by /mapmenudebug as "current=").
Config.MapScreenIds = {}

-- How often the custom map refreshes while open (ms)
Config.PlayerUpdateInterval = 100
Config.BlipUpdateInterval = 2000

-- Blips with these sprites are never drawn (radius/area blips, player, north)
Config.IgnoredSprites = { [5] = true, [6] = true, [9] = true, [10] = true, [11] = true, [161] = true }

--[[
    Legend layout. Sections are drawn top-to-bottom in this order.
    Every entry matches blips by Sprite (and optionally Color, the GTA blip colour index).
    Entries without any matching blip are hidden from the list automatically.

    Icon  = Font Awesome 5 class used in the list
    Tint  = optional hex colour for the icon; if omitted the blip's own colour is used
]]
Config.Sections = {
    {
        Id = 'services', Label = 'Services',
        Entries = {
            { Id = 'mechanic',  Label = 'Autocare Mechanic', Icon = 'fas fa-tools',            Tint = '#e8e8e8', Sprites = { 225, 478 }, Colors = { 12, 47 } },
            { Id = 'bank',      Label = 'Bank',              Icon = 'fas fa-dollar-sign',      Tint = '#5fb85a', Sprites = { 108, 276 } },
            { Id = 'carwash',   Label = 'Car Wash',          Icon = 'fas fa-car-wash',         Tint = '#e8e8e8', Sprites = { 100 } },
            { Id = 'city',      Label = 'City Services',     Icon = 'fas fa-shield-alt',       Tint = '#e8e8e8', Sprites = { 590, 419 } },
            { Id = 'crafting',  Label = 'Crafting Bench',    Icon = 'fas fa-hammer',           Tint = '#d18b47', Sprites = { 402 } },
            { Id = 'fuel',      Label = 'Fuel Station',      Icon = 'fas fa-gas-pump',         Tint = '#d93a3a', Sprites = { 361 } },
            { Id = 'hospital',  Label = 'Hospital',          Icon = 'fas fa-plus',             Tint = '#3fae49', Sprites = { 61 } },
            { Id = 'police',    Label = 'Police',            Icon = 'fas fa-star',             Tint = '#4a90e2', Sprites = { 60, 43, 427 } },
            { Id = 'prison',    Label = 'Prison',            Icon = 'fas fa-dungeon',          Tint = '#5b8fd6', Sprites = { 188 } },
        },
    },
    {
        Id = 'shops', Label = 'Shops',
        Entries = {
            { Id = 'store',     Label = 'Convenience Store', Icon = 'fas fa-shopping-basket',  Tint = '#5fb85a', Sprites = { 52 } },
            { Id = 'hardware',  Label = 'Hardware Store',    Icon = 'fas fa-toolbox',          Tint = '#e8e8e8', Sprites = { 566 } },
            { Id = 'ammu',      Label = 'Ammunation',        Icon = 'fas fa-crosshairs',       Tint = '#e8e8e8', Sprites = { 110 } },
            { Id = 'clothing',  Label = 'Clothing Store',    Icon = 'fas fa-tshirt',           Sprites = { 366 } },
            { Id = 'barber',    Label = 'Barber',            Icon = 'fas fa-cut',              Sprites = { 71 } },
            { Id = 'tattoo',    Label = 'Tattoo Shop',       Icon = 'fas fa-pen-nib',          Sprites = { 75 } },
            { Id = 'vehshop',   Label = 'Vehicle Dealer',    Icon = 'fas fa-car',              Sprites = { 225, 226 }, Colors = { 3, 7 } },
            { Id = 'rental',    Label = 'Vehicle Rental',    Icon = 'fas fa-key',              Sprites = { 225 }, Colors = { 11 } },
        },
    },
    {
        Id = 'housing', Label = 'Housing',
        Entries = {
            { Id = 'apartments', Label = 'Apartments',       Icon = 'fas fa-home',             Tint = '#3fae49', Sprites = { 475, 40 } },
        },
    },
    {
        Id = 'garages', Label = 'Garages',
        Entries = {
            { Id = 'airdepot',  Label = 'Air Depot',         Icon = 'fas fa-plane',            Tint = '#4a90e2', Sprites = { 307 } },
            { Id = 'boathouse', Label = 'Boathouse',         Icon = 'fas fa-ship',             Tint = '#4a90e2', Sprites = { 356, 410 } },
            { Id = 'hangar',    Label = 'Hangar',            Icon = 'fas fa-warehouse',        Tint = '#4a90e2', Sprites = { 359, 569 } },
            { Id = 'impound',   Label = 'Impound Lot',       Icon = 'fas fa-truck-pickup',     Tint = '#4a90e2', Sprites = { 317, 68 } },
            { Id = 'parking',   Label = 'Public Parking',    Icon = 'fas fa-parking',          Tint = '#4a90e2', Sprites = { 357, 50 } },
        },
    },
    {
        Id = 'businesses', Label = 'Businesses',
        Entries = {
            { Id = 'food',      Label = 'Food & Drinks',     Icon = 'fas fa-hamburger',        Sprites = { 106, 439, 489, 674, 93 } },
            { Id = 'media',     Label = 'Media',             Icon = 'fas fa-broadcast-tower',  Sprites = { 135 } },
            { Id = 'electro',   Label = 'Electronics',       Icon = 'fas fa-laptop',           Sprites = { 619 } },
            { Id = 'mc',        Label = 'Motorcycle Clubs',  Icon = 'fas fa-motorcycle',       Sprites = { 348 } },
            { Id = 'dispensary',Label = 'Dispensary',        Icon = 'fas fa-cannabis',         Sprites = { 140 } },
            { Id = 'jewelry',   Label = 'Jewelry',           Icon = 'fas fa-gem',              Sprites = { 617 } },
            { Id = 'pawn',      Label = 'Pawn Shop',         Icon = 'fas fa-coins',            Sprites = { 587 } },
            { Id = 'arcade',    Label = 'Arcade',            Icon = 'fas fa-gamepad',          Sprites = { 740 } },
            { Id = 'other_biz', Label = 'Other Businesses',  Icon = 'fas fa-briefcase',        Sprites = { 124, 557, 365, 183, 186, 59, 72, 780 } },
        },
    },
}
