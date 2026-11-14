-- MLO decoration menu (basic test version): buy + place furniture, walls and doors, move / remove them.
-- Uses from cl_mlo.lua: GetMloInsideHouseId, GetMloZone, GetMloDecorEntity, HousingRaycast, HousingLoadModel
local FW = exports['fw-core']:GetCoreObject()
local IsEditing = false

exports("IsDecorating", function() return IsEditing end)

-- // Helpers \\ --

local function IsInsideHouse(House)
    return House ~= nil and GetMloInsideHouseId() == House.Id
end

local function IsPlacementValid(House, Coords)
    if #(GetEntityCoords(PlayerPedId()) - Coords) > 12.0 then return false end
    local Zone = GetMloZone(House.Mlo)
    return Zone ~= nil and Zone:isPointInside(Coords)
end

local function GetItemLabel(Model)
    local Item = Config.DecorByModel[Model]
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

local function GetRefund(Model)
    local Item = Config.DecorByModel[Model]
    if not Config.Decorate.ChargeMoney or not Item then return 0 end
    return math.floor((Item.Price or 0) * (Config.Decorate.RefundPercentage or 0) / 100)
end

local UI = exports['fw-ui'] -- bottom-right key hints

local function SetOutline(Entity, State, R, G, B)
    if SetEntityDrawOutline == nil then return end -- older game builds
    SetEntityDrawOutline(Entity, State)
    if State then
        SetEntityDrawOutlineColor(R, G, B, 255)
        if SetEntityDrawOutlineShader then SetEntityDrawOutlineShader(1) end
    end
end

local DisabledControls = { 14, 15, 16, 17, 24, 25, 37, 44, 45, 47, 140, 141, 142, 172, 173, 174, 175, 177, 199, 200, 257, 261, 262 }
local function DisableEditorControls()
    for _, Control in ipairs(DisabledControls) do DisableControlAction(0, Control, true) end
end

local function SwallowInput()
    -- Stops ESC / right click from opening the pause menu right after leaving a mode.
    UI:HideKeyHints()
    local Release = GetGameTimer() + 300
    while GetGameTimer() < Release do DisableEditorControls() Citizen.Wait(0) end
end

local function Reopen(HouseId)
    Citizen.SetTimeout(450, function() OpenMloDecorateMenu(HouseId) end)
end

-- Models that don't exist in this game build are hidden (and printed once).
local ValidModelCache = {}
local function IsModelAvailable(Model)
    if ValidModelCache[Model] == nil then
        ValidModelCache[Model] = IsModelInCdimage(GetHashKey(Model)) == 1 or IsModelInCdimage(GetHashKey(Model)) == true
        if not ValidModelCache[Model] then
            print(("^3[fw-housing]^7 Decor model '%s' does not exist in your game, hidden from the menu."):format(Model))
        end
    end
    return ValidModelCache[Model]
end

-- // Placement mode \\ --

