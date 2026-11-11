-- /duicalib [model] : fit the screen corners of the nearest prop and print the config line (Config.DevMode).

if not Config.DevMode then return end

local Corners = { 'TL', 'TR', 'BL' }
local Help = '[1/2/3] Corner  [Arrows] Move X/Z  [PgUp/PgDn] Depth  [SHIFT] Fine  [ENTER] Print  [BACKSPACE] Exit'

local function FindProp(Model)
    local Pos = GetEntityCoords(PlayerPedId())
    local Models = Model and { [Model] = true } or Config.Models
    for Name in pairs(Models) do
        local Entity = GetClosestObjectOfType(Pos.x, Pos.y, Pos.z, 5.0, joaat(Name), false, false, false)
        if Entity ~= 0 then return Entity, Name end
    end
end

local function Fmt(V) return ('vec3(%.3f, %.3f, %.3f)'):format(V.x, V.y, V.z) end

RegisterCommand('duicalib', function(_, Args)
    local Entity, Name = FindProp(Args[1])
    if not Entity then return print('[fw-dui] no prop within 5m') end

    -- Unknown models need an entry to be attachable.
    if not Config.Models[Name] then
        Config.Models[Name] = { Name = Name }
        print(('[fw-dui] %s is not in Config.Models, add it after calibrating'):format(Name))
    end

    -- Start from the config, or the front face of the model's bounding box.
    local M = Config.Models[Name]
    local Min, Max = GetModelDimensions(GetEntityModel(Entity))
    local G = {
        TL = M.TL or vector3(Min.x, Min.y, Max.z),
        TR = M.TR or vector3(Max.x, Min.y, Max.z),
        BL = M.BL or vector3(Min.x, Min.y, Min.z),
    }

    local W, H = GetResolution(Name)
    local Id = Create(('nui://%s/html/calibrate.html'):format(GetCurrentResourceName()), W, H)
    if not Id then return end

    Attach(Id, Entity, G) -- G is edited in place below, the screen follows
    local Selected = 1
    exports['fw-ui']:ShowInteraction(Help)

    CreateThread(function()
        while Duis[Id] do
            for Key = 157, 160 do DisableControlAction(0, Key, true) end
            DisableControlAction(0, 177, true)

            if IsDisabledControlJustPressed(0, 157) then Selected = 1 end
            if IsDisabledControlJustPressed(0, 158) then Selected = 2 end
            if IsDisabledControlJustPressed(0, 160) then Selected = 3 end

            local Step = IsControlPressed(0, 21) and 0.001 or 0.005
            local Move = vector3(
                (IsControlJustPressed(0, 175) and Step or 0) - (IsControlJustPressed(0, 174) and Step or 0),
                (IsControlJustPressed(0, 10) and Step or 0) - (IsControlJustPressed(0, 11) and Step or 0),
                (IsControlJustPressed(0, 172) and Step or 0) - (IsControlJustPressed(0, 173) and Step or 0)
            )
            local C = Corners[Selected]
            G[C] = G[C] + Move

            -- Mark the selected corner.
            local P = GetOffsetFromEntityInWorldCoords(Entity, G[C].x, G[C].y, G[C].z)
            DrawMarker(28, P.x, P.y, P.z, 0, 0, 0, 0, 0, 0, 0.008, 0.008, 0.008, 255, 0, 255, 220, false, false, 2, false, nil, nil, false)

            if IsControlJustPressed(0, 191) then
                local Width, Height = #(G.TR - G.TL), #(G.BL - G.TL)
                print(('[\'%s\'] = { Resolution = { 1280, %d }, TL = %s, TR = %s, BL = %s },'):format(
                    Name, math.floor(1280 * Height / Width + 0.5), Fmt(G.TL), Fmt(G.TR), Fmt(G.BL)))
            end

            if IsDisabledControlJustPressed(0, 177) or not DoesEntityExist(Entity) then
                Destroy(Id)
                break
            end
            Wait(0)
        end
        exports['fw-ui']:HideInteraction()
    end)
end, false)
