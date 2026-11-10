-- ATM session: owns the screen state, moves the on-screen cursor with the mouse and
-- hit-tests clicks against client/layout.lua. Every change is pushed to the DUI.

local FW = exports['fw-core']:GetCoreObject()

local ATM = {
    inSession = false,
    busy = false,
    entity = nil,
    model = nil,
    state = { screen = 'idle' },
    cursor = { x = 50.0, y = 72.0 },
}

-- ── helpers ────────────────────────────────────────────────────────────────

local function Clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function SetInteractDisabled(disabled)
    if GetResourceState('interact') ~= 'started' then return end
    exports['interact']:Disable(disabled)
end

local function PlaySound(name, set)
    PlaySoundFrontend(-1, name, set, true)
end

local function Push()
    ATM_DUI.Send('STATE', ATM.state)
end

local function SetScreen(screen)
    ATM.state.screen = screen
    Push()
end

local function CurrentAccount()
    return ATM.state.accounts and ATM.state.accounts[ATM.state.accIndex]
end

local toastId = 0
local function Toast(msg)
    toastId = toastId + 1
    local id = toastId
    ATM.state.toast = { msg = msg, id = id }
    PlaySound('ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    Push()
    SetTimeout(2500, function()
        if ATM.state.toast and ATM.state.toast.id == id then
            ATM.state.toast = nil
            Push()
        end
    end)
end

local function HitTest(x, y)
    for _, el in ipairs(ATM_Layout[ATM.state.screen] or {}) do
        local r = el.rect
        if x >= r[1] and x <= r[1] + r[3] and y >= r[2] and y <= r[2] + r[4] then
            if (el.id == 'acc_prev' or el.id == 'acc_next') and #ATM.state.accounts < 2 then return nil end
            return el.id
        end
    end
end

local function GetClosestATM()
    local coords = GetEntityCoords(PlayerPedId())
    local closest, closestDist = nil, 2.0
    for model in pairs(Config.Models) do
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, closestDist, joaat(model), false, false, false)
        if obj ~= 0 then
            local dist = #(coords - GetEntityCoords(obj))
            if dist <= closestDist then closest, closestDist = obj, dist end
        end
    end
    return closest
end

local function ModelOf(entity)
    local hash = GetEntityModel(entity)
    for model in pairs(Config.Models) do
        if joaat(model) == hash then return model end
    end
end

-- ── cash prop ──────────────────────────────────────────────────────────────

local function DispenseCash(amount)
    local entity, o = ATM.entity, Config.Models[ATM.model].cash
    local model = amount > 500 and `prop_cash_pile_02` or `prop_anim_cash_pile_01`
    lib.requestModel(model)

    local from = GetOffsetFromEntityInWorldCoords(entity, o.x, o.startY, o.z)
    local to = GetOffsetFromEntityInWorldCoords(entity, o.x, o.endY, o.z)
    local prop = CreateObject(model, from.x, from.y, from.z, true, true, false)
    SetEntityHeading(prop, GetEntityHeading(entity) + 90.0)
    SetEntityCollision(prop, false, false)

    for i = 1, 60 do
        local p = from + (to - from) * (i / 60.0)
        SetEntityCoordsNoOffset(prop, p.x, p.y, p.z, false, false, false)
        Wait(30)
    end
    Wait(2500)
    DeleteObject(prop)
    SetModelAsNoLongerNeeded(model)
end

-- ── actions ────────────────────────────────────────────────────────────────

local function OpenHistory()
    local acc = CurrentAccount()
    ATM.state.history = nil
    ATM.state.historyLoading = true
    SetScreen('history')

    local history = lib.callback.await('osm-atmdui:getHistory', false, acc.id)
    if not ATM.inSession then return end
    ATM.state.history = history or {}
    ATM.state.historyLoading = false
    Push()
end

local function OpenWithdraw()
    ATM.state.amount = ''
    SetScreen('withdraw')
end

