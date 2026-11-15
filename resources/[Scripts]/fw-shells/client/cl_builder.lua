-- Visual shell builder: freecam + floor-plane cursor + NUI panel (html/index.html). /shellcreator opens the shell list.
local FW = exports['fw-core']:GetCoreObject()
local Ed = nil
local CELL = Config.Cell
local COL = { ok = { 149, 239, 119 }, bad = { 235, 80, 80 }, sel = { 255, 210, 80 }, grid = { 255, 255, 255 } }
local TOOLS = { select = true, wall = true, door = true, window = true, collision = true }

-- // Math \\ --

local function Copy(T) return json.decode(json.encode(T)) end
local function Norm(V) local L = #V return L > 0 and V / L or V end
local function Snap(V, S) return math.floor(V / S + 0.5) * S end
local function V3(P) return vector3(P.x, P.y, P.z) end

local function CamVectors(Rot)
    local X, Z = math.rad(Rot.x), math.rad(Rot.z)
    local Fwd = vector3(-math.sin(Z) * math.cos(X), math.cos(Z) * math.cos(X), math.sin(X))
    local Right = vector3(math.cos(Z), math.sin(Z), 0.0)
    local Up = vector3(Right.y * Fwd.z - Right.z * Fwd.y, Right.z * Fwd.x - Right.x * Fwd.z, Right.x * Fwd.y - Right.y * Fwd.x)
    return Fwd, Right, Up
end

-- Camera position + ray direction through the NUI cursor.
local function CursorRay()
    local X, Y = GetNuiCursorPosition()
    local W, H = GetActiveScreenResolution()
    local Fwd, Right, Up = CamVectors(GetCamRot(Ed.Cam, 2))
    local T = math.tan(math.rad(GetCamFov(Ed.Cam)) / 2)
    return GetCamCoord(Ed.Cam), Norm(Fwd + Right * ((X / W * 2 - 1) * T * (W / H)) + Up * ((1 - Y / H * 2) * T))
end

local function CursorCast(Flags)
    local From, Dir = CursorRay()
    local To = From + Dir * 60.0
    local _, Hit, Coords, _, Entity = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, Flags, PlayerPedId(), 4))
    return Hit == 1, Coords, Entity
end

local function SegDist(P, A, B)
    local Ab, Ap = B - A, P - A
    local T = math.max(0.0, math.min(1.0, (Ap.x * Ab.x + Ap.y * Ab.y) / math.max(Ab.x * Ab.x + Ab.y * Ab.y, 1e-8)))
    return #(P - (A + Ab * T))
end

local function Ends(W)
    local R = math.rad(W.Heading)
    local D = vector3(math.cos(R), math.sin(R), 0.0) * (W.L / 2)
    return V3(W.Pos) - D, V3(W.Pos) + D
end

