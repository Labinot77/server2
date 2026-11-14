-- Pawn shop logistics (server/sv_pawn.lua, client/cl_pawn.lua, html/pawn.html).
-- Buy orders are checked against the Safe. Accepted orders are packed (one box per item line) into the
-- Drop-off storage, runners carry the boxes to a freight drop-off and the business cashes out the payout.

Config = Config or {}

Config.Pawn = {
    Business = 'The Brick House', -- phone_businesses name, also an entry in Config.Orders.Businesses (sh_orders.lua)

    Safe = { Coords = vector3(150.26, -1711.04, 29.31), Slots = 50, Weight = 5000.0 },    -- StashAccess
    DropOff = { Coords = vector3(150.26, -1711.04, 30.31), Slots = 50, Weight = 5000.0 }, -- every member

    -- Rough position of the prop_monitor_w_large in the map: the monitor within 3.5m of it is the shop computer.
    Monitor = { Coords = vector3(150.96, -1711.62, 29.36) },

    BoxItem = 'pawn-box', -- carried in hand (fw-assets Type 3): box carry animation, no running. Drop-off storage only takes these (fw-inventory Config.InventoryWhitelist)
    Blip = { Sprite = 478, Color = 46, Scale = 0.85 }, -- drop-offs on the map, for members and runners who carried a box
    DeliverTime = 4000,

    Offers = {
        Count = 12,             -- buy orders on the board
        Lifetime = { 240, 360 }, -- minutes
        Fee = 0.15,             -- accept fee (share of the payout), paid from the business account
    },

    Runner = { PerBox = 100 },   -- cash per delivered box, paid to the runner
    AlertChance = 0.25,          -- criminal shipments: police alert per delivered box

    -- Expires = minutes a shipment has to be delivered after it's packed / on the road.
    Routes = {
        Local = { Label = 'Local', Multiplier = 1.0, Packed = 1440, Transit = 60, Dropoffs = {
            { Label = 'Freight Dropoff 01', Coords = vector3(486.92, -1928.94, 24.72) },
            { Label = 'Freight Dropoff 02', Coords = vector3(-160.68, -2445.66, 6.0) },
        } },
        Interstate = { Label = 'Interstate', Multiplier = 1.15, Packed = 720, Transit = 120, Dropoffs = {
            { Label = 'Port of Los Santos', Coords = vector3(1196.84, -3253.55, 7.09) },
            { Label = 'Elysian Terminal', Coords = vector3(822.4, -2988.2, 6.02) },
        } },
        International = { Label = 'International', Multiplier = 1.3, Packed = 720, Transit = 120, Dropoffs = {
            { Label = 'LSIA Cargo', Coords = vector3(-1142.0, -2860.0, 13.95) },
            { Label = 'Port Container Yard', Coords = vector3(1015.4, -3110.6, 5.9) },
        } },
    },

    -- Item = fw-inventory item, Need / Price = random range, Illegal = the order is CRIMINAL.
    Categories = {
        General = { Label = 'General Order', Tag = 'Electronics', Lines = { 1, 4 }, Items = {
            { Item = 'stolen-tv', Label = 'Flat Panel TV', Need = { 1, 3 }, Price = { 220, 300 }, Illegal = true },
            { Item = 'stolen-pc', Label = 'Computer', Need = { 1, 3 }, Price = { 180, 260 }, Illegal = true },
            { Item = 'stolen-micro', Label = 'Microwave', Need = { 1, 4 }, Price = { 60, 90 }, Illegal = true },
            { Item = 'laptop', Label = 'Laptop', Need = { 1, 3 }, Price = { 250, 340 } },
            { Item = 'electronics', Label = 'Electronics', Need = { 5, 20 }, Price = { 40, 70 } },
            { Item = 'phone', Label = 'Phone', Need = { 1, 4 }, Price = { 80, 120 } },
        } },
        Jewelry = { Label = 'Jewelry Order', Tag = 'Valuables', Lines = { 1, 5 }, Items = {
            { Item = 'rolex', Label = 'Crowex Watch', Need = { 1, 3 }, Price = { 480, 560 } },
            { Item = 'goldchain', Label = 'Gold Chain', Need = { 1, 4 }, Price = { 320, 360 } },
            { Item = 'white-pearl', Label = 'Pearl Necklace', Need = { 1, 4 }, Price = { 260, 300 } },
            { Item = 'heirloom', Label = 'Silver Ring', Need = { 1, 4 }, Price = { 170, 210 } },
            { Item = 'diamond', Label = 'Diamond', Need = { 1, 3 }, Price = { 600, 750 }, Illegal = true },
            { Item = 'goldbar', Label = 'Gold Bar', Need = { 1, 2 }, Price = { 900, 1100 }, Illegal = true },
        } },
        Vehicle = { Label = 'Vehicle Parts Order', Tag = 'Parts', Lines = { 1, 3 }, Items = {
            { Item = 'stolen-vehicle-rim', Label = 'Vehicle Rim', Need = { 2, 4 }, Price = { 140, 200 }, Illegal = true },
            { Item = 'vehicle-engine', Label = 'Engine', Need = { 1, 2 }, Price = { 400, 550 } },
            { Item = 'vehicle-transmission', Label = 'Transmission', Need = { 1, 2 }, Price = { 300, 420 } },
            { Item = 'vehicle-brakes', Label = 'Brakes', Need = { 1, 3 }, Price = { 150, 220 } },
            { Item = 'generic-mechanic-part', Label = 'Mechanic Part', Need = { 2, 8 }, Price = { 50, 80 } },
        } },
        Hunting = { Label = 'Hunting Order', Tag = 'Pelts', Lines = { 1, 3 }, Items = {
            { Item = 'hunting-carcass-one', Label = 'Poor Pelt', Need = { 1, 3 }, Price = { 100, 140 } },
            { Item = 'hunting-carcass-two', Label = 'Good Pelt', Need = { 1, 3 }, Price = { 200, 260 } },
            { Item = 'hunting-carcass-three', Label = 'Perfect Pelt', Need = { 1, 2 }, Price = { 350, 420 } },
        } },
        Art = { Label = 'Art & Collectibles Order', Tag = 'Valuables', Lines = { 1, 3 }, Items = {
            { Item = 'diamond-skull', Label = 'Diamond Skull', Need = { 1, 1 }, Price = { 1500, 2000 }, Illegal = true },
            { Item = 'diamond-chessboard', Label = 'Chessboard', Need = { 1, 1 }, Price = { 900, 1200 }, Illegal = true },
            { Item = 'gold-record', Label = 'Gold Record', Need = { 1, 2 }, Price = { 400, 550 } },
            { Item = 'platinum-record', Label = 'Platinum Record', Need = { 1, 2 }, Price = { 550, 700 } },
            { Item = 'diamond-record', Label = 'Diamond Record', Need = { 1, 2 }, Price = { 700, 900 } },
        } },
    },
}

-- The monitor is the business' computer (cl_laptop.lua / sv_orders.lua).
Config.Orders.Businesses[Config.Pawn.Business].Computers = { Config.Pawn.Monitor.Coords }
