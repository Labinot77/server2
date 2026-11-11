Config = Config or {}
Shared = Shared or {}

Config.Drops = {}

Config.MaxPlayerWeight = 250.0 -- Base carry weight (pockets + body + accessories).
Config.MaxPlayerSlots = 46

-- // Player inventory layout \\ --
-- Every section lives inside the same 'ply-<citizenid>' inventory, so all existing
-- exports (HasEnoughOfItem, GetItemByName, RemoveItem, ...) keep working untouched.
Config.SlotLayout = {
    Pockets     = { 1, 15 },  -- Always available.
    Backpack    = { 16, 35 }, -- Only usable while a backpack is equipped in the backpack body slot.
    Body        = { 36, 41 }, -- ID card, phone, keys, wallet, backpack, radio.
    Accessories = { 42, 46 }, -- Clothing props, applied on the ped when equipped.
}

-- Rules per equipment slot.
--  Items     : item names allowed in this slot.
--  Clothing  : fw-clothes ComponentId that gets applied when equipped (accessories only).
--  AutoPlace : when an item is given (AddItem without slot) it goes here first if empty.
--  Icon      : Material Symbols icon shown on the empty slot.
Config.EquipSlots = {
    [36] = { Section = 'Body', Label = 'ID Card',  Icon = 'badge',                 Items = { 'id_card' },                AutoPlace = true },
    [37] = { Section = 'Body', Label = 'Phone',    Icon = 'smartphone',            Items = { 'phone', 'burnerphone' },   AutoPlace = true },
    [38] = { Section = 'Body', Label = 'Keys',     Icon = 'key',                   Items = { 'keyring' },                AutoPlace = true },
    [39] = { Section = 'Body', Label = 'Wallet',   Icon = 'account_balance_wallet', Items = { 'wallet' },                AutoPlace = true },
    [40] = { Section = 'Body', Label = 'Backpack', Icon = 'backpack',              Items = { 'backpack' },               AutoPlace = false, IsBackpack = true },
    [41] = { Section = 'Body', Label = 'Radio',    Icon = 'radio',                 Items = { 'radio' },                  AutoPlace = true },

    [42] = { Section = 'Accessories', Label = 'Hat',      Icon = 'styler',     Items = { 'hat' },      Clothing = 'Hat' },
    [43] = { Section = 'Accessories', Label = 'Mask',     Icon = 'masks',      Items = { 'mask' },     Clothing = 'Masks' },
    [44] = { Section = 'Accessories', Label = 'Glasses',  Icon = 'eyeglasses', Items = { 'glasses' },  Clothing = 'Glasses' },
    [45] = { Section = 'Accessories', Label = 'Earrings', Icon = 'diamond',    Items = { 'earrings' }, Clothing = 'Earrings' },
    [46] = { Section = 'Accessories', Label = 'Watch',    Icon = 'watch',      Items = { 'watch' },    Clothing = 'Watches' },
}

-- Items that can be equipped in the backpack slot.
--  Weight : extra carry weight while equipped.
--  Slots  : how many of the backpack slots (16-35) unlock. Max = size of Config.SlotLayout.Backpack.
Config.Backpacks = {
    ['backpack'] = { Weight = 100.0, Slots = 20 },
}

Config.BackpackSlot = 40

-- // Layout helpers (shared client/server) \\ --
function GetSlotSection(Slot)
    Slot = tonumber(Slot)
    if not Slot then return false end
    for Section, Range in pairs(Config.SlotLayout) do
        if Slot >= Range[1] and Slot <= Range[2] then
            return Section
        end
    end
    return false
end

function IsEquipSlot(Slot)
    return Config.EquipSlots[tonumber(Slot)] ~= nil
end

function CanItemGoInSlot(ItemName, Slot)
    local SlotData = Config.EquipSlots[tonumber(Slot)]
    if not SlotData then return true end

    for _, Allowed in pairs(SlotData.Items) do
        if Allowed == ItemName then return true end
    end
    return false
end

