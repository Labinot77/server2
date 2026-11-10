-- Furniture editor: buy, place, move and remove decorations (MLO + shell houses).
local FW = exports['fw-core']:GetCoreObject()
local IsEditing = false

exports("IsDecorating", function() return IsEditing end)

-- // Helpers \\ --

local function IsInsideHouse(House)
    if House.Mlo then return MloInsideHouseId == House.Id end
    local Current = GetHousingCurrentHouse()
    return IsInsideShell() and Current ~= nil and Current.Id == House.Id
end

local function IsPlacementValid(House, Coords)
    if #(GetEntityCoords(PlayerPedId()) - Coords) > 12.0 then return false end

    if House.Mlo then
        local Zone = GetMloZone(House.Mlo)
        return Zone ~= nil and Zone:isPointInside(Coords)
    end

    if Coords.z > -50.0 then return false end
    return #(vector2(Coords.x, Coords.y) - vector2(House.Coords.x, House.Coords.y)) <= Config.Decorate.ShellMaxDistance
end

local function GetDecorEntity(House, DecorId)
    if House.Mlo then return GetMloDecorEntity(House.Id, DecorId) end
    return GetShellDecorEntity(DecorId)
end

local function GetItemLabel(Model)
    local Item = Config.FurnitureByModel[Model]
    return Item and Item.Label or tostring(Model)
end

local function FormatMoney(Amount)
    local Formatted = tostring(math.floor(Amount))
    while true do
        local New, Count = Formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        Formatted = New
        if Count == 0 then break end
    end
    return '$' .. Formatted
end

-- AddTextEntry instead of a STRING component: components are truncated at 99 characters.
local LastHelpText = nil
local function ShowHelp(Text)
    if Text ~= LastHelpText then
        LastHelpText = Text
        AddTextEntry('FW_HOUSING_DECOR_HELP', Text)
    end
    BeginTextCommandDisplayHelp('FW_HOUSING_DECOR_HELP')
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function SetOutline(Entity, State, R, G, B)
    if SetEntityDrawOutline == nil then return end -- older game builds
    SetEntityDrawOutline(Entity, State)
    if State then
        SetEntityDrawOutlineColor(R, G, B, 255)
        if SetEntityDrawOutlineShader then SetEntityDrawOutlineShader(1) end
    end
end

local DisabledControls = { 14, 15, 16, 17, 24, 25, 37, 44, 45, 140, 141, 142, 172, 173, 174, 175, 177, 199, 200, 257, 261, 262 }
local function DisableEditorControls()
    for _, Control in ipairs(DisabledControls) do DisableControlAction(0, Control, true) end
end

local function Reopen(HouseId)
    Citizen.SetTimeout(450, function() OpenDecorateMenu(HouseId) end)
end

-- // Placement mode \\ --

