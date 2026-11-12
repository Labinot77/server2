FW = exports['fw-core']:GetCoreObject()

RegisterNetEvent("fw-clothes:Server:DeleteOutfit")
AddEventHandler("fw-clothes:Server:DeleteOutfit", function(Data)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    exports['ghmattimysql']:executeSync("DELETE FROM `player_outfits` WHERE `id` = ? AND `citizenid` = ?", {
        Data.OutfitId,
        Player.PlayerData.citizenid,
    })

    -- Remove the share code once the outfit itself is gone.
    exports['ghmattimysql']:executeSync("DELETE FROM `player_outfit_codes` WHERE `outfitid` = ? AND NOT EXISTS (SELECT 1 FROM `player_outfits` WHERE `id` = ?)", {
        Data.OutfitId, Data.OutfitId
    })

    -- Deleting from inside the clothing menu must not reset what the player is trying on.
    if Data.KeepMenu then return end

    TriggerClientEvent("fw-clothes:Client:CloseOutfits", Source, {}, true)
    Citizen.Wait(5)
    TriggerClientEvent("fw-clothes:Client:LoadSkin", Source, nil)
end)

FW.Functions.CreateCallback("fw-clothes:Server:GetMoney", function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb(false) end

    Cb({
        Cash = Player.PlayerData.money.cash or 0,
        Bank = exports['fw-financials']:GetAccountBalance(Player.PlayerData.charinfo.account) or 0,
    })
end)

RegisterNetEvent("fw-clothes:Server:StealShoes")
AddEventHandler("fw-clothes:Server:StealShoes", function(TargetSrc, NewShoes)
    local Source = source

    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    local Target = FW.Functions.GetPlayer(TargetSrc)
    if Target == nil or type(NewShoes) ~= "number" then return end

    local Distance = #(GetEntityCoords(GetPlayerPed(Source)) - GetEntityCoords(GetPlayerPed(TargetSrc)))
    if Distance > 3.0 then return end

    TriggerClientEvent("fw-clothes:Client:ToggleFacewear", TargetSrc, 'Shoes', NewShoes)
    Player.Functions.AddItem('weapon_shoe', 1, false, nil, true)
end)

FW.Functions.CreateCallback("fw-clothes:Server:GetDefaultClothes", function(Source, Cb, Gender)
    Cb(GetDefaultClothes(Gender))
end)

FW.Functions.CreateCallback("fw-clothes:Server:GetPlayerOutfit", function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    Cb(Player.PlayerData.skin)
end)

FW.Functions.CreateCallback("fw-clothes:Server:GetPlayerOutfits", function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    local Result = exports['ghmattimysql']:executeSync("SELECT * FROM `player_outfits` WHERE `citizenid` = ?", {Player.PlayerData.citizenid})
    local Retval = {}

    for k, v in pairs(Result) do
        Retval[#Retval + 1] = {
            Id = v.id,
            Title = v.name,
            Outfit = json.decode(v.outfit)
        }
    end

    Cb(Retval)
end)

-- Clothing slots mirror what you wear (after buying clothes or wearing an outfit):
-- a worn piece replaces the item in its slot (or is given), a piece you don't wear is deleted from its slot.
function SyncClothingItems(Source, Skin)
    for ComponentId, ItemName in pairs(Config.ClothingItems) do
        local Worn = Skin.Clothes[ComponentId]
        if type(Worn) == "table" then
            local IsWorn = Worn[1] ~= GetNakedValue(Skin.Model, ComponentId)
            exports['fw-inventory']:SetEquippedClothing(Source, ItemName, IsWorn and { Prop = Worn[1], Texture = Worn[2] })
        end
    end
end

FW.Functions.CreateCallback("fw-clothes:Server:PurchaseClothes", function(Source, Cb, PaymentType, _ClientPrice, NewSkin)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    local Valid, Msg = ValidateSkin(Source, NewSkin)
    if not Valid then return Cb({Success = false, Msg = Msg}) end

    -- Never trust the price the client sends.
    local Price = ConsumeFreeEdit(Source) and 0 or CalculateClothesPrice(Player.PlayerData.skin, NewSkin)

    if Price > 0 and PaymentType ~= "Cash" and PaymentType ~= "Bank" then
        return Cb({Success = false, Msg = "Ongeldige betaalmethode.."})
    end

    local BankBalance = exports['fw-financials']:GetAccountBalance(Player.PlayerData.charinfo.account)
    if PaymentType == "Cash" and Price > 0 and not Player.Functions.RemoveMoney('Cash', Price) then
        return Cb({Success = false, Msg = "Je hebt niet genoeg contant.."})
    elseif PaymentType == "Bank" and Price > 0 and BankBalance < Price then
        return Cb({Success = false, Msg = "Je hebt niet genoeg bank balans.."})
    end

    if PaymentType == "Bank" and Price > 0 then
        exports['fw-financials']:RemoveMoneyFromAccount(Player.PlayerData.citizenid, Player.PlayerData.charinfo.account, Player.PlayerData.charinfo.account, Price, 'PURCHASE', "Kleding gekocht", false)
    end

    Player.Functions.SetSkin({ Model = NewSkin.Model, Clothes = NewSkin.Clothes })
    SyncClothingItems(Source, NewSkin)

    Cb({Success = true})
end)