-- Returns the equip slot an item belongs to, or false.
function GetEquipSlotForItem(ItemName)
    for Slot, SlotData in pairs(Config.EquipSlots) do
        for _, Allowed in pairs(SlotData.Items) do
            if Allowed == ItemName then return Slot end
        end
    end
    return false
end

-- Inventory = PlayerData.inventory table (slot -> item).
function GetEquippedBackpack(Inventory)
    local Item = Inventory and Inventory[Config.BackpackSlot]
    if Item and Config.Backpacks[Item.Item] then
        return Item, Config.Backpacks[Item.Item]
    end
    return false, false
end

-- Number of usable backpack slots right now.
function GetUnlockedBackpackSlots(Inventory)
    local _, BagData = GetEquippedBackpack(Inventory)
    if not BagData then return 0 end

    local MaxBagSlots = Config.SlotLayout.Backpack[2] - Config.SlotLayout.Backpack[1] + 1
    return math.min(BagData.Slots or MaxBagSlots, MaxBagSlots)
end

function IsBackpackSlotUnlocked(Inventory, Slot)
    Slot = tonumber(Slot)
    if GetSlotSection(Slot) ~= 'Backpack' then return true end
    return Slot < Config.SlotLayout.Backpack[1] + GetUnlockedBackpackSlots(Inventory)
end

function IsBackpackEmpty(Inventory)
    for i = Config.SlotLayout.Backpack[1], Config.SlotLayout.Backpack[2] do
        if Inventory[i] then return false end
    end
    return true
end

function GetMaxPlayerWeight(Inventory)
    local _, BagData = GetEquippedBackpack(Inventory)
    return Config.MaxPlayerWeight + (BagData and BagData.Weight or 0.0)
end

-- Checks a single item landing in a player-inventory slot.
-- Returns true or false + reason.
function ValidatePlayerSlot(Inventory, Slot, ItemName, Amount)
    Slot = tonumber(Slot)
    if not Slot or Slot < 1 or Slot > Config.MaxPlayerSlots then
        return false, "Ongeldige slot."
    end

    if not CanItemGoInSlot(ItemName, Slot) then
        return false, ("Dit kan niet in het %s vak."):format(Config.EquipSlots[Slot].Label)
    end

    if IsEquipSlot(Slot) and Amount and Amount > 1 then
        return false, "Je kan maar 1 item uitrusten."
    end

    if not IsBackpackSlotUnlocked(Inventory, Slot) then
        return false, "Je hebt geen (grotere) rugzak om."
    end

    if GetSlotSection(Slot) == 'Backpack' and Config.Backpacks[ItemName] then
        return false, "Je kan geen rugzak in een rugzak stoppen."
    end

    return true
end

Config.TrunkSpaces = {
    [0]  = { 1.0, 50, 150 }, -- Compacts
    [1]  = { 2.0, 150, 300 }, -- Sedans
    [2]  = { 5.0, 200, 500 }, -- SUVs
    [3]  = { 3.0, 100, 250 }, -- Coupes
    [4]  = { 3.0, 100, 250 }, -- Muscle
    [5]  = { 1.0, 150, 200 }, -- Sports Classics
    [6]  = { 1.0, 150, 200 }, -- Sports
    [7]  = { 1.0, 75, 200 }, -- Super
    [8]  = { 0.0, 0, 0 }, -- Motorcycles
    [9]  = { 1.0, 100, 300 }, -- Off-road
    [10] = { 4.0, 300, 500 }, -- Industrial
    [11] = { 5.0, 250, 500 }, -- Utility
    [12] = { 5.0, 250, 500 }, -- Vans
    [13] = { 0.0, 0, 0 }, -- Cycles
    [14] = { 2.0, 100, 300 }, -- Boats
    [15] = { 1.0, 100, 400 }, -- Helicopters
    [16] = { 5.0, 100, 4000 }, -- Planes
    [17] = { 10.0, 100, 600 }, -- Service
    [18] = { 2.0, 200, 500 }, -- Emergency
    [19] = { 5.0, 200, 500 }, -- Military
    [20] = { 20.0, 250, 2000 }, -- Commerical
    [21] = { 10.0, 200, 500 }, -- Trains
}