-- Returns Coords, Rot when confirmed, nil when cancelled.
local function RunPlacement(House, Model, Existing)
    local Hash = HousingLoadModel(Model)
    if not Hash then
        FW.Functions.Notify("This object could not be loaded.", "error")
        return
    end

    local Ped = PlayerPedId()
    local Min = GetModelDimensions(Hash)
    local StartCoords = Existing and GetEntityCoords(Existing) or GetOffsetFromEntityInWorldCoords(Ped, 0.0, 1.5, 0.0)
    local StartRot = Existing and GetEntityRotation(Existing, 2) or vector3(0.0, 0.0, GetEntityHeading(Ped))

    local Ghost = CreateObjectNoOffset(Hash, StartCoords.x, StartCoords.y, StartCoords.z, false, false, false)
    SetEntityCollision(Ghost, false, false)
    SetEntityAlpha(Ghost, 200, false)
    FreezeEntityPosition(Ghost, true)
    SetModelAsNoLongerNeeded(Hash)

    if Existing and DoesEntityExist(Existing) then
        SetEntityVisible(Existing, false, false)
        SetEntityCollision(Existing, false, false)
    end

    IsEditing = true
    local Heading, Height = StartRot.z, 0.0
    local Base = vector3(StartCoords.x, StartCoords.y, StartCoords.z + Min.z)
    local Result, LastInvalidNotify = nil, 0

    while true do
        Citizen.Wait(0)
        DisableEditorControls()

        if not IsInsideHouse(House) or IsEntityDead(Ped) then break end

        local Hit, EndCoords = HousingRaycast(Config.Decorate.MaxRayDistance, Ghost, 1 + 16)
        if Hit then Base = EndCoords end

        local Fine = IsControlPressed(0, 21) -- SHIFT
        local Step = Fine and 1.0 or Config.Decorate.RotateStep
        if IsDisabledControlJustPressed(0, 15) then Heading = Heading + Step end -- scroll up
        if IsDisabledControlJustPressed(0, 14) then Heading = Heading - Step end -- scroll down
        if IsDisabledControlPressed(0, 174) then Heading = Heading + (Fine and 0.25 or 1.5) end -- arrow left
        if IsDisabledControlPressed(0, 175) then Heading = Heading - (Fine and 0.25 or 1.5) end -- arrow right
        if IsDisabledControlPressed(0, 172) then Height = Height + Config.Decorate.HeightStep end -- arrow up
        if IsDisabledControlPressed(0, 173) then Height = Height - Config.Decorate.HeightStep end -- arrow down
        if IsControlJustPressed(0, 45) or IsDisabledControlJustPressed(0, 45) then Height = 0.0 end -- R: reset height
        Heading = Heading % 360.0

        local Pos = vector3(Base.x, Base.y, Base.z - Min.z + Height)
        SetEntityCoordsNoOffset(Ghost, Pos.x, Pos.y, Pos.z, false, false, false)
        SetEntityRotation(Ghost, StartRot.x, StartRot.y, Heading, 2, true)

        local Valid = IsPlacementValid(House, Pos)
        SetOutline(Ghost, true, Valid and 46 or 220, Valid and 204 or 53, Valid and 113 or 69)
        DrawMarker(25, Pos.x, Pos.y, Base.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, Valid and 46 or 220, Valid and 204 or 53, Valid and 113 or 69, 140, false, false, 2, false, nil, nil, false)

        ShowHelp(("~b~%s~s~~n~~INPUT_ATTACK~ Place~n~~INPUT_CELLPHONE_CANCEL~ Cancel~n~~INPUT_WEAPON_WHEEL_NEXT~ / ~INPUT_CELLPHONE_LEFT~ ~INPUT_CELLPHONE_RIGHT~ Rotate (~INPUT_SPRINT~ fine)~n~~INPUT_CELLPHONE_UP~ ~INPUT_CELLPHONE_DOWN~ Height  ~INPUT_RELOAD~ Reset height"):format(GetItemLabel(Model)))

        if IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 191) then
            if Valid then
                Result = { Coords = Pos, Rot = vector3(StartRot.x, StartRot.y, Heading) }
                break
            elseif GetGameTimer() - LastInvalidNotify > 1500 then
                LastInvalidNotify = GetGameTimer()
                FW.Functions.Notify("You can only place furniture inside the house.", "error")
            end
        end

        if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 25) then
            break
        end
    end

    DeleteEntity(Ghost)
    if Existing and DoesEntityExist(Existing) then
        SetEntityVisible(Existing, true, false)
        SetEntityCollision(Existing, true, true)
    end

    -- Swallow the key press so ESC doesn't open the pause menu right after cancelling.
    local Release = GetGameTimer() + 300
    while GetGameTimer() < Release do DisableEditorControls() Citizen.Wait(0) end
    IsEditing = false

    if Result then return Result.Coords, Result.Rot end
end

-- // Select mode (look at an object) \\ --

local function FindDecorByEntity(House, Entity)
    if not Entity or Entity == 0 then return end
    for _, v in ipairs(House.Decorations or {}) do
        if GetDecorEntity(House, v.Id) == Entity then return v end
    end
end