-- Returns Coords, Rot when confirmed, nil when cancelled.
local function RunPlacement(House, Model, Existing)
    local Hash = HousingLoadModel(Model)
    if not Hash then
        FW.Functions.Notify("This object could not be loaded.", "error")
        return
    end

    local Item = Config.DecorByModel[Model] or {}
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
    local Snap = Item.Type == 'wall' or Item.Type == 'door' -- walls/doors start with snapping on
    local Base = vector3(StartCoords.x, StartCoords.y, StartCoords.z + Min.z)
    local Result, LastInvalidNotify = nil, 0

    while true do
        Citizen.Wait(0)
        DisableEditorControls()

        if not IsInsideHouse(House) or IsEntityDead(Ped) then
            FW.Functions.Notify("You left the house.", "error")
            break
        end

        -- 1 = world, 16 = objects: so things can be stacked on tables etc.
        local Hit, EndCoords = HousingRaycast(Config.Decorate.MaxRayDistance, Ghost, 1 + 16)
        if Hit then Base = EndCoords end

        local Fine = IsControlPressed(0, 21) -- SHIFT
        local Step = Fine and 1.0 or Config.Decorate.RotateStep
        if IsDisabledControlJustPressed(0, 47) then -- G
            Snap = not Snap
            FW.Functions.Notify(Snap and "Snapping on." or "Snapping off.", "primary")
        end

        if Snap then
            if IsDisabledControlJustPressed(0, 15) or IsDisabledControlJustPressed(0, 174) then Heading = Heading + Config.Decorate.SnapAngle end
            if IsDisabledControlJustPressed(0, 14) or IsDisabledControlJustPressed(0, 175) then Heading = Heading - Config.Decorate.SnapAngle end
            Heading = math.floor((Heading / Config.Decorate.SnapAngle) + 0.5) * Config.Decorate.SnapAngle
        else
            if IsDisabledControlJustPressed(0, 15) then Heading = Heading + Step end -- scroll up
            if IsDisabledControlJustPressed(0, 14) then Heading = Heading - Step end -- scroll down
            if IsDisabledControlPressed(0, 174) then Heading = Heading + (Fine and 0.25 or 1.5) end -- arrow left
            if IsDisabledControlPressed(0, 175) then Heading = Heading - (Fine and 0.25 or 1.5) end -- arrow right
        end
        if IsDisabledControlPressed(0, 172) then Height = Height + Config.Decorate.HeightStep end -- arrow up
        if IsDisabledControlPressed(0, 173) then Height = Height - Config.Decorate.HeightStep end -- arrow down
        if IsDisabledControlJustPressed(0, 45) then Height = 0.0 end -- R
        Heading = Heading % 360.0

        local Pos = vector3(Base.x, Base.y, Base.z - Min.z + Height)
        SetEntityCoordsNoOffset(Ghost, Pos.x, Pos.y, Pos.z, false, false, false)
        SetEntityRotation(Ghost, StartRot.x, StartRot.y, Heading, 2, true)

        local Valid = IsPlacementValid(House, Pos)
        local R, G, B = Valid and 46 or 220, Valid and 204 or 53, Valid and 113 or 69
        SetOutline(Ghost, true, R, G, B)
        DrawMarker(25, Pos.x, Pos.y, Base.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, R, G, B, 140, false, false, 2, false, nil, nil, false)

        UI:ShowKeyHints({ { '', ('%s (%.0f°)'):format(GetItemLabel(Model), Heading) }, { 'LMB', 'Place' }, { 'SCROLL', 'Rotate' }, { 'SHIFT', 'Fine' }, { { 'UP', 'DOWN' }, 'Height' }, { 'R', 'Reset' }, { 'G', Snap and 'Snap on' or 'Snap off' }, { 'BACKSPACE', 'Cancel' } })

        if IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 191) then -- LMB / ENTER
            if Valid then
                Result = { Coords = Pos, Rot = vector3(StartRot.x, StartRot.y, Heading) }
                break
            elseif GetGameTimer() - LastInvalidNotify > 1500 then
                LastInvalidNotify = GetGameTimer()
                FW.Functions.Notify("You can only place objects inside the house.", "error")
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

    SwallowInput()
    IsEditing = false

    if Result then return Result.Coords, Result.Rot end
end

-- // Select mode (look at an object) \\ --

local function FindDecorByEntity(House, Entity)
    if not Entity or Entity == 0 then return end
    for _, v in ipairs(House.Decorations or {}) do
        if GetMloDecorEntity(v.Id) == Entity then return v end
    end
end

local function RunSelect(House)
    IsEditing = true
    local HoveredEntity = nil

    while true do
        Citizen.Wait(0)
        DisableEditorControls()
        if not IsInsideHouse(House) then break end

        House = Config.Houses[House.Id] or House
        local _, _, Entity = HousingRaycast(Config.Decorate.MaxRayDistance, PlayerPedId(), 16)
        local Decor = FindDecorByEntity(House, Entity)

        if HoveredEntity and HoveredEntity ~= Entity and DoesEntityExist(HoveredEntity) then SetOutline(HoveredEntity, false) end
        HoveredEntity = Decor and Entity or nil
        if HoveredEntity then SetOutline(HoveredEntity, true, 52, 152, 219) end

        if Decor then
            local Refund = GetRefund(Decor.Model)
            UI:ShowKeyHints({ { '', GetItemLabel(Decor.Model) }, { 'LMB', 'Move' }, { 'X', Refund > 0 and ('Remove (+' .. FormatMoney(Refund) .. ')') or 'Remove' }, { 'BACKSPACE', 'Back' } })
        else
            UI:ShowKeyHints({ { '', 'Look at an object you placed' }, { 'BACKSPACE', 'Back' } })
        end

        if Decor and IsDisabledControlJustPressed(0, 24) then
            SetOutline(HoveredEntity, false)
            local Coords, Rot = RunPlacement(House, Decor.Model, HoveredEntity)
            if Coords then
                TriggerServerEvent("fw-housing:Server:Decor:Update", House.Id, Decor.Id, Coords, Rot)
            end
            IsEditing = true
            Citizen.Wait(250)
        elseif Decor and IsControlJustPressed(0, 73) then -- X
            SetOutline(HoveredEntity, false)
            TriggerServerEvent("fw-housing:Server:Decor:Remove", House.Id, Decor.Id)
            HoveredEntity = nil
            Citizen.Wait(250)
        end

        if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 25) then
            break
        end
    end

    if HoveredEntity and DoesEntityExist(HoveredEntity) then SetOutline(HoveredEntity, false) end
    SwallowInput()
    IsEditing = false
end

-- // Menu \\ --

