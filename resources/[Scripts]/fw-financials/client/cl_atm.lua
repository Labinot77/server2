-- ATM on the ATM's own screen (was osm-atmdui). fw-dui handles the page, camera + cursor; this file owns the session
-- state and hit-tests clicks against cl_atm_layout.lua.
-- The ATM you use gets one of its model's two screen copies (fw-dui location pool, the server picks a free one), so
-- two players at ATMs next to each other both have their own screen, and everyone around sees it. Idle ATMs show
-- one shared idle screen (fw-dui idle page, see fw-dui:Client:Idle below).
local SCREEN = 'atm'
local DUI = exports['fw-dui']

local ATM = { InSession = false, Busy = false, Entity = nil, Model = nil, Hover = nil, State = { screen = 'idle' } }

-- ── Helpers ────────────────────────────────────────────────────────────────

local function Send(Action, Data, MirrorData) DUI:Send(SCREEN, Action, Data, MirrorData) end

-- What players watching you see: the same screen, balances as **.
local function Masked(State)
    local M = {}
    for K, V in pairs(State) do M[K] = V end
    if State.accounts then
        M.accounts = {}
        for I, Acc in ipairs(State.accounts) do
            M.accounts[I] = { id = Acc.id, label = Acc.label, balance = '**', canHistory = Acc.canHistory }
        end
    end
    if State.result then M.result = { amount = State.result.amount, balance = '**', message = State.result.message } end
    return M
end

local function Push() Send('STATE', ATM.State, Masked(ATM.State)) end
local function PlaySound(Name, Set) PlaySoundFrontend(-1, Name, Set, true) end

local function SetBusy(Busy)
    ATM.Busy = Busy
    DUI:SetCloseable(not Busy)
end

local function SetScreen(Screen)
    ATM.State.screen = Screen
    Push()
end

local function CurrentAccount()
    return ATM.State.accounts and ATM.State.accounts[ATM.State.accIndex]
end

local ToastId = 0
local function Toast(Msg)
    ToastId = ToastId + 1
    local Id = ToastId
    ATM.State.toast = { msg = Msg, id = Id }
    PlaySound('ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    Push()
    SetTimeout(2500, function()
        if ATM.State.toast and ATM.State.toast.id == Id then
            ATM.State.toast = nil
            Push()
        end
    end)
end

local function HitTest(X, Y)
    for _, El in ipairs(ATM_Layout[ATM.State.screen] or {}) do
        local R = El.rect
        if X >= R[1] and X <= R[1] + R[3] and Y >= R[2] and Y <= R[2] + R[4] then
            if (El.id == 'acc_prev' or El.id == 'acc_next') and #ATM.State.accounts < 2 then return nil end
            return El.id
        end
    end
end

-- ATM model name of an entity, also when fw-dui swapped it to its screen copy (Variant).
local function ModelOf(Entity)
    local Model = DUI:GetBaseModel(Entity)
    return Model and Config.ATM.Models[Model] and Model or nil
end

local function GetClosestATM()
    local Coords = GetEntityCoords(PlayerPedId())
    local Closest, ClosestDist = nil, 2.0
    for Model in pairs(Config.ATM.Models) do
        local Names = DUI:GetVariants(Model)
        table.insert(Names, 1, Model)
        for _, Name in ipairs(Names) do
            local Obj = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, ClosestDist, joaat(Name), false, false, false)
            if Obj ~= 0 then
                local Dist = #(Coords - GetEntityCoords(Obj))
                if Dist <= ClosestDist then Closest, ClosestDist = Obj, Dist end
            end
        end
    end
    return Closest
end

local function DispenseCash(Amount)
    local Entity, O = ATM.Entity, Config.ATM.Models[ATM.Model].Cash
    local Model = Amount > 500 and `prop_cash_pile_02` or `prop_anim_cash_pile_01`
    RequestModel(Model)
    while not HasModelLoaded(Model) do Wait(10) end

    local From = GetOffsetFromEntityInWorldCoords(Entity, O.X, O.StartY, O.Z)
    local To = GetOffsetFromEntityInWorldCoords(Entity, O.X, O.EndY, O.Z)
    local Prop = CreateObject(Model, From.x, From.y, From.z, true, true, false)
    SetEntityHeading(Prop, GetEntityHeading(Entity) + 90.0)
    SetEntityCollision(Prop, false, false)

    for I = 1, 60 do
        local P = From + (To - From) * (I / 60.0)
        SetEntityCoordsNoOffset(Prop, P.x, P.y, P.z, false, false, false)
        Wait(30)
    end
    Wait(2500)
    DeleteObject(Prop)
    SetModelAsNoLongerNeeded(Model)
end

-- ── Actions ────────────────────────────────────────────────────────────────

