-- Keypad (Config.FleecaKeypad.Model) at each Fleeca's StaffDoor. Its display is a DUI (html/fleeca/keypad.html),
-- the code is typed on the keyboard (fw-dui typing): digits, Backspace, Enter. The server checks it and opens
-- DoorIds[Config.FleecaKeypad.DoorId] (the service door).
local Cfg = Config.FleecaKeypad
local DUI = exports['fw-dui']
local SCREEN = 'fleeca_keypad'
local Pad = { Open = false, Busy = false, Code = '', Id = nil }

local function Push(Status) DUI:Send(SCREEN, 'state', { length = #Pad.Code, status = Status or 'idle' }) end

local function BankAt(Coords)
    for Id, Bank in pairs(Config.Fleeca) do
        if #(Coords - Bank.StaffDoor) < 3.0 then return Id end
    end
end

local function Close()
    if not Pad.Open then return end
    Pad.Open, Pad.Code = false, ''
    DUI:StopFocus()
    DUI:Release(SCREEN)
    Push()
end

local function Open(Entity)
    local Id = BankAt(GetEntityCoords(Entity))
    if Pad.Open or not Id then return end
    local Shown, Screen = DUI:Show(SCREEN, Entity)
    if not Shown then return end

    Pad.Open, Pad.Busy, Pad.Code, Pad.Id = true, false, '', Id
    TaskTurnPedToFaceEntity(PlayerPedId(), Screen, 500)
    Wait(500)
    Push()
    DUI:Focus(SCREEN, {}) -- keyboard only, no cursor
end

local function Submit()
    Pad.Busy = true
    local Ok = FW.SendCallback('fw-heists:Server:Fleeca:Keypad', Pad.Id, Pad.Code)
    Pad.Code = ''
    Push(Ok and 'granted' or 'denied')
    PlaySoundFrontend(-1, Ok and 'Hack_Success' or 'Hack_Failed', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true)
    Wait(1200)
    Pad.Busy = false
    if Ok then Close() elseif Pad.Open then Push() end
end

AddEventHandler('fw-dui:Client:Key', function(Name, Key)
    if Name ~= SCREEN or not Pad.Open or Pad.Busy then return end
    if Key == 'Enter' and #Pad.Code > 0 then return CreateThread(Submit) end

    if Key:match('^%d$') and #Pad.Code < Cfg.MaxDigits then
        Pad.Code = Pad.Code .. Key
    elseif Key == 'Backspace' and #Pad.Code > 0 then
        Pad.Code = Pad.Code:sub(1, -2)
    else
        return
    end
    PlaySoundFrontend(-1, 'PIN_BUTTON', 'ATM_SOUNDS', true)
    Push()
end)

AddEventHandler('fw-dui:Client:Closed', function(Name)
    if Name ~= SCREEN then return end
    Pad.Open, Pad.Code = false, ''
    DUI:Release(SCREEN)
end)

AddEventHandler('fw-dui:Client:Shown', function(Name)
    if Name == SCREEN and not Pad.Open then Push() end
end)

local function RegisterScreen()
    DUI:RegisterScreen(SCREEN, { Url = ('nui://%s/html/fleeca/keypad.html'):format(GetCurrentResourceName()), Models = { Cfg.Model }, Distance = 4.0, Mirror = true })
end

AddEventHandler('onClientResourceStart', function(Resource)
    if Resource == 'fw-dui' then RegisterScreen() end
end)

CreateThread(function()
    if GetResourceState('fw-dui') == 'started' then RegisterScreen() end
    exports['interact']:AddModelInteraction({
        modelData = { { model = Cfg.Model, offset = vec3(0.0, 0.0, 0.0) } }, distance = 3.0, interactDst = 1.2,
        options = { { name = 'fleeca_keypad', label = 'Use keypad',
            canInteract = function(Entity) return not Pad.Open and BankAt(GetEntityCoords(Entity)) ~= nil end,
            action = function(Entity) CreateThread(function() Open(Entity) end) end } },
    })
end)
