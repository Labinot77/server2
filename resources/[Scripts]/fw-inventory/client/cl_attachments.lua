-- // Weapon attachments (client) \\ --
-- Applies what's stored on the weapon item (Info.Attachments, Info.Ammo) to the gun in your hand.
-- Which GTA component an attachment becomes is decided here with DoesWeaponTakeWeaponComponent,
-- so it works for any weapon (incl. add-on weapons) that uses base-game components.

local function Takes(WeaponHash, Component)
    return Component and DoesWeaponTakeWeaponComponent(WeaponHash, GetHashKey(Component))
end

-- The component this attachment item becomes on this weapon, or false if it doesn't fit.
function ResolveAttachmentComponent(ItemName, WeaponName)
    local Data, Fixed = GetWeaponAttachment(ItemName, WeaponName)
    if not Data then return false end

    local Hash = GetHashKey(WeaponName)
    if Fixed and Takes(Hash, Fixed) then return Fixed end

    for _, Component in ipairs(Data.Candidates or {}) do
        if Takes(Hash, Component) then return Component end
    end
    return false
end
exports("ResolveAttachmentComponent", ResolveAttachmentComponent)

-- Every component any attachment could give this weapon (stripped before re-applying).
local function GetPossibleComponents(WeaponName)
    local Retval = {}
    for _, Data in pairs(Config.WeaponAttachments) do
        if Data.Components and Data.Components[WeaponName] then Retval[#Retval + 1] = Data.Components[WeaponName] end
        for _, Component in ipairs(Data.Candidates or {}) do Retval[#Retval + 1] = Component end
    end
    return Retval
end

function ApplyWeaponAttachments(Ped, WeaponName, Info)
    local Hash = GetHashKey(WeaponName)

    for _, Component in ipairs(GetPossibleComponents(WeaponName)) do
        local CompHash = GetHashKey(Component)
        if HasPedGotWeaponComponent(Ped, Hash, CompHash) then
            RemoveWeaponComponentFromPed(Ped, Hash, CompHash)
        end
    end

    local Attachments = Info and type(Info.Attachments) == 'table' and Info.Attachments or {}
    for _, Attached in pairs(Attachments) do
        local Component = Attached and Attached.Item and ResolveAttachmentComponent(Attached.Item, WeaponName)
        if Component then
            GiveWeaponComponentToPed(Ped, Hash, GetHashKey(Component))
        end
    end
end

-- // Animations for magazine in / out \\ --
local IsHandlingMagazine = false

local function WaitForReload(Ped)
    local Started = GetGameTimer()
    Citizen.Wait(150)
    while IsPedReloading(Ped) and GetGameTimer() - Started < 4000 do Citizen.Wait(50) end
end

local function PlayHandlingAnim(Ped)
    local Anim = Config.MagazineLoadAnim
    if not Anim or not LoadAnimDictTimeout(Anim.Dict) then return end
    TaskPlayAnim(Ped, Anim.Dict, Anim.Anim, 4.0, 4.0, 1300, Anim.Flag or 49, 0, false, false, false)
end

-- Server changed a weapon's magazine/attachments.
--  Action: 'MagIn' | 'MagOut' | 'Attach' | 'Detach'
RegisterNetEvent("fw-inventory:Client:WeaponModified")
AddEventHandler("fw-inventory:Client:WeaponModified", function(Slot, Action)
    Citizen.Wait(150) -- let the inventory refresh land first
    local Item = FW.Functions.GetPlayerData().inventory[tonumber(Slot)]
    if not Item then return end

    local Ped, Hash = PlayerPedId(), GetHashKey(Item.Item)
    local InHand = GetSelectedPedWeapon(Ped) == Hash
    local Ammo = math.max(0, math.floor(tonumber(Item.Info and Item.Info.Ammo) or 0))

    if not InHand then
        -- Not holding it: just show the player handling the magazine.
        if Action == 'MagIn' or Action == 'MagOut' then PlayHandlingAnim(Ped) end
        return
    end

    if Action == 'MagIn' and not IsHandlingMagazine then
        -- Everything in reserve + empty clip -> GTA plays the reload and loads it.
        IsHandlingMagazine = true
        SetAmmoInClip(Ped, Hash, 0)
        SetPedAmmo(Ped, Hash, Ammo)
        MakePedReload(Ped)
        WaitForReload(Ped)
        IsHandlingMagazine = false
    elseif Action == 'MagOut' and not IsHandlingMagazine then
        -- Play the reload with a single round in reserve, then empty the gun.
        IsHandlingMagazine = true
        SetAmmoInClip(Ped, Hash, 0)
        SetPedAmmo(Ped, Hash, 1)
        MakePedReload(Ped)
        WaitForReload(Ped)
        SetPedAmmo(Ped, Hash, 0)
        SetAmmoInClip(Ped, Hash, 0)
        IsHandlingMagazine = false
    else
        SetPedAmmo(Ped, Hash, Ammo)
        SetAmmoInClip(Ped, Hash, Ammo)
    end

    ApplyWeaponAttachments(Ped, Item.Item, Item.Info)
end)

-- // NUI \\ --
-- Which slots / items fit a weapon (the NUI can't call natives, it asks here).
RegisterNUICallback("GetWeaponAttachmentFits", function(Data, Cb)
    local WeaponName = Data and Data.Weapon
    local Kinds, Items = {}, {}

    if WeaponName then
        for ItemName, Attachment in pairs(Config.WeaponAttachments) do
            local Fits = ResolveAttachmentComponent(ItemName, WeaponName) ~= false
            Items[ItemName] = Fits
            if Fits then Kinds[Attachment.Kind] = true end
        end
    end

    Cb({ Kinds = Kinds, Items = Items })
end)

function GetNuiWeaponAttachments()
    local Retval = {}
    for ItemName, Data in pairs(Config.WeaponAttachments) do
        Retval[#Retval + 1] = { Item = ItemName, Kind = Data.Kind }
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
