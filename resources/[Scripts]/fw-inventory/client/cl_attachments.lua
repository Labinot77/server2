-- // Weapon attachments (client) \\ --
-- Applies what's stored on the weapon item (Info.Attachments, Info.Ammo) to the gun in your hand.

-- Every component any attachment can give this weapon (to strip them before re-applying).
local function GetPossibleComponents(WeaponName)
    local Retval = {}
    for _, Data in pairs(Config.WeaponAttachments) do
        if Data.Components and Data.Components[WeaponName] then
            Retval[#Retval + 1] = Data.Components[WeaponName]
        end
    end
    return Retval
end

function ApplyWeaponAttachments(Ped, WeaponName, Info)
    local Hash = GetHashKey(WeaponName)

    for _, Component in ipairs(GetPossibleComponents(WeaponName)) do
        if HasPedGotWeaponComponent(Ped, Hash, GetHashKey(Component)) then
            RemoveWeaponComponentFromPed(Ped, Hash, GetHashKey(Component))
        end
    end

    local Attachments = Info and type(Info.Attachments) == 'table' and Info.Attachments or {}
    for _, Attached in pairs(Attachments) do
        local _, Component = GetWeaponAttachment(Attached.Item, WeaponName)
        if Component and DoesWeaponTakeWeaponComponent(Hash, GetHashKey(Component)) then
            GiveWeaponComponentToPed(Ped, Hash, GetHashKey(Component))
        end
    end
end

-- Server changed a weapon's magazine/attachments; update it if it's the one in your hand.
RegisterNetEvent("fw-inventory:Client:WeaponModified")
AddEventHandler("fw-inventory:Client:WeaponModified", function(Slot)
    Citizen.Wait(150) -- let the inventory refresh land first
    local Item = FW.Functions.GetPlayerData().inventory[tonumber(Slot)]
    if not Item then return end

    local Ped, Hash = PlayerPedId(), GetHashKey(Item.Item)
    if GetSelectedPedWeapon(Ped) ~= Hash then return end

    local Ammo = math.max(0, math.floor(tonumber(Item.Info and Item.Info.Ammo) or 0))
    SetPedAmmo(Ped, Hash, Ammo)
    SetAmmoInClip(Ped, Hash, Ammo)
    ApplyWeaponAttachments(Ped, Item.Item, Item.Info)
end)

-- // NUI data \\ --
function GetNuiWeaponAttachments()
    local Retval = {}
    for ItemName, Data in pairs(Config.WeaponAttachments) do
        local Weapons = {}
        for WeaponName in pairs(Data.Components or {}) do Weapons[#Weapons + 1] = WeaponName end
        Retval[#Retval + 1] = { Item = ItemName, Kind = Data.Kind, Weapons = Weapons }
    end
    return Retval
end

-- weapon item name -> magazine type (from fw-weapons ammo types)
function GetNuiWeaponMagTypes()
    local Retval = {}
    local Ok, Weapons = pcall(function() return exports['fw-weapons']:GetAllWeaponList() end)
    if not Ok or type(Weapons) ~= 'table' then return Retval end

    for _, Data in pairs(Weapons) do
        local Name = Data.WeaponID or Data.WeaponId
        local MagType = Name and GetMagazineTypeForAmmo(Data.AmmoType)
        if MagType then Retval[Name] = MagType end
    end
    return Retval
end
