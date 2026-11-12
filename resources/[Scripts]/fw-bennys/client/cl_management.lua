-- Management app on the business laptop (html/management.html): hire, fire, pay, roles, bank access.
-- The page is click-only (a DUI can't receive keyboard input), typed values are asked with the fw-ui input.
-- All checks happen on the server (server/sv_management.lua).

local DUI = exports['fw-dui']
local APP = Config.Laptop.Apps.Management.id

local function Send(Action, Data, MirrorData) DUI:SendApp(LAPTOP_SCREEN, APP, Action, Data, MirrorData) end
local function Toast(Text, Type) Send('toast', { text = Text, type = Type or 'success' }) end

local function Input(Fields)
    local Result = exports['fw-ui']:CreateInput(Fields)
    return type(Result) == 'table' and Result or nil
end

local function Sound(Ok)
    if Ok then
        PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    else
        PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
end

local STATE_ID = { Label = 'State ID', Icon = 'fas fa-id-card', Name = 'Cid' }
local AMOUNT = { Label = 'Amount', Icon = 'fas fa-dollar-sign', Name = 'Amount', Type = 'number' }
local COMMENT = { Label = 'Comment', Icon = 'fas fa-comment', Name = 'Comment' }

-- ── Shown by cl_laptop.lua ─────────────────────────────────────────────────

-- Locked screen (idle laptop / after use), so nobody walking by sees the staff list. Not mirrored.
function ManagementLock()
    Send('lock', {}, false)
end

function ManagementLoad(Business)
    CreateThread(function()
        local View = FW.SendCallback('fw-bennys:Server:Management:Get', Business)
        if GetLaptopBusiness() ~= Business then return end
        if not View or View.Denied then
            return Send('lock', { text = "You don't have access to this app" })
        end
        Send('view', View)
    end)
end

-- ── Actions ────────────────────────────────────────────────────────────────

local function Run(Business, Action, Data)
    local Result = FW.SendCallback('fw-bennys:Server:Management:Action', Business, Action, Data) or {}
    if GetLaptopBusiness() ~= Business then return Result end

    Sound(Result.Success)
    if Result.Message then Toast(Result.Message, Result.Success and 'success' or 'error') end
    if Result.View then Send('view', Result.View) end
    if Result.Bank then Send('bank', Result.Bank) end
    if Result.Denied then Send('lock', { text = "You don't have access to this app" }) end
    return Result
end

local Handlers = {
    refresh = function(Business) ManagementLoad(Business) end,
    sound = function() PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end,

    hire = function(Business, Data)
        local Result = Input({ STATE_ID })
        if Result then Run(Business, 'Hire', { Cid = Result.Cid, Role = Data.Role }) end
    end,
    fire = function(Business, Data) Run(Business, 'Fire', { Cid = Data.Cid }) end,
    setRole = function(Business, Data) Run(Business, 'SetRole', { Cid = Data.Cid, Role = Data.Role }) end,

    -- With a Cid it pays that employee, without one it asks who to pay.
    pay = function(Business, Data)
        local Fields = Data.Cid and { AMOUNT, COMMENT } or { STATE_ID, AMOUNT, COMMENT }
        local Result = Input(Fields)
        if Result then Run(Business, 'Pay', { Cid = Data.Cid or Result.Cid, Amount = Result.Amount, Comment = Result.Comment }) end
    end,
    charge = function(Business)
        local Result = Input({ STATE_ID, AMOUNT, COMMENT })
        if Result then Run(Business, 'Charge', { Cid = Result.Cid, Amount = Result.Amount, Comment = Result.Comment }) end
    end,

    createRole = function(Business)
        local Result = Input({ { Label = 'Role name', Icon = 'fas fa-id-badge', Name = 'Name' } })
        if Result then Run(Business, 'CreateRole', { Name = Result.Name }) end
    end,
    setPermission = function(Business, Data) Run(Business, 'SetPermission', { Role = Data.Role, Permission = Data.Permission, Value = Data.Value }) end,
    deleteRole = function(Business, Data) Run(Business, 'DeleteRole', { Role = Data.Role }) end,

    getBank = function(Business, Data) Run(Business, 'GetBankAccess', { Cid = Data.Cid }) end,
    setBank = function(Business, Data) Run(Business, 'SetBankAccess', { Cid = Data.Cid, Permission = Data.Permission, Value = Data.Value }) end,
}

RegisterNUICallback('management', function(Data, Cb)
    Cb('ok')
    local Business = GetLaptopBusiness()
    local Handler = Data and Handlers[Data.Action]
    if not Business or not Handler then return end -- watchers' copies of the page post too: ignored
    CreateThread(function() Handler(Business, Data) end)
end)
