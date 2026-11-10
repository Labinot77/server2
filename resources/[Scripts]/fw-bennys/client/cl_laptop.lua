-- Work-order laptop: a DUI page shown on the laptop's screen, either drawn into the prop's script render
-- target (e.g. prop_laptop_lester2 -> script_rt_tvscreen) or replacing its screen texture (AddReplaceTexture).
-- While in use the camera looks at the screen and the mouse moves a cursor inside the page.
-- Laptops come from the placed_props table (server/sv_orders.lua -> LoadLaptops).
FW = FW or exports['fw-core']:GetCoreObject()

local TXD, TEX = 'bennys_laptop_txd', 'bennys_laptop_tex_1'
local Width, Height = 1280, 800 -- current DUI size (set per model)

local Laptop = {
    Dui = nil,
    Open = false,
    Preview = nil,  -- entity drawn without a session (/bennyslaptop)
    Entity = nil,
    Business = nil,
    Cam = nil,
    Cursor = { X = 50.0, Y = 50.0 },
    Replaced = nil, -- { Dict, Name } currently replaced texture
    Target = nil,   -- { Name, Id, Registered } current render target
}

local Laptops = {}       -- from placed_props: { Id, Model, Coords, Business }

-- ── DUI ────────────────────────────────────────────────────────────────────

local function Send(Action, Data)
    if not Laptop.Dui then return end
    SendDuiMessage(Laptop.Dui, json.encode({ action = Action, data = Data }))
end

local function EnsureDui(Model)
    local Res = (Config.Laptop.Models[Model] or {}).Resolution or { 1280, 800 }

    -- Recreate when the next laptop uses a different screen size.
    if Laptop.Dui and (Res[1] ~= Width or Res[2] ~= Height) then
        DestroyDui(Laptop.Dui)
        Laptop.Dui = nil
    end
    if Laptop.Dui then return true end

    Width, Height = Res[1], Res[2]
    Laptop.Dui = CreateDui(('nui://%s/html/laptop.html'):format(GetCurrentResourceName()), Width, Height)
    if not Laptop.Dui then return false end

    -- Runtime txd can only be created once; a new texture name per DUI.
    Laptop.TxdHandle = Laptop.TxdHandle or CreateRuntimeTxd(TXD)
    Laptop.TexIndex = (Laptop.TexIndex or 0) + 1
    TEX = ('bennys_laptop_tex_%d'):format(Laptop.TexIndex)
    CreateRuntimeTextureFromDuiHandle(Laptop.TxdHandle, TEX, GetDuiHandle(Laptop.Dui))

    local Deadline = GetGameTimer() + 4000
    while not IsDuiAvailable(Laptop.Dui) and GetGameTimer() < Deadline do Wait(50) end
    Wait(300) -- let the page boot before the first message
    return true
end

-- ── Screen texture ─────────────────────────────────────────────────────────

local function ReleaseScreen()
    if Laptop.Replaced then
        RemoveReplaceTexture(Laptop.Replaced.Dict, Laptop.Replaced.Name)
        Laptop.Replaced = nil
    end
    if Laptop.Target then
        if Laptop.Target.Registered and IsNamedRendertargetRegistered(Laptop.Target.Name) then
            ReleaseNamedRendertarget(Laptop.Target.Name)
        end
        Laptop.Target = nil
    end
end

-- Puts the DUI on the screen of Model (nil = take it off).
local function SetScreen(Model)
    ReleaseScreen()

    local Data = Model and Config.Laptop.Models[Model]
    if not Data then return end

    if Data.RenderTarget then
        local Name = Data.RenderTarget
        local Registered = false
        if not IsNamedRendertargetRegistered(Name) then
            RegisterNamedRendertarget(Name, false)
            Registered = true
        end
        if not IsNamedRendertargetLinked(joaat(Model)) then
            LinkNamedRendertarget(joaat(Model))
        end
        Laptop.Target = { Name = Name, Id = GetNamedRendertargetRenderId(Name), Registered = Registered }
    elseif Data.Texture then
        -- The texture dictionary of a prop's screen is its model name (from placed_props).
        local Dict = Data.Dict or Model
        AddReplaceTexture(Dict, Data.Texture, TXD, TEX)
        Laptop.Replaced = { Dict = Dict, Name = Data.Texture }
    end
