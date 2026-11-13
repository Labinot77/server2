-- Keypads with a DUI display (html/fleeca/keypad.html), typed on the keyboard (fw-dui typing): digits, Backspace, Enter.
--   fleeca_keypad   : keypad at every Fleeca's StaffDoor, Config.FleecaKeypad.Code -> service door
--   fleeca_secpanel : security panel next to an advanced bank's door, the code worked out from the terminal
local DUI = exports['fw-dui']
local Url = ('nui://%s/html/fleeca/keypad.html'):format(GetCurrentResourceName())
local Pad = { Open = nil, Busy = false, Code = '', Target = nil }

local Pads = {
    fleeca_keypad = {
        Model = Config.FleecaKeypad.Model, Max = Config.FleecaKeypad.MaxDigits,
        Find = function(C)
            for Id, Bank in pairs(Config.Fleeca) do
                if #(C - Bank.StaffDoor) < 3.0 then return { Id = Id } end
            end
        end,
        Submit = function(T, Code) return FW.SendCallback('fw-heists:Server:Fleeca:Keypad', T.Id, Code) end,
    },
    fleeca_secpanel = {
        Model = Config.FleecaAdvanced.Models.Panel, Max = 6,
        Find = function(C) -- the advanced door whose Panel is closest
            local Best, BestDist = nil, 4.0
            for Id, Bank in pairs(Config.Fleeca) do
                for Door, D in ipairs(Bank.Advanced and Bank.Advanced.Doors or {}) do
                    local Dist = #(C - vector3(D.Panel.x, D.Panel.y, D.Panel.z))
                    if Dist < BestDist then Best, BestDist = { Id = Id, Door = Door }, Dist end
                end
            end
            return Best
        end,
        Submit = function(T, Code) return FW.SendCallback('fw-heists:Server:FleecaAdv:Panel', T.Id, T.Door, Code) end,
    },
}

local function Push(Name, Status)
    DUI:Send(Name, 'state', { length = Pad.Open == Name and #Pad.Code or 0, status = Status or 'idle' })
end

local function Close()
    local Name = Pad.Open
    if not Name then return end
    Pad.Open, Pad.Code = nil, ''
    DUI:StopFocus()
    DUI:Release(Name)
    Push(Name)
end

local function Open(Name, Entity)
    local Target = Pads[Name].Find(GetEntityCoords(Entity))
    if Pad.Open or not Target then return end
    local Shown, Screen = DUI:Show(Name, Entity)
    if not Shown then return end

    Pad.Open, Pad.Busy, Pad.Code, Pad.Target = Name, false, '', Target
    TaskTurnPedToFaceEntity(PlayerPedId(), Screen, 500)
    Wait(500)
    Push(Name)
    DUI:Focus(Name, {}) -- keyboard only, no cursor
end

local function Submit()
    local Name = Pad.Open
    Pad.Busy = true
    local Ok = Pads[Name].Submit(Pad.Target, Pad.Code)
    Pad.Code = ''
    Push(Name, Ok and 'granted' or 'denied')
    PlaySoundFrontend(-1, Ok and 'Hack_Success' or 'Hack_Failed', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true)
    Wait(1200)
    Pad.Busy = false
    if Ok then Close() elseif Pad.Open == Name then Push(Name) end
end

AddEventHandler('fw-dui:Client:Key', function(Name, Key)
    if Name ~= Pad.Open or Pad.Busy then return end
    if Key == 'Enter' and #Pad.Code > 0 then return CreateThread(Submit) end

    if Key:match('^%d$') and #Pad.Code < Pads[Name].Max then
        Pad.Code = Pad.Code .. Key
    elseif Key == 'Backspace' and #Pad.Code > 0 then
        Pad.Code = Pad.Code:sub(1, -2)
    else
        return
    end
    PlaySoundFrontend(-1, 'PIN_BUTTON', 'ATM_SOUNDS', true)
    Push(Name)
end)

AddEventHandler('fw-dui:Client:Closed', function(Name)
    if Name ~= Pad.Open then return end
    Pad.Open, Pad.Code = nil, ''
    DUI:Release(Name)
end)

AddEventHandler('fw-dui:Client:Shown', function(Name)
    if Pads[Name] and Pad.Open ~= Name then Push(Name) end
end)

-- Panels are the bank interior's own (static) panels: fw-dui swaps them to the _dui model at their positions (SwapFrom)
-- and keeps an invisible copy there (Static) so range, camera and interact can find them.
local function PanelSpots()
    local List = {}
    for _, Bank in pairs(Config.Fleeca) do
        for _, D in ipairs(Bank.Advanced and Bank.Advanced.Doors or {}) do List[#List + 1] = D.Panel end
    end
    return List
end

local function RegisterScreens()
    local Static = { fleeca_keypad = Config.FleecaKeypad.Static, fleeca_secpanel = PanelSpots() }
    local SwapFrom = { fleeca_secpanel = Config.FleecaAdvanced.Models.PanelMap }
    for Name, P in pairs(Pads) do
        DUI:RegisterScreen(Name, { Url = Url, Models = { P.Model }, Distance = 3.5, Mirror = true, Static = Static[Name], SwapFrom = SwapFrom[Name] })
    end
end

AddEventHandler('onClientResourceStart', function(Resource)
    if Resource == 'fw-dui' then RegisterScreens() end
end)

CreateThread(function()
    if GetResourceState('fw-dui') == 'started' then RegisterScreens() end
    for Name, P in pairs(Pads) do
        exports['interact']:AddModelInteraction({
            modelData = { { model = P.Model, offset = vec3(0.0, 0.0, 0.0) } }, distance = 3.0, interactDst = 1.2,
            options = { { name = Name, label = 'Use keypad',
                canInteract = function(Entity) return not Pad.Open and P.Find(GetEntityCoords(Entity)) ~= nil end,
                action = function(Entity) CreateThread(function() Open(Name, Entity) end) end } },
        })
    end
end)
