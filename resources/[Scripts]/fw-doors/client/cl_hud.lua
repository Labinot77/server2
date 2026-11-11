-- Door HUD, ported from ox_doorlock (codera edit): [E] key + bitmap-font label,
-- ring marker on nearby doors and a centre crosshair while targeting a door.

DoorHud = { Enabled = false, Access = {} }

local Defaults = {
    Enabled = true, Mode = 'interact', InteractDistance = 2.0, GateInteractDistance = 8.0, RegisterDistance = 30.0, Labels = { [0] = 'UNLOCKED', [1] = 'LOCKED' },
    Colors = { [0] = { 255, 255, 255, 255 }, [1] = { 255, 255, 255, 255 } },
    NoAccessAlpha = 160, KeyColor = { 255, 255, 255, 255 }, KeySize = 0.0125, TextSize = 0.0115,
    TextGap = 0.0045, Tracking = -3, SpaceWidth = 12, RingSize = 0.0095, RingAlpha = 195,
    CenterSize = 0.0035, RingDistance = 6.0, ZOffset = 0.0, ShowOnGates = false,
}
Config.HUD = Config.HUD or {}
for K, V in pairs(Defaults) do
    if Config.HUD[K] == nil then Config.HUD[K] = V end
end

local Cfg = Config.HUD
if not Cfg.Enabled then return end

if Cfg.Mode == 'interact' then
    -- cl_interact.lua handles the UI; fw-ui prompts and our own drawing stay off.
    DoorHud.Enabled, DoorHud.Interact = true, true
    return
end
if not DoorHudFont then return print('^1[fw-doors]^7 cl_hud_font.lua not loaded - check fxmanifest.lua') end

local TXD = 'fw_doors_hud'
local Font = DoorHudFont
local Glyphs = Font.glyphs
local K = Cfg.TextSize / Font.lineHeight

local DrawSprite, DrawSpriteUv = DrawSprite, DrawSpriteUv
local SetDrawOrigin, ClearDrawOrigin = SetDrawOrigin, ClearDrawOrigin
local GetAspectRatio = GetAspectRatio

local Txd = CreateRuntimeTxd(TXD)
for _, Name in ipairs({ 'key_e', 'font', 'dot', 'crosshair' }) do
    CreateRuntimeTextureFromImage(Txd, Name, ('assets/hud/%s.png'):format(Name))
end

local function DrawHudText(Str, X, Y, Ratio, C, Alpha)
    local Baseline = Y + (Font.lineHeight * 0.5) * K * Ratio

    for i = 1, #Str do
        local Ch = Str:sub(i, i)
        if Ch == ' ' then
            X = X + Cfg.SpaceWidth * K
        else
            local G = Glyphs[Ch]
            if G then
                local W, H = G[5] * K, G[6] * K * Ratio
                local Cy = Baseline + (G[7] - G[6] * 0.5) * K * Ratio
                DrawSpriteUv(TXD, 'font', X + W * 0.5, Cy, W, H, G[1], G[2], G[3], G[4], 0.0, C[1], C[2], C[3], Alpha or C[4])
                X = X + (G[5] - Cfg.Tracking) * K
            end
        end
    end
end

local function DrawPrompt(Coords, State, HasAccess)
    local Ratio = GetAspectRatio(true)
    local Label = Cfg.Labels[State] or ''
    local Color = Cfg.Colors[State] or { 255, 255, 255, 255 }
    local KeySize = Cfg.KeySize

    SetDrawOrigin(Coords.x, Coords.y, Coords.z + Cfg.ZOffset, 0)

    if HasAccess then
        local Kc = Cfg.KeyColor
        DrawSprite(TXD, 'key_e', 0.0, 0.0, KeySize, KeySize * Ratio, 0.0, Kc[1], Kc[2], Kc[3], Kc[4])
        DrawHudText(Label, KeySize * 0.5 + Cfg.TextGap, 0.0, Ratio, Color)
    else
        DrawHudText(Label, KeySize * 0.5 + Cfg.TextGap, 0.0, Ratio, Color, Cfg.NoAccessAlpha)
    end

    ClearDrawOrigin()
end

local function DrawRing(Coords)
    local Ratio = GetAspectRatio(true)
    SetDrawOrigin(Coords.x, Coords.y, Coords.z + Cfg.ZOffset, 0)
    DrawSprite(TXD, 'dot', 0.0, 0.0, Cfg.RingSize, Cfg.RingSize * Ratio, 0.0, 255, 255, 255, Cfg.RingAlpha)
    ClearDrawOrigin()
end

local function DrawCenter()
    local S = Cfg.CenterSize
    DrawSprite(TXD, 'crosshair', 0.5, 0.5, S, S * GetAspectRatio(true), 0.0, 255, 255, 255, 255)
end

-- Middle of the door model (like ox_doorlock), falls back to the config coords.
local Centers = {}

local function GetDoorCenter(DoorId, Door)
    local Cached = Centers[DoorId]
    if Cached and Cached.Src == Door.Coords and DoesEntityExist(Cached.Entity) then
        return Cached.Coords
    end

    local Model = type(Door.Model) == 'string' and GetHashKey(Door.Model) or Door.Model
    local Entity = GetClosestObjectOfType(Door.Coords.x, Door.Coords.y, Door.Coords.z, 1.0, Model, false, false, false)
    if Entity == 0 then return Door.Coords end

    local Min, Max = GetModelDimensions(Model)
    local Mid = GetOffsetFromEntityInWorldCoords(Entity, (Min.x + Max.x) / 2, (Min.y + Max.y) / 2, 0.0)
    local Center = vector3(Mid.x, Mid.y, Door.Coords.z)

    Centers[DoorId] = { Entity = Entity, Coords = Center, Src = Door.Coords }
    return Center
end

function DoorHud.Invalidate(DoorId)
    if DoorId then Centers[DoorId] = nil else Centers = {} end
end

local function ShouldDraw(Door)
    if not Door or Door.Disabled or Door.IsHidden then return false end
    if Door.IsGate and not Cfg.ShowOnGates then return false end
    return true
end

-- Collect doors in range every 500ms so the draw loop stays cheap.
local Nearby = {}

CreateThread(function()
    while true do
        local List = {}
        if LoggedIn and Config.Doors then
            local Pos = GetEntityCoords(PlayerPedId())
            local Range = Cfg.RingDistance + 2.0
            for DoorId, Door in pairs(Config.Doors) do
                if ShouldDraw(Door) and Door.Coords and #(Pos - Door.Coords) < Range then
                    List[#List + 1] = DoorId
                end
            end
        end
        Nearby = List
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        local Num = #Nearby
        if Num > 0 then
            local Pos = GetEntityCoords(PlayerPedId())
            local Targeting = false

            for i = 1, Num do
                local DoorId = Nearby[i]
                local Door = Config.Doors[DoorId]

                if ShouldDraw(Door) then
                    local Dist = #(Pos - Door.Coords)
                    local Interact = Door.IsGate and 8.0 or 2.0
                    local Center = GetDoorCenter(DoorId, Door)

                    if DoorId == CurrentDoor and Dist < Interact then
                        DrawPrompt(Center, Door.Locked, DoorHud.Access[DoorId])
                        Targeting = true
                    elseif Dist <= Cfg.RingDistance then
                        DrawRing(Center)
                    end
                end
            end

            if Targeting then DrawCenter() end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

DoorHud.Enabled = true
