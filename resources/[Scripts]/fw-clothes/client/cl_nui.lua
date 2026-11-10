-- NUI callbacks used by the illenium-style clothing menu in fw-ui (apps/Clothing).
-- The older callbacks (ProcessComponentChange, ProcessSliderChange, CloseMenu, ...) live in _cl_main.lua.

local function ReloadDecorations()
    local Clothes = Config.CurrentSkin.Clothes
    LoadFacialDecorations(PlayerPedId(), {
        Head = Clothes.TattoosHead,
        Torso = Clothes.TattoosTorso,
        LArm = Clothes.TattoosLArm,
        RArm = Clothes.TattoosRArm,
        LLeg = Clothes.TattoosLLeg,
        RLeg = Clothes.TattoosRLeg,
        Fade = Clothes.Fade,
    })
end

-- // Camera \\ --

RegisterNUICallback("Clothing/SetCameraFocus", function(Data, Cb)
    local Stage = Config.CameraFocus[Data.Focus or "character"] or Config.CameraFocus.character
    SetCameraStage(PlayerPedId(), Stage)
    Cb("ok")
end)

RegisterNUICallback("Clothing/CameraStep", function(Data, Cb)
    UpdateCameraPosition(PlayerPedId(), Data.Up == true)
    Cb("ok")
end)

RegisterNUICallback("Clothing/Rotate", function(Data, Cb)
    local Ped = PlayerPedId()
    SetEntityHeading(Ped, GetEntityHeading(Ped) + ((tonumber(Data.Dir) or 1) * 10.0))
    Cb("ok")
end)

-- // Tattoos: click a tattoo to wear it, click again to take it off \\ --

RegisterNUICallback("Clothing/ToggleTattoo", function(Data, Cb)
    local Zone, Index = Data.Zone, tonumber(Data.Index)
    if not TattooZoneKeys[Zone] or not Index or Index <= 0 then
        return Cb({ Success = false })
    end

    local Gender = GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01") and "Male" or "Female"
    local ZoneName = Zone:gsub("^Tattoos", "")
    if not Config.Tattoos[Gender][ZoneName] or not Config.Tattoos[Gender][ZoneName][Index] then
        return Cb({ Success = false })
    end

    -- Rebuild the zone as a clean list so layers never end up with mixed number / string keys.
    local Worn, List = GetTattooSet(Config.CurrentSkin.Clothes[Zone]), {}
    if Worn[Index] then
        Worn[Index] = nil
    else
        local Count = 0
        for _ in pairs(Worn) do Count = Count + 1 end
        if Count >= Config.MaxTattooLayers then
            FW.Functions.Notify(("Je kan maximaal %s tattoos per zone hebben."):format(Config.MaxTattooLayers), "error")
            return Cb({ Success = false })
        end
        Worn[Index] = true
    end

    for Value in pairs(Worn) do List[#List + 1] = Value end
    table.sort(List)
    if #List == 0 then List = { 0 } end

    Config.CurrentSkin.Clothes[Zone] = List
    ReloadDecorations()

    Cb({ Success = true, Zone = List, Price = GetClothesPrice() })
end)

-- // Saved outfits inside the clothing menu \\ --

local function GetOutfitList()
    local Outfits = FW.SendCallback("fw-clothes:Server:GetPlayerOutfits") or {}
    local Retval = {}
    for _, v in pairs(Outfits) do
        Retval[#Retval + 1] = { Id = v.Id, Title = v.Title }
    end
    return Retval
end

RegisterNUICallback("Clothing/GetOutfits", function(Data, Cb)
    Cb(GetOutfitList())
end)

RegisterNUICallback("Clothing/WearOutfit", function(Data, Cb)
    local NewSkin = FW.SendCallback("fw-clothes:Server:WearOutfit", Data.Id)
    if not NewSkin then return Cb({ Success = false }) end

    -- The outfit is already paid for, so it becomes the new starting point of this session.
    Config.CurrentSkin = NewSkin
    SavedClothes = DeepCopyTable(NewSkin)

    LoadPedModel(NewSkin.Model)
    LoadOutfit(PlayerPedId(), NewSkin.Clothes)
    TriggerEvent('fw-misc:Client:Play:Audio', 'change-clothes')

    SendSkinToUI()
    Cb({ Success = true, Price = GetClothesPrice() })
end)

RegisterNUICallback("Clothing/SaveOutfit", function(Data, Cb)
    if type(Data.Name) ~= "string" or #Data.Name == 0 or #Data.Name > 50 then
        return Cb({ Success = false })
    end

    -- The server stores the skin it knows about: changes that are not paid for yet are not included.
    FW.TriggerServer("fw-clothes:Server:SavePlayerOutfit", Data.Name, Config.CurrentSkin)
    Citizen.Wait(300)
    Cb({ Success = true, Outfits = GetOutfitList() })
end)

RegisterNUICallback("Clothing/DeleteOutfit", function(Data, Cb)
    TriggerServerEvent("fw-clothes:Server:DeleteOutfit", { OutfitId = Data.Id, KeepMenu = true })
    Citizen.Wait(300)
    Cb({ Success = true, Outfits = GetOutfitList() })
end)

RegisterNUICallback("Clothing/ShareOutfit", function(Data, Cb)
    Cb({ Code = FW.SendCallback("fw-clothes:Server:GenerateOutfitCode", Data.Id) or false })
end)

RegisterNUICallback("Clothing/ImportOutfit", function(Data, Cb)
    if type(Data.Name) ~= "string" or type(Data.Code) ~= "string" then
        return Cb({ Success = false, Msg = "Ongeldige naam of code." })
    end

    local Response = FW.SendCallback("fw-clothes:Server:ImportOutfitCode", Data.Name, Data.Code) or {}
    Response.Outfits = Response.Success and GetOutfitList() or nil
    Cb(Response)
end)
