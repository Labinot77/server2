-- Keypads with a DUI display (html/fleeca/keypad.html), typed on the keyboard (fw-dui typing): digits, Backspace, Enter.
--   fleeca_keypad   : keypad at every Fleeca's StaffDoor, Config.FleecaKeypad.Code -> service door
--   fleeca_secpanel : security panel next to an advanced bank's door, the code worked out from the terminal
--                     (fleeca_secpanel_<model> for a door with its own panel copy)
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
        Done = function(T) return FleecaVault[T.Id] and FleecaVault[T.Id].Staff == 1 end,
        Static = Config.FleecaKeypad.Static,
    },
}

-- Security panels: one screen per panel model. A panel model only shows one page at a time (the texture swap is
-- per model), so a door with its own copy (Doors[x].PanelModel, e.g. v_corp_bk_secpanel_dui_02) gets its own screen
-- and both panels can show a page at once. Without the copy streamed, doors share Config.FleecaAdvanced.Models.Panel.
local function PanelModel(D)
    local M = D.PanelModel
    return M and IsModelInCdimage(joaat(M)) and M or Config.FleecaAdvanced.Models.Panel
end

for _, Bank in pairs(Config.Fleeca) do
    for _, D in ipairs(Bank.Advanced and Bank.Advanced.Doors or {}) do
        local Model = PanelModel(D)
        local Name = Model == Config.FleecaAdvanced.Models.Panel and 'fleeca_secpanel' or 'fleeca_secpanel_' .. Model
        Pads[Name] = Pads[Name] or {
            Model = Model, Max = 6, Static = {}, SwapFrom = Config.FleecaAdvanced.Models.PanelMap,
            Find = function(C) -- the advanced door (with this panel model) whose Panel is at this panel (within 1m)
                local Best, BestDist = nil, 1.0
                for Id, B in pairs(Config.Fleeca) do
                    for Door, DD in ipairs(B.Advanced and B.Advanced.Doors or {}) do
                        local Dist = PanelModel(DD) == Model and #(C - vector3(DD.Panel.x, DD.Panel.y, DD.Panel.z))
                        if Dist and Dist < BestDist then Best, BestDist = { Id = Id, Door = Door }, Dist end
                    end
                end
                return Best
            end,
            Submit = function(T, Code) return FW.SendCallback('fw-heists:Server:FleecaAdv:Panel', T.Id, T.Door, Code) end,
            Done = function(T) return FleecaVault[T.Id] and FleecaVault[T.Id].Doors[T.Door] end, -- door already open
            Live = function(T) return FleecaVault[T.Id] and FleecaVault[T.Id].Live == T.Door end,  -- a code is live for it
        }
        table.insert(Pads[Name].Static, D.Panel)
    end
end

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
    if Ok then
        Close()
        if FleecaAdvRefresh then FleecaAdvRefresh(Pad.Target.Id) end -- prompt gone right away
    elseif Pad.Open == Name then Push(Name) end
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
local function RegisterScreens()
    for Name, P in pairs(Pads) do
        DUI:RegisterScreen(Name, { Url = Url, Models = { P.Model }, Distance = 3.5, Mirror = true, Static = P.Static, SwapFrom = P.SwapFrom })
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
                canInteract = function(Entity)
                    local T = not Pad.Open and P.Find(GetEntityCoords(Entity))
                    -- hidden once the code was entered; panels only while a code is live for their door
                    return T and not P.Done(T) and (not P.Live or P.Live(T))
                end,
                action = function(Entity) CreateThread(function() Open(Name, Entity) end) end } },
        })
    end
end)

-- /fleecatest panels: every security panel near you and the door it belongs to (server/sv_fleeca_test.lua)
RegisterNetEvent('fw-heists:Client:FleecaTest:Panels', function()
    local C, Lines = GetEntityCoords(PlayerPedId()), {}
    for _, Obj in ipairs(GetGamePool('CObject')) do
        local Model, P = GetEntityModel(Obj), nil
        for Name, Pad in pairs(Pads) do
            if Pad.Live and joaat(Pad.Model) == Model then P = Pad end
        end
        local Pos = GetEntityCoords(Obj)
        if P and #(C - Pos) < 15.0 then
            local T = P.Find(Pos)
            local V = T and FleecaVault[T.Id]
            Lines[#Lines + 1] = ('%s at vector4(%.2f, %.2f, %.2f, %.1f) %s -> %s%s'):format(P.Model, Pos.x, Pos.y, Pos.z, GetEntityHeading(Obj),
                GetEntityAlpha(Obj) == 0 and '(fw-dui copy)' or '(real object)',
                T and ('door ' .. T.Door) or 'NO DOOR (not within 1m of a Panel)',
                V and (' | live code for door %s | open: %s'):format(tostring(V.Live), tostring(V.Doors[T.Door])) or '')
        end
    end
    if #Lines == 0 then Lines[1] = 'No security panels within 15m' end
    for _, L in ipairs(Lines) do print('[fleecatest] ' .. L) end
    FW.Functions.Notify(('%d panel(s), see F8'):format(#Lines), 'primary')
end)
