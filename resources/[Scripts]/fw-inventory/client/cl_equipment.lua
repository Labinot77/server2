-- // Equipment sync \\ --
-- Watches the Body / Accessories slots of the local player and applies the effect
-- of whatever is in them. Because it diffs PlayerData.inventory on every update,
-- it works no matter HOW an item got moved: drag & drop, use-item, being robbed,
-- admin /clearinv, RemoveItem from another resource, ...

local LastEquipment = nil -- [Slot] = signature string | false

local function Signature(Item)
    if not Item then return false end
    return Item.Item .. '|' .. (Item.CustomType or '') .. '|' .. json.encode(Item.Info or {})
end

local function GetBackpackClothing(Item)
    if not Item then return false end
    if Item.Info and Item.Info.Prop then return Item.Info end

    local BagData = Config.Backpacks[Item.Item]
    if not BagData or not BagData.Drawable then return false end

    local IsFemale = GetEntityModel(PlayerPedId()) == GetHashKey("mp_f_freemode_01")
    local Drawable = IsFemale and BagData.Drawable.Female or BagData.Drawable.Male
    if not Drawable then return false end

    return { Prop = Drawable[1], Texture = Drawable[2] or 0 }
end

local function ApplySlot(Slot, SlotData, Item, IsInitial)
    if SlotData.Clothing then
        if Item then
            TriggerEvent('fw-clothes:Client:SetAccessory', SlotData.Clothing, Item.Info or {}, not IsInitial)
        elseif not IsInitial then
            -- Never strip clothing on login, only on an actual unequip.
            TriggerEvent('fw-clothes:Client:SetAccessory', SlotData.Clothing, false, true)
        end
    end

    if SlotData.IsBackpack then
        local Clothing = GetBackpackClothing(Item)
        if Clothing then
            TriggerEvent('fw-clothes:Client:SetAccessory', 'Bags', Clothing, false)
        elseif not Item and not IsInitial and LastEquipment and LastEquipment[Slot] then
            local Previous = LastEquipment[Slot]
            local PrevName = Previous and Previous:match("^([^|]+)")
            if PrevName and Config.Backpacks[PrevName] and Config.Backpacks[PrevName].Drawable then
                TriggerEvent('fw-clothes:Client:SetAccessory', 'Bags', false, false)
            end
        end

        TriggerEvent('fw-inventory:Client:OnBackpackChanged', Item, Item and Config.Backpacks[Item.Item] or false)
    end

    TriggerEvent('fw-inventory:Client:OnEquipmentChanged', Slot, SlotData, Item)
end

function SyncEquipment(Inventory, IsInitial)
    if not Inventory then return end
    if not IsInitial and LastEquipment == nil then return end -- Not initialised yet.

    local NewState = {}
    for Slot, SlotData in pairs(Config.EquipSlots) do
        local Item = Inventory[Slot]
        local Sig = Signature(Item)
        NewState[Slot] = Sig

        -- LastEquipment is still the previous state here, ApplySlot relies on that.
        if IsInitial or LastEquipment[Slot] ~= Sig then
            ApplySlot(Slot, SlotData, Item, IsInitial)
        end
    end

    LastEquipment = NewState

    -- Keep an open inventory's locks/weight in sync with the backpack.
    if CurrentInventory then
        SendNUIMessage({
            Action = "SetPlayerLimits",
            MaxWeight = GetMaxPlayerWeight(Inventory),
            BackpackSlots = GetUnlockedBackpackSlots(Inventory),
        })
    end
end

RegisterNetEvent('FW:Player:SetPlayerData')
AddEventHandler('FW:Player:SetPlayerData', function(PlayerData)
    if PlayerData and PlayerData.inventory then
        SyncEquipment(PlayerData.inventory, false)
    end
end)

RegisterNetEvent('FW:Client:OnPlayerLoaded')
AddEventHandler('FW:Client:OnPlayerLoaded', function()
    -- Move items that sit in slots they're no longer allowed in (old 40-slot layout).
    FW.TriggerServer('fw-inventory:Server:FixLayout')

    -- Give fw-clothes time to load the skin first, then lay equipped accessories over it.
    Citizen.SetTimeout(3000, function()
        local PlayerData = FW.Functions.GetPlayerData()
        if PlayerData and PlayerData.inventory then
            SyncEquipment(PlayerData.inventory, true)
        end
    end)
end)

RegisterNetEvent('FW:Client:OnPlayerUnload')
AddEventHandler('FW:Client:OnPlayerUnload', function()
    LastEquipment = nil
end)

AddEventHandler('onResourceStart', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    Citizen.SetTimeout(1000, function()
        local PlayerData = FW.Functions.GetPlayerData()
        if PlayerData and PlayerData.inventory then
            SyncEquipment(PlayerData.inventory, true)
        end
    end)
end)

-- // Exports \\ --
exports("GetEquippedItem", function(SlotOrLabel)
    local Inventory = FW.Functions.GetPlayerData().inventory
    local Slot = tonumber(SlotOrLabel)
    if not Slot then
        for k, v in pairs(Config.EquipSlots) do
            if v.Label == SlotOrLabel or v.Clothing == SlotOrLabel then Slot = k break end
        end
    end
    return Slot and Inventory[Slot] or false
end)

exports("HasBackpack", function()
    return GetEquippedBackpack(FW.Functions.GetPlayerData().inventory) ~= false
end)

exports("GetMaxWeight", function()
    return GetMaxPlayerWeight(FW.Functions.GetPlayerData().inventory)
end)

-- Layout sent to the NUI (arrays only: sparse Lua tables don't JSON-encode reliably).
function GetNuiLayout()
    local EquipSlots = {}
    for Slot, Data in pairs(Config.EquipSlots) do
        EquipSlots[#EquipSlots + 1] = {
            Slot = Slot, Section = Data.Section, Label = Data.Label, Icon = Data.Icon,
            Items = Data.Items, IsBackpack = Data.IsBackpack or false,
        }
    end

    local Backpacks = {}
    for Name, Data in pairs(Config.Backpacks) do
        Backpacks[#Backpacks + 1] = { Name = Name, Weight = Data.Weight or 0.0, Slots = Data.Slots }
    end

    return {
        SlotLayout = Config.SlotLayout,
        EquipSlots = EquipSlots,
        Backpacks = Backpacks,
        BackpackSlot = Config.BackpackSlot,
        MaxPlayerWeight = Config.MaxPlayerWeight,
        MaxPlayerSlots = Config.MaxPlayerSlots,
        Magazines = Config.Magazines,
        AttachmentSlots = Config.AttachmentSlots,
        WeaponAttachments = GetNuiWeaponAttachments(),
        WeaponMagTypes = GetNuiWeaponMagTypes(),
    }
end

-- True when a working (not broken) phone sits in the BODY phone slot.
exports("HasPhoneEquipped", function(ItemName)
    local Equipped, Item = IsPhoneEquipped(FW.Functions.GetPlayerData().inventory, ItemName)
    if not Equipped then return false end
    return exports['fw-inventory']:CalculateQuality(Item.Item, Item.CreateDate) > 1.0
end)

-- Magazines (used by fw-weapons).
exports("GetMagazineTypeForAmmo", function(AmmoType) return GetMagazineTypeForAmmo(AmmoType) end)
exports("GetMagazineConfig", function() return Config.Magazines end)
exports("GetReloadTime", function() return Config.ReloadTime end)