Config.Dumpsters = {
    [GetHashKey("prop_cs_dumpster_01a")] = true,
    [GetHashKey("p_dumpster_t")] = true,
    [GetHashKey("prop_dumpster_01a")] = true,
    [GetHashKey("prop_dumpster_02a")] = true,
    [GetHashKey("prop_dumpster_02b")] = true,
    [GetHashKey("prop_dumpster_3a")] = true,
    [GetHashKey("prop_dumpster_4a")] = true,
    [GetHashKey("prop_dumpster_4b")] = true,
}

Config.BackEngine = {
    [GetHashKey("ninef")] = true,
    [GetHashKey("adder")] = true,
    [GetHashKey("vagner")] = true,
    [GetHashKey("t20")] = true,
    [GetHashKey("infernus")] = true,
    [GetHashKey("zentorno")] = true,
    [GetHashKey("reaper")] = true,
    [GetHashKey("comet2")] = true,
    [GetHashKey("comet3")] = true,
    [GetHashKey("jester")] = true,
    [GetHashKey("jester2")] = true,
    [GetHashKey("cheetah")] = true,
    [GetHashKey("cheetah2")] = true,
    [GetHashKey("prototipo")] = true,
    [GetHashKey("turismor")] = true,
    [GetHashKey("pfister811")] = true,
    [GetHashKey("ardent")] = true,
    [GetHashKey("nero")] = true,
    [GetHashKey("nero2")] = true,
    [GetHashKey("tempesta")] = true,
    [GetHashKey("vacca")] = true,
    [GetHashKey("bullet")] = true,
    [GetHashKey("osiris")] = true,
    [GetHashKey("entityxf")] = true,
    [GetHashKey("turismo2")] = true,
    [GetHashKey("fmj")] = true,
    [GetHashKey("re7b")] = true,
    [GetHashKey("tyrus")] = true,
    [GetHashKey("italigtb")] = true,
    [GetHashKey("penetrator")] = true,
    [GetHashKey("monroe")] = true,
    [GetHashKey("ninef2")] = true,
    [GetHashKey("stingergt")] = true,
    [GetHashKey("surfer")] = true,
    [GetHashKey("surfer2")] = true,
    [GetHashKey("gp1")] = true,
    [GetHashKey("autarch")] = true,
    [GetHashKey("tyrant")] = true
}

Config.Throwables = {
    [GetHashKey("weapon_grenade")] = true,
    [GetHashKey("weapon_stickybomb")] = true,
    [GetHashKey("weapon_molotov")] = true,
    [GetHashKey("weapon_brick")] = true,
    [GetHashKey("weapon_flare")] = true,
    [GetHashKey("weapon_smokegrenade")] = true,
    [GetHashKey("weapon_shoe")] = true,
    [GetHashKey("weapon_brick")] = true,
    [GetHashKey("weapon_banana")] = true,
}

Config.Attachments = {
    ['silencer_oilcan'] = {
        -- ['weapon_m70'] = 'COMPONENT_OIL_SUPP',
        -- ['weapon_colt'] = 'COMPONENT_OIL_SUPP',
        -- ['weapon_beretta'] = 'COMPONENT_OIL_SUPP',
        -- ['weapon_glock18c'] = 'COMPONENT_OIL_SUPP',
        -- ['weapon_heavypistol'] = 'COMPONENT_OIL_SUPP',
    },
    ['silencer'] = {
        ['weapon_m70'] = 'COMPONENT_AT_AR_SUPP_02',
        ['weapon_colt'] = 'COMPONENT_AT_PI_SUPP',
        ['weapon_beretta'] = 'COMPONENT_AT_PI_SUPP',
        ['weapon_glock18c'] = 'COMPONENT_AT_PI_SUPP',
        ['weapon_heavypistol'] = 'COMPONENT_AT_PI_SUPP',
    },
}

exports("GetConfig", function()
    return Config
end)

exports("GetShared", function()
    return Shared
end)

function DeepCopyTable(Obj)
    if type(Obj) ~= 'table' then return Obj end
    local res = {}
    
    for k, v in pairs(Obj) do
        res[DeepCopyTable(k)] = DeepCopyTable(v)
    end

    return res