local function RunSelect(House)
    IsEditing = true
    local Hovered, HoveredEntity = nil, nil

    while true do
        Citizen.Wait(0)
        DisableEditorControls()
        if not IsInsideHouse(House) then break end

        House = Config.Houses[House.Id] or House
        local _, _, Entity = HousingRaycast(Config.Decorate.MaxRayDistance, PlayerPedId(), 16)
        local Decor = FindDecorByEntity(House, Entity)

        if HoveredEntity and HoveredEntity ~= Entity and DoesEntityExist(HoveredEntity) then SetOutline(HoveredEntity, false) end
        Hovered, HoveredEntity = Decor, Decor and Entity or nil
        if HoveredEntity then SetOutline(HoveredEntity, true, 52, 152, 219) end

        if Hovered then
            local Item = Config.FurnitureByModel[Hovered.Model]
            local Refund = (Config.Decorate.ChargeMoney and Item) and math.floor((Item.Price or 0) * (Config.Decorate.RefundPercentage or 0) / 100) or 0
            ShowHelp(("~b~%s~s~~n~~INPUT_ATTACK~ Move~n~~INPUT_VEH_DUCK~ Remove%s~n~~INPUT_CELLPHONE_CANCEL~ Back"):format(GetItemLabel(Hovered.Model), Refund > 0 and (" (+" .. FormatMoney(Refund) .. ")") or ""))
        else
            ShowHelp("Look at a piece of furniture.~n~~INPUT_CELLPHONE_CANCEL~ Back")
        end

        if Hovered and IsDisabledControlJustPressed(0, 24) then
            SetOutline(HoveredEntity, false)
            IsEditing = false
            local Coords, Rot = RunPlacement(House, Hovered.Model, HoveredEntity)
            if Coords then
                TriggerServerEvent("fw-housing:Server:Decor:Update", House.Id, Hovered.Id, Coords, Rot)
            end
            IsEditing = true
            Citizen.Wait(250)
        elseif Hovered and IsControlJustPressed(0, 73) then -- X
            SetOutline(HoveredEntity, false)
            TriggerServerEvent("fw-housing:Server:Decor:Remove", House.Id, Hovered.Id)
            Hovered, HoveredEntity = nil, nil
            Citizen.Wait(250)
        end

        if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 25) then
            break
        end
    end

    if HoveredEntity and DoesEntityExist(HoveredEntity) then SetOutline(HoveredEntity, false) end
    local Release = GetGameTimer() + 300
    while GetGameTimer() < Release do DisableEditorControls() Citizen.Wait(0) end
    IsEditing = false
end

-- // Menu \\ --