local function Withdraw()
    local acc = CurrentAccount()
    local amount = tonumber(ATM.state.amount) or 0

    if amount <= 0 then return Toast(Config.Text.invalid_amount) end
    if amount > Config.Withdraw.maxPerTransaction then return Toast(Config.Text.over_limit) end
    if amount > ATM.state.dailyLeft then return Toast(Config.Text.daily_limit) end
    if amount > acc.balance then return Toast(Config.Text.insufficient_funds) end

    ATM.busy = true
    ATM.state.processing = true
    Push()

    local ok, balance, err, dailyLeft = lib.callback.await('osm-atmdui:withdraw', false, acc.id, amount)
    if not ATM.inSession then return end
    Wait(900)

    ATM.busy = false
    ATM.state.processing = false
    if balance then acc.balance = balance end

    if not ok then
        Push()
        return Toast(err or Config.Text.error)
    end

    ATM.state.dailyLeft = dailyLeft
    ATM.state.amount = ''
    ATM.state.result = { amount = amount, balance = balance, message = Config.Text.take_cash }
    PlaySound('WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    SetScreen('result')
    DispenseCash(amount)
end

local Actions = {
    acc_prev = function()
        ATM.state.accIndex = ((ATM.state.accIndex - 2) % #ATM.state.accounts) + 1
        Push()
    end,
    acc_next = function()
        ATM.state.accIndex = (ATM.state.accIndex % #ATM.state.accounts) + 1
        Push()
    end,
    acc_confirm = function() SetScreen('menu') end,

    menu_history = OpenHistory,
    tab_history = OpenHistory,
    menu_withdraw = OpenWithdraw,
    tab_withdraw = OpenWithdraw,
    menu_finish = function() ATM.EndSession() end,
    back = function() SetScreen(ATM.state.screen == 'menu' and 'accounts' or 'menu') end,

    key_clear = function() ATM.state.amount = ''; Push() end,
    key_del = function() ATM.state.amount = ATM.state.amount:sub(1, -2); Push() end,
    submit = Withdraw,
    result_done = function() SetScreen('menu') end,
}

local function OnClick(id)
    if ATM.busy or not id then return end
    PlaySound('PIN_BUTTON', 'ATM_SOUNDS')
    ATM_DUI.Send('PRESS', { id = id })

    local digit = id:match('^key_(%d)$')
    local quick = id:match('^quick_(%d)$')

    if digit then
        local amt = ATM.state.amount
        if (amt == '' and digit == '0') or #amt >= Config.Withdraw.maxDigits then return end
        ATM.state.amount = amt .. digit
        Push()
    elseif quick then
        ATM.state.amount = tostring(Config.Withdraw.quickAmounts[tonumber(quick)])
        Push()
    elseif Actions[id] then
        CreateThread(Actions[id]) -- some actions await the server
    end
end

-- ── input ──────────────────────────────────────────────────────────────────

local function InputLoop()
    local last
    while ATM.inSession do
        DisableAllControlActions(0)

        local c = ATM.cursor
        c.x = Clamp(c.x + GetDisabledControlNormal(0, 1) * Config.CursorSensitivity, 0.0, 100.0)
        c.y = Clamp(c.y + GetDisabledControlNormal(0, 2) * Config.CursorSensitivity, 0.0, 100.0)
        local hover = HitTest(c.x, c.y)

        local key = ('%.1f:%.1f:%s'):format(c.x, c.y, hover)
        if key ~= last then
            last = key
            ATM_DUI.Send('CURSOR', { x = c.x, y = c.y, hover = hover, visible = true })
        end

        if IsDisabledControlJustPressed(0, 24) then OnClick(hover) end

        -- ESC / Backspace / right click
        if not ATM.busy and (IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 25)) then
            ATM.EndSession()
        end

        Wait(0)
    end
end

-- ── session ────────────────────────────────────────────────────────────────

function ATM.StartSession(entity)
    local model = ModelOf(entity)
    if ATM.inSession or not model or not FW.Functions.GetPlayerData().citizenid then return end

    ATM.inSession, ATM.busy = true, false
    ATM.entity, ATM.model = entity, model
    ATM.cursor = { x = 50.0, y = 72.0 }
    ATM.state = { screen = 'loading', accounts = {}, accIndex = 1, amount = '' }

    SetInteractDisabled(true)
    TaskTurnPedToFaceEntity(PlayerPedId(), entity, 800)
    Wait(600)

    ATM_DUI.Show(model)
    Push()

    lib.requestAnimDict('amb@prop_human_atm@male@idle_a')
    TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@idle_a', 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)
    ATM_Camera.Start(entity, model)
    CreateThread(InputLoop)

    local accounts, dailyLeft = lib.callback.await('osm-atmdui:getAccounts', false)
    if not ATM.inSession then return end

    ATM.state.accounts = accounts or {}
    ATM.state.dailyLeft = dailyLeft
    if #ATM.state.accounts == 0 then
        Toast(Config.Text.no_accounts)
        Wait(1500)
        return ATM.EndSession()
    end
    SetScreen('accounts')
end

function ATM.EndSession()
    if not ATM.inSession then return end
    ATM.inSession, ATM.busy = false, true
    ATM.state = { screen = 'goodbye' }
    Push()
    ATM_DUI.Send('CURSOR', { visible = false })

    ATM_Camera.Stop()
    ClearPedTasks(PlayerPedId())
    SetInteractDisabled(false)

    SetTimeout(1200, function()
        if ATM.inSession then return end
        ATM_DUI.Hide()
        ATM.entity, ATM.model, ATM.busy = nil, nil, false
    end)
end

-- ── API for your interact script ───────────────────────────────────────────

local function OpenATM(entity)
    if ATM.inSession then return false end
    if type(entity) ~= 'number' or not DoesEntityExist(entity) then entity = GetClosestATM() end
    if not entity then
        FW.Functions.Notify(Config.Text.no_atm, 'error')
        return false
    end
    CreateThread(function() ATM.StartSession(entity) end)
    return true
end

exports('OpenATM', OpenATM)
exports('CloseATM', ATM.EndSession)
exports('IsInSession', function() return ATM.inSession end)

if Config.TestCommand then
    RegisterCommand(Config.TestCommand, function() OpenATM() end, false)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() or not ATM.inSession then return end
    ATM_Camera.Stop()
    ClearPedTasks(PlayerPedId())
    SetInteractDisabled(false)
end)