end
-- // Phone \\ --
-- The phone only works while it's equipped in the BODY phone slot (see fw-phone).
Config.PhoneItem = 'phone'

function GetPhoneSlot()
    for Slot, SlotData in pairs(Config.EquipSlots) do
        if SlotData.Label == 'Phone' then return Slot end
    end
    return false
end

function IsPhoneEquipped(Inventory, ItemName)
    local Slot = GetPhoneSlot()
    local Item = Slot and Inventory and Inventory[Slot]
    return Item ~= nil and Item ~= false and Item.Item == (ItemName or Config.PhoneItem), Item
end

-- // Ground items \\ --
-- true  = every item on the ground (and its exact placed spot) is saved in the DB
--         (table `inventory_drops`, created automatically) and comes back after a restart.
-- false = normal drops: kept in memory only and wiped on every server restart.
Config.PersistentDrops = true

-- Saved drops that haven't been touched for this many hours are deleted on start (0 = keep forever).
Config.DropLifetimeHours = 72

-- Players can only pick up / open ground items they can actually see (raycast from their head),
-- so nothing can be grabbed through walls, floors or doors.
Config.DropRequireLineOfSight = true

-- // Magazines & bullets \\ --
-- Guns of these ammo types no longer take ammo boxes:
--   buy `bullets` -> use a `magazine` (opens the loader under GROUND) -> drag bullets in -> [R] reloads.
-- The magazine's CustomType (= key below) must match the gun's ammo type.
-- Capacity = max bullets in one magazine of that type.
-- BoxBullets = how many loose bullets an old ammo box of that type turns into when used.
Config.Magazines = {
    Pistol   = { Label = 'Pistol',   Capacity = 12, AmmoType = 'AMMO_PISTOL',   BoxBullets = 50 },
    Smg      = { Label = 'SMG',      Capacity = 30, AmmoType = 'AMMO_SMG',      BoxBullets = 50 },
    Rifle    = { Label = 'AR',       Capacity = 30, AmmoType = 'AMMO_RIFLE',    BoxBullets = 50 },
    Shotgun  = { Label = 'Shotgun',  Capacity = 8,  AmmoType = 'AMMO_SHOTGUN',  BoxBullets = 12 },
    Sniper   = { Label = 'Sniper',   Capacity = 5,  AmmoType = 'AMMO_SNIPER',   BoxBullets = 12 },
    Revolver = { Label = 'Revolver', Capacity = 6,  AmmoType = 'AMMO_REVOLVER', BoxBullets = 12 },
}

Config.ReloadTime = 1800 -- ms the reload takes / blocks a new reload.

function GetMagazineTypeForAmmo(AmmoType)
    for Type, Data in pairs(Config.Magazines) do
        if Data.AmmoType == AmmoType then return Type end
    end
    return false
end

function GetMagazineCapacity(Type)
    return Config.Magazines[Type] and Config.Magazines[Type].Capacity or 0
end

