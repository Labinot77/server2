-- Admin house creator (/housecreator): zone, front / back doors (fw-doors), spawn, surfaces and details.
-- Saved on the server in the `mlo_houses` table (sv_mlo.lua), every client gets the house right away.
local FW = exports['fw-core']:GetCoreObject()

local Draft, DraftKey, Tool = nil, nil, nil
local COLOR = { 149, 239, 119 }
local OpenDraftMenu

local function Blank()
    return { Label = '', Price = 250000, Class = 2, MaxDecorations = 150, Height = 4.5, Stash = { Slots = 40, Weight = 1000 },
        Zone = { points = {} }, FrontDoor = { Doors = {} }, BackDoor = { Doors = {} } }
end

local function Ev(Name, Args)
    Args = Args or {}
    Args.Event, Args.Type = 'fw-housing:Client:Creator:' .. Name, 'Client'
    return Args
end

local function Reopen() SetTimeout(250, function() if Draft then OpenDraftMenu() end end) end

local function Help(Text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(Text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function Input(Fields)
    Wait(100)
    return exports['fw-ui']:CreateInput(Fields)
end

local function Split(Text)
    local List = {}
    for Part in tostring(Text or ''):gmatch('[^,%s]+') do List[#List + 1] = Part end
    return List
end

-- // Drawing the draft (zone, doors, spawn) \\ --

local function Marker(C, Size, Col)
    DrawMarker(28, C.x, C.y, C.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Size, Size, Size, Col[1], Col[2], Col[3], 200, false, false, 2, false, nil, nil, false)
end

local function DrawDraft()
    local Z, P = Draft.Zone, Draft.Zone.points
    local Ped = GetEntityCoords(PlayerPedId())
    local Min = Z.minZ or Ped.z - 1.0
    local Max = Z.maxZ or Min + Draft.Height
    for I = 1, #P do
        local A, B = P[I], P[I % #P + 1]
        if #P > 1 then
            DrawLine(A.x, A.y, Min, B.x, B.y, Min, COLOR[1], COLOR[2], COLOR[3], 255)
            DrawLine(A.x, A.y, Max, B.x, B.y, Max, COLOR[1], COLOR[2], COLOR[3], 255)
        end
        DrawLine(A.x, A.y, Min, A.x, A.y, Max, COLOR[1], COLOR[2], COLOR[3], 255)
    end
    for _, D in ipairs(Draft.FrontDoor.Doors) do Marker(D.Coords, 0.25, COLOR) end
    for _, D in ipairs(Draft.BackDoor.Doors) do Marker(D.Coords, 0.25, { 242, 163, 101 }) end
    if Draft.Spawn then Marker(Draft.Spawn, 0.3, { 70, 140, 240 }) end
end

local function StartDrawing()
    Citizen.CreateThread(function()
        while Draft do
            DrawDraft()
            Citizen.Wait(0)
        end
    end)
end

-- // Tools \\ --

local function ZoneTool()
    Tool = 'zone'
    Citizen.CreateThread(function()
        while Tool == 'zone' and Draft do
            local Hit, Coords = HousingRaycast(30.0)
            if Hit then Marker(Coords, 0.12, { 255, 255, 255 }) end
            Help(('~INPUT_CONTEXT~ add point  ~INPUT_VEH_DUCK~ undo  ~INPUT_CELLPHONE_UP~ ~INPUT_CELLPHONE_DOWN~ height (%.2fm)  ~INPUT_FRONTEND_ACCEPT~ done'):format(Draft.Height))
            DisableControlAction(0, 73, true)
            local Z = Draft.Zone
            if IsControlJustPressed(0, 38) and Hit then
                table.insert(Z.points, { x = Coords.x, y = Coords.y, z = Coords.z })
                Z.minZ = math.min(Z.minZ or 1e9, Coords.z - 0.5)
                Z.maxZ = Z.minZ + Draft.Height
            elseif IsDisabledControlJustPressed(0, 73) and #Z.points > 0 then
                table.remove(Z.points)
            elseif IsControlJustPressed(0, 172) or IsControlJustPressed(0, 173) then
                Draft.Height = math.max(1.0, Draft.Height + (IsControlJustPressed(0, 172) and 0.25 or -0.25))
                if Z.minZ then Z.maxZ = Z.minZ + Draft.Height end
            elseif IsControlJustPressed(0, 191) then
                Tool = nil
            end
            Citizen.Wait(0)
        end
        Reopen()
    end)
end

local function DoorTool(Side)
    Tool = 'door'
    local Doors = Draft[Side].Doors
    Citizen.CreateThread(function()
        local Last
        while Tool == 'door' and Draft do
            local Hit, _, Entity = HousingRaycast(10.0)
            local IsObject = Hit and Entity ~= 0 and GetEntityType(Entity) == 3
            if Last and Last ~= Entity and DoesEntityExist(Last) then SetEntityDrawOutline(Last, false) end
            if IsObject then
                SetEntityDrawOutline(Entity, true)
                SetEntityDrawOutlineColor(COLOR[1], COLOR[2], COLOR[3], 255)
                Last = Entity
            end
            Help(('Look at the %s door (%d/2)  ~INPUT_CONTEXT~ select  ~INPUT_FRONTEND_ACCEPT~ done'):format(Side == 'FrontDoor' and 'front' or 'back', #Doors))
            if IsControlJustPressed(0, 38) and IsObject then
                local C = GetEntityCoords(Entity)
                local Dupe = false
                for _, D in ipairs(Doors) do if #(vector3(D.Coords.x, D.Coords.y, D.Coords.z) - C) < 0.1 then Dupe = true end end
                if not Dupe then Doors[#Doors + 1] = { Model = GetEntityModel(Entity), Coords = { x = C.x, y = C.y, z = C.z } } end
                if #Doors >= 2 then Tool = nil end
            elseif IsControlJustPressed(0, 191) then
                Tool = nil
            end
            Citizen.Wait(0)
        end
        if Last and DoesEntityExist(Last) then SetEntityDrawOutline(Last, false) end
        Reopen()
    end)
end

-- // Menus \\ --

OpenDraftMenu = function()
    if not Draft then return end
    local Z, CanSave = Draft.Zone, #Draft.Zone.points >= 3 and #Draft.FrontDoor.Doors > 0 and Draft.Label ~= ''
    local S = Draft.Surfaces or {}
    local function DoorMenu(Side)
        return {
            { Title = 'Pick door(s)', Desc = 'Look at the door, E to select (2 for a double door)', CloseMenu = true, Data = Ev('Tool', { Tool = 'door', Side = Side }) },
            { Title = 'Clear', CloseMenu = true, Data = Ev('Clear', { What = Side }) },
        }
    end

    FW.Functions.OpenMenu({ MainMenuItems = {
        { Title = (DraftKey and 'Edit: ' or 'New house: ') .. (Draft.Label ~= '' and Draft.Label or '(no name)'), Desc = DraftKey or 'Not saved yet' },
        { Title = 'Details', Icon = 'pen', Desc = ('$%s · class %s · %s objects'):format(Draft.Price, Draft.Class, Draft.MaxDecorations), CloseMenu = true, Data = Ev('Details') },
        { Title = 'Zone', Icon = 'draw-polygon', Desc = ('%d points · %.2fm high'):format(#Z.points, Draft.Height), SecondMenu = {
            { Title = 'Draw / add points', Desc = 'Walk the corners of the interior, E on the floor', CloseMenu = true, Data = Ev('Tool', { Tool = 'zone' }) },
            { Title = 'Clear points', CloseMenu = true, Data = Ev('Clear', { What = 'Zone' }) },
        } },
        { Title = 'Front door', Icon = 'door-closed', Desc = #Draft.FrontDoor.Doors .. ' / 2 doors (required)', SecondMenu = DoorMenu('FrontDoor') },
        { Title = 'Back door', Icon = 'door-open', Desc = #Draft.BackDoor.Doors .. ' / 2 doors (optional)', SecondMenu = DoorMenu('BackDoor') },
        { Title = 'Spawn point', Icon = 'street-view', Desc = Draft.Spawn and 'Set' or 'Not set (zone centre)', CloseMenu = true, Data = Ev('Spawn') },
        { Title = 'Surfaces', Icon = 'paint-roller', Desc = S.Txd and S.Txd or 'None (no wall / floor colours)', CloseMenu = true, Data = Ev('Surfaces') },
        { Title = 'Stash', Icon = 'box', Desc = ('%s slots · %s weight'):format(Draft.Stash.Slots, Draft.Stash.Weight), CloseMenu = true, Data = Ev('Stash') },
        { Title = 'Save house', Icon = 'save', Desc = CanSave and 'Creates / updates the house, doors get locked' or 'Needs a name, 3 zone points and a front door', Disabled = not CanSave, CloseMenu = true, Data = Ev('Save') },
        { Title = 'Discard draft', Icon = 'trash', CloseMenu = true, Data = Ev('Discard') },
    } })
end

local function OpenRootMenu()
    if Draft then return OpenDraftMenu() end
    local List = FW.SendCallback("fw-housing:Server:Creator:List")
    if not List then return end

    local Houses = {}
    for _, H in ipairs(List) do
        local Sub = {
            { Title = 'Edit', Icon = 'pen', CloseMenu = true, Data = Ev('Edit', { Key = H.Key, Def = H.Data, Dynamic = H.Dynamic }) },
            { Title = 'Teleport', Icon = 'location-arrow', CloseMenu = true, Data = Ev('Teleport', { Def = H.Data }) },
            { Title = 'Test: buy it', Icon = 'key', Desc = '/buymlo ' .. H.Key, CloseMenu = true, Data = Ev('Command', { Command = 'buymlo ' .. H.Key }) },
            { Title = 'Test: reset owner', Icon = 'undo', Desc = '/sellmlo ' .. H.Key, CloseMenu = true, Data = Ev('Command', { Command = 'sellmlo ' .. H.Key }) },
        }
        if H.Dynamic then
            Sub[#Sub + 1] = { Title = 'Delete', Icon = 'trash', SecondMenu = {
                { Title = 'Yes, delete ' .. H.Label, Desc = 'Removes the house, its furniture and doors', CloseMenu = true, Data = Ev('Delete', { Key = H.Key }) },
            } }
        end
        Houses[#Houses + 1] = { Title = H.Label, Desc = ('%s · $%s · %s%s'):format(H.Key, H.Price or 0, H.Owned and 'owned' or 'for sale', H.Dynamic and '' or ' · config'), SecondMenu = Sub }
    end

    FW.Functions.OpenMenu({ MainMenuItems = {
        { Title = 'House creator', Desc = #List .. ' MLO houses' },
        { Title = 'Create new house', Icon = 'plus', Desc = 'Stand inside the empty MLO', CloseMenu = true, Data = Ev('New') },
        { Title = 'Houses', Icon = 'list', SecondMenu = Houses, Disabled = #Houses == 0 },
    } })
end

-- // Menu events \\ --

local function On(Name, Fn) RegisterNetEvent('fw-housing:Client:Creator:' .. Name, Fn) end

On('Open', OpenRootMenu)

On('New', function()
    Draft, DraftKey = Blank(), nil
    StartDrawing()
    Reopen()
end)

On('Edit', function(D)
    Draft, DraftKey = D.Def, D.Key
    Draft.FrontDoor = Draft.FrontDoor or { Doors = {} }
    Draft.BackDoor = Draft.BackDoor or { Doors = {} }
    Draft.Stash = Draft.Stash or { Slots = 40, Weight = 1000 }
    Draft.Height = (Draft.Zone.maxZ or 0) - (Draft.Zone.minZ or 0)
    if not D.Dynamic then FW.Functions.Notify("Saving stores this config house in the database, the database copy wins from now on.", "primary") end
    StartDrawing()
    Reopen()
end)

On('Teleport', function(D)
    local Def, X, Y = D.Def, 0.0, 0.0
    for _, P in ipairs(Def.Zone.points) do X, Y = X + P.x, Y + P.y end
    local C = Def.Spawn or { x = X / #Def.Zone.points, y = Y / #Def.Zone.points, z = Def.Zone.minZ + 1.0, w = 0.0 }
    SetEntityCoords(PlayerPedId(), C.x, C.y, C.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), C.w or 0.0)
end)

On('Command', function(D) ExecuteCommand(D.Command) end)
On('Delete', function(D) TriggerServerEvent("fw-housing:Server:Creator:Delete", D.Key) end)

On('Tool', function(D)
    if D.Tool == 'zone' then ZoneTool() else DoorTool(D.Side) end
end)

On('Clear', function(D)
    if D.What == 'Zone' then Draft.Zone = { points = {} } else Draft[D.What].Doors = {} end
    Reopen()
end)

On('Spawn', function()
    local C = GetEntityCoords(PlayerPedId())
    Draft.Spawn = { x = C.x, y = C.y, z = C.z, w = GetEntityHeading(PlayerPedId()) }
    Reopen()
end)

On('Details', function()
    local R = Input({
        { Label = 'Name / address', Icon = 'fas fa-home', Name = 'Label', Value = Draft.Label },
        { Label = 'Price', Icon = 'fas fa-dollar-sign', Name = 'Price', Value = tostring(Draft.Price) },
        { Label = 'Class (0-10)', Icon = 'fas fa-layer-group', Name = 'Class', Value = tostring(Draft.Class) },
        { Label = 'Max decorations', Icon = 'fas fa-couch', Name = 'MaxDecorations', Value = tostring(Draft.MaxDecorations) },
    })
    if R then
        Draft.Label = R.Label or Draft.Label
        Draft.Price = tonumber(R.Price) or Draft.Price
        Draft.Class = tonumber(R.Class) or Draft.Class
        Draft.MaxDecorations = tonumber(R.MaxDecorations) or Draft.MaxDecorations
    end
    Reopen()
end)

On('Surfaces', function()
    local S = Draft.Surfaces or {}
    local R = Input({
        { Label = 'Texture dictionary (.ytd) of the shell', Icon = 'fas fa-images', Name = 'Txd', Value = S.Txd or '' },
        { Label = 'Wall textures (comma separated)', Icon = 'fas fa-border-all', Name = 'Walls', Value = table.concat(S.Walls or {}, ', ') },
        { Label = 'Floor textures', Icon = 'fas fa-square', Name = 'Floor', Value = table.concat(S.Floor or {}, ', ') },
        { Label = 'Ceiling textures', Icon = 'fas fa-square-full', Name = 'Ceiling', Value = table.concat(S.Ceiling or {}, ', ') },
    })
    if R then
        Draft.Surfaces = (R.Txd or '') ~= '' and { Txd = R.Txd, Walls = Split(R.Walls), Floor = Split(R.Floor), Ceiling = Split(R.Ceiling) } or nil
    end
    Reopen()
end)

On('Stash', function()
    local R = Input({
        { Label = 'Slots', Icon = 'fas fa-th', Name = 'Slots', Value = tostring(Draft.Stash.Slots) },
        { Label = 'Max weight', Icon = 'fas fa-weight-hanging', Name = 'Weight', Value = tostring(Draft.Stash.Weight) },
    })
    if R then Draft.Stash = { Slots = tonumber(R.Slots) or Draft.Stash.Slots, Weight = tonumber(R.Weight) or Draft.Stash.Weight } end
    Reopen()
end)

On('Save', function()
    TriggerServerEvent("fw-housing:Server:Creator:Save", DraftKey, Draft)
    Draft, DraftKey, Tool = nil, nil, nil
end)

On('Discard', function()
    Draft, DraftKey, Tool = nil, nil, nil
end)
