-- // Magazines & bullets \\ --
-- magazine (CustomType = Pistol/Smg/Rifle/...) : Info.Bullets = rounds inside, max Config.Magazines[Type].Capacity
-- bullets  (same CustomTypes)                  : loose rounds, stackable
-- weapon                                        : Info.Ammo = rounds in the gun, Info.Mag = type of the inserted magazine
--
-- Reload ([R], fw-weapons): the fullest matching magazine goes in, the magazine that was in the
-- gun comes back out with whatever was left in it (so empty magazines are reused). Guns that
-- still have loose ammo from the old ammo-box system get those rounds back as loose bullets.

local function Notify(Player, Text, Type)
    Player.Functions.Notify(Text, Type or "error")
end

local function RefreshSlots(Player, Slots)
    for _, Slot in pairs(Slots) do
        if Slot then
            Player.Functions.RefreshInvSlot(Slot)
            TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Slot)
        end
    end
end

local function GetMagazine(Player, Slot)
    local Item = Player.PlayerData.inventory[tonumber(Slot)]
    if not Item or Item.Item ~= 'magazine' or not Config.Magazines[Item.CustomType] then return false end
    return Item
end

local function GetBullets(Item)
    return math.max(0, math.floor(tonumber(Item.Info and Item.Info.Bullets) or 0))
end

-- // Use magazine -> open the inventory with the loader under GROUND \\ --
FW.Functions.CreateUsableItem("magazine", function(Source, Item)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player or not GetMagazine(Player, Item.Slot) then return end
    TriggerClientEvent("fw-inventory:Client:OpenMagazineLoader", Source, Item.Slot)
end)

FW.Functions.CreateUsableItem("bullets", function(Source, Item)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end
    Notify(Player, "Gebruik een magazijn om deze kogels te laden.", "primary")
end)

-- // Load bullets into a magazine (timed) \\ --
-- Begin: validates + reserves how many go in and how long it takes.
-- Finish: only accepted once that time has passed, then the bullets move.
local PendingLoads = {} -- [Source] = { MagSlot, BulletSlot, Amount, Type, Ends }

local function CheckLoad(Player, MagSlot, BulletSlot, Amount)
    local Magazine = GetMagazine(Player, MagSlot)
    if not Magazine then return false, "Magazijn niet gevonden." end

    local Bullets = Player.PlayerData.inventory[tonumber(BulletSlot)]
    if not Bullets or Bullets.Item ~= 'bullets' then return false end
    if Bullets.CustomType ~= Magazine.CustomType then
        return false, ("Dit zijn geen %s kogels."):format(Config.Magazines[Magazine.CustomType].Label)
    end

    local Current, Capacity = GetBullets(Magazine), GetMagazineCapacity(Magazine.CustomType)
    local ToLoad = math.min(math.floor(tonumber(Amount) or Bullets.Amount), Bullets.Amount, Capacity - Current)
    if ToLoad <= 0 then
        return false, Current >= Capacity and "Dit magazijn is al vol." or "Geen kogels om te laden."
    end

    return true, ToLoad, Magazine, Bullets
end

FW.Functions.CreateCallback("fw-inventory:Server:BeginLoadMagazine", function(Source, Cb, MagSlot, BulletSlot, Amount)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return Cb({ Success = false }) end

    local Ok, ToLoad, Magazine = CheckLoad(Player, MagSlot, BulletSlot, Amount)
    if not Ok then return Cb({ Success = false, Message = ToLoad }) end

    local Duration = GetMagazineLoadTime(ToLoad)
    PendingLoads[Source] = {
        MagSlot = tonumber(MagSlot), BulletSlot = tonumber(BulletSlot), Amount = ToLoad,
        Type = Magazine.CustomType, Ends = GetGameTimer() + Duration - 250, -- small allowance for latency
    }

    Cb({ Success = true, Amount = ToLoad, Duration = Duration, Current = GetBullets(Magazine), Capacity = GetMagazineCapacity(Magazine.CustomType) })
end)

FW.RegisterServer("fw-inventory:Server:FinishLoadMagazine", function(Source)
    local Player = FW.Functions.GetPlayer(Source)
    local Pending = PendingLoads[Source]
    PendingLoads[Source] = nil
    if not Player or not Pending then return end

    if GetGameTimer() < Pending.Ends then return end -- finished too early: ignore

    -- Re-check: things may have moved during the progress bar.
    local Ok, ToLoad, Magazine, Bullets = CheckLoad(Player, Pending.MagSlot, Pending.BulletSlot, Pending.Amount)
    if not Ok then
        if ToLoad then Notify(Player, ToLoad) end
        return
    end
    if Magazine.CustomType ~= Pending.Type then return end

    local Current = GetBullets(Magazine)
    if not Player.Functions.RemoveItem('bullets', ToLoad, Bullets.Slot, false, Bullets.CustomType) then return end
    Player.Functions.SetItemKV('magazine', Magazine.Slot, 'Bullets', Current + ToLoad, Magazine.CustomType)

    RefreshSlots(Player, { Bullets.Slot, Magazine.Slot })
end)

FW.RegisterServer("fw-inventory:Server:CancelLoadMagazine", function(Source)
    PendingLoads[Source] = nil
end)

AddEventHandler("playerDropped", function()
    PendingLoads[source] = nil
end)

