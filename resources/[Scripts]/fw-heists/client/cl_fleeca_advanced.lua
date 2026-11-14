-- Advanced Fleeca (config/sh_fleeca_advanced.lua, server/sv_fleeca_advanced.lua)
--   1. Power box: [E] Access (cutters) -> hack the branch WiFi with Bugger (cl_fleeca_laptop.lua): network down +
--      the staff door keypad code
--   2. Lobby terminal (monitor DUI): Fleeca app, password from one of the sticky notes
--   3. Dashboard: generate a door code (number + instructions) -> a 2nd player types the result on the door's security panel
--   After that the normal Fleeca flow (cl_fleeca.lua) continues: vault laptop, gate, loot.
local Cfg = Config.FleecaAdvanced
local DUI = exports['fw-dui']
local TERMINAL = 'fleeca_terminal'
local Url = function(Page) return ('nui://%s/html/fleeca/%s.html'):format(GetCurrentResourceName(), Page) end

local Apps = {
    Terminal = { id = 'fleeca', label = 'Fleeca Branch Terminal', icon = 'fas fa-university', color = 'linear-gradient(160deg, #40c057, #2b8a3e)', url = Url('terminal'), width = 70, height = 72 },
}

local Current = nil                       -- advanced bank the player is in
local Notes = {}                          -- spawned sticky notes { Entity, Text }
local NotesData = {}                      -- [FleecaId] = { { Coords, Text } }
local Steps = {}                          -- [FleecaId] = 'access' | 'hack' | 'done' (cached for canInteract)
local Busy = false
local Interact = exports['interact']
local Term = { Open = false, Entity = nil } -- Entity = the one monitor that is the terminal (closest to Advanced.Terminal)

local function FindTerminal()
    local A, Best, BestDist = Config.Fleeca[Current].Advanced.Terminal, nil, 3.0
    local Models = exports['fw-dui']:GetVariants(Cfg.Models.Monitor) -- the monitor in use is one of its screen copies
    table.insert(Models, 1, Cfg.Models.Monitor)
    for _, Model in ipairs(Models) do
        local Entity = GetClosestObjectOfType(A.x, A.y, A.z, BestDist, joaat(Model), false, false, false)
        local Dist = Entity ~= 0 and #(A - GetEntityCoords(Entity))
        if Dist and Dist <= BestDist then Best, BestDist = Entity, Dist end
    end
    return Best
end

local function Notify(Text, Type) FW.Functions.Notify(Text, Type or 'primary') end
local function Prefix(Name) return GetFleecaPrefix(Current) .. Name end
local function Adv() return Current and Config.Fleeca[Current].Advanced end

local function Spawn(Model, C, Networked)
    local Hash = joaat(Model)
    RequestModel(Hash)
    local Deadline = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Deadline do Wait(10) end
    local Obj = CreateObject(Hash, C.x, C.y, C.z, Networked == true, false, false)
    SetEntityHeading(Obj, C.w or 0.0)
    FreezeEntityPosition(Obj, true)
    SetModelAsNoLongerNeeded(Hash)
    return Obj
end

local function Delete(Obj) if Obj and DoesEntityExist(Obj) then DeleteEntity(Obj) end end

local function Fingerprint()
    if not IsWearingHandshoes() and math.random(1, 100) <= 85 then TriggerServerEvent('fw-police:Server:CreateEvidence', 'Fingerprint') end
end

-- ── Screens ────────────────────────────────────────────────────────────────
-- Only registered inside an advanced bank, so other laptops / monitors in the city are left alone.

-- Both models have screen copies (fw-dui location pool): a prop only shows a page while it's in use.
local function SetScreens(Active)
    if GetResourceState('fw-dui') ~= 'started' then return end
    DUI:RegisterScreen(TERMINAL, { Models = Active and { Cfg.Models.Monitor } or {}, Mirror = true, Desktop = true })
end

local function SendT(Action, Data, Mirror) DUI:SendApp(TERMINAL, Apps.Terminal.id, Action, Data, Mirror) end

local function TerminalInit(Session)
    local Labels = {}
    for i, D in ipairs(Adv().Doors) do Labels[i] = { label = D.Label, desc = D.Desc } end
    SendT('init', {
        branch = Adv().Name, user = Session and Session.User, doors = Session and Session.Doors, labels = Labels,
        bypassed = DataManager.Get(Prefix('powerbox'), 0) ~= 0, lifetime = Cfg.CodeLifetime,
        clock = { GetClockHours(), GetClockMinutes(), GetClockSeconds() }, seed = Current * 7919 + GetClockHours(),
    }) -- mirrored: players around the terminal see the same page
end