local function MakeWall(A, B, H, Holes)
    local D = B - A
    return { Pos = { x = A.x + D.x / 2, y = A.y + D.y / 2, z = A.z }, Heading = math.deg(math.atan(D.y, D.x)), L = #D.xy, H = H, Holes = Holes or {} }
end

local function OnFloor(W) return math.abs(W.Pos.z - Ed.FloorZ) < 0.5 end

-- Cursor on the floor plane, snapped to wall ends (magnet) or the grid. Returns point, magnet.
local function Cursor()
    local O, D = CursorRay()
    if math.abs(D.z) < 1e-4 then return end
    local T = (Ed.FloorZ - O.z) / D.z
    if T <= 0 or T > 80 then return end
    local P = O + D * T
    for I, W in ipairs(Ed.Walls) do
        if OnFloor(W) and not (Ed.Drag and Ed.Drag.Index == I) then
            for _, E in ipairs({ Ends(W) }) do
                if #(E.xy - P.xy) < 0.3 then return vector3(E.x, E.y, Ed.FloorZ), true end
            end
        end
    end
    if Ed.Grid then P = vector3(Snap(P.x, CELL), Snap(P.y, CELL), Ed.FloorZ) end
    return P, false
end

-- End of a wall from A towards P: length on the grid, angle in 15 degree steps (Ortho). Magnet points are used as they are.
local function WallEnd(A, P, Magnet)
    local D = P - A
    if Magnet or not Ed.Ortho then return P, #D.xy end
    local Len = Snap(#D.xy, CELL)
    local Ang = math.rad(Snap(math.deg(math.atan(D.y, D.x)), 15.0))
    return A + vector3(math.cos(Ang), math.sin(Ang), 0.0) * Len, Len
end

local function WallAt(P, Max)
    local Best, Index = Max or 0.5, nil
    for I, W in ipairs(Ed.Walls) do
        if OnFloor(W) then
            local A, B = Ends(W)
            local D = SegDist(P.xy, A.xy, B.xy)
            if D < Best then Best, Index = D, I end
        end
    end
    return Index
end

-- Wall with the current door / window added at P, or nil when it doesn't fit.
local function TryHole(I, P)
    local Kind = Ed.Tool
    local Def = Kind == 'door' and Config.Doors[Ed.Door] or Config.Windows[Ed.Window]
    local W = Copy(Ed.Walls[I])
    local N = #W.Holes
    W.Holes[N + 1] = { Type = Kind, X = (WallOffset(W, P)), Z = Def.Z or 0.0, W = Def.W, H = Def.H, Model = Def.Model }
    W = SanitizeWall(W)
    if #W.Holes > N then return W, W.Holes[#W.Holes] end
end

-- // Drawing \\ --

local function Line(A, B, C) DrawLine(A.x, A.y, A.z, B.x, B.y, B.z, C[1], C[2], C[3], 255) end

local function Dot(P, C, S)
    S = S or 0.12
    DrawMarker(28, P.x, P.y, P.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, S, S, S, C[1], C[2], C[3], 200, false, false, 2, false, nil, nil, false)
end

local function Text3D(P, Text)
    SetDrawOrigin(P.x, P.y, P.z, 0)
    SetTextScale(0.35, 0.35)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(Text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function Frame3D(A, B, H, C)
    local Up = vector3(0.0, 0.0, H)
    Line(A, B, C) Line(A + Up, B + Up, C) Line(A, A + Up, C) Line(B, B + Up, C)
end

local function WallBox(W, C)
    local A, B = Ends(W)
    Frame3D(A, B, W.H, C)
    Text3D((A + B) / 2 + vector3(0.0, 0.0, W.H + 0.25), ('%.2f m'):format(W.L))
end

local function HoleBox(W, H, C)
    for _, Y in ipairs({ -0.08, 0.08 }) do
        Frame3D(WallToWorld(W, H.X - H.W / 2, Y, H.Z), WallToWorld(W, H.X + H.W / 2, Y, H.Z), H.H, C)
    end
end

local function DrawGrid(P)
    local Cx, Cy, Z, R = Snap(P.x, 1.0), Snap(P.y, 1.0), Ed.FloorZ + 0.01, 8
    for I = -R, R do
        local A = (I == 0) and 120 or 45
        DrawLine(Cx + I, Cy - R, Z, Cx + I, Cy + R, Z, 255, 255, 255, A)
        DrawLine(Cx - R, Cy + I, Z, Cx + R, Cy + I, Z, 255, 255, 255, A)
    end
end

-- // State \\ --

local function Push()
    local S = Ed.Sel and Ed.Walls[Ed.Sel]
    SendNUIMessage({ Action = 'State', Data = {
        Tool = Ed.Tool, Label = Ed.Label, Tint = Ed.Tint, FrameTint = Ed.FrameTint, Height = Ed.Height, Floor = Ed.FloorZ,
        Grid = Ed.Grid, Ortho = Ed.Ortho, Top = Ed.Top, Door = Ed.Door, Window = Ed.Window, Removed = Ed.Removed, Walls = #Ed.Walls,
        Sel = S and { Index = Ed.Sel, L = S.L, H = S.H, Heading = S.Heading, Holes = S.Holes } or nil,
        Undo = Ed.Index > 1, Redo = Ed.Index < #Ed.History, Dirty = Ed.Dirty, Chain = Ed.Chain ~= nil,
    } })
end

local function Warn(Text) SendNUIMessage({ Action = 'Warn', Text = Text }) end

local function Rebuild()
    DeleteShell(Ed.Ents)
    local Walls = {}
    for _, W in ipairs(Ed.Walls) do Walls[#Walls + 1] = SanitizeWall(W) end
    Ed.Walls = Walls
    if Ed.Sel and not Ed.Walls[Ed.Sel] then Ed.Sel = nil end
    Ed.Ents = SpawnShell(Ed)
    ApplyRemoved(Ed.Removed, true)
end

local function Snapshot() return Copy({ Walls = Ed.Walls, Removed = Ed.Removed, Label = Ed.Label, Tint = Ed.Tint, FrameTint = Ed.FrameTint }) end

local function Commit()
    Rebuild()
    for I = #Ed.History, Ed.Index + 1, -1 do Ed.History[I] = nil end
    Ed.History[#Ed.History + 1] = Snapshot()
    Ed.Index, Ed.Dirty = #Ed.History, true
    Push()
end

local function Restore(S)
    ApplyRemoved(Ed.Removed, false)
    for K, V in pairs(Copy(S)) do Ed[K] = V end
    Ed.Dirty = true
    Rebuild()
    Push()
end

-- Dragged wall (Select tool): move it, or move one end while the other stays. Holes keep their place.
local function DragWall(P, Magnet)
    local D, W = Ed.Drag, Ed.Walls[Ed.Drag.Index]
    if not P or not W then return end
    if D.Mode == 'move' then
        local N = Copy(W)
        N.Pos.x, N.Pos.y = W.Pos.x + P.x - D.Start.x, W.Pos.y + P.y - D.Start.y
        return N
    end
    local A, B = Ends(W)
    local Fixed = D.Mode == 'a' and B or A
    local E = WallEnd(Fixed, P, Magnet)
    local N = D.Mode == 'a' and MakeWall(E, Fixed, W.H, Copy(W.Holes)) or MakeWall(Fixed, E, W.H, Copy(W.Holes))
    if N.L < 1.0 then return end
    for _, H in ipairs(N.Holes) do
        H.X = D.Mode == 'a' and (H.X - W.L / 2 + N.L / 2) or (H.X + W.L / 2 - N.L / 2)
    end
    return N
end

-- // Camera \\ --

local function Fly()
    local Rot = GetCamRot(Ed.Cam, 2)
    local Z = math.rad(Rot.z)
    local Fwd, Right = vector3(-math.sin(Z), math.cos(Z), 0.0), vector3(math.cos(Z), math.sin(Z), 0.0)
    local Move = vector3(0.0, 0.0, 0.0)
    if IsDisabledControlPressed(0, 32) then Move = Move + Fwd end   -- W
    if IsDisabledControlPressed(0, 33) then Move = Move - Fwd end   -- S
    if IsDisabledControlPressed(0, 35) then Move = Move + Right end -- D
    if IsDisabledControlPressed(0, 34) then Move = Move - Right end -- A
    if IsDisabledControlPressed(0, 38) then Move = Move + vector3(0.0, 0.0, 1.0) end -- E
    if IsDisabledControlPressed(0, 44) then Move = Move - vector3(0.0, 0.0, 1.0) end -- Q
    if #Move == 0 then return end
    local C = GetCamCoord(Ed.Cam) + Norm(Move) * Config.CamSpeed * (IsDisabledControlPressed(0, 21) and 3.0 or 1.0) * GetFrameTime()
    SetCamCoord(Ed.Cam, C.x, C.y, C.z)
end

local function SetOutline(E)
    if Ed.Outlined == E then return end
    if Ed.Outlined and DoesEntityExist(Ed.Outlined) then SetEntityDrawOutline(Ed.Outlined, false) end
    Ed.Outlined = E
    if E then SetEntityDrawOutline(E, true) SetEntityDrawOutlineColor(235, 80, 80, 255) end
end

local function DrawFrame()
    local P, Magnet = Cursor()
    Ed.Cursor, Ed.Magnet = P, Magnet
    if P and Ed.Tool ~= 'collision' then DrawGrid(P) end

    local S = Ed.Sel and Ed.Walls[Ed.Sel]
    if S and not Ed.Drag then
        WallBox(S, COL.sel)
        local A, B = Ends(S)
        Dot(A, COL.sel, 0.2) Dot(B, COL.sel, 0.2)
    end
    for _, R in ipairs(Ed.Removed) do Dot(V3(R.Coords), COL.bad, 0.15) end

    local Target = nil
    if Ed.Drag then
        local W = DragWall(P, Magnet)
        if W then WallBox(W, COL.ok) end
    elseif Ed.Tool == 'wall' and P then
        if Ed.Chain then
            local E, Len = WallEnd(Ed.Chain, P, Magnet)
            local C = Len >= 1.0 and COL.ok or COL.bad
            Frame3D(Ed.Chain, E, Ed.Height, C)
            Text3D((Ed.Chain + E) / 2 + vector3(0.0, 0.0, Ed.Height + 0.25), ('%.2f m'):format(Len))
        end
        Dot(P, Magnet and COL.sel or COL.ok)
    elseif (Ed.Tool == 'door' or Ed.Tool == 'window') and P then
        local I = WallAt(P)
        if I then
            local W, H = TryHole(I, P)
            if W then HoleBox(W, H, COL.ok) else Text3D(P + vector3(0.0, 0.0, 1.0), '~r~No room here') end
        end
    elseif Ed.Tool == 'collision' then
        local Hit, C, E = CursorCast(-1)
        if Hit and E ~= 0 and GetEntityType(E) == 3 and not Ed.Ents[E] then
            Target = E
            Text3D(C, 'Click: remove collision')
        elseif Hit then
            Text3D(C, '~r~Static map collision~s~ (can\'t be removed in game)')
        end
    end
    Ed.Target = Target
    SetOutline(Target)
end

-- // Open / close \\ --

local function Close()
    if not Ed then return end
    SetOutline(nil)
    ApplyRemoved(Ed.Removed, false) -- the streamer puts the saved ones back
    DeleteShell(Ed.Ents)
    SendNUIMessage({ Action = 'Close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    RenderScriptCams(false, true, 400, true, false)
    DestroyCam(Ed.Cam, false)
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
    Ed, EditingId = nil, nil
end

local function Save()
    local Id = FW.SendCallback('fw-shells:Server:Save', Ed.Id, Snapshot())
    if not Id then return Warn('Not saved: a shell needs at least one wall.') end
    Ed.Id, EditingId, Ed.Dirty = Id, Id, false
    Warn('Saved.')
    Push()
end

local function Open(Id)
    if Ed then return end
    local S, Ped = Id and Shells[Id], PlayerPedId()
    local Pos, Rot = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local Cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', Pos.x, Pos.y, Pos.z, Rot.x, 0.0, Rot.z, 60.0, false, 0)
    SetCamActive(Cam, true)
    RenderScriptCams(true, true, 400, true, false)
    FreezeEntityPosition(Ped, true)

    Ed = {
        Id = Id, Label = S and S.Label or 'New shell', Tint = S and S.Tint or Config.Tint, FrameTint = S and S.FrameTint or Config.FrameTint,
        Walls = S and Copy(S.Walls) or {}, Removed = S and Copy(S.Removed or {}) or {}, Cam = Cam, Ents = {},
        Tool = S and 'select' or 'wall', Height = Config.WallHeight, Grid = true, Ortho = true, Door = 1, Window = 1,
        FloorZ = S and S.Walls[1].Pos.z or GetEntityCoords(Ped).z - GetEntityHeightAboveGround(Ped), History = {}, Index = 0,
    }
    EditingId = Id
    Rebuild()
    Ed.History[1], Ed.Index = Snapshot(), 1

    local Doors, Windows = {}, {}
    for I, D in ipairs(Config.Doors) do Doors[I] = { Label = D.Label, Size = ('%g x %g m'):format(D.W, D.H) } end
    for I, D in ipairs(Config.Windows) do Windows[I] = { Label = D.Label } end
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ Action = 'Open', Data = { Doors = Doors, Windows = Windows, Colors = Config.Colors } })
    Push()

    CreateThread(function()
        local NextApply = 0
        while Ed do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            HideHudAndRadarThisFrame()
            if not Ed.Typing then Fly() end
            local C = GetCamCoord(Ed.Cam)
            SetFocusPosAndVel(C.x, C.y, C.z, 0.0, 0.0, 0.0)
            DrawFrame()
            if GetGameTimer() > NextApply then NextApply = GetGameTimer() + 1000 ApplyRemoved(Ed.Removed, true) end
            Wait(0)
        end
    end)
end

-- // NUI callbacks \\ --

local function Cb(Name, Fn)
    RegisterNUICallback('b/' .. Name, function(D, Reply)
        Reply(Ed and Fn(D or {}) or {})
    end)
end

local Keys = {
    grid = function() Ed.Grid = not Ed.Grid end,
    ortho = function() Ed.Ortho = not Ed.Ortho end,
    top = function()
        Ed.Top = not Ed.Top
        local R = GetCamRot(Ed.Cam, 2)
        SetCamRot(Ed.Cam, Ed.Top and -89.0 or -35.0, 0.0, R.z, 2)
    end,
    floorpick = function()
        local Hit, C = CursorCast(1)
        if Hit then Ed.FloorZ = C.z end
    end,
    floorup = function() Ed.FloorZ = Ed.FloorZ + CELL end,
    floordown = function() Ed.FloorZ = Ed.FloorZ - CELL end,
    delete = function()
        if not Ed.Sel then return end
        table.remove(Ed.Walls, Ed.Sel)
        Ed.Sel = nil
        Commit()
    end,
    undo = function() if Ed.Index > 1 then Ed.Index = Ed.Index - 1 Restore(Ed.History[Ed.Index]) end end,
    redo = function() if Ed.Index < #Ed.History then Ed.Index = Ed.Index + 1 Restore(Ed.History[Ed.Index]) end end,
    save = Save,
}

Cb('key', function(D)
    if D.K == 'cancel' then -- Esc / right click: stop the wall, drop the selection, else ask to close
        if Ed.Chain then Ed.Chain = nil elseif Ed.Sel then Ed.Sel = nil else return { Close = true } end
    elseif Keys[D.K] then
        Keys[D.K]()
    end
    if Ed then Push() end
end)

Cb('tool', function(D)
    if not TOOLS[D.T] then return end
    Ed.Tool, Ed.Chain, Ed.Drag = D.T, nil, nil
    Push()
end)

Cb('typing', function(D) Ed.Typing = D.State == true end)

Cb('look', function(D)
    local R = GetCamRot(Ed.Cam, 2)
    local Pitch = Ed.Top and R.x or math.max(-89.0, math.min(89.0, R.x - (D.dy or 0) * 0.12))
    SetCamRot(Ed.Cam, Pitch, 0.0, R.z - (D.dx or 0) * 0.12, 2)
end)

Cb('wheel', function(D) -- zoom along the view
    local Fwd = CamVectors(GetCamRot(Ed.Cam, 2))
    local C = GetCamCoord(Ed.Cam) - Fwd * (D.d or 0) * 0.75
    SetCamCoord(Ed.Cam, C.x, C.y, C.z)
end)

Cb('down', function()
    local P, Magnet, Tool = Ed.Cursor, Ed.Magnet, Ed.Tool
    if Tool == 'wall' then
        if not P then return end
        if not Ed.Chain then Ed.Chain, Ed.ChainStart = P, P return Push() end
        local E, Len = WallEnd(Ed.Chain, P, Magnet)
        if Len < 1.0 then return Warn('Walls need to be at least 1 m long.') end
        Ed.Walls[#Ed.Walls + 1] = MakeWall(Ed.Chain, E, Ed.Height)
        Ed.Chain = #(E - Ed.ChainStart) > 0.05 and E or nil -- clicking the first point closes the room
        Commit()
    elseif Tool == 'door' or Tool == 'window' then
        local I = P and WallAt(P)
        local W = I and TryHole(I, P)
        if not W then return Warn(I and 'No room there: holes need 25 cm of wall around them.' or 'Click on a wall.') end
        Ed.Walls[I], Ed.Sel = W, I
        Commit()
    elseif Tool == 'collision' then
        local E = Ed.Target
        if not E then return end
        local C = GetEntityCoords(E)
        SetOutline(nil)
        Ed.Removed[#Ed.Removed + 1] = { Model = GetEntityModel(E), Name = GetEntityArchetypeName(E), Hide = false, Coords = { x = C.x, y = C.y, z = C.z } }
        Commit()
    else
        local I = P and WallAt(P, 0.6)
        Ed.Sel = I
        if I then
            local A, B = Ends(Ed.Walls[I])
            Ed.Drag = { Index = I, Start = P, Mode = #(P.xy - A.xy) < 0.35 and 'a' or #(P.xy - B.xy) < 0.35 and 'b' or 'move' }
        end
        Push()
    end
end)

Cb('up', function()
    local D = Ed.Drag
    if not D then return end
    local N = DragWall(Ed.Cursor, Ed.Magnet)
    Ed.Drag = nil
    if N and Ed.Cursor and #(Ed.Cursor - D.Start) > 0.05 then
        Ed.Walls[D.Index] = N
        Commit()
    end
end)

Cb('set', function(D)
    local V = D.V
    if D.K == 'Label' then Ed.Label = tostring(V):sub(1, 64)
    elseif D.K == 'Tint' or D.K == 'FrameTint' then Ed[D.K] = math.floor(math.max(0, math.min(15, tonumber(V) or 0)))
    elseif D.K == 'Height' then Ed.Height = math.max(1.0, math.min(Config.MaxHeight, Snap(tonumber(V) or Ed.Height, CELL))) return Push()
    elseif D.K == 'Door' and Config.Doors[V] then Ed.Door = V return Push()
    elseif D.K == 'Window' and Config.Windows[V] then Ed.Window = V return Push()
    else return end
    Commit()
end)

-- Selected wall: length / height / rotation around its centre.
Cb('wall', function(D)
    local W = Ed.Sel and Ed.Walls[Ed.Sel]
    if not W then return end
    W.L, W.H, W.Heading = tonumber(D.L) or W.L, tonumber(D.H) or W.H, tonumber(D.Heading) or W.Heading
    Commit()
end)

Cb('hole', function(D)
    local W = Ed.Sel and Ed.Walls[Ed.Sel]
    local H = W and W.Holes[D.I]
    if not H then return end
    if D.K == 'Remove' then table.remove(W.Holes, D.I)
    elseif D.K == 'Model' and Config.Doors[D.V] then H.Model = Config.Doors[D.V].Model
    elseif D.K == 'Flip' or D.K == 'Passage' then H[D.K] = not H[D.K]
    else return end
    Commit()
end)

Cb('removed', function(D)
    local R = Ed.Removed[D.I]
    if not R then return end
    ApplyRemoved({ R }, false)
    if D.K == 'Delete' then table.remove(Ed.Removed, D.I) elseif D.K == 'Hide' then R.Hide = not R.Hide end
    Commit()
end)

Cb('close', function(D)
    if D.Save then Save() if Ed.Dirty then return end end
    Close()
end)

-- // Shell list (/shellcreator) \\ --

local function Ev(Name, Args)
    Args = Args or {}
    Args.Event, Args.Type = 'fw-shells:Client:' .. Name, 'Client'
    return Args
end

RegisterNetEvent('fw-shells:Client:Menu', function()
    if Ed then return end
    local List = {}
    for Id, S in pairs(Shells) do
        List[#List + 1] = { Title = S.Label, Desc = ('%s · %d walls'):format(Id, #S.Walls), SecondMenu = {
            { Title = 'Edit', Icon = 'pen', CloseMenu = true, Data = Ev('Edit', { Id = Id }) },
            { Title = 'Teleport', Icon = 'location-arrow', CloseMenu = true, Data = Ev('Teleport', { Id = Id }) },
            { Title = 'Delete', Icon = 'trash', SecondMenu = { { Title = 'Yes, delete ' .. S.Label, CloseMenu = true, Data = Ev('Delete', { Id = Id }) } } },
        } }
    end
    FW.Functions.OpenMenu({ MainMenuItems = {
        { Title = 'Shell creator', Desc = #List .. ' shells' },
        { Title = 'New shell', Icon = 'plus', Desc = 'Stand in the MLO house', CloseMenu = true, Data = Ev('Edit') },
        { Title = 'Shells', Icon = 'list', SecondMenu = List, Disabled = #List == 0 },
    } })
end)

RegisterNetEvent('fw-shells:Client:Edit', function(D) SetTimeout(250, function() Open(D and D.Id) end) end)
RegisterNetEvent('fw-shells:Client:Delete', function(D) TriggerServerEvent('fw-shells:Server:Delete', D.Id) end)
RegisterNetEvent('fw-shells:Client:Teleport', function(D)
    local C = Shells[D.Id] and GetShellCenter(Shells[D.Id])
    if C then SetEntityCoords(PlayerPedId(), C.x, C.y, C.z + 0.5, false, false, false, false) end
end)

AddEventHandler('onResourceStop', function(Res) if Res == GetCurrentResourceName() then Close() end end)