function OpenDecorateMenu(HouseId)
    if IsEditing then return end
    if not HouseId or Config.Houses == nil or not Config.Houses[HouseId] then
        return FW.Functions.Notify("You need to be inside a house to decorate.", "error")
    end

    local House = Config.Houses[HouseId]
    if not IsInsideHouse(House) then
        return FW.Functions.Notify("You need to be inside the house to decorate.", "error")
    end

    if not FW.SendCallback("fw-housing:Server:Decor:CanDecorate", HouseId) then
        return FW.Functions.Notify("You don't have permission to decorate this house.", "error")
    end

    local Decorations = House.Decorations or {}
    local Max = House.Mlo and (Config.MLOHouses[House.Mlo].MaxDecorations or 100) or 100

    -- Shop
    local Shop = {}
    for _, Category in ipairs(Config.Furniture) do
        local Items = {}
        for _, Item in ipairs(Category.Items) do
            Items[#Items + 1] = {
                Title = Item.Label,
                Desc = Config.Decorate.ChargeMoney and FormatMoney(Item.Price or 0) or nil,
                Data = { Event = 'fw-housing:Client:Decor:StartPlace', HouseId = HouseId, Model = Item.Model },
            }
        end
        Shop[#Shop + 1] = { Title = Category.Category, Icon = Category.Icon, SecondMenu = Items }
    end

    -- Placed list, closest first
    local PlyCoords, Placed = GetEntityCoords(PlayerPedId()), {}
    local Sorted = {}
    for _, v in ipairs(Decorations) do Sorted[#Sorted + 1] = v end
    table.sort(Sorted, function(A, B)
        return #(PlyCoords - vector3(A.Coords.x, A.Coords.y, A.Coords.z)) < #(PlyCoords - vector3(B.Coords.x, B.Coords.y, B.Coords.z))
    end)

    for _, v in ipairs(Sorted) do
        local Item = Config.FurnitureByModel[v.Model]
        local Refund = (Config.Decorate.ChargeMoney and Item) and math.floor((Item.Price or 0) * (Config.Decorate.RefundPercentage or 0) / 100) or 0
        Placed[#Placed + 1] = {
            Title = GetItemLabel(v.Model),
            Desc = ("%.1fm away"):format(#(PlyCoords - vector3(v.Coords.x, v.Coords.y, v.Coords.z))),
            SecondMenu = {
                { Title = 'Move', Icon = 'arrows-alt', Data = { Event = 'fw-housing:Client:Decor:StartMove', HouseId = HouseId, DecorId = v.Id } },
                { Title = 'Remove' .. (Refund > 0 and (' (+' .. FormatMoney(Refund) .. ')') or ''), Icon = 'trash', Data = { Event = 'fw-housing:Client:Decor:Remove', HouseId = HouseId, DecorId = v.Id } },
            },
        }
    end

    local MenuItems = {
        { Title = 'Decorate: ' .. House.Adress, Desc = ('%d / %d objects placed'), CloseMenu = false },
        { Title = 'Buy furniture', Icon = 'shopping-cart', SecondMenu = Shop, Disabled = #Decorations >= Max },
        { Title = 'Select by looking', Icon = 'crosshairs', Desc = 'Aim at furniture to move or remove it', Data = { Event = 'fw-housing:Client:Decor:StartSelect', HouseId = HouseId }, Disabled = #Decorations == 0 },
        { Title = 'Placed furniture', Icon = 'list', SecondMenu = Placed, Disabled = #Decorations == 0 },
    }
    MenuItems[1].Desc = MenuItems[1].Desc:format(#Decorations, Max)

    FW.Functions.OpenMenu({ MainMenuItems = MenuItems })
end
exports("OpenDecorateMenu", OpenDecorateMenu)

-- // Menu events \\ --

RegisterNetEvent("fw-housing:Client:Decor:StartPlace")
AddEventHandler("fw-housing:Client:Decor:StartPlace", function(Data)
    local House = Config.Houses[Data.HouseId]
    if not House or IsEditing then return end

    local Coords, Rot = RunPlacement(House, Data.Model)
    if Coords then
        TriggerServerEvent("fw-housing:Server:Decor:Add", Data.HouseId, Data.Model, Coords, Rot)
    end
    Reopen(Data.HouseId)
end)

RegisterNetEvent("fw-housing:Client:Decor:StartMove")
AddEventHandler("fw-housing:Client:Decor:StartMove", function(Data)
    local House = Config.Houses[Data.HouseId]
    if not House or IsEditing then return end

    local Decor = nil
    for _, v in ipairs(House.Decorations or {}) do
        if v.Id == Data.DecorId then Decor = v break end
    end
    if not Decor then return end

    local Coords, Rot = RunPlacement(House, Decor.Model, GetDecorEntity(House, Decor.Id))
    if Coords then
        TriggerServerEvent("fw-housing:Server:Decor:Update", Data.HouseId, Decor.Id, Coords, Rot)
    end
    Reopen(Data.HouseId)
end)

RegisterNetEvent("fw-housing:Client:Decor:Remove")
AddEventHandler("fw-housing:Client:Decor:Remove", function(Data)
    TriggerServerEvent("fw-housing:Server:Decor:Remove", Data.HouseId, Data.DecorId)
    Reopen(Data.HouseId)
end)

RegisterNetEvent("fw-housing:Client:Decor:StartSelect")
AddEventHandler("fw-housing:Client:Decor:StartSelect", function(Data)
    local House = Config.Houses[Data.HouseId]
    if not House or IsEditing then return end

    RunSelect(House)
    Reopen(Data.HouseId)
end)