AddEventHandler('fw-dui:Client:Shown', function(Name, Entity)
    if Name == TERMINAL and not Term.Open then
        if not Current then return DUI:SetApps(TERMINAL, {}) end
        DUI:SetApps(TERMINAL, { Apps.Terminal }) -- plain desktop, the app is opened from the dock
        TerminalInit(nil)
    end
end)

-- ── Bank area: monitor, notes, screens ─────────────────────────────────────

-- Scales a frozen prop (GTA has no native scale, the matrix does it).
local function Scale(Obj, C, S)
    local H = math.rad(C.w or 0.0)
    local F, R = vector3(-math.sin(H), math.cos(H), 0.0) * S, vector3(math.cos(H), math.sin(H), 0.0) * S
    SetEntityMatrix(Obj, F.x, F.y, F.z, R.x, R.y, R.z, 0.0, 0.0, S, C.x, C.y, C.z)
end

local function ClearNotes()
    for _, N in ipairs(Notes) do
        Interact:RemoveInteractionByEntity(N.Entity)
        Delete(N.Entity)
    end
    Notes = {}
end

local function SpawnNotes()
    ClearNotes()
    for i, N in ipairs(NotesData[Current] or {}) do
        local Obj = Spawn(Cfg.Models.Note, N.Coords)
        SetEntityCollision(Obj, false, false)
        Scale(Obj, N.Coords, Cfg.NoteScale)
        Notes[i] = { Entity = Obj, Text = N.Text, Service = N.Service }
        Interact:AddLocalEntityInteraction({
            entity = Obj, distance = 3.0, interactDst = 1.2,
            options = { { label = 'Read note', action = function() FW.Functions.Notify(('Backdoor code, last serviced %s ago: "%s"'):format(N.Service or '?', N.Text), 'primary', 8000) end } },
        })
    end
end

local function Leave()
    if Term.Open then DUI:StopFocus() Term.Open = false end
    ClearNotes()
    Current = nil
    SetScreens(false)
end

local function Enter(Id)
    Current = Id
    NotesData[Id] = FW.SendCallback('fw-heists:Server:FleecaAdv:GetNotes', Id)
    SpawnNotes()
    SetScreens(true)
end

RegisterNetEvent('fw-heists:Client:FleecaAdv:Notes', function(Id, Notes)
    NotesData[Id] = Notes
    if Id == Current then SpawnNotes() end
end)

-- ── Vault: state for the prompts (terminal, panels, loot, trolley) ─────────
FleecaVault = {} -- [FleecaId] = { Vault, Gate, Staff, Trolley, Loot = {}, Doors = {} } (also read by cl_fleeca_keypad.lua)
local TROLLEY = 'ch_prop_ch_cash_trolly_01c'

local function TrolleyAt(Id)
    local T = Config.Fleeca[Id].Advanced.Trolley
    local Obj = T and GetClosestObjectOfType(T.x, T.y, T.z, 2.5, joaat(TROLLEY), false, false, false)
    return Obj and Obj ~= 0 and Obj or nil
end

function FleecaAdvRefresh(Id)
    FleecaVault[Id] = FW.SendCallback('fw-heists:Server:FleecaAdv:VaultState', Id) or nil
    local Obj = TrolleyAt(Id)
    if Obj then RegisterTrolley('fleeca-' .. Id, 'Cash', Obj) end -- spawned by another player: grabbable here too
end

-- The vault door opened (terminal code or /fleecatest): swing it now, and the opener spawns the trolley.
RegisterNetEvent('fw-heists:Client:FleecaAdv:VaultOpened', function(Id, Opener)
    if GetCurrentFleeca() ~= Id then return end
    CheckFleecaVaultDoor(Id)
    FleecaAdvRefresh(Id)
    local T = Config.Fleeca[Id].Advanced.Trolley
    if Opener == GetPlayerServerId(PlayerId()) and T and not TrolleyAt(Id) and FleecaVault[Id] and FleecaVault[Id].Trolley == 0 then
        SpawnTrolley('fleeca-' .. Id, 'Cash', T)
    end
end)

CreateThread(function()
    while true do
        local Id, Bank = GetCurrentFleeca()
        if not (Bank and Bank.Advanced) then Id = nil end
        if Id ~= Current then
            if Current then Leave() end
            if Id then Enter(Id) end
        end
        Term.Entity = Current and FindTerminal() or nil -- changes when fw-dui swaps it to a screen copy
        if Current then FleecaAdvRefresh(Current) end
        -- The terminal can only be used once the staff door keypad was done (sets door-lockpicked)
        local Vault = Current and FleecaVault[Current]
        Term.Unlocked = Term.Entity ~= nil and Vault and Vault.Staff == 1
        -- Box state for the interact prompts, only while near the box
        if Current and #(GetEntityCoords(PlayerPedId()) - Config.Fleeca[Current].PowerBox[1]) < 10.0 then RefreshStep(Current) end
        Wait(1000)
    end
end)