local function OpenHistory()
    local Acc = CurrentAccount()
    ATM.State.history, ATM.State.historyLoading = nil, true
    SetScreen('history')

    local History = FW.SendCallback('fw-financials:Server:ATM:GetHistory', Acc.id)
    if not ATM.InSession then return end
    ATM.State.history, ATM.State.historyLoading = History or {}, false
    Push()
end

local function OpenWithdraw()
    ATM.State.amount = ''
    SetScreen('withdraw')
end

local function Withdraw()
    local Acc, Text = CurrentAccount(), Config.ATM.Text
    local Amount = tonumber(ATM.State.amount) or 0

    if Amount <= 0 then return Toast(Text.invalid_amount) end
    if Amount > Config.ATM.Withdraw.MaxPerTransaction then return Toast(Text.over_limit) end
    if Amount > ATM.State.dailyLeft then return Toast(Text.daily_limit) end
    if Amount > Acc.balance then return Toast(Text.insufficient_funds) end

    SetBusy(true)
    ATM.State.processing = true
    Push()

    local Result = FW.SendCallback('fw-financials:Server:ATM:Withdraw', Acc.id, Amount) or {}
    if not ATM.InSession then return end
    Wait(900)

    SetBusy(false)
    ATM.State.processing = false
    if Result.Balance then Acc.balance = Result.Balance end

    if not Result.Success then
        Push()
        return Toast(Result.Error or Text.error)
    end

    ATM.State.dailyLeft, ATM.State.amount = Result.DailyLeft, ''
    ATM.State.result = { amount = Amount, balance = Result.Balance, message = Text.take_cash }
    PlaySound('WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    SetScreen('result')
    DispenseCash(Amount)
end

local Actions = {
    acc_prev = function()
        ATM.State.accIndex = ((ATM.State.accIndex - 2) % #ATM.State.accounts) + 1
        Push()
    end,
    acc_next = function()
        ATM.State.accIndex = (ATM.State.accIndex % #ATM.State.accounts) + 1
        Push()
    end,
    acc_confirm = function() SetScreen('menu') end,

    menu_history = OpenHistory,
    tab_history = OpenHistory,
    menu_withdraw = OpenWithdraw,
    tab_withdraw = OpenWithdraw,
    menu_finish = function() EndATM() end,
    back = function() SetScreen(ATM.State.screen == 'menu' and 'accounts' or 'menu') end,

    key_clear = function() ATM.State.amount = ''; Push() end,
    key_del = function() ATM.State.amount = ATM.State.amount:sub(1, -2); Push() end,
    submit = Withdraw,
    result_done = function() SetScreen('menu') end,
}

local function OnClick(Id)
    if ATM.Busy or not Id then return end
    PlaySound('PIN_BUTTON', 'ATM_SOUNDS')
    Send('PRESS', { id = Id })

    local Digit, Quick = Id:match('^key_(%d)$'), Id:match('^quick_(%d)$')
    if Digit then
        local Amt = ATM.State.amount
        if (Amt == '' and Digit == '0') or #Amt >= Config.ATM.Withdraw.MaxDigits then return end
        ATM.State.amount = Amt .. Digit
        Push()
    elseif Quick then
        ATM.State.amount = tostring(Config.ATM.Withdraw.QuickAmounts[tonumber(Quick)])
        Push()
    elseif Actions[Id] then
        CreateThread(Actions[Id]) -- some actions await the server
    end
end

-- Keyboard (fw-dui typing): digits, Backspace and Enter on the withdraw screen.
AddEventHandler('fw-dui:Client:Key', function(Name, Key)
    if Name ~= SCREEN or not ATM.InSession or ATM.State.screen ~= 'withdraw' then return end
    local Id = Key:match('^%d$') and 'key_' .. Key or (Key == 'Backspace' and 'key_del') or (Key == 'Enter' and 'submit')
    if Id then OnClick(Id) end
end)

-- ── Session ────────────────────────────────────────────────────────────────

local function StartATM(Entity)
    local Model = ModelOf(Entity)
    local PlayerData = FW.Functions.GetPlayerData()
    if ATM.InSession or not Model or not PlayerData or not PlayerData.citizenid then return end

    ATM.InSession, ATM.Entity, ATM.Model, ATM.Hover = true, Entity, Model, nil
    ATM.State = { screen = 'loading', accounts = {}, accIndex = 1, amount = '' }
    SetBusy(false)

    TaskTurnPedToFaceEntity(PlayerPedId(), Entity, 800)
    Wait(600)

    local Shown, ScreenEntity = DUI:Show(SCREEN, Entity)
    if not Shown then
        ATM.InSession = false
        local Text = Config.ATM.Text
        if ScreenEntity == 'busy' then return FW.Functions.Notify(Text.atm_busy or 'Someone is using this ATM', 'error') end
        if ScreenEntity == 'full' then return FW.Functions.Notify(Text.atms_full or 'All ATMs here are busy, try again in a moment', 'error') end
        return FW.Functions.Notify(('ATM screen failed (%s), see /duitrace'):format(tostring(ScreenEntity)), 'error')
    end
    ATM.Entity = ScreenEntity -- the screen copy when fw-dui swapped the ATM
    Push()

    exports['fw-assets']:RequestAnimationDict('amb@prop_human_atm@male@idle_a')
    TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@idle_a', 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)
    DUI:Focus(SCREEN, { X = 50.0, Y = 72.0, Sensitivity = Config.ATM.CursorSensitivity })

    local Result = FW.SendCallback('fw-financials:Server:ATM:GetAccounts') or {}
    if not ATM.InSession then return end

    ATM.State.accounts, ATM.State.dailyLeft = Result.Accounts or {}, Result.DailyLeft or 0
    if #ATM.State.accounts == 0 then
        Toast(Config.ATM.Text.no_accounts)
        Wait(1500)
        return EndATM()
    end
    SetScreen('accounts')
end

function EndATM()
    if not ATM.InSession then return end
    ATM.InSession = false
    SetBusy(true)
    ATM.State = { screen = 'goodbye' }
    Push()
    Send('CURSOR', { visible = false })

    DUI:StopFocus()
    ClearPedTasks(PlayerPedId())

    SetTimeout(1200, function()
        if ATM.InSession then return end
        ATM.State = { screen = 'idle' }
        Push()
        DUI:Release(SCREEN) -- the ATM gets its normal screen back, the copy is free for the next player
        ATM.Entity, ATM.Model, ATM.Busy = nil, nil, false
    end)
end

-- Entity optional: nearest ATM when nil. Used by cl_zones.lua (interact).
function OpenATM(Entity)
    if ATM.InSession then return false end
    if type(Entity) ~= 'number' or not DoesEntityExist(Entity) then Entity = GetClosestATM() end
    if not Entity then
        FW.Functions.Notify(Config.ATM.Text.no_atm, 'error')
        return false
    end
    CreateThread(function() StartATM(Entity) end)
    return true
end

exports('OpenATM', OpenATM)
exports('CloseATM', EndATM)
exports('IsInATM', function() return ATM.InSession end)

if Config.ATM.TestCommand then
    RegisterCommand(Config.ATM.TestCommand, function() OpenATM() end, false)
end

-- ── fw-dui ─────────────────────────────────────────────────────────────────

local function RegisterScreen()
    local Models = {}
    for Model in pairs(Config.ATM.Models) do Models[#Models + 1] = Model end
    DUI:RegisterScreen(SCREEN, {
        Url = ('nui://%s/html/atm/index.html'):format(GetCurrentResourceName()),
        Models = Models,
        Mirror = true, -- players nearby see your ATM screen (balances hidden)
    })
end

local function InitData(Model, Idle)
    local M = Config.ATM.Models[Model]
    return {
        layout = ATM_Layout,
        bankName = Config.ATM.BankName,
        quickAmounts = Config.ATM.Withdraw.QuickAmounts,
        dailyLimit = Config.ATM.Withdraw.DailyLimit,
        model = Model,
        sheet = M and (Idle and M.IdleSheet or M.Sheet) == true,
    }
end

-- Your ATM's page is loaded: the static setup, then your session (mirrored, so players around get it too).
AddEventHandler('fw-dui:Client:Shown', function(Name, Entity)
    if Name ~= SCREEN then return end
    Send('INIT', InitData(ModelOf(Entity)))
    Push()
end)

-- The idle page of an ATM model (shared by every ATM of that model nobody uses): setup + the idle screen.
AddEventHandler('fw-dui:Client:Idle', function(Name, Model)
    if Name ~= SCREEN or not Config.ATM.Models[Model] then return end
    DUI:SendIdle(SCREEN, Model, 'INIT', InitData(Model, true))
    DUI:SendIdle(SCREEN, Model, 'STATE', { screen = 'idle' })
end)

AddEventHandler('fw-dui:Client:Cursor', function(Name, X, Y)
    if Name ~= SCREEN then return end
    ATM.Hover = HitTest(X, Y)
    Send('CURSOR', { x = X, y = Y, hover = ATM.Hover, visible = true })
end)

AddEventHandler('fw-dui:Client:Click', function(Name)
    if Name == SCREEN then OnClick(ATM.Hover) end
end)

AddEventHandler('fw-dui:Client:Closed', function(Name)
    if Name == SCREEN then EndATM() end
end)

AddEventHandler('onClientResourceStart', function(Resource)
    if Resource == 'fw-dui' then RegisterScreen() end
end)

CreateThread(function()
    if GetResourceState('fw-dui') == 'started' then RegisterScreen() end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() and ATM.InSession then ClearPedTasks(PlayerPedId()) end
end)
