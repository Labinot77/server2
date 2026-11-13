-- Advanced Fleeca (see config/sh_fleeca_advanced.lua). The server owns every step: box, hack, password, codes, doors.
local Cfg = Config.FleecaAdvanced
local Banks = {}    -- [FleecaId] = { Password, Hint, Notes, Fails, LockedUntil, Hacker, Code, Doors = { [i] = true } }
local Sessions = {} -- [Source] = FleecaId (logged in on a terminal)

local function Key(Id, Name) return GetFleecaPrefix(Id) .. Name end

local function Near(Source, Coords, Max)
    return #(GetEntityCoords(GetPlayerPed(Source)) - vector3(Coords.x, Coords.y, Coords.z)) <= Max
end

local function HasItem(Source, Item)
    local Player = FW.Functions.GetPlayer(Source)
    return Player and Player.Functions.GetItemByName(Item) ~= nil
end

-- New password + notes for a bank: one note has the password, the others decoys with another first letter.
local function Generate(Id)
    local Adv = Config.Fleeca[Id].Advanced
    local Words, Letters = {}, {}
    for _, W in ipairs(Cfg.Words) do Words[#Words + 1] = W end

    local function Password()
        for _ = 1, #Words do
            local W = table.remove(Words, math.random(#Words))
            if not Letters[W:sub(1, 1)] then
                Letters[W:sub(1, 1)] = true
                return W .. math.random(10, 99)
            end
        end
        return 'Fleeca' .. math.random(10, 99)
    end

    local Spots = {}
    for _, V in ipairs(Adv.Notes) do Spots[#Spots + 1] = V end

    local Bank = { Password = Password(), Notes = {}, Fails = 0, LockedUntil = 0, Doors = {} }
    local Correct = math.random(math.min(Cfg.NoteCount, #Spots))
    for i = 1, math.min(Cfg.NoteCount, #Spots) do
        local Spot = table.remove(Spots, math.random(#Spots))
        Bank.Notes[i] = { Coords = Spot, Text = i == Correct and Bank.Password or Password() }
    end
    Bank.Hint = ('Starts with "%s" and has %d characters.'):format(Bank.Password:sub(1, 1), #Bank.Password)

    Banks[Id] = Bank
    TriggerClientEvent('fw-heists:Client:FleecaAdv:Notes', -1, Id, Bank.Notes)
end

local function DoorStates(Id)
    local List = {}
    for i in ipairs(Config.Fleeca[Id].Advanced.Doors) do List[i] = Banks[Id].Doors[i] == true end
    return List
end

-- Live dashboard update for everyone logged in on this bank's terminal.
local function PushState(Id)
    local State = { Doors = DoorStates(Id), Code = Banks[Id].Code and { Door = Banks[Id].Code.Door } or false }
    for Src, BankId in pairs(Sessions) do
        if BankId == Id then TriggerClientEvent('fw-heists:Client:FleecaAdv:State', Src, Id, State) end
    end
end

local function Valid(Id) return Config.Fleeca[Id] and Config.Fleeca[Id].Advanced and Banks[Id] end

CreateThread(function()
    for Id, Bank in pairs(Config.Fleeca) do
        if Bank.Advanced then Generate(Id) end
    end
end)

AddEventHandler('fw-heists:Server:Fleeca:OnReset', function(Id)
    if not Config.Fleeca[Id].Advanced then return end
    DataManager.Set(Key(Id, 'box-open'), 0)
    for _, D in ipairs(Config.Fleeca[Id].Advanced.Doors) do -- doors that aren't in DoorIds (those are relocked by sv_fleeca.lua)
        TriggerEvent('fw-doors:Server:SetLockStateById', D.Door, 1)
    end
    for Src, BankId in pairs(Sessions) do
        if BankId == Id then Sessions[Src] = nil end
    end
    Generate(Id)
end)

AddEventHandler('playerDropped', function()
    Sessions[source] = nil
    for _, Bank in pairs(Banks) do
        if Bank.Hacker == source then Bank.Hacker = nil end
    end
end)

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:GetNotes', function(Source, Cb, Id)
    Cb(Valid(Id) and Banks[Id].Notes or {})
end)

-- ── Power box ──────────────────────────────────────────────────────────────

local function CanStart(Source, Id)
    if not Valid(Id) or not Near(Source, Config.Fleeca[Id].PowerBox[1], 4.0) then return false end
    local Blocked = DataManager.Get('HeistsDisabled', 0) == 1 or DataManager.Get('GlobalCooldown', false) == true
    if Blocked and not GlobalState.FleecaTest then return false end -- /fleecatest mode skips cooldown / disabled
    return DataManager.Get(Key(Id, 'powerbox'), 0) == 0
end

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:Access', function(Source, Cb, Id)
    if not CanStart(Source, Id) or DataManager.Get(Key(Id, 'box-open'), 0) ~= 0 or not HasItem(Source, Cfg.Items.Cutters) then return Cb(false) end
    DataManager.Set(Key(Id, 'box-open'), 1)
    Cb(true)
end)

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:StartHack', function(Source, Cb, Id)
    if not CanStart(Source, Id) or DataManager.Get(Key(Id, 'box-open'), 0) ~= 1 then return Cb(false) end
    if Banks[Id].Hacker then return Cb('busy') end
    if not HasItem(Source, Cfg.Items.Laptop) then return Cb(false) end
    Banks[Id].Hacker, Banks[Id].HackStart = Source, os.time()
    Cb(true)
end)

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:FinishHack', function(Source, Cb, Id, Success)
    local Bank = Valid(Id)
    if not Bank or Bank.Hacker ~= Source then return Cb(false) end
    Bank.Hacker = nil
    if not Success or os.time() - Bank.HackStart < 5 or not CanStart(Source, Id) then return Cb(false) end

    DataManager.Set(Key(Id, 'powerbox'), 1) -- vault laptop / gate / loot from cl_fleeca.lua check this
    StartFleecaRobbery(Source, Id)
    Cb(true)
end)

-- ── Terminal ───────────────────────────────────────────────────────────────

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:Login', function(Source, Cb, Id, Password)
    local Bank = Valid(Id)
    if not Bank or not Near(Source, Config.Fleeca[Id].Center, 25.0) then return Cb({ Error = 'Workstation unavailable.' }) end
    if DataManager.Get(Key(Id, 'powerbox'), 0) == 0 then return Cb({ Error = 'Locked by branch security. Remote sign-in disabled.' }) end
    if os.time() < Bank.LockedUntil then return Cb({ Error = ('Too many attempts. Try again in %ds.'):format(Bank.LockedUntil - os.time()) }) end

    if type(Password) ~= 'string' or Password:lower() ~= Bank.Password:lower() then
        Bank.Fails = Bank.Fails + 1
        if Bank.Fails >= Cfg.MaxAttempts then
            Bank.Fails, Bank.LockedUntil = 0, os.time() + Cfg.Lockout
            return Cb({ Error = ('Account locked for %ds.'):format(Cfg.Lockout), Alert = true })
        end
        return Cb({ Error = ('Incorrect password. %d attempt(s) left.'):format(Cfg.MaxAttempts - Bank.Fails) })
    end

    Bank.Fails, Sessions[Source] = 0, Id
    Cb({ Ok = true, User = Cfg.User, Doors = DoorStates(Id) })
end)

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:Hint', function(Source, Cb, Id)
    Cb(Valid(Id) and Banks[Id].Hint or '')
end)

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:Session', function(Source, Cb, Id)
    Cb(Sessions[Source] == Id and Valid(Id) and { User = Cfg.User, Doors = DoorStates(Id) } or false)
end)

RegisterNetEvent('fw-heists:Server:FleecaAdv:SignOut', function() Sessions[source] = nil end)

-- Codes: the terminal shows a number + instructions, the door code is the number after them (in order).
local Rules = {
    { Label = 'Enter it backwards', Fn = function(S) return S:reverse() end },
    { Label = 'Increase every digit by one', Fn = function(S) return (S:gsub('%d', function(D) return tostring((D + 1) % 10) end)) end },
    { Label = 'Decrease every digit by one', Fn = function(S) return (S:gsub('%d', function(D) return tostring((D - 1) % 10) end)) end, Not = 2 },
    { Label = 'Swap the first and last digit', Fn = function(S) return S:sub(-1) .. S:sub(2, -2) .. S:sub(1, 1) end },
}

local function PickRules(Count)
    local Pool, Picked, Used = {}, {}, {}
    for i = 1, #Rules do Pool[i] = i end
    while #Picked < Count and #Pool > 0 do
        local i = table.remove(Pool, math.random(#Pool))
        if not Used[Rules[i].Not] and not (i == 2 and Used[3]) then
            Used[i], Picked[#Picked + 1] = true, Rules[i]
        end
    end
    return Picked
end

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:GenerateCode', function(Source, Cb, Id, Door)
    local Bank = Valid(Id)
    local Doors = Bank and Config.Fleeca[Id].Advanced.Doors
    if not Bank or Sessions[Source] ~= Id or not Doors[Door] or Bank.Doors[Door] then return Cb(false) end
    if Door > 1 and not Bank.Doors[Door - 1] then return Cb(false) end

    local Shown, Labels = tostring(math.random(100000, 999999)), {}
    local Code = Shown
    for i, R in ipairs(PickRules(Doors[Door].Rules or Door)) do
        Code, Labels[i] = R.Fn(Code), R.Label
    end

    Bank.Code = { Door = Door, Code = Code, Expires = os.time() + Cfg.CodeLifetime } -- replaces the previous one
    PushState(Id)
    Cb({ Shown = Shown, Rules = Labels, Memorise = Cfg.CodeMemorise, Lifetime = Cfg.CodeLifetime })
end)

-- ── Security panels next to the doors (cl_fleeca_keypad.lua) ───────────────

-- Opens terminal door Door of bank Id. Also used by /fleecatest.
function FleecaAdvOpenDoor(Id, Door)
    local Data = Config.Fleeca[Id].Advanced.Doors[Door]
    Banks[Id].Doors[Door] = true
    TriggerEvent('fw-doors:Server:SetLockStateById', Data.Door, 0)
    if Data.Door == Config.Fleeca[Id].DoorIds[3] then DataManager.Set(Key(Id, 'vault-gate'), 2) end -- loot behind the gate (cl_fleeca.lua)
    PushState(Id)
end

function FleecaAdvState(Id) return Banks[Id] end -- for /fleecatest

FW.Functions.CreateCallback('fw-heists:Server:FleecaAdv:Panel', function(Source, Cb, Id, Door, Code)
    local Bank = Valid(Id)
    local Data = Bank and Config.Fleeca[Id].Advanced.Doors[Door]
    if not Data or not Near(Source, Data.Panel, 4.0) then return Cb(false) end

    local Live = Bank.Code
    if not Live or Live.Door ~= Door or os.time() > Live.Expires or tostring(Code) ~= Live.Code then return Cb(false) end

    Bank.Code = nil -- single use
    FleecaAdvOpenDoor(Id, Door)
    Cb(true)
end)

-- ── Staff door keypad prop (cl_fleeca_keypad.lua), every Fleeca ───────────

FW.Functions.CreateCallback('fw-heists:Server:Fleeca:Keypad', function(Source, Cb, Id, Code)
    local Bank = Config.Fleeca[Id]
    if not Bank or not Near(Source, Bank.StaffDoor, 3.0) or tostring(Code) ~= Config.FleecaKeypad.Code then return Cb(false) end

    TriggerEvent('fw-doors:Server:SetLockStateById', Bank.DoorIds[Config.FleecaKeypad.DoorId], 0)
    DataManager.Set(Key(Id, 'door-lockpicked'), 1) -- replaces the staff door lockpick: the vault laptop (cl_fleeca.lua) needs it
    Cb(true)
end)
