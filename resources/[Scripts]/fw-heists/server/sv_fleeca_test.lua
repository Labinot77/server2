-- /fleecatest <action> [arg] (admin): walk through the advanced Fleeca robbery. Works on the advanced bank you're in
-- (or the first one). Output: notification + F8 console.
local Cfg = Config.FleecaAdvanced

local function BankOf(Source)
    local C, First = GetEntityCoords(GetPlayerPed(Source)), nil
    for Id, Bank in pairs(Config.Fleeca) do
        if Bank.Advanced then
            First = First or Id
            if #(C - Bank.Center) < 80.0 then return Id end
        end
    end
    return First
end

local function Say(Source, ...) TriggerClientEvent('fw-heists:Client:FleecaTest:Print', Source, { ... }) end
local function Get(Id, Name) return DataManager.Get(GetFleecaPrefix(Id) .. Name, 0) end
local function Set(Id, Name, Value) DataManager.Set(GetFleecaPrefix(Id) .. Name, Value) end
local function V3(P) return vector3(P.x, P.y, P.z) end

local function Teleport(Source, C)
    local Ped = GetPlayerPed(Source)
    SetEntityCoords(Ped, C.x, C.y, C.z, false, false, false, false)
end

local Actions
Actions = {
    help = function(Source)
        local List = {}
        for Name in pairs(Actions) do List[#List + 1] = Name end
        table.sort(List)
        Say(Source, 'Actions: ' .. table.concat(List, ', '),
            'on/off: test mode (no cops, cooldown or disabled heists needed)',
            'tp box|terminal|panel1|panel2|staff|vault: teleport to a step',
            'door 1|2: open a terminal door without a code')
    end,

    on = function(Source)
        GlobalState.FleecaTest = true
        DataManager.Set('GlobalCooldown', false)
        Say(Source, 'Test mode ON: no cops, cooldown or disabled heists needed')
    end,
    off = function(Source)
        GlobalState.FleecaTest = false
        Say(Source, 'Test mode OFF')
    end,

    items = function(Source)
        local Player = FW.Functions.GetPlayer(Source)
        Player.Functions.AddItem(Cfg.Items.Cutters, 1, false, nil, true)
        Player.Functions.AddItem(Cfg.Items.Laptop, 1, false, nil, true)
        Say(Source, ('Gave %s + %s'):format(Cfg.Items.Cutters, Cfg.Items.Laptop))
    end,

    -- Skip steps
    box = function(Source, Id)
        Set(Id, 'box-open', 1)
        Say(Source, 'Power box open: next is [E] Hack network')
    end,
    hack = function(Source, Id)
        Set(Id, 'box-open', 1)
        Set(Id, 'powerbox', 1)
        Say(Source, 'Network hacked (no minigame, no reset timer): the terminal accepts the password now')
    end,
    staff = function(Source, Id)
        TriggerEvent('fw-doors:Server:SetLockStateById', Config.Fleeca[Id].DoorIds[Config.FleecaKeypad.DoorId], 0)
        Set(Id, 'door-lockpicked', 1)
        Say(Source, 'Staff door keypad done (service door open, vault laptop allowed)')
    end,
    door = function(Source, Id, Arg)
        local Door = tonumber(Arg)
        local Data = Door and Config.Fleeca[Id].Advanced.Doors[Door]
        if not Data then return Say(Source, 'Usage: /fleecatest door 1|2') end
        FleecaAdvOpenDoor(Id, Door)
        Say(Source, ('Opened %s (%s)'):format(Data.Label, Data.Door))
    end,
    vault = function(Source, Id)
        Set(Id, 'vault', 2)
        Say(Source, 'Vault state set to open (2)')
    end,

    -- Answers
    password = function(Source, Id)
        local Bank = FleecaAdvState(Id)
        for i, N in ipairs(Bank.Notes) do
            if N.Text == Bank.Password then
                return Say(Source, ('Password: %s (note %d of %d)'):format(Bank.Password, i, #Bank.Notes), 'Hint: ' .. Bank.Hint)
            end
        end
    end,
    code = function(Source, Id)
        local Live = FleecaAdvState(Id).Code
        if not Live then return Say(Source, 'No live code, generate one on the terminal first') end
        Say(Source, ('Door code: %s for %s (%ds left)'):format(Live.Code, Config.Fleeca[Id].Advanced.Doors[Live.Door].Label, Live.Expires - os.time()))
    end,

    status = function(Source, Id)
        local Bank, Doors = FleecaAdvState(Id), {}
        for i, D in ipairs(Config.Fleeca[Id].Advanced.Doors) do Doors[i] = ('%s=%s'):format(D.Label, Bank.Doors[i] and 'open' or 'locked') end
        Say(Source, ('Fleeca %d (%s) | test mode %s'):format(Id, Config.Fleeca[Id].Advanced.Name, tostring(GlobalState.FleecaTest == true)),
            ('box-open=%s powerbox=%s door-lockpicked=%s vault=%s vault-gate=%s'):format(Get(Id, 'box-open'), Get(Id, 'powerbox'), Get(Id, 'door-lockpicked'), Get(Id, 'vault'), Get(Id, 'vault-gate')),
            'Doors: ' .. table.concat(Doors, ', '),
            ('Password: %s | live code: %s | global cooldown: %s'):format(Bank.Password, Bank.Code and Bank.Code.Code or 'none', tostring(DataManager.Get('GlobalCooldown', false))))
    end,

    reset = function(Source, Id)
        ResetFleeca(Id) -- relocks doors, clears states, new password + notes (OnReset)
        DataManager.Set('GlobalCooldown', false)
        Config.Fleeca[Id].Robber = nil
        Say(Source, ('Fleeca %d reset: doors locked, new password + notes'):format(Id))
    end,

    tp = function(Source, Id, Arg)
        local Bank, Adv = Config.Fleeca[Id], Config.Fleeca[Id].Advanced
        local Spots = {
            box = Bank.PowerBox[1], terminal = Adv.Terminal, staff = Bank.StaffDoor, vault = Bank.Vault,
            panel1 = Adv.Doors[1] and V3(Adv.Doors[1].Panel), panel2 = Adv.Doors[2] and V3(Adv.Doors[2].Panel),
        }
        local C = Spots[Arg or '']
        if not C then return Say(Source, 'Usage: /fleecatest tp box|terminal|panel1|panel2|staff|vault') end
        Teleport(Source, C)
        Say(Source, 'Teleported to ' .. Arg)
    end,
}

FW.Commands.Add('fleecatest', 'Advanced Fleeca test tools (/fleecatest help)', { { name = 'action', help = 'help, on, off, items, box, hack, staff, door, vault, password, code, status, reset, tp' }, { name = 'arg', help = 'door number / tp spot' } }, false, function(Source, Args)
    local Action = Actions[(Args[1] or 'help'):lower()]
    if not Action then return Say(Source, 'Unknown action, try /fleecatest help') end
    local Id = BankOf(Source)
    if not Id or not FleecaAdvState(Id) then return Say(Source, 'No advanced Fleeca configured') end
    Action(Source, Id, Args[2])
end, 'admin')
