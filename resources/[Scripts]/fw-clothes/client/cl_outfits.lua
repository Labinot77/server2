local IsRemovingFacewear = false

-- Outfits
RegisterNetEvent("fw-clothes:Client:OpenOutfits")
AddEventHandler("fw-clothes:Client:OpenOutfits", function(Forced, IsCommand)
    local PlayerData = FW.Functions.GetPlayerData()

    if IsCommand then
        local Hit, Pos, Vehicle = RayCastGamePlayCamera(5.0)
		if not Hit or Vehicle == -1 or GetEntityType(Vehicle) ~= 2 then
            Forced = false
        else
            local IsGov = exports['fw-vehicles']:IsPoliceVehicle(Vehicle)
            if not IsGov or (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ems") then
                Forced = false
            end
        end
    end

    if not Forced and IsPlayerAdmin() then
        Forced = true
    end

    if Forced or IsNearChangingRoom() then
        local Outfits = FW.SendCallback("fw-clothes:Server:GetPlayerOutfits")
        local ContextMenu = {
            {
                Title = "Outfit Opslaan",
                Icon = "plus",
                Data = { Event = "fw-clothes:Client:SaveOutfitPrompt", Forced = Forced }
            },
            {
                Title = "Outfit Importeren",
                Desc = "Voeg een outfit toe met een deelcode",
                Icon = "file-import",
                Data = { Event = "fw-clothes:Client:ImportOutfitPrompt" }
            },
        }

        -- Job outfits (managed by the boss of the job).
        local JobData = FW.SendCallback("fw-clothes:Server:GetJobOutfits")
        if JobData and JobData.Allowed and (#JobData.Outfits > 0 or JobData.IsBoss) then
            local JobMenu = {}
            for _, v in pairs(JobData.Outfits) do
                local Entry = {
                    Title = v.Title,
                    Desc = ("Vanaf rang %s"):format(v.MinRank),
                    Icon = "user-tie",
                    Data = { Event = "fw-clothes:Client:WearJobOutfit", OutfitId = v.Id },
                }
                if JobData.IsBoss then
                    Entry.SecondMenu = {
                        { Title = "Aantrekken", Icon = "check", Data = { Event = "fw-clothes:Client:WearJobOutfit", OutfitId = v.Id } },
                        { Title = "Verwijderen", Icon = "trash", Data = { Event = "fw-clothes:Server:DeleteJobOutfit", OutfitId = v.Id } },
                    }
                    Entry.Data = nil
                end
                JobMenu[#JobMenu + 1] = Entry
            end

            if JobData.IsBoss then
                JobMenu[#JobMenu + 1] = {
                    Title = "Huidige kleding opslaan als werk outfit",
                    Icon = "plus",
                    Data = { Event = "fw-clothes:Client:SaveJobOutfitPrompt" },
                }
            end

            table.insert(ContextMenu, {
                Title = "Werk Outfits",
                Desc = PlayerData.job.label,
                Icon = "briefcase",
                SecondMenu = JobMenu,
            })
        end

        for k, v in pairs(Outfits) do
            table.insert(ContextMenu, {
                Title = ("(%s) %s"):format(v.Id, v.Title),
                Icon = "tshirt",
                CloseMenu = false,
                Data = { Event = 'fw-clothes:Client:LoadOutfit', IsPreview = true, Outfit = v.Outfit },
                SecondMenu = {
                    {
                        Title = "Aantrekken",
                        Icon = "check",
                        Data = { Event = "fw-clothes:Client:LoadOutfit", Outfit = v.Outfit, OutfitId = v.Id, IsPreview = false }
                    },
                    {
                        Title = "Deelcode",
                        Icon = "share-alt",
                        Data = { Event = "fw-clothes:Client:ShareOutfit", OutfitId = v.Id }
                    },
                    {
                        Title = "Overschrijven",
                        Icon = "user-edit",
                        Data = { Event = "fw-clothes:Client:OverwriteOutfit", OutfitId = v.Id }
                    },
                    {
                        Title = "Verwijderen",
                        Icon = "trash",
                        Data = { Event = "fw-clothes:Server:DeleteOutfit", OutfitId = v.Id }
                    },
                }
            })
        end

        Citizen.Wait(50)
        FW.Functions.OpenMenu({
            MainMenuItems = ContextMenu,
            ReturnEvent = { Event = "fw-clothes:Client:CloseOutfits", Type = "Client", KeepCam = true },
            CloseEvent = { Event = "fw-clothes:Client:CloseOutfits", Type = "Client" },
        })
        CreateClothingCamera(true, false, 3)
    end
end)

RegisterNetEvent("fw-clothes:Client:CloseOutfits")
AddEventHandler("fw-clothes:Client:CloseOutfits", function(Data, IgnoreLoad)
    if not Data.KeepCam then
        CreateClothingCamera(false)
    end

    if not IgnoreLoad then
        LoadPedModel(Config.CurrentSkin.Model)
        LoadOutfit(PlayerPedId(), Config.CurrentSkin.Clothes)
    end
end)

RegisterNetEvent("fw-clothes:Client:LoadOutfit")
AddEventHandler("fw-clothes:Client:LoadOutfit", function(Data)
    if not Data.IsPreview then
        -- The server loads the outfit from the database and sets it, the client only applies the result.
        local NewSkin = FW.SendCallback("fw-clothes:Server:WearOutfit", Data.OutfitId)
        CreateClothingCamera(false)
        if not NewSkin then
            LoadPedModel(Config.CurrentSkin.Model)
            LoadOutfit(PlayerPedId(), Config.CurrentSkin.Clothes)
            return
        end

        Config.CurrentSkin = NewSkin
        TriggerEvent('fw-misc:Client:Play:Audio', 'change-clothes')
        LoadPedModel(NewSkin.Model)
        LoadOutfit(PlayerPedId(), NewSkin.Clothes)
        return
    end

    LoadPedModel(Data.Outfit.Model)
    LoadOutfit(PlayerPedId(), Data.Outfit.Clothes)
end)

RegisterNetEvent("fw-clothes:Client:OverwriteOutfit")
AddEventHandler("fw-clothes:Client:OverwriteOutfit", function(Data)
    FW.TriggerServer("fw-clothes:Server:SavePlayerOutfit", nil, Config.CurrentSkin, Data.OutfitId)
end)

RegisterNetEvent("fw-clothes:Client:SaveOutfitPrompt")
AddEventHandler("fw-clothes:Client:SaveOutfitPrompt", function(Data)
    if not Data.Forced and not IsNearChangingRoom() then return end
    CreateClothingCamera(false)
    Citizen.Wait(10)

    local Result = exports['fw-ui']:CreateInput({
        { Name = "Name", Label = "Outfit Name", Icon = "fas fa-tshirt" }
    })

    if Result and Result.Name then
        FW.TriggerServer("fw-clothes:Server:SavePlayerOutfit", Result.Name, Config.CurrentSkin)
    end
end)

-- Outfit codes
RegisterNetEvent("fw-clothes:Client:ShareOutfit")
AddEventHandler("fw-clothes:Client:ShareOutfit", function(Data)
    CreateClothingCamera(false)
    LoadPedModel(Config.CurrentSkin.Model)
    LoadOutfit(PlayerPedId(), Config.CurrentSkin.Clothes)

    local Code = FW.SendCallback("fw-clothes:Server:GenerateOutfitCode", Data.OutfitId)
    if not Code then
        return FW.Functions.Notify("Kon geen deelcode maken..", "error")
    end

    Citizen.Wait(10)
    exports['fw-ui']:CreateInput({
        { Name = "Code", Label = "Deelcode (Ctrl+C om te kopieren)", Icon = "fas fa-share-alt", Value = Code },
    })
end)

RegisterNetEvent("fw-clothes:Client:ImportOutfitPrompt")
AddEventHandler("fw-clothes:Client:ImportOutfitPrompt", function()
    CreateClothingCamera(false)
    LoadPedModel(Config.CurrentSkin.Model)
    LoadOutfit(PlayerPedId(), Config.CurrentSkin.Clothes)
    Citizen.Wait(10)

    local Result = exports['fw-ui']:CreateInput({
        { Name = "Name", Label = "Outfit Naam", Icon = "fas fa-tshirt" },
        { Name = "Code", Label = "Deelcode", Icon = "fas fa-key" },
    })

    if not Result or not Result.Name or #Result.Name == 0 or not Result.Code or #Result.Code == 0 then return end

    local Response = FW.SendCallback("fw-clothes:Server:ImportOutfitCode", Result.Name, Result.Code)
    if Response and Response.Success then
        FW.Functions.Notify("Outfit geimporteerd.", "success")
    else
        FW.Functions.Notify(Response and Response.Msg or "Importeren mislukt..", "error")
    end
end)

-- Job outfits
RegisterNetEvent("fw-clothes:Client:WearJobOutfit")
AddEventHandler("fw-clothes:Client:WearJobOutfit", function(Data)
    CreateClothingCamera(false)

    local NewSkin = FW.SendCallback("fw-clothes:Server:WearJobOutfit", Data.OutfitId)
    if not NewSkin then
        LoadPedModel(Config.CurrentSkin.Model)
        LoadOutfit(PlayerPedId(), Config.CurrentSkin.Clothes)
        return FW.Functions.Notify("Je kan dit outfit niet aantrekken..", "error")
    end

    Config.CurrentSkin = NewSkin
    TriggerEvent('fw-misc:Client:Play:Audio', 'change-clothes')
    LoadOutfit(PlayerPedId(), NewSkin.Clothes)
end)

RegisterNetEvent("fw-clothes:Client:SaveJobOutfitPrompt")
AddEventHandler("fw-clothes:Client:SaveJobOutfitPrompt", function()
    CreateClothingCamera(false)
    LoadPedModel(Config.CurrentSkin.Model)
    LoadOutfit(PlayerPedId(), Config.CurrentSkin.Clothes)
    Citizen.Wait(10)

    local PlayerData = FW.Functions.GetPlayerData()
    local Job = FW.Shared.Jobs[PlayerData.job.name]
    local RankChoices = {}
    if Job then
        local Grades = {}
        for Grade in pairs(Job.grades) do Grades[#Grades + 1] = tonumber(Grade) end
        table.sort(Grades)
        for _, Grade in ipairs(Grades) do
            RankChoices[#RankChoices + 1] = { Icon = false, Text = Job.grades[tostring(Grade)].name, Value = tostring(Grade) }
        end
    end

    local Result = exports['fw-ui']:CreateInput({
        { Name = "Name", Label = "Outfit Naam", Icon = "fas fa-tshirt" },
        { Name = "Rank", Label = "Minimale rang", Icon = "fas fa-tag", Choices = RankChoices },
    })

    if not Result or not Result.Name or #Result.Name == 0 then return end
    FW.SendCallback("fw-clothes:Server:SaveJobOutfit", Result.Name, Result.Rank)
end)

-- Facewear
RegisterNetEvent("fw-clothes:Client:ToggleFacewear")
AddEventHandler("fw-clothes:Client:ToggleFacewear", function(ComponentId, State, IsCommand, ItemInfo, ItemSlot)
    local TypeData = Config.ClothingTypes[ComponentId]
    if TypeData == nil then return end

    if ComponentId == 'Shoes' then
        Config.CurrentSkin.Clothes.Shoes[1] = State
        Config.CurrentSkin.Clothes.Shoes[2] = 0
        SetPedComponentVariation(PlayerPedId(), TypeData.Drawable, Config.CurrentSkin.Clothes[ComponentId][1], Config.CurrentSkin.Clothes[ComponentId][2], TypeData.ColorType or 0)
        FW.TriggerServer("fw-clothes:Server:SetOutfit", Config.CurrentSkin)
        return
    end

    if not State and Config.CurrentSkin.Clothes[ComponentId][1] == (TypeData.Prop ~= nil and -1 or 0) then
        return
    end

    if IsRemovingFacewear then return end
    IsRemovingFacewear = true

    local FacewearAnim = Config.FacewearAnimations[ComponentId]
    exports['fw-assets']:RequestAnimationDict(FacewearAnim[1])
    TaskPlayAnim(PlayerPedId(), FacewearAnim[1], FacewearAnim[2], 4.0, 3.0, GetAnimDuration(FacewearAnim[1], FacewearAnim[2]) * 1000, 49, 1.0, 0, 0, 0)
    Citizen.Wait(800)

    if ComponentId == 'Vest' and not IsCommand then
        return
    end

    if State then
        if ItemSlot then
            FW.TriggerServer("fw-clothes:Server:RemoveFacewear", ItemSlot)
        end

        Config.CurrentSkin.Clothes[ComponentId][1] = ItemInfo and ItemInfo.Prop or Config.CurrentSkin.Clothes[ComponentId][1]
        Config.CurrentSkin.Clothes[ComponentId][2] = ItemInfo and ItemInfo.Texture or Config.CurrentSkin.Clothes[ComponentId][2]

        if TypeData.Prop ~= nil then
            SetPedPropIndex(PlayerPedId(), TypeData.Prop, Config.CurrentSkin.Clothes[ComponentId][1], Config.CurrentSkin.Clothes[ComponentId][2], true)
        elseif TypeData.Drawable ~= nil then
            SetPedComponentVariation(PlayerPedId(), TypeData.Drawable, Config.CurrentSkin.Clothes[ComponentId][1], Config.CurrentSkin.Clothes[ComponentId][2], TypeData.ColorType or 0)
        end
    else
        if IsCommand then
            FW.TriggerServer("fw-clothes:Server:ReceiveFacewearItem", ComponentId, Config.CurrentSkin.Clothes[ComponentId])
        end

        if ComponentId ~= 'Vest' then
            Config.CurrentSkin.Clothes[ComponentId][1] = TypeData.Prop ~= nil and -1 or 0
            Config.CurrentSkin.Clothes[ComponentId][2] = 0
        end

        if TypeData.Prop ~= nil then
            ClearPedProp(PlayerPedId(), TypeData.Prop)
        elseif TypeData.Drawable ~= nil then
            SetPedComponentVariation(PlayerPedId(), TypeData.Drawable, 0, 0, TypeData.ColorType or 0)
        end
    end

    Citizen.Wait(ComponentId == 'Vest' and 1500 or ((GetAnimDuration(FacewearAnim[1], FacewearAnim[2]) * 1000) - 1000))
    ClearPedTasks(PlayerPedId())

    FW.TriggerServer("fw-clothes:Server:SetOutfit", Config.CurrentSkin)
    IsRemovingFacewear = false
end)

-- Called by fw-inventory whenever an Accessory (or backpack) slot changes.
-- ItemInfo = { Prop = drawable, Texture = texture } to wear it, false to take it off.
local IsAnimatingAccessory = false
RegisterNetEvent("fw-clothes:Client:SetAccessory")
AddEventHandler("fw-clothes:Client:SetAccessory", function(ComponentId, ItemInfo, Animate)
    local TypeData = Config.ClothingTypes[ComponentId]
    if TypeData == nil then return end
    if not Config.CurrentSkin or not Config.CurrentSkin.Clothes then return end -- Skin not loaded yet.

    if Config.CurrentSkin.Clothes[ComponentId] == nil then
        Config.CurrentSkin.Clothes[ComponentId] = { TypeData.Prop ~= nil and -1 or 0, 0 }
    end

    local Ped = PlayerPedId()
    local FacewearAnim = Config.FacewearAnimations[ComponentId]
    if Animate and FacewearAnim and not IsAnimatingAccessory and not IsPedInAnyVehicle(Ped, false) then
        IsAnimatingAccessory = true
        Citizen.CreateThread(function()
            exports['fw-assets']:RequestAnimationDict(FacewearAnim[1])
            TaskPlayAnim(Ped, FacewearAnim[1], FacewearAnim[2], 4.0, 3.0, GetAnimDuration(FacewearAnim[1], FacewearAnim[2]) * 1000, 49, 1.0, 0, 0, 0)
            Citizen.Wait(1200)
            StopAnimTask(Ped, FacewearAnim[1], FacewearAnim[2], 1.0)
            IsAnimatingAccessory = false
        end)
    end

    if ItemInfo then
        -- Items without Prop data (e.g. bought in a store) keep whatever the skin already had.
        if ItemInfo.Prop ~= nil then Config.CurrentSkin.Clothes[ComponentId][1] = ItemInfo.Prop end
        if ItemInfo.Texture ~= nil then Config.CurrentSkin.Clothes[ComponentId][2] = ItemInfo.Texture end

        if TypeData.Prop ~= nil then
            SetPedPropIndex(Ped, TypeData.Prop, Config.CurrentSkin.Clothes[ComponentId][1], Config.CurrentSkin.Clothes[ComponentId][2], true)
        elseif TypeData.Drawable ~= nil then
            SetPedComponentVariation(Ped, TypeData.Drawable, Config.CurrentSkin.Clothes[ComponentId][1], Config.CurrentSkin.Clothes[ComponentId][2], TypeData.ColorType or 0)
        end
    else
        Config.CurrentSkin.Clothes[ComponentId][1] = TypeData.Prop ~= nil and -1 or 0
        Config.CurrentSkin.Clothes[ComponentId][2] = 0

        if TypeData.Prop ~= nil then
            ClearPedProp(Ped, TypeData.Prop)
        elseif TypeData.Drawable ~= nil then
            SetPedComponentVariation(Ped, TypeData.Drawable, 0, 0, TypeData.ColorType or 0)
        end
    end

    FW.TriggerServer("fw-clothes:Server:SetOutfit", Config.CurrentSkin)
end)

-- Returns what is currently worn for a component, so items can store it.
exports("GetWornAccessory", function(ComponentId)
    if not Config.CurrentSkin or not Config.CurrentSkin.Clothes then return false end
    return Config.CurrentSkin.Clothes[ComponentId]
end)

-- Functions
function IsNearChangingRoom()
    for k, v in pairs(Config.ChangeRooms) do
        local Distance = #(GetEntityCoords(PlayerPedId()) - v.Coords)
        if Distance < 4.0 then
            return true
        end
    end
    return false
end

function RayCastGamePlayCamera(Distance)
    local CameraRotation = GetGameplayCamRot()
    local CameraCoord = GetGameplayCamCoord()
    local Direction = RotationToDirection(CameraRotation)
    local Destination = {x = CameraCoord.x + Direction.x * Distance, y = CameraCoord.y + Direction.y * Distance, z = CameraCoord.z + Direction.z * Distance}
    local A, B, C, D, E = GetShapeTestResult(StartShapeTestRay(CameraCoord.x, CameraCoord.y, CameraCoord.z, Destination.x, Destination.y, Destination.z, -1, PlayerPedId(), 0))
    return B, C, E
end

function RotationToDirection(Rotation)
    local RotX, RotZ = math.rad(Rotation.x), math.rad(Rotation.z)
    local CosOfRotX = math.abs(math.cos(RotX))
    return vector3(-math.sin(RotZ) * CosOfRotX, math.cos(RotZ) * CosOfRotX, math.sin(RotX))
end