FW.RegisterServer("fw-clothes:Server:SetOutfit", function(Source, NewSkin)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil or type(NewSkin) ~= "table" or type(NewSkin.Clothes) ~= "table" then return end

    local IsFree, Component = IsFreeSkinChange(Player.PlayerData.skin, NewSkin, Source)
    if not IsFree then
        TriggerEvent('fw-logs:Server:Log', 'anticheat', 'Clothes', ('%s (%s) tried to change `%s` without paying.'):format(GetPlayerName(Source), Player.PlayerData.citizenid, tostring(Component or "Model")), 'red')
        TriggerClientEvent("fw-clothes:Client:LoadSkin", Source, nil)
        return
    end

    Player.Functions.SetSkin({ Model = NewSkin.Model, Clothes = NewSkin.Clothes })
end)

FW.RegisterServer("fw-clothes:Server:SavePlayerOutfit", function(Source, Name, Outfit, OverwriteId)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    if OverwriteId then
        -- Store the skin the server knows about, not whatever the client sends.
        local Skin = Player.PlayerData.skin
        exports['ghmattimysql']:executeSync("UPDATE `player_outfits` SET `outfit` = ? WHERE `id` = ? AND `citizenid` = ?", {
            json.encode({ Model = Skin.Model, Clothes = Skin.Clothes }),
            OverwriteId,
            Player.PlayerData.citizenid
        })

        Player.Functions.Notify("Outfit overschreven.")
    else
        if type(Name) ~= "string" or #Name == 0 or #Name > 50 then return end

        local Skin = Player.PlayerData.skin
        exports['ghmattimysql']:executeSync("INSERT INTO `player_outfits` (`citizenid`, `name`, `outfit`) VALUES (?, ?, ?)", {
            Player.PlayerData.citizenid,
            Name,
            json.encode({ Model = Skin.Model, Clothes = Skin.Clothes })
        })

        Player.Functions.Notify("Outfit opgeslagen.")
    end

    TriggerClientEvent("fw-clothes:Client:CloseOutfits", Source, {KeepCam = false}, true)
end)

FW.RegisterServer("fw-clothes:Server:RemoveFacewear", function(Source,  ItemSlot)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    local Item = Player.Functions.GetItemBySlot(ItemSlot)
    if Item == nil or (Item.Item ~= 'hat' and Item.Item ~= 'mask' and Item.Item ~= 'glasses') then
        return
    end

    Player.Functions.RemoveItem(Item.Item, 1, ItemSlot, true, false)
end)

FW.RegisterServer("fw-clothes:Server:ReceiveFacewearItem", function(Source, ComponentId, ComponentData)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    local ComponentItems = {
        Hat = 'hat',
        Masks = 'mask',
        Glasses = 'glasses',
        Earrings = 'earrings',
        Watches = 'watch',
    }

    if ComponentItems[ComponentId] == nil then
        return
    end

    -- Lands in pockets (accessory slots are never auto-filled), the prop gets removed client-side.
    Player.Functions.AddItem(ComponentItems[ComponentId], 1, false, {Prop = ComponentData[1], Texture = ComponentData[2]}, true)
end)

FW.Commands.Add("outfits", "Open kledingkast", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:OpenOutfits', Source, true, true)
end)

-- Take off: if the accessory is equipped as an item, move it to pockets (fw-inventory removes the prop).
-- Otherwise (worn via outfit/skin) fall back to the old behaviour that turns it into an item.
local function TakeOffAccessory(Source, ComponentId)
    if exports['fw-inventory']:GetEquippedItem(Source, ComponentId) then
        exports['fw-inventory']:UnequipSlot(Source, exports['fw-inventory']:GetEquipSlotByClothing(ComponentId))
        return
    end
    TriggerClientEvent('fw-clothes:Client:ToggleFacewear', Source, ComponentId, false, true)
end

FW.Commands.Add("reloadskin", "Herlaad je kleding/ped (fixt onzichtbare kleding)", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ReloadSkin', Source)
end)

FW.Commands.Add("clearstuckprops", "Verwijder objecten die aan je vast zitten", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ClearStuckProps', Source)
end)

FW.Commands.Add("h0", "Zet je helm af", {}, false, function(Source, Args)
    TakeOffAccessory(Source, 'Hat')
end)

FW.Commands.Add("m0", "Zet je masker af", {}, false, function(Source, Args)
    TakeOffAccessory(Source, 'Masks')
end)