end

-- Render targets have to be drawn every frame.
local function DrawScreen()
    local Target = Laptop.Target
    if not Target then return end
    SetTextRenderId(Target.Id)
    SetScriptGfxDrawOrder(4)
    SetScriptGfxDrawBehindPausemenu(true)
    DrawSprite(TXD, TEX, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    SetTextRenderId(GetDefaultScriptRendertargetRenderId())
end

-- The placed_props row this spawned entity belongs to.
local function GetLaptopForEntity(Entity)
    local Coords = GetEntityCoords(Entity)
    local Hash = GetEntityModel(Entity)
    for _, Entry in ipairs(Laptops) do
        if joaat(Entry.Model) == Hash and #(Coords - Entry.Coords) <= Config.Laptop.MatchDistance then
            return Entry
        end
    end
end

-- ── Camera ─────────────────────────────────────────────────────────────────

local function StartCamera(Entity, Model)
    local C = (Config.Laptop.Models[Model] or {}).Camera or Config.Laptop.Camera
    local Pos = GetOffsetFromEntityInWorldCoords(Entity, C.Offset.x, C.Offset.y, C.Offset.z)
    local Target = GetOffsetFromEntityInWorldCoords(Entity, C.LookAt.x, C.LookAt.y, C.LookAt.z)

    Laptop.Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Laptop.Cam, Pos.x, Pos.y, Pos.z)
    PointCamAtCoord(Laptop.Cam, Target.x, Target.y, Target.z)
    SetCamFov(Laptop.Cam, C.Fov)
    RenderScriptCams(true, true, C.Transition, true, true)
end

local function StopCamera()
    if not Laptop.Cam then return end
    RenderScriptCams(false, true, Config.Laptop.Camera.Transition, true, true)
    DestroyCam(Laptop.Cam, false)
    Laptop.Cam = nil
end

-- ── Session ────────────────────────────────────────────────────────────────

local function SetInteractDisabled(Disabled)
    if GetResourceState('interact') == 'started' then exports['interact']:Disable(Disabled) end
end

local function Clamp(V, Min, Max) return math.max(Min, math.min(Max, V)) end

function CloseLaptop()
    if not Laptop.Open then return end
    Laptop.Open = false

    Send('close')
    StopCamera()
    ReleaseScreen()
    SetInteractDisabled(false)

    local Ped = PlayerPedId()
    ClearPedTasks(Ped)
    FreezeEntityPosition(Ped, false)
    TriggerEvent('hud:client:ToggleHUD', true)

    Laptop.Entity, Laptop.Business = nil, nil
end

