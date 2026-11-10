-- /reloadskin and /clearstuckprops, ported from illenium-appearance.
local LastUse = 0

local function CanUse()
    local Ped = PlayerPedId()
    local PlayerData = FW.Functions.GetPlayerData()

    if GetGameTimer() - LastUse < Config.ReloadSkinCooldown then return false end
    if InClothesMenu or CreatingCharacter then return false end
    if PlayerData.metadata.isdead or PlayerData.metadata.ishandcuffed then return false end
    if IsPedInAnyVehicle(Ped, false) or IsPedFalling(Ped) or IsPedRagdoll(Ped) or IsPedSwimming(Ped) then return false end

    return true
end

RegisterNetEvent("fw-clothes:Client:ReloadSkin")
AddEventHandler("fw-clothes:Client:ReloadSkin", function()
    if not CanUse() then
        return FW.Functions.Notify("Je kan je skin nu niet herladen..", "error")
    end
    LastUse = GetGameTimer()

    local Ped = PlayerPedId()
    local Health, Armour = GetEntityHealth(Ped), GetPedArmour(Ped)
    local Weapon = GetSelectedPedWeapon(Ped)

    local Skin = FW.SendCallback("fw-clothes:Server:GetPlayerOutfit")
    if not Skin then return end
    Config.CurrentSkin = Skin

    -- Force the model to be re-applied, that's what fixes invisible / broken peds.
    LoadPedModel(Skin.Model, true)
    Citizen.Wait(250)
    LoadOutfit(PlayerPedId(), Skin.Clothes)

    Ped = PlayerPedId()
    SetEntityMaxHealth(Ped, 200)
    SetEntityHealth(Ped, Health)
    SetPedArmour(Ped, Armour)
    if Weapon and Weapon ~= `WEAPON_UNARMED` then
        -- A new ped model drops the weapon in hand, let fw-inventory clear its state.
        TriggerEvent('fw-inventory:Client:ResetWeapon')
    end

    FW.Functions.Notify("Skin herladen.", "success")
end)

RegisterNetEvent("fw-clothes:Client:ClearStuckProps")
AddEventHandler("fw-clothes:Client:ClearStuckProps", function()
    if not CanUse() then
        return FW.Functions.Notify("Je kan dit nu niet doen..", "error")
    end
    LastUse = GetGameTimer()

    local Ped, Removed = PlayerPedId(), 0
    for _, Object in pairs(GetGamePool("CObject")) do
        if IsEntityAttachedToEntity(Ped, Object) then
            SetEntityAsMissionEntity(Object, true, true)
            DeleteObject(Object)
            DeleteEntity(Object)
            Removed = Removed + 1
        end
    end

    -- Items fw-assets attaches (bags, weapons on back) get re-attached.
    TriggerEvent("fw-assets:Client:Attach:Items")
    FW.Functions.Notify(("%s object(en) verwijderd."):format(Removed), "success")
end)