FW.Commands.Add("b0", "Zet je bril af", {}, false, function(Source, Args)
    TakeOffAccessory(Source, 'Glasses')
end)

FW.Commands.Add("v0", "Doe je vest uit", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ToggleFacewear', Source, 'Vest', false, true)
end)

FW.Commands.Add("h1", "Zet je helm op", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ToggleFacewear', Source, 'Hat', true, true)
end)

FW.Commands.Add("m1", "Zet je masker op", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ToggleFacewear', Source, 'Masks', true, true)
end)

FW.Commands.Add("b1", "Zet je bril op", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ToggleFacewear', Source, 'Glasses', true, true)
end)

FW.Commands.Add("v1", "Doe je vest aan", {}, false, function(Source, Args)
    TriggerClientEvent('fw-clothes:Client:ToggleFacewear', Source, 'Vest', true, true)
end)

-- Using a clothing item equips it into its slot (or takes it off when already equipped).
for _, ItemName in pairs(Config.ClothingItems) do
    FW.Functions.CreateUsableItem(ItemName, function(Source, Item)
        local Player = FW.Functions.GetPlayer(Source)
        if Player == nil or Player.Functions.GetItemBySlot(Item.Slot) == nil then return end
        exports['fw-inventory']:ToggleEquipItem(Source, Item.Slot)
    end)
end

function GetDefaultClothes(Gender)
    if Gender == "Female" then
        return {
            Model = "mp_f_freemode_01",
            Clothes = {
                Watches = {-1,0},
                FaceThree = {0,0},
                FaceJawBone = {50,50},
                FaceMix = 0.0,
                FaceEyebrows = {50,50},
                Hair = {97,0,11,0},
                Lipstick = {-1,3,0,33},
                Complexion = {0,0},
                Undershirt = {14,0},
                Arms = {15,0},
                Eyebrows = {0,0,0},
                Jacket = {15,0},
                SkinMix = 0.0,
                Masks = {0,0},
                Blemishes = {0,0},
                Glasses = {15,0},
                ChestHair = {0,0,0},
                FaceEyeColor = {0},
                FaceCheeks = {50,50,50},
                BodyBlemishes = {0,0},
                Hat = {-1,0},
                FaceTwo = {0,0},
                Bags = {0,0},
                Earrings = {-1,0},
                Blush = {-1,0,0,42},
                FaceOne = {45,0},
                Decals = {0,0},
                Bracelets = {-1,0},
                Scarfs = {0,0},
                Beard = {0,0,0},
                Shoes = {35,0},
                FaceChin = {50,50,50,50},
                ThirdFaceMix = 0.0,
                Moles = {0,0},
                FaceNose = {50,50,50,50,50,50},
                Fade = {0},
                Ageing = {0,0},
                Vest = {0,0},
                Makeup = {-1,1,0,0},
                SunDamage = {0,0},
                Pants = {15,0},
                FaceMisc = {50,50,50},
                TattoosHead = {0},
                TattoosTorso = {0},
                TattoosLArm = {0},
                TattoosRArm = {0},
                TattoosLLeg = {0},
                TattoosRLeg = {0}
            }
        }
    end

    return {
        Model = "mp_m_freemode_01",
        Clothes = {
            Watches = {-1,0},
            FaceThree = {0,0},
            FaceJawBone = {50,50},
            Makeup = {-1,1,0,0},
            FaceEyebrows = {50,50},
            Hair = {0,0,0,0},
            Lipstick = {-1,3,0,33},
            Complexion = {0,0},
            Undershirt = {15,0},
            Arms = {15,0},
            Eyebrows = {0,0,0},
            Jacket = {15,0},
            SkinMix = 50.0,
            Masks = {0,0},
            Blemishes = {0,0},
            Glasses = {0,0},
            ChestHair = {0,0,0},
            FaceEyeColor = {0},
            FaceCheeks = {50,50,50},
            BodyBlemishes = {0,0},
            Decals = {0,0},
            FaceTwo = {0,0},
            Bags = {0,0},
            Hat = {-1,0},
            Blush = {-1,0,0,42},
            Earrings = {-1,0},
            FaceOne = {0,0},
            Scarfs = {0,0},
            Bracelets = {-1,0},
            Beard = {0,0,0},
            Ageing = {0,0},
            FaceChin = {50,50,50,50},
            Shoes = {34,0},
            Moles = {0,0},
            ThirdFaceMix = 50.0,
            Fade = {0},
            FaceNose = {50,50,50,50,50,50},
            Vest = {0,0},
            FaceMix = 50.0,
            SunDamage = {0,0},
            Pants = {61,0},
            FaceMisc = {50,50,50},
            TattoosHead = {0},
            TattoosTorso = {0},
            TattoosLArm = {0},
            TattoosRArm = {0},
            TattoosLLeg = {0},
            TattoosRLeg = {0}
        }
    }
end

exports("GetDefaultClothes", GetDefaultClothes)