function OpenLaptop(Entity, Business, Model)
    if Laptop.Open or not DoesEntityExist(Entity) then return end
    if not EnsureDui(Model) then return FW.Functions.Notify("Laptop kon niet worden geladen..", "error") end

    Laptop.Open, Laptop.Entity, Laptop.Business = true, Entity, Business
    Laptop.Preview = nil

    local PlayerData = FW.Functions.GetPlayerData()
    Send('init', {
        resource = GetCurrentResourceName(),
        business = Business,
        label = Config.Orders.Businesses[Business] and Config.Orders.Businesses[Business].Label or Business,
        me = { cid = PlayerData.citizenid, name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname) },
    })
    Send('orders', OrdersByBusiness[Business] or {})

    -- Fetch fresh in the background.
    CreateThread(function()
        local List = FW.SendCallback('fw-bennys:Server:Orders:Get', Business)
        if List and Laptop.Open then
            OrdersByBusiness[Business] = List
            Send('orders', List)
        end
    end)

    local Ped = PlayerPedId()
    TaskTurnPedToFaceEntity(Ped, Entity, 600)
    SetInteractDisabled(true)
    TriggerEvent('hud:client:ToggleHUD', false)

    CreateThread(function()
        Wait(600)
        if not Laptop.Open then return end
        FreezeEntityPosition(Ped, true)
        exports['fw-assets']:RequestAnimationDict('anim@heists@prison_heiststation@cop_reactions')
        TaskPlayAnim(Ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0, false, false, false)
    end)

    StartCamera(Entity, Model)
    SetScreen(Model)
    Laptop.Cursor = { X = 50.0, Y = 50.0 }

    CreateThread(function()
        local Last = ''
        while Laptop.Open do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            HideHudAndRadarThisFrame()
            DrawScreen()

            if not DoesEntityExist(Laptop.Entity) or IsEntityDead(PlayerPedId()) then
                CloseLaptop()
                break
            end

            local C = Laptop.Cursor
            C.X = Clamp(C.X + GetDisabledControlNormal(0, 1) * Config.Laptop.CursorSensitivity, 0.0, 100.0)
            C.Y = Clamp(C.Y + GetDisabledControlNormal(0, 2) * Config.Laptop.CursorSensitivity, 0.0, 100.0)

            local PX, PY = math.floor(C.X / 100 * Width), math.floor(C.Y / 100 * Height)
            local Key = PX .. ':' .. PY
            if Key ~= Last then
                Last = Key
                SendDuiMouseMove(Laptop.Dui, PX, PY)
            end

            if IsDisabledControlJustPressed(0, 24) then SendDuiMouseDown(Laptop.Dui, 'left') end
            if IsDisabledControlJustReleased(0, 24) then SendDuiMouseUp(Laptop.Dui, 'left') end
            if IsDisabledControlJustPressed(0, 241) then SendDuiMouseWheel(Laptop.Dui, 120, 0) end
            if IsDisabledControlJustPressed(0, 242) then SendDuiMouseWheel(Laptop.Dui, -120, 0) end

            -- ESC / Backspace / right click
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 25) then
                CloseLaptop()
                break
            end

            Wait(0)
        end
    end)
end

-- ── Page -> client ─────────────────────────────────────────────────────────

RegisterNUICallback('laptop', function(Data, Cb)
    local Action = Data and Data.Action
    if Action == 'close' then
        Cb('ok')
        return CloseLaptop()
    end

    if not Laptop.Open then return Cb('ok') end
    local Business = Laptop.Business

    if Action == 'refresh' then
        local List = FW.SendCallback('fw-bennys:Server:Orders:Get', Business)
        if List then
            OrdersByBusiness[Business] = List
            Send('orders', List)
        end
        return Cb('ok')
    end

    if Action == 'accept' or Action == 'release' or Action == 'decline' or Action == 'complete' then
        local Result = FW.SendCallback('fw-bennys:Server:Orders:Action', Action, Data.Id)
        if Result and Result.Success then
            local Messages = { accept = 'Order geaccepteerd', release = 'Order vrijgegeven', decline = 'Order geannuleerd', complete = 'Order afgerond' }
            Send('toast', { text = Messages[Action], type = 'success' })
            PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            Send('toast', { text = Result and Result.Message or 'Er ging iets mis', type = 'error' })
            PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        end
        return Cb('ok')
    end

    if Action == 'locate' then
        local Order = GetOrderById(Data.Id)
        local Vehicle = Order and FindOrderVehicle(Order.NetId, Order.Plate)
        if Vehicle then
            local Coords = GetEntityCoords(Vehicle)
            SetNewWaypoint(Coords.x, Coords.y)
            Send('toast', { text = 'Waypoint gezet naar het voertuig', type = 'success' })
        else
            Send('toast', { text = 'Voertuig niet in de buurt', type = 'error' })
        end
        return Cb('ok')
    end

    if Action == 'sound' then
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end

    Cb('ok')
end)

AddEventHandler('fw-bennys:Client:Laptop:Orders', function(Business, List)
    if Laptop.Open and Laptop.Business == Business then Send('orders', List) end
end)

-- ── Interact on the laptop props ───────────────────────────────────────────