-- Loading bullets into a magazine: Base + PerBullet ms (12 pistol rounds = 0.5s + 12 x 0.3s = 4.1s).
Config.MagazineLoadTime = { Base = 500, PerBullet = 300 }
Config.MagazineLoadAnim = { Dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", Anim = "machinic_loop_mechandplayer", Flag = 49 }

function GetMagazineLoadTime(Bullets)
    return math.floor(Config.MagazineLoadTime.Base + Config.MagazineLoadTime.PerBullet * Bullets)
end


-- // Weapon attachments (right-click a weapon -> Attachments) \\ --
-- Attachments are stored ON the weapon (Info.Attachments) and travel with it, like the magazine
-- (Info.Mag + Info.Ammo). The panel always shows Magazine (magazine guns) + every slot below;
-- slots the weapon can't take are shown locked.
Config.AttachmentSlots = {
    { Kind = 'Muzzle', Label = 'Muzzle', Icon = 'blur_on' },
    { Kind = 'Grip',   Label = 'Grip',   Icon = 'pan_tool' },
    { Kind = 'Sight',  Label = 'Sight',  Icon = 'center_focus_strong' },
}

-- Item -> slot + which weapon component it becomes.
--  Candidates : GTA components of this kind; the first one the weapon accepts
--               (DoesWeaponTakeWeaponComponent) is used. Works for add-on weapons that use base components.
--  Components : optional fixed component per weapon, checked first (e.g. for add-on components).
local Suppressors = {
    'COMPONENT_AT_PI_SUPP', 'COMPONENT_AT_PI_SUPP_02', 'COMPONENT_CERAMICPISTOL_SUPP',
    'COMPONENT_AT_AR_SUPP', 'COMPONENT_AT_AR_SUPP_02', 'COMPONENT_AT_SR_SUPP', 'COMPONENT_AT_SR_SUPP_03',
}
local MuzzleBrakes = {
    'COMPONENT_AT_PI_COMP', 'COMPONENT_AT_PI_COMP_02', 'COMPONENT_AT_PI_COMP_03',
    'COMPONENT_AT_MUZZLE_01', 'COMPONENT_AT_MUZZLE_02', 'COMPONENT_AT_MUZZLE_03', 'COMPONENT_AT_MUZZLE_04',
    'COMPONENT_AT_MUZZLE_05', 'COMPONENT_AT_MUZZLE_06', 'COMPONENT_AT_MUZZLE_07', 'COMPONENT_AT_MUZZLE_08', 'COMPONENT_AT_MUZZLE_09',
}
local Grips = { 'COMPONENT_AT_AR_AFGRIP', 'COMPONENT_AT_AR_AFGRIP_02' }
local Sights = {
    'COMPONENT_AT_SIGHTS', 'COMPONENT_AT_SIGHTS_SMG', 'COMPONENT_AT_PI_RAIL', 'COMPONENT_AT_PI_RAIL_02',
    'COMPONENT_AT_SCOPE_MACRO', 'COMPONENT_AT_SCOPE_MACRO_02', 'COMPONENT_AT_SCOPE_MACRO_MK2', 'COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2',
    'COMPONENT_AT_SCOPE_SMALL', 'COMPONENT_AT_SCOPE_SMALL_02', 'COMPONENT_AT_SCOPE_SMALL_MK2', 'COMPONENT_AT_SCOPE_SMALL_SMG_MK2',
    'COMPONENT_AT_SCOPE_MEDIUM', 'COMPONENT_AT_SCOPE_MEDIUM_MK2',
}

Config.WeaponAttachments = {
    ['silencer']        = { Kind = 'Muzzle', Candidates = Suppressors,  Components = Config.Attachments['silencer'] },
    ['silencer_oilcan'] = { Kind = 'Muzzle', Candidates = Suppressors,  Components = Config.Attachments['silencer_oilcan'] },
    ['att_muzzlebrake'] = { Kind = 'Muzzle', Candidates = MuzzleBrakes },
    ['att_grip']        = { Kind = 'Grip',   Candidates = Grips },
    ['att_sight']       = { Kind = 'Sight',  Candidates = Sights },
}

-- Server/shared check: is this item an attachment for that slot? (Whether the weapon physically
-- takes it is checked client-side with DoesWeaponTakeWeaponComponent, the server has no natives.)
function GetWeaponAttachment(ItemName, WeaponName)
    local Data = Config.WeaponAttachments[ItemName]
    if not Data then return false end
    local Fixed = Data.Components and Data.Components[WeaponName]
    return Data, Fixed
end

-- // Open sounds \\ --
-- fw-inventory plays these itself when that inventory type actually opens (fw-misc sound ids).
-- If the script that opened it already played the same sound just before, it isn't played twice.
Config.OpenSounds = {
    ['Stash'] = 'general.stashOpen',
    ['Apartment Stash'] = 'general.stashOpen',
    ['Traphouse Opslag'] = 'general.stashOpen',
}

-- Crafting UI: also list recipes the player has not unlocked yet (greyed out with the rep they need).
Config.ShowLockedRecipes = true

-- Inventory closes when you're moved this far (m) from where you opened it (pushed, dragged, car moved).
Config.InventoryMoveDistance = 2.5