AddEventHandler('onClientResourceStart', function(Resource)
    if Resource == 'fw-dui' and Current then SetScreens(true) end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() and Current then Leave() end
end)

-- ── 1. Power box ───────────────────────────────────────────────────────────

function RefreshStep(Id)
    if DataManager.Get(GetFleecaPrefix(Id) .. 'powerbox', 0) ~= 0 then Steps[Id] = 'done'
    else Steps[Id] = DataManager.Get(GetFleecaPrefix(Id) .. 'box-open', 0) == 1 and 'hack' or 'access' end
end

local function CanRob()
    if GlobalState.FleecaTest then return true end -- /fleecatest mode: no cops / cooldown needed
    if DataManager.Get('HeistsDisabled', 0) == 1 or CurrentCops < Config.RequiredCopsFleeca or DataManager.Get('GlobalCooldown', false) == true then
        Notify("You can't do this right now..", 'error')
        return false
    end
    return true
end

local function Access(Id)
    if not exports['fw-inventory']:HasEnoughOfItem(Cfg.Items.Cutters, 1) then return Notify('You need heavy cutters..', 'error') end
    if not CanRob() then return end

    local Ped, Box = PlayerPedId(), Config.Fleeca[Id].PowerBox[1]
    local Obj = GetClosestObjectOfType(Box.x, Box.y, Box.z, 3.0, joaat('prop_elecbox_09'), false, false, false)
    if Obj ~= 0 then TaskTurnPedToFaceEntity(Ped, Obj, 800) Wait(800) end

    local Finished = FW.Functions.CompactProgressbar(Cfg.CutTime, 'Cutting the lock..', false, true,
        { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true },
        { animDict = 'mini@repair', anim = 'fixing_a_ped', flags = 1 }, {}, {}, false)
    if not Finished then return end

    Fingerprint()
    if not FW.SendCallback('fw-heists:Server:FleecaAdv:Access', Id) then return Notify("It won't budge..", 'error') end
    TriggerServerEvent('fw-inventory:Server:DecayItem', Cfg.Items.Cutters, nil, 20.0)
    PlaySoundFromCoord(-1, 'Drill_Pin_Break', Box.x, Box.y, Box.z, 'DLC_HEIST_FLEECA_SOUNDSET', false, 0, false)
    Notify('The box is open, the branch network is exposed. Hack it from a laptop nearby.', 'success')
end

-- Runs an interact action off the render loop, one at a time.
local function Run(Fn, ...)
    if Busy then return end
    local Args = { ... }
    CreateThread(function()
        Busy = true
        Fn(table.unpack(Args))
        Busy = false
        if Current then RefreshStep(Current) end
    end)
end

-- Power box points (one per advanced bank): [E] ACCESS. Once it's cut open the branch WiFi can be hacked with Bugger
-- (the green heist laptop, cl_fleeca_laptop.lua).
CreateThread(function()
    for Id, Bank in pairs(Config.Fleeca) do
        if Bank.Advanced then
            local C = Bank.PowerBox[1]
            local Box = GetClosestObjectOfType(C.x, C.y, C.z, 3.0, joaat('prop_elecbox_09'), false, false, false)
            local Point = Box ~= 0 and GetOffsetFromEntityInWorldCoords(Box, 0.0, 0.0, 1.0) or C + vec3(0.0, 0.0, 0.8)
            Interact:AddInteraction({
                coords = Point, distance = 6.0, interactDst = 1.5, name = 'fleeca_adv_powerbox_' .. Id,
                options = {
                    { name = 'access', label = 'Access', canInteract = function() return not Busy and Steps[Id] == 'access' end,
                        action = function() Run(Access, Id) end },
                },
            })
        end
    end
end)

-- ── 2. Terminal ────────────────────────────────────────────────────────────

-- Entity = one of the bank's own monitors. fw-dui swaps it to the _dui copy (like the ATMs).
local function OpenTerminal(Entity)
    if Term.Open or Busy or not Current then return end
    local Shown, Screen = DUI:Show(TERMINAL, Entity)
    if not Shown then return Notify("The terminal won't start.", 'error') end

    Term.Open = true
    TaskTurnPedToFaceEntity(PlayerPedId(), Screen, 600)
    DUI:SetApps(TERMINAL, { Apps.Terminal })
    DUI:Focus(TERMINAL, { Mouse = true })
    TerminalInit(FW.SendCallback('fw-heists:Server:FleecaAdv:Session', Current))
end

AddEventHandler('fw-dui:Client:Closed', function(Name)
    if Name == TERMINAL then
        Term.Open = false
        DUI:Release(TERMINAL)
    end
end)