local LastLaptopFetch = 0
local Registered = {} -- [Model] = true (interact's AddModelInteraction appends, so register once)

local function SetLaptops(List)
    Laptops = {}
    for _, Entry in ipairs(List or {}) do
        Laptops[#Laptops + 1] = {
            Id = Entry.Id,
            Model = Entry.Model,
            Business = Entry.Business,
            Coords = vector3(Entry.Coords.x, Entry.Coords.y, Entry.Coords.z),
        }
    end
end

RegisterNetEvent('fw-bennys:Client:Laptop:SetLaptops', SetLaptops)

-- Laptops placed after the resource started aren't known yet: ask the server to re-read placed_props.
local function RefreshLaptops(Force)
    if not Force and GetGameTimer() - LastLaptopFetch < 30000 then return end
    LastLaptopFetch = GetGameTimer()
    CreateThread(function()
        SetLaptops(FW.SendCallback('fw-bennys:Server:Laptop:GetLaptops', true))
    end)
end

-- Why the prompt is (not) shown, as a reason string; nil = can interact.
function LaptopBlockReason(Entity)
    if Laptop.Open then return 'laptop already open' end
    local Entry = GetLaptopForEntity(Entity)
    if not Entry then
        RefreshLaptops(false)
        return 'no placed_props match'
    end
    if not IsOrderMechanic(Entry.Business) then return 'not a member of ' .. Entry.Business .. ' (client cache)' end
    return nil
end

function LaptopCanInteract(Entity)
    return LaptopBlockReason(Entity) == nil
end

local function RegisterInteractions()
    if GetResourceState('interact') ~= 'started' then return end

    -- Every configured model gets the prompt; which business it belongs to comes from placed_props.
    for Model in pairs(Config.Laptop.Models) do
        if not Registered[Model] then
            if not IsModelValid(joaat(Model)) then
                print(('[fw-bennys] Laptop model %s is not valid (not streamed?), skipping interaction'):format(Model))
            else
                Registered[Model] = true
                exports['interact']:AddModelInteraction({
                    modelData = { { model = Model, offset = vec3(0.0, 0.0, 0.15) } },
                    distance = 3.0,
                    interactDst = 1.4,
                    name = 'bennys_laptop_' .. Model,
                    options = {
                        {
                            name = 'bennys_laptop_orders',
                            label = 'Work Orders',
                            canInteract = function(Entity) return LaptopCanInteract(Entity) end,
                            action = function(Entity)
                                local Entry = GetLaptopForEntity(Entity)
                                if not Entry then return end
                                CreateThread(function() OpenLaptop(Entity, Entry.Business, Entry.Model) end)
                            end,
                        },
                    },
                })
            end
        end
    end
end

CreateThread(function()
    while GetResourceState('interact') ~= 'started' do Wait(500) end
    while not FW.Functions.GetPlayerData() or not FW.Functions.GetPlayerData().citizenid do Wait(1000) end
    RegisterInteractions()
    LastLaptopFetch = GetGameTimer()
    SetLaptops(FW.SendCallback('fw-bennys:Server:Laptop:GetLaptops', false))
end)

-- ── /workorders: open the nearest laptop without interact (fallback + testing) ──

RegisterCommand('workorders', function()
    local Ped = GetEntityCoords(PlayerPedId())
    for Model in pairs(Config.Laptop.Models) do
        local Entity = GetClosestObjectOfType(Ped.x, Ped.y, Ped.z, 2.5, joaat(Model), false, false, false)
        if Entity ~= 0 then
            local Reason = LaptopBlockReason(Entity)
            if Reason then return FW.Functions.Notify("Laptop: " .. Reason, "error") end
            local Entry = GetLaptopForEntity(Entity)
            return CreateThread(function() OpenLaptop(Entity, Entry.Business, Entry.Model) end)
        end
    end
    FW.Functions.Notify("Geen laptop in de buurt..", "error")
end)

-- ── Debug: /bennysdebug explains why the laptop prompt does or doesn't show ───

RegisterCommand('bennysdebug', function()
    CreateThread(function()
        local Lines = {}
        local function Add(Text, ...) Lines[#Lines + 1] = Text:format(...) end

        local Fresh = FW.SendCallback('fw-bennys:Server:Laptop:GetLaptops', true) or {}
        SetLaptops(Fresh)
        LastLaptopFetch = GetGameTimer()
        local Mine = FW.SendCallback('fw-bennys:Server:Orders:GetMyBusinesses') or {}

        local Cid, Cached = GetOrderMechanicState()
        Add('interact: %s | nui focused: %s | interactionsDisabled: %s | in vehicle: %s', GetResourceState('interact'), tostring(IsNuiFocused()),
            tostring(LocalPlayer.state.interactionsDisabled), tostring(IsPedInAnyVehicle(PlayerPedId(), false)))
        Add('client cache: cid=%s businesses=%s', tostring(Cid), #Cached > 0 and table.concat(Cached, ', ') or 'EMPTY')
        Add('my order businesses: %s', #Mine > 0 and table.concat(Mine, ', ') or 'NONE (not owner/employee in phone_businesses)')
        Add('laptops in placed_props (inside a business Area): %d', #Laptops)
        for _, Entry in ipairs(Laptops) do
            Add('  #%s %s @ %.2f, %.2f, %.2f -> %s', Entry.Id, Entry.Model, Entry.Coords.x, Entry.Coords.y, Entry.Coords.z, Entry.Business)
        end

        local Ped = GetEntityCoords(PlayerPedId())
        for Model, Data in pairs(Config.Laptop.Models) do
            local Hash = joaat(Model)
            local Entity = GetClosestObjectOfType(Ped.x, Ped.y, Ped.z, 10.0, Hash, false, false, false)
            Add('model %s: valid=%s registered=%s screen=%s', Model, tostring(IsModelValid(Hash)), tostring(Registered[Model] == true),
                Data.RenderTarget and ('rendertarget ' .. Data.RenderTarget) or ('texture ' .. tostring(Data.Dict or Model) .. '/' .. tostring(Data.Texture)))
            if Entity ~= 0 then
                local Coords = GetEntityCoords(Entity)
                local Entry = GetLaptopForEntity(Entity)
                Add('  nearest: entity %d @ %.2f, %.2f, %.2f (%.1fm away) -> %s', Entity, Coords.x, Coords.y, Coords.z, #(Coords - Ped),
                    Entry and ('matches placed_props #' .. Entry.Id .. ' (' .. Entry.Business .. ')') or ('NO placed_props match within ' .. Config.Laptop.MatchDistance .. 'm'))
                Add('  prompt: %s', LaptopBlockReason(Entity) or 'SHOULD SHOW (look at the laptop, within ~1.5m)')
            else
                Add('  nearest: none within 10m')
            end
        end

        print('[fw-bennys] ---- laptop debug ----')
        for _, Line in ipairs(Lines) do print(Line) end
        FW.Functions.Notify("Benny's laptop debug geprint in F8", "primary")
    end)
end)

-- ── Preview: /bennyslaptop shows the page on the nearest laptop's screen ───────

RegisterCommand('bennyslaptop', function()
    if Laptop.Preview then
        Laptop.Preview = nil
        return
    end

    local Coords = GetEntityCoords(PlayerPedId())
    for Model in pairs(Config.Laptop.Models) do
        local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, 5.0, joaat(Model), false, false, false)
        if Entity ~= 0 then
            CreateThread(function()
                if Laptop.Open or not EnsureDui(Model) then return end
                Send('init', { resource = GetCurrentResourceName(), business = 'Preview', label = 'Preview', me = { cid = '', name = 'Preview' }, calibrate = true })
                Laptop.Preview = Entity
                SetScreen(Model)
                while Laptop.Preview == Entity and DoesEntityExist(Entity) and not Laptop.Open do
                    DrawScreen()
                    Wait(0)
                end
                if not Laptop.Open then ReleaseScreen() end
            end)
            return FW.Functions.Notify("Laptop preview aan (/bennyslaptop om uit te zetten)", "primary")
        end
    end
    FW.Functions.Notify("Geen laptop in de buurt..", "error")
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    CloseLaptop()
    ReleaseScreen()
    if Laptop.Dui then DestroyDui(Laptop.Dui) end
end)