-- // Take bullets out of a magazine \\ --
FW.RegisterServer("fw-inventory:Server:UnloadMagazine", function(Source, MagSlot, Amount, ToSlot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    local Magazine = GetMagazine(Player, MagSlot)
    if not Magazine then return end

    local Current = GetBullets(Magazine)
    local ToUnload = math.min(math.floor(tonumber(Amount) or Current), Current)
    if ToUnload <= 0 then return end

    -- Use the slot it was dropped on if that's free or the same bullets, otherwise find one.
    local Inventory = Player.PlayerData.inventory
    ToSlot = tonumber(ToSlot)
    local Target = ToSlot and Inventory[ToSlot]
    local ValidTarget = ToSlot and ToSlot ~= Magazine.Slot
        and (Target == nil or (Target.Item == 'bullets' and Target.CustomType == Magazine.CustomType))
        and ValidatePlayerSlot(Inventory, ToSlot, 'bullets', ToUnload)
    if not ValidTarget then
        ToSlot = FindPlayerSlot(Inventory, 'bullets', Magazine.CustomType)
    end
    if not ToSlot then return Notify(Player, "Je hebt geen ruimte.") end

    Player.Functions.SetItemKV('magazine', Magazine.Slot, 'Bullets', Current - ToUnload, Magazine.CustomType)
    if not Player.Functions.AddItem('bullets', ToUnload, ToSlot, {}, false, Magazine.CustomType) then
        -- Couldn't add (overweight etc.), put them back.
        Player.Functions.SetItemKV('magazine', Magazine.Slot, 'Bullets', Current, Magazine.CustomType)
        return Notify(Player, "Je kan dit niet dragen.")
    end

    RefreshSlots(Player, { Magazine.Slot, ToSlot })
end)

-- // Reload \\ --
-- Returns { Success, Ammo, Message }
FW.Functions.CreateCallback("fw-inventory:Server:ReloadWeapon", function(Source, Cb, WeaponSlot, CurrentAmmo)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return Cb({ Success = false }) end

    local Weapon = Player.PlayerData.inventory[tonumber(WeaponSlot)]
    if not Weapon or not Shared.Items[Weapon.Item] or not Shared.Items[Weapon.Item].Weapon then
        return Cb({ Success = false })
    end

    local WeaponData = exports['fw-weapons']:GetWeaponList(GetHashKey(Weapon.Item))
    local MagType = WeaponData and GetMagazineTypeForAmmo(WeaponData.AmmoType)
    if not MagType then
        return Cb({ Success = false, Message = "Dit wapen gebruikt geen magazijnen." })
    end

    -- Fullest loaded magazine of this type.
    local Best = false
    for Slot, Item in pairs(Player.PlayerData.inventory) do
        if Item and Item.Item == 'magazine' and Item.CustomType == MagType and GetBullets(Item) > 0 then
            if not Best or GetBullets(Item) > GetBullets(Best) then Best = Item end
        end
    end

    if not Best then
        return Cb({ Success = false, Message = ("Je hebt geen geladen %s magazijn."):format(Config.Magazines[MagType].Label) })
    end

    -- Rounds still in the gun: never more than the server knows about.
    local InGun = math.max(0, math.min(math.floor(tonumber(CurrentAmmo) or 0), tonumber(Weapon.Info.Ammo) or 0))
    local NewAmmo = math.min(GetBullets(Best), GetMagazineCapacity(MagType))
    local OldMag = Weapon.Info.Mag
    local BestSlot = Best.Slot

    if not Player.Functions.RemoveItem('magazine', 1, BestSlot, false, MagType) then
        return Cb({ Success = false })
    end

    if OldMag and Config.Magazines[OldMag] then
        -- The ejected magazine takes the spot of the one that went in.
        Player.Functions.AddItem('magazine', 1, BestSlot, { Bullets = math.min(InGun, GetMagazineCapacity(OldMag)) }, false, OldMag)
    elseif InGun > 0 then
        -- Old ammo-box ammo in the gun: give it back as loose bullets.
        Player.Functions.AddItem('bullets', InGun, false, {}, true, MagType)
    end

    Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Ammo', NewAmmo)
    Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Mag', MagType)

    RefreshSlots(Player, { BestSlot, Weapon.Slot })
    Cb({ Success = true, Ammo = NewAmmo })
end)

-- // Old ammo boxes -> loose bullets (called from fw-weapons when an ammo box is used) \\ --
function ConvertAmmoBox(Source, Slot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end

    local Box = Player.PlayerData.inventory[tonumber(Slot)]
    if not Box or Box.Item ~= 'ammo' then return false end

    local MagData = Config.Magazines[Box.CustomType]
    if not MagData then return false end -- Taser, EMP, paintball, ... keep the old system.

    if not Player.Functions.RemoveItem('ammo', 1, Box.Slot, false, Box.CustomType) then return true end
    Player.Functions.AddItem('bullets', MagData.BoxBullets or 50, false, {}, true, Box.CustomType)
    Notify(Player, ("Je hebt de doos opengemaakt: %sx %s kogels."):format(MagData.BoxBullets or 50, MagData.Label), "success")
    return true
end
exports("ConvertAmmoBox", ConvertAmmoBox)

exports("GetMagazineTypeForAmmo", GetMagazineTypeForAmmo)
exports("GetMagazineConfig", function() return Config.Magazines end)