local function BuildCatalog(HouseId, TypeFilter)
    local Categories = {}
    for _, Category in ipairs(Config.DecorCatalog) do
        if TypeFilter(Category.Type) then
            local Items = {}
            for _, Item in ipairs(Category.Items) do
                if IsModelAvailable(Item.Model) then
                    Items[#Items + 1] = {
                        Title = Item.Label,
                        Desc = Config.Decorate.ChargeMoney and FormatMoney(Item.Price or 0) or 'Free (test)',
                        CloseMenu = true,
                        Data = { Event = 'fw-housing:Client:Decor:StartPlace', Type = 'Client', HouseId = HouseId, Model = Item.Model },
                    }
                end
            end
            if #Items > 0 then
                Categories[#Categories + 1] = { Title = Category.Category, Icon = Category.Icon, Desc = #Items .. ' items', SecondMenu = Items }
            end
        end
    end
    return Categories
end

function OpenMloDecorateMenu(HouseId)
    if IsEditing then return end
    HouseId = HouseId or GetMloInsideHouseId()

    local House = HouseId and Config.Houses and Config.Houses[HouseId]
    if not House or not House.Mlo then
        return FW.Functions.Notify("You need to be inside your house to decorate.", "error")
    end

    if not IsInsideHouse(House) then
        return FW.Functions.Notify("You need to be inside the house to decorate.", "error")
    end

    if not FW.SendCallback("fw-housing:Server:Decor:CanDecorate", HouseId) then
        return FW.Functions.Notify("You don't have permission to decorate this house.", "error")
    end

    local Decorations = House.Decorations or {}
    local Max = Config.MLOHouses[House.Mlo].MaxDecorations or 100
    local IsFull = #Decorations >= Max

    -- Placed list, closest first
    local PlyCoords, Placed, Sorted = GetEntityCoords(PlayerPedId()), {}, {}
    for _, v in ipairs(Decorations) do Sorted[#Sorted + 1] = v end
    table.sort(Sorted, function(A, B)
        return #(PlyCoords - vector3(A.Coords.x, A.Coords.y, A.Coords.z)) < #(PlyCoords - vector3(B.Coords.x, B.Coords.y, B.Coords.z))
    end)

    for _, v in ipairs(Sorted) do
        local Refund = GetRefund(v.Model)
        Placed[#Placed + 1] = {
            Title = GetItemLabel(v.Model),
            Desc = ("%.1fm away"):format(#(PlyCoords - vector3(v.Coords.x, v.Coords.y, v.Coords.z))),
            SecondMenu = {
                { Title = 'Move', Icon = 'arrows-alt', CloseMenu = true, Data = { Event = 'fw-housing:Client:Decor:StartMove', Type = 'Client', HouseId = HouseId, DecorId = v.Id } },
                { Title = 'Remove' .. (Refund > 0 and (' (+' .. FormatMoney(Refund) .. ')') or ''), Icon = 'trash', CloseMenu = true, Data = { Event = 'fw-housing:Client:Decor:Remove', Type = 'Client', HouseId = HouseId, DecorId = v.Id } },
            },
        }
    end

    local MenuItems = {
        { Title = 'Decorate: ' .. House.Adress, Desc = ('%d / %d objects placed'):format(#Decorations, Max), CloseMenu = false },
        { Title = 'Furniture', Icon = 'couch', Desc = 'Seating, tables, beds, electronics..', SecondMenu = BuildCatalog(HouseId, function(T) return T == 'furniture' end), Disabled = IsFull },
        { Title = 'Walls', Icon = 'border-all', Desc = 'Split the house into rooms', SecondMenu = BuildCatalog(HouseId, function(T) return T == 'wall' end), Disabled = IsFull },
        { Title = 'Doors', Icon = 'door-open', Desc = 'Doors that can be opened / closed', SecondMenu = BuildCatalog(HouseId, function(T) return T == 'door' end), Disabled = IsFull },
        { Title = 'Select by looking', Icon = 'crosshairs', Desc = 'Aim at an object to move or remove it', CloseMenu = true, Data = { Event = 'fw-housing:Client:Decor:StartSelect', Type = 'Client', HouseId = HouseId }, Disabled = #Decorations == 0 },
        { Title = 'Placed objects', Icon = 'list', SecondMenu = Placed, Disabled = #Decorations == 0 },
        { Title = 'Garage', Icon = 'warehouse', Desc = ('Stand outside (max %.0fm from the house) and use /mlogarage'):format(Config.MLOGarage.MaxDistanceFromZone), CloseMenu = false },
    }

    FW.Functions.OpenMenu({ MainMenuItems = MenuItems })
end
exports("OpenMloDecorateMenu", OpenMloDecorateMenu)

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

    local Coords, Rot = RunPlacement(House, Decor.Model, GetMloDecorEntity(Decor.Id))
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

RegisterCommand("decorate", function()
    OpenMloDecorateMenu(GetMloInsideHouseId())
end, false)