local TerminalActions = {
    login = function(Data) -- typed on the screen (fw-dui keys)
        local Result = FW.SendCallback('fw-heists:Server:FleecaAdv:Login', Current, tostring(Data.Password or ''))
        if Result.Alert then TriggerServerEvent('fw-mdw:Server:SendAlert:FleecaBank', GetEntityCoords(PlayerPedId())) end
        SendT('login', Result)
    end,
    hint = function() SendT('hint', FW.SendCallback('fw-heists:Server:FleecaAdv:Hint', Current)) end,
    generate = function(Data)
        local Result = FW.SendCallback('fw-heists:Server:FleecaAdv:GenerateCode', Current, tonumber(Data.Door))
        SendT('code', Result and { door = tonumber(Data.Door), shown = Result.Shown, rules = Result.Rules, memorise = Result.Memorise, lifetime = Result.Lifetime }
            or { error = 'Unable to generate a code.' })
    end,
    refresh = function()
        local Session = FW.SendCallback('fw-heists:Server:FleecaAdv:Session', Current)
        if Session then SendT('state', { Doors = Session.Doors }) end
    end,
    signout = function()
        TriggerServerEvent('fw-heists:Server:FleecaAdv:SignOut')
        SendT('signedout', {})
    end,
}

RegisterNUICallback('fleecaTerminal', function(Data, Cb)
    Cb('ok')
    local Action = TerminalActions[Data.Action]
    if Term.Open and Current and Action then CreateThread(function() Action(Data) end) end
end)

RegisterNetEvent('fw-heists:Client:FleecaAdv:State', function(Id, State)
    if Id == Current and Term.Open then SendT('state', State) end
end)

-- ── 3. Keypads + notes ─────────────────────────────────────────────────────


-- The bank's monitors (map props): base model and its _dui copy, only inside an advanced bank.
CreateThread(function()
    local Models = { { model = Cfg.Models.Monitor, offset = vec3(0.0, 0.0, 0.25) } }
    for _, Variant in ipairs(DUI:GetVariants(Cfg.Models.Monitor)) do Models[#Models + 1] = { model = Variant, offset = vec3(0.0, 0.0, 0.25) } end
    Interact:AddModelInteraction({
        modelData = Models, distance = 4.0, interactDst = 1.5,
        options = { { name = 'fleeca_terminal', label = 'Use terminal',
            canInteract = function(Entity) return Entity == Term.Entity and Term.Unlocked and not Term.Open and not Busy end,
            action = function(Entity) CreateThread(function() OpenTerminal(Entity) end) end } },
    })
end)

-- /fleecatest output (server/sv_fleeca_test.lua): F8 console + notification
RegisterNetEvent('fw-heists:Client:FleecaTest:Print', function(Lines)
    for _, Line in ipairs(Lines) do print('[fleecatest] ' .. Line) end
    FW.Functions.Notify(Lines[1], 'primary', 6000)
end)

-- Loot spots (Overvallen, cl_fleeca.lua Loot) + the vault trolley, via interact
CreateThread(function()
    for Id, Bank in pairs(Config.Fleeca) do
        for k, Zone in ipairs(Bank.Advanced and Bank.Zones or {}) do
            local Option = Zone.Options and Zone.Options[1]
            local Safe = Option and Option.EventName == 'fw-heists:Client:Fleeca:Loot' and Option.EventParams.SafeId
            if Safe then
                Interact:AddInteraction({
                    coords = Zone.Center + vec3(0.0, 0.0, 0.3), distance = 4.0, interactDst = 1.5, name = ('fleeca_adv_loot_%d_%d'):format(Id, Safe),
                    options = { { label = 'Overvallen',
                        -- 1-2: once the vault door is open, 3-5: behind the security door (DoorIds[3])
                        canInteract = function()
                            local V = FleecaVault[Id]
                            return Current == Id and not Busy and V and V.Vault == 2 and (Safe <= 2 or V.Gate == 2) and V.Loot[Safe] == 0
                        end,
                        action = function() Run(function() TriggerEvent('fw-heists:Client:Fleeca:Loot', { SafeId = Safe }) end) end } },
                })
            end
        end
    end

    Interact:AddModelInteraction({
        modelData = { { model = TROLLEY, offset = vec3(0.0, 0.0, 1.0) } }, distance = 4.0, interactDst = 1.5,
        options = { { name = 'fleeca_trolley', label = 'Grab cash',
            canInteract = function(Entity)
                local V = Current and FleecaVault[Current]
                return V and V.Trolley == 0 and not Busy and Entity == TrolleyAt(Current)
            end,
            action = function(Entity) Run(function() TriggerEvent('fw-heists:Client:Trolley:Grab', {}, Entity) end) end } },
    })
end)
