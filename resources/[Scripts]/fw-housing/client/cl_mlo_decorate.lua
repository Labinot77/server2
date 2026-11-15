-- MLO decorate editor: freecam locked to the house zone, gizmo, multi-select / link, tint, grid snap,
-- local working copy (Ctrl+S save / Ctrl+Z undo / Ctrl+Y redo). NUI in html/index.html. House management: the tablet (cl_tablet.lua).
-- Uses from cl_mlo.lua: GetMloInsideHouseId, GetMloZone, GetMloDecorEntity, GetMloWall, HousingLoadModel, HasMloAccess,
-- IsMloOwner, CreateWall, LayoutWall, DeleteWall, SetMloDecorPaused
local FW = exports['fw-core']:GetCoreObject()
local Cfg = Config.Decorate

local Ed = nil
local COLORS = { x = { 225, 60, 60 }, y = { 80, 220, 100 }, z = { 60, 130, 255 }, hover = { 255, 220, 80 } }
local NEXT_AXIS = { z = 'x', x = 'y', y = 'z' }

exports("IsDecorating", function() return Ed ~= nil end)

-- // Math \\ --

local function Cross(A, B) return vector3(A.y * B.z - A.z * B.y, A.z * B.x - A.x * B.z, A.x * B.y - A.y * B.x) end
local function Dot(A, B) return A.x * B.x + A.y * B.y + A.z * B.z end
local function Norm(V) local L = #V return L > 0 and V / L or V end
local function SnapTo(V, Step) return Step > 0 and math.floor(V / Step + 0.5) * Step or V end
local function Copy(T) return T and json.decode(json.encode(T)) or nil end

local function CamVectors(Rot)
    local X, Z = math.rad(Rot.x), math.rad(Rot.z)
    local Fwd = vector3(-math.sin(Z) * math.cos(X), math.cos(Z) * math.cos(X), math.sin(X))
    local Right = vector3(math.cos(Z), math.sin(Z), 0.0)
    return Fwd, Right, Cross(Right, Fwd)
end

-- Camera position, ray direction through the NUI cursor, cursor (0..1).
local function CursorRay()
    local X, Y = GetNuiCursorPosition()
    local W, H = GetActiveScreenResolution()
    local Fwd, Right, Up = CamVectors(GetCamRot(Ed.Cam, 2))
    local T = math.tan(math.rad(GetCamFov(Ed.Cam)) / 2)
    local Dir = Fwd + Right * ((X / W * 2 - 1) * T * (W / H)) + Up * ((1 - Y / H * 2) * T)
    return GetCamCoord(Ed.Cam), Norm(Dir), vector2(X / W, Y / H)
end

local function Cast(From, Dir, Ignore, Flags)
    local To = From + Dir * 30.0
    local Ray = StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, Flags or (1 + 16), Ignore or PlayerPedId(), 4)
    local _, Hit, Coords, Normal, Entity = GetShapeTestResult(Ray)
    return Hit == 1, Coords, Entity, Normal
end

local function PlaneHit(Origin, Dir, Point, Normal)
    local D = Dot(Dir, Normal)
    if math.abs(D) < 1e-4 then return end
    local T = Dot(Point - Origin, Normal) / D
    return T > 0 and Origin + Dir * T or nil
end

local function ToScreen(V)
    local On, X, Y = GetScreenCoordFromWorldCoord(V.x, V.y, V.z)
    return On and vector2(X, Y) or nil
end

local function SegDist(P, A, B)
    local Ab, Ap = B - A, P - A
    local T = math.max(0.0, math.min(1.0, (Ap.x * Ab.x + Ap.y * Ab.y) / math.max(Ab.x * Ab.x + Ab.y * Ab.y, 1e-8)))
    return #(P - (A + Ab * T))
end

-- // Items (working copy) \\ --

local function InZone(C)
    local Zone = GetMloZone(Ed.House.Mlo)
    return Zone ~= nil and Zone:isPointInside(C) and C.z >= (Zone.minZ or -1e9) and C.z <= (Zone.maxZ or 1e9)
end

local function Parts(It)
    if not It then return {} end
    if It.WallObj then
        local List = {}
        for _, P in ipairs(It.WallObj.Pieces) do List[#List + 1] = P.Entity end
        return List
    end
    return { It.Ent }
end

local function Valid(It) return It and It.Ent and DoesEntityExist(It.Ent) end
local function Sel() return Ed.Sel and Ed.Items[Ed.Sel] end
local function GridStep() return Ed.Grid and Cfg.GridSteps[Ed.GridInc] or 0.0 end
local function RotStep() return Cfg.RotSteps[Ed.RotInc] + 0.0 end
local function Transform(It) return GetEntityCoords(It.Ent), GetEntityRotation(It.Ent, 2) end

local function SetTransform(It, Pos, Rot)
    if not Valid(It) then return end
    if Pos then SetEntityCoordsNoOffset(It.Ent, Pos.x, Pos.y, Pos.z, false, false, false) end
    if Rot then SetEntityRotation(It.Ent, Rot.x, Rot.y, Rot.z, 2, true) end
    if It.WallObj then LayoutWall(It.WallObj) end
end

local function SetTint(It, Tint)
    It.Tint = Tint
    for _, E in ipairs(Parts(It)) do
        if DoesEntityExist(E) then SetObjectTextureVariation(E, Tint or 0) end
    end
end

local function SetAlpha(It, Alpha)
    for _, E in ipairs(Parts(It)) do
        if DoesEntityExist(E) then if Alpha then SetEntityAlpha(E, Alpha, false) else ResetEntityAlpha(E) end end
    end
end

local function SetRemoved(It, Removed)
    It.Removed = Removed
    for _, E in ipairs(Parts(It)) do
        if DoesEntityExist(E) then
            SetEntityVisible(E, not Removed, false)
            SetEntityCollision(E, not Removed, not Removed)
        end
    end
end

local function Outline(It, On)
    if SetEntityDrawOutline == nil then return end
    for _, E in ipairs(Parts(It)) do
        if DoesEntityExist(E) then SetEntityDrawOutline(E, On) end
    end
    if On then SetEntityDrawOutlineColor(80, 220, 100, 255) end
end

local function BottomOffset(It)
    if It.WallObj then return 0.0 end
    local Min = GetModelDimensions(GetEntityModel(It.Ent))
    return -Min.z
end

local function NewProp(Model, Pos, Rot)
    local Hash = HousingLoadModel(Model)
    if not Hash then return end
    local Ent = CreateObjectNoOffset(Hash, Pos.x, Pos.y, Pos.z, false, false, false)
    SetEntityRotation(Ent, Rot.x, Rot.y, Rot.z, 2, true)
    FreezeEntityPosition(Ent, true)
    SetModelAsNoLongerNeeded(Hash)
    return Ent
end

-- Where an item goes on the surface under the cursor (State = per placing / drag session):
--   floors: standing on it (grid snap), ceilings: hanging under it,
--   walls (house shell, other walls, ...): flush against the wall, turned to face out of it. It's turned once per
--   wall, so a rotation you add (scroll) sticks while you slide along the same wall.
-- Returns the position and, when it turned, the rotation.
local function SurfacePose(It, Coords, Normal, State)
    if It.WallObj or not Normal or Normal.z > 0.7 then
        State.Wall = nil
        local Step = GridStep()
        return vector3(SnapTo(Coords.x, Step), SnapTo(Coords.y, Step), Coords.z + BottomOffset(It))
    end
    local Min, Max = GetModelDimensions(GetEntityModel(It.Ent))
    if Normal.z < -0.7 then
        State.Wall = nil
        return vector3(Coords.x, Coords.y, Coords.z - Max.z)
    end

    local N = Norm(vector3(Normal.x, Normal.y, 0.0))
    local Heading = math.deg(math.atan(-N.x, N.y)) -- the item's front (+Y) points out of the wall
    local _, R = Transform(It)
    local Rot
    if not State.Wall or math.abs((Heading - State.Wall + 180.0) % 360.0 - 180.0) > 1.0 then
        State.Wall = Heading
        Rot = vector3(R.x, R.y, Heading)
    end
    -- Back of the item against the wall: -Y side when it faces out, +Y side when turned around.
    local Facing = math.cos(math.rad((Rot or R).z - Heading))
    local Depth = Facing >= 0 and -Min.y or Max.y
    return vector3(Coords.x, Coords.y, Coords.z - (Min.z + Max.z) / 2) + N * Depth, Rot
end

-- Moves the primary selection; in link mode the rest of the selection follows (offsets turn with the yaw).
local function MoveSel(Pos, Rot)
    local It = Sel()
    if not Valid(It) then return end
    local P0, R0 = Transform(It)
    Pos, Rot = Pos or P0, Rot or R0
    SetTransform(It, Pos, Rot)
    if not Ed.Link then return end
    local Yaw, DR = math.rad(Rot.z - R0.z), Rot - R0
    local C, S = math.cos(Yaw), math.sin(Yaw)
    for Key in pairs(Ed.Multi) do
        local O = Ed.Items[Key]
        if Key ~= Ed.Sel and Valid(O) and not O.Removed then
            local P, R = Transform(O)
            local Off = P - P0
            SetTransform(O, Pos + vector3(Off.x * C - Off.y * S, Off.x * S + Off.y * C, Off.z), R + DR)
        end
    end
end

-- Rebuilds a wall with new dimensions. Existing walls keep their original pieces hidden for discard.
local function RebuildWall(It, W)
    local Pos, Rot = Transform(It)
    if It.Own then
        DeleteWall(It.WallObj)
    else
        It.OrigWallObj = It.OrigWallObj or It.WallObj
        for _, E in ipairs(Parts(It)) do SetEntityVisible(E, false, false) SetEntityCollision(E, false, false) end
        It.Own = true
    end
    It.WallObj = CreateWall(W, Pos, Rot, It.Tint)
    It.Ent, It.Wall = It.WallObj.Anchor, W
end

local function LoadItems()
    Ed.Items, Ed.Sel, Ed.Multi, Ed.Placing, Ed.Drag, Ed.N = {}, nil, {}, nil, nil, 0
    for _, D in ipairs(Ed.House.Decorations or {}) do
        local Key = 'd' .. D.Id
        Ed.Items[Key] = {
            Key = Key, Id = D.Id, Model = D.Model, Wall = Copy(D.Wall), Tint = D.Tint,
            Ent = GetMloDecorEntity(D.Id), WallObj = GetMloWall(D.Id),
            Orig = { Pos = vector3(D.Coords.x, D.Coords.y, D.Coords.z), Rot = vector3(D.Rot.x, D.Rot.y, D.Rot.z), Wall = json.encode(D.Wall or false), Tint = D.Tint },
        }
    end
end

-- // History \\ --

local function Snapshot()
    local S = {}
    for Key, It in pairs(Ed.Items) do
        if Valid(It) then
            local Pos, Rot = Transform(It)
            S[Key] = { Pos = Pos, Rot = Rot, Wall = Copy(It.Wall), Tint = It.Tint, Removed = It.Removed }
        end
    end
    return S
end

local function ClearSel()
    for Key in pairs(Ed.Multi) do Outline(Ed.Items[Key], false) end
    Ed.Sel, Ed.Multi = nil, {}
end

local function ApplySnapshot(S)
    for Key, It in pairs(Ed.Items) do
        local St = S[Key]
        if Valid(It) then
            if St and St.Wall and json.encode(St.Wall) ~= json.encode(It.Wall) then RebuildWall(It, St.Wall) end
            SetRemoved(It, not St or St.Removed == true)
            if St then SetTransform(It, St.Pos, St.Rot) SetTint(It, St.Tint) end
        end
    end
    ClearSel()
end

local Push

local function Commit()
    for I = #Ed.History, Ed.Index + 1, -1 do Ed.History[I] = nil end
    Ed.History[#Ed.History + 1] = Snapshot()
    Ed.Index = #Ed.History
    Ed.Dirty = true
    Push()
end

local function ResetHistory()
    Ed.History, Ed.Index, Ed.Dirty = { Snapshot() }, 1, false
end

local function Warn(Text)
    SendNUIMessage({ Action = 'Warn', Text = Text })
end

-- // NUI state \\ --

local function Count()
    local N = 0
    for _, It in pairs(Ed.Items) do if not It.Removed then N = N + 1 end end
    return N, Config.MLOHouses[Ed.House.Mlo].MaxDecorations or 100
end

-- Bank balance minus what the unsaved changes will cost.
local function Funds()
    local Price = Cfg.Price or 0
    local Refund, Have = math.floor(Price * (Cfg.RefundPercentage or 0) / 100), Ed.Balance or 0
    for Key, It in pairs(Ed.Items) do
        if not It.Id and not It.Removed and Key ~= Ed.Placing then Have = Have - Price end
        if It.Id and It.Removed then Have = Have + Refund end
    end
    return Have, Price
end

local function MaxCrates() return (Config.MLOHouses[Ed.House.Mlo].Stash or {}).Crates or 0 end

local function CrateCount(Model)
    local N = 0
    for _, O in pairs(Ed.Items) do
        if not O.Removed and O.Model == (Model or Config.Storage.Crate) then N = N + 1 end
    end
    return N
end

Push = function()
    local Placed, Max = Count()
    local Multi = 0
    for _ in pairs(Ed.Multi) do Multi = Multi + 1 end
    local Data = { Placed = Placed, Max = Max, Dirty = Ed.Dirty, Undo = Ed.Index > 1, Redo = Ed.Index < #Ed.History,
        Adv = Ed.Adv, Axis = Ed.Axis, Rot = Cfg.RotSteps[Ed.RotInc], Grid = Ed.Grid, GridStep = Cfg.GridSteps[Ed.GridInc],
        Link = Ed.Link, Shop = Ed.Shop, Placing = Ed.Placing ~= nil, Multi = Multi, MaxSelect = Cfg.MaxSelect, List = {} }
    if Cfg.ChargeMoney and Ed.Balance then Data.Have, Data.Need = Funds() end

    local Crates, Wardrobes, Walls = 0, 0, 0
    for _, O in pairs(Ed.Items) do
        if not O.Removed then
            local Item = GetDecorItem(O.Model) or {}
            Crates = Crates + (Item.Type == 'crate' and 1 or 0)
            Wardrobes = Wardrobes + (Item.Type == 'wardrobe' and 1 or 0)
            Walls = Walls + ((O.Wall or Item.Category == 'Custom Walls') and 1 or 0)
        end
    end
    Data.Stats = { Crates = Crates, MaxCrates = MaxCrates(), Wardrobes = Wardrobes, Walls = Walls }

    local It = Sel()
    if Valid(It) then
        local Pos, Rot = Transform(It)
        Data.Sel = { Key = It.Key, Model = It.Model, Label = GetItemLabel(It.Model), Pos = { x = Pos.x, y = Pos.y, z = Pos.z },
            Rot = { x = Rot.x, y = Rot.y, z = Rot.z }, Wall = It.Wall, Tint = It.Tint or 0, New = It.Id == nil,
            Tintable = It.Wall ~= nil or (GetDecorItem(It.Model) or {}).Tint == true }
    end
    local Cam = GetCamCoord(Ed.Cam)
    for Key, O in pairs(Ed.Items) do
        if not O.Removed and Valid(O) and Key ~= Ed.Placing then
            Data.List[#Data.List + 1] = { Key = Key, Model = O.Model, Label = GetItemLabel(O.Model), Dist = #(Cam - GetEntityCoords(O.Ent)) }
        end
    end
    table.sort(Data.List, function(A, B) return A.Dist < B.Dist end)
    SendNUIMessage({ Action = 'State', Data = Data })
end

local function SelectOnly(Key)
    ClearSel()
    if Key then Ed.Sel, Ed.Multi = Key, { [Key] = true } end
end

local function ToggleMulti(Key)
    if Ed.Multi[Key] then
        Ed.Multi[Key] = nil
        Outline(Ed.Items[Key], false)
        if Ed.Sel == Key then Ed.Sel = next(Ed.Multi) end
        return
    end
    local N = 0
    for _ in pairs(Ed.Multi) do N = N + 1 end
    if N >= Cfg.MaxSelect then return Warn(('Selection Limit: You can select up to %d objects.'):format(Cfg.MaxSelect)) end
    Ed.Multi[Key], Ed.Sel = true, Key
end

-- // Placing new items (follow the cursor until clicked) \\ --

local function CancelPlacing()
    local It = Ed.Placing and Ed.Items[Ed.Placing]
    if not It then return end
    if It.WallObj then DeleteWall(It.WallObj) elseif DoesEntityExist(It.Ent) then DeleteEntity(It.Ent) end
    Ed.Items[Ed.Placing], Ed.Placing = nil, nil
    if Ed.Sel and not Ed.Items[Ed.Sel] then ClearSel() end
end

local function StartPlacing(Model, Wall, Rot, Tint)
    CancelPlacing()
    if not Ed.Shop then return end
    local Placed, Max = Count()
    if Placed >= Max then return Warn('Object Limit: This house is full, remove something first.') end
    if Model == Config.Storage.Crate and CrateCount() >= MaxCrates() then
        return Warn(('Storage Limit: This house can have %d storage crates.'):format(MaxCrates()))
    end

    local Origin, Dir = CursorRay()
    local Hit, Coords = Cast(Origin, Dir)
    local Pos = Hit and Coords or Origin + Dir * 2.0
    Rot = Rot or vector3(0.0, 0.0, GetCamRot(Ed.Cam, 2).z + 180.0)

    Ed.N = Ed.N + 1
    local It = { Key = 'n' .. Ed.N, Model = Model, Own = true }
    if Wall then
        It.Wall = SanitizeWall(Wall)
        It.WallObj = CreateWall(It.Wall, Pos, Rot, Tint)
        It.Ent = It.WallObj and It.WallObj.Anchor
    else
        It.Ent = NewProp(Model, Pos, Rot)
    end
    if not It.Ent then return Warn('Invalid Object: This object could not be loaded.') end

    SetTint(It, Tint)
    SetAlpha(It, 190)
    Ed.Items[It.Key] = It
    SelectOnly(It.Key)
    Ed.Placing, Ed.Surface = It.Key, {}
end

local function FinishPlacing()
    local It = Ed.Placing and Ed.Items[Ed.Placing]
    if not It then return end
    if not InZone(GetEntityCoords(It.Ent)) then return Warn('Invalid Position: That is outside of the house.') end
    if Cfg.ChargeMoney then
        local Have, Need = Funds()
        if Have < Need then return Warn('Not Enough Money: You do not have enough to build this object.') end
    end
    SetAlpha(It, nil)
    Ed.Placing = nil
    Commit()
end

-- // Gizmo \\ --

local function GizmoAxes(It)
    if Ed.Adv then
        local Right, Fwd, Up = GetEntityMatrix(It.Ent)
        return { x = Norm(Right), y = Norm(Fwd), z = Norm(Up) }
    end
    return { x = vector3(1.0, 0.0, 0.0), y = vector3(0.0, 1.0, 0.0), z = vector3(0.0, 0.0, 1.0) }
end

local function Tri(A, B, C, Col)
    DrawPoly(A.x, A.y, A.z, B.x, B.y, B.z, C.x, C.y, C.z, Col[1], Col[2], Col[3], 255)
    DrawPoly(C.x, C.y, C.z, B.x, B.y, B.z, A.x, A.y, A.z, Col[1], Col[2], Col[3], 255)
end

local function Basis(Axis)
    local U = Norm(Cross(Axis, math.abs(Axis.z) < 0.9 and vector3(0.0, 0.0, 1.0) or vector3(1.0, 0.0, 0.0)))
    return U, Cross(Axis, U)
end

local function Line(A, B, W, Col)
    local Fwd = CamVectors(GetCamRot(Ed.Cam, 2))
    local N = Norm(Cross(B - A, Fwd)) * W
    Tri(A + N, B + N, B - N, Col)
    Tri(A + N, B - N, A - N, Col)
end

local function Cone(Base, Dir, Len, R, Col)
    local U, V = Basis(Dir)
    local Tip = Base + Dir * Len
    for I = 0, 7 do
        local A1, A2 = I / 8 * math.pi * 2, (I + 1) / 8 * math.pi * 2
        local P1, P2 = Base + (U * math.cos(A1) + V * math.sin(A1)) * R, Base + (U * math.cos(A2) + V * math.sin(A2)) * R
        Tri(P1, P2, Tip, Col)
        Tri(P1, P2, Base, Col)
    end
end

-- Draws the gizmo, returns the handle under the cursor: 'x'|'y'|'z' (move), 'c' (centre), 'rx'|'ry'|'rz' (rotate).
local function Gizmo(It, Mouse)
    local P = GetEntityCoords(It.Ent)
    local Size = #(GetCamCoord(Ed.Cam) - P) * 0.16
    local Axes, Hover, Best = GizmoAxes(It), nil, 0.012
    local Active = Ed.Drag and Ed.Drag.Axis
    local function Col(H, Axis) return (Active or Hover) == H and COLORS.hover or COLORS[Axis] end

    local Ps = ToScreen(P)
    if Ps and #(Mouse - Ps) < 0.01 then Hover, Best = 'c', 0 end
    for Axis, Dir in pairs(Axes) do
        local A, B = Ps, ToScreen(P + Dir * Size)
        local D = A and B and SegDist(Mouse, A, B) or 1
        if D < Best then Hover, Best = Axis, D end
    end

    local Rings = {}
    if Ed.Adv then
        local R = Size * 0.75
        for Axis, Dir in pairs(Axes) do
            local U, V = Basis(Dir)
            local Pts = {}
            for I = 0, 40 do
                local A = I / 40 * math.pi * 2
                local Pt = P + (U * math.cos(A) + V * math.sin(A)) * R
                Pts[#Pts + 1] = { Pt, ToScreen(Pt) }
                local Prev = Pts[#Pts - 1]
                if Best > 0 and Prev and Prev[2] and Pts[#Pts][2] then
                    local D = SegDist(Mouse, Prev[2], Pts[#Pts][2])
                    if D < Best then Hover, Best = 'r' .. Axis, D end
                end
            end
            Rings[Axis] = Pts
        end
    end

    for Axis, Pts in pairs(Rings) do
        local C = Col('r' .. Axis, Axis)
        for I = 2, #Pts do Line(Pts[I - 1][1], Pts[I][1], Size * 0.006, C) end
    end
    for Axis, Dir in pairs(Axes) do
        local C = Col(Axis, Axis)
        Line(P, P + Dir * Size * 0.85, Size * 0.012, C)
        Cone(P + Dir * Size * 0.85, Dir, Size * 0.15, Size * 0.04, C)
    end
    local C = (Active or Hover) == 'c' and COLORS.hover or { 255, 255, 255 }
    DrawMarker(28, P.x, P.y, P.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Size * 0.035, Size * 0.035, Size * 0.035, C[1], C[2], C[3], 230, false, false, 2, false, nil, nil, false)
    return Hover, P, Axes
end

local function StartDrag(It, Handle, P, Axes)
    local Origin, Dir, Mouse = CursorRay()
    local Pos, Rot = Transform(It)
    local D = { Axis = Handle, Pos = Pos, Rot = Rot, Mouse = Mouse }
    if Handle:sub(1, 1) == 'r' then
        local C = ToScreen(P)
        if not C then return end
        D.Center, D.A0 = C, math.atan(Mouse.y - C.y, Mouse.x - C.x)
        D.Sign = Dot(Axes[Handle:sub(2)], Norm(P - Origin)) < 0 and -1 or 1
    elseif Handle == 'c' then
        D.Normal = vector3(0.0, 0.0, 1.0)
        D.Start = PlaneHit(Origin, Dir, Pos, D.Normal)
        if not D.Start then return end
    elseif Handle ~= 's' then
        D.Dir = Axes[Handle]
        D.Normal = Norm(Cross(D.Dir, Cross(Norm(Pos - Origin), D.Dir)))
        D.Start = PlaneHit(Origin, Dir, Pos, D.Normal)
        if not D.Start then return end
    end
    Ed.Drag = D
end

local function UpdateDrag(It)
    local D = Ed.Drag
    local Origin, Dir, Mouse = CursorRay()
    -- A click without moving shouldn't nudge anything.
    if not D.Moved then
        if #(Mouse - D.Mouse) < 0.004 then return end
        D.Moved = true
    end

    if D.Axis:sub(1, 1) == 'r' then
        local A = math.atan(Mouse.y - D.Center.y, Mouse.x - D.Center.x)
        local Deg = SnapTo(math.deg(A - D.A0) * D.Sign, Ed.Grid and RotStep() or 0.0)
        local Ax, R = D.Axis:sub(2), D.Rot
        return MoveSel(nil, vector3(R.x + (Ax == 'x' and Deg or 0.0), R.y + (Ax == 'y' and Deg or 0.0), R.z + (Ax == 'z' and Deg or 0.0)))
    end

    local Step, New = GridStep(), nil
    if D.Axis == 's' then
        -- Slide over surfaces under the cursor (floors, walls, ceilings).
        local Hit, Coords, _, Normal = Cast(Origin, Dir, It.Ent, It.WallObj and 1 or nil)
        if not Hit then return end
        D.Surface = D.Surface or {}
        local Rot
        New, Rot = SurfacePose(It, Coords, Normal, D.Surface)
        if InZone(New) then MoveSel(New, Rot) end
        return
    else
        local Hit = PlaneHit(Origin, Dir, D.Pos, D.Normal)
        if not Hit then return end
        if D.Axis == 'c' then
            local Delta = Hit - D.Start
            New = D.Pos + vector3(SnapTo(Delta.x, Step), SnapTo(Delta.y, Step), 0.0)
        else
            New = D.Pos + D.Dir * SnapTo(Dot(Hit - D.Start, D.Dir), Step)
        end
    end
    if InZone(New) then MoveSel(New) end
end

local function ItemAt(Entity)
    for Key, It in pairs(Ed.Items) do
        if not It.Removed and Key ~= Ed.Placing then
            for _, E in ipairs(Parts(It)) do
                if E == Entity then return Key end
            end
        end
    end
end

local function Pick()
    local Origin, Dir = CursorRay()
    local Hit, _, Entity = Cast(Origin, Dir)
    return Hit and Entity ~= 0 and ItemAt(Entity) or nil
end

-- // Catalog \\ --

local Catalog, Entities, SentEntities = nil, nil, false

local function BuildCatalog()
    if Catalog then return Catalog end
    Catalog = {}
    local Txd = Config.CustomWalls.Txd
    for _, W in ipairs(Config.CustomWalls.List) do
        if IsModelInCdimage(GetHashKey(W.Model)) then
            local Ho = W.Hole and { x = (W.Hole.X + W.W / 2 - W.Hole.W / 2) / W.W, y = 1 - (W.Hole.Z + W.Hole.H) / W.H, w = W.Hole.W / W.W, h = W.Hole.H / W.H } -- opening, fractions of the panel
            Catalog[#Catalog + 1] = { M = W.Model, L = W.Label, C = 'Custom Walls', T = true, A = W.W / W.H, Ho = Ho, I = ('https://nui-img/%s/fw_cw_%s'):format(Txd, W.Material) }
        end
    end
    if IsModelInCdimage(GetHashKey('fw_wall_100x100')) then Catalog[#Catalog + 1] = { M = 'fw_wall', L = 'Wall (resizable)', C = 'Build', W = true, T = true } end
    for _, Model in ipairs({ Config.Storage.Crate, Config.Storage.Wardrobe }) do
        if IsModelInCdimage(GetHashKey(Model)) then Catalog[#Catalog + 1] = { M = Model, L = GetItemLabel(Model), C = 'Storage' } end
    end
    for _, Cat in ipairs(Config.DecorCatalog) do
        for _, Item in ipairs(Cat.items) do
            if IsModelInCdimage(GetHashKey(Item.model)) then Catalog[#Catalog + 1] = { M = Item.model, L = GetItemLabel(Item.model), C = Cat.category } end
        end
    end
    return Catalog
end

-- Every prop from fw-dev's Config.Entities that exists in the game (no peds / vehicles).
local function BuildEntities()
    if Entities then return Entities end
    Entities = {}
    for Hash, Name in pairs(GetEntityList()) do
        if not Config.DecorByModel[Name] and IsEntityProp(Name) and IsModelInCdimage(Hash) and not IsModelAVehicle(Hash) then Entities[#Entities + 1] = Name end
    end
    table.sort(Entities)
    return Entities
end

-- // Open / close / save \\ --

local function Discard()
    CancelPlacing()
    for _, It in pairs(Ed.Items) do
        if It.OrigWallObj then
            DeleteWall(It.WallObj)
            It.WallObj, It.Ent, It.Own, It.OrigWallObj = It.OrigWallObj, It.OrigWallObj.Anchor, false, nil
        end
        if It.Own then
            if It.WallObj then DeleteWall(It.WallObj) elseif DoesEntityExist(It.Ent) then DeleteEntity(It.Ent) end
        else
            SetRemoved(It, false)
            SetTransform(It, It.Orig.Pos, It.Orig.Rot)
            SetTint(It, It.Orig.Tint)
        end
        Outline(It, false)
    end
end

local function Save()
    CancelPlacing()
    local Changes = { Adds = {}, Updates = {}, Removes = {} }
    for _, It in pairs(Ed.Items) do
        if Valid(It) then
            local Pos, Rot = Transform(It)
            local P, R = { x = Pos.x, y = Pos.y, z = Pos.z }, { x = Rot.x, y = Rot.y, z = Rot.z }
            if It.Id then
                if It.Removed then
                    Changes.Removes[#Changes.Removes + 1] = It.Id
                elseif #(Pos - It.Orig.Pos) > 0.001 or #(Rot - It.Orig.Rot) > 0.01 or json.encode(It.Wall or false) ~= It.Orig.Wall or (It.Tint or 0) ~= (It.Orig.Tint or 0) then
                    Changes.Updates[#Changes.Updates + 1] = { Id = It.Id, Coords = P, Rot = R, Wall = It.Wall, Tint = It.Tint }
                end
            elseif not It.Removed then
                Changes.Adds[#Changes.Adds + 1] = { Model = It.Model, Coords = P, Rot = R, Wall = It.Wall, Tint = It.Tint }
            end
        end
        Outline(It, false)
    end
    TriggerServerEvent("fw-housing:Server:Decor:Save", Ed.HouseId, Changes)
    return Changes
end

-- After saving: drop the editor's own entities and hand everything back to cl_mlo (it respawns what changed).
local function Cleanup()
    for _, It in pairs(Ed.Items) do
        if It.Own and It.WallObj then DeleteWall(It.WallObj) elseif It.Own and DoesEntityExist(It.Ent) then DeleteEntity(It.Ent) end
        if It.OrigWallObj then It.WallObj, It.Own, It.OrigWallObj = It.OrigWallObj, false, nil end
        if not It.Own then SetRemoved(It, false) end
    end
    Ed.Items, Ed.Sel, Ed.Multi, Ed.Dirty = {}, nil, {}, false
    SetMloDecorPaused(false)
end

local function RefreshBalance()
    if not Cfg.ChargeMoney then return end
    Citizen.CreateThread(function()
        local Balance = FW.SendCallback("fw-housing:Server:Decor:GetBalance")
        if Ed then Ed.Balance = Balance or 0 Push() end
    end)
end

-- Saves, then takes over the entities again once the server copy has been respawned.
local function Reload()
    local Id = Ed.HouseId
    Cleanup()
    Citizen.CreateThread(function()
        local Timeout = GetGameTimer() + 3000
        while GetGameTimer() < Timeout do
            Citizen.Wait(250)
            if not Ed then return end
            local Ready = true
            for _, D in ipairs(Config.Houses[Id].Decorations or {}) do
                if not GetMloDecorEntity(D.Id) then Ready = false end
            end
            if Ready and not Ed.Saving then break end
        end
        if not Ed or Ed.HouseId ~= Id then return end
        SetMloDecorPaused(true)
        Ed.House = Config.Houses[Id]
        LoadItems()
        ResetHistory()
        RefreshBalance()
        Push()
    end)
end

-- Editor owns the screen: no phone / inventory / other keybinds, no HUD or minimap.
local function SetScreenOwned(State)
    LocalPlayer.state:set('keybindsBlocked', State or nil, false)
    pcall(function() exports['fw-hud']:SetHudBlocked(State and 'all' or false) end)
end

function CloseMloEditor()
    if not Ed then return end
    SetScreenOwned(false)
    SetStreamedTextureDictAsNoLongerNeeded(Config.CustomWalls.Txd)
    CancelPlacing()
    if Ed.Dirty then Discard() end
    for _, It in pairs(Ed.Items) do Outline(It, false) end
    SendNUIMessage({ Action = 'Close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    RenderScriptCams(false, true, 400, true, false)
    DestroyCam(Ed.Cam, false)
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
    SetMloDecorPaused(false)
    Ed = nil
end

local function Fly()
    local Fwd, Right = CamVectors(GetCamRot(Ed.Cam, 2))
    local Move = vector3(0.0, 0.0, 0.0)
    if IsDisabledControlPressed(0, 32) then Move = Move + Fwd end   -- W
    if IsDisabledControlPressed(0, 33) then Move = Move - Fwd end   -- S
    if IsDisabledControlPressed(0, 35) then Move = Move + Right end -- D
    if IsDisabledControlPressed(0, 34) then Move = Move - Right end -- A
    if IsDisabledControlPressed(0, 38) then Move = Move + vector3(0.0, 0.0, 1.0) end -- E
    if IsDisabledControlPressed(0, 44) then Move = Move - vector3(0.0, 0.0, 1.0) end -- Q
    if #Move == 0 then return end
    local Speed = (Cfg.CamSpeed or 3.0) * (IsDisabledControlPressed(0, 21) and 3.0 or 1.0) * GetFrameTime()
    local New = GetCamCoord(Ed.Cam) + Norm(Move) * Speed
    if InZone(New) then SetCamCoord(Ed.Cam, New.x, New.y, New.z) end
end

function OpenMloDecorateMenu()
    if Ed then return end
    local HouseId = GetMloInsideHouseId()
    if not HouseId or not HasMloAccess(HouseId, 'Decorate') then return FW.Functions.Notify("You can't decorate here.", "error") end

    local Pos, Rot = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local Cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Pos.x, Pos.y, Pos.z, Rot.x, 0.0, Rot.z, 60.0, false, 0)
    SetCamActive(Cam, true)
    RenderScriptCams(true, true, 400, true, false)
    FreezeEntityPosition(PlayerPedId(), true)
    SetMloDecorPaused(true)
    SetScreenOwned(true)
    RequestStreamedTextureDict(Config.CustomWalls.Txd, false) -- thumbnails (nui-img) of the custom walls

    Ed = { HouseId = HouseId, House = Config.Houses[HouseId], Cam = Cam, Adv = false, Axis = 'z', RotInc = Cfg.RotInc or 2,
        GridInc = Cfg.GridInc or 3, Grid = false, Link = false, Shop = true, Typing = false }
    LoadItems()
    ResetHistory()
    RefreshBalance()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ Action = 'Open', Data = { Catalog = BuildCatalog(), Groups = Cfg.Groups, Thumb = Cfg.Thumbnails, Address = Ed.House.Adress, Colors = Config.CustomWalls.TintColors,
        Entities = not SentEntities and BuildEntities() or nil } })
    SentEntities = true
    Push()

    Citizen.CreateThread(function()
        local LastPush = 0
        while Ed do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            HideHudAndRadarThisFrame()
            if GetMloInsideHouseId() ~= Ed.HouseId or IsEntityDead(PlayerPedId()) then CloseMloEditor() break end

            if not Ed.Typing then Fly() end
            local C = GetCamCoord(Ed.Cam)
            SetFocusPosAndVel(C.x, C.y, C.z, 0.0, 0.0, 0.0)

            for Key in pairs(Ed.Multi) do Outline(Ed.Items[Key], true) end
            local It = Sel()
            if Ed.Placing and Valid(It) then
                -- New object follows the cursor over surfaces (sticks to walls).
                local Origin, Dir = CursorRay()
                local Hit, Coords, _, Normal = Cast(Origin, Dir, It.Ent, It.WallObj and 1 or nil)
                if Hit then
                    local P, R = SurfacePose(It, Coords, Normal, Ed.Surface)
                    if InZone(P) then SetTransform(It, P, R) end
                end
            elseif Valid(It) then
                local _, _, Mouse = CursorRay()
                Ed.Hover = { Gizmo(It, Mouse) }
                if Ed.Drag then
                    UpdateDrag(It)
                    if GetGameTimer() - LastPush > 100 then LastPush = GetGameTimer() Push() end
                end
            else
                Ed.Hover = nil
            end
            Citizen.Wait(0)
        end
    end)
end
exports("OpenMloDecorateMenu", OpenMloDecorateMenu)
RegisterCommand("decorate", OpenMloDecorateMenu, false)

-- // NUI callbacks \\ --

local function Cb(Name, Fn)
    RegisterNUICallback('editor/' .. Name, function(D, Reply)
        Reply(Ed and Fn(D or {}) or 'ok')
    end)
end

local function Rotate(Deg)
    local It = Sel()
    if not Valid(It) then return end
    local _, R = Transform(It)
    local Ax = Ed.Axis
    MoveSel(nil, vector3(R.x + (Ax == 'x' and Deg or 0.0), R.y + (Ax == 'y' and Deg or 0.0), R.z + (Ax == 'z' and Deg or 0.0)))
end

local function Each(Fn)
    for Key in pairs(Ed.Multi) do
        local It = Ed.Items[Key]
        if Valid(It) and not It.Removed then Fn(It) end
    end
end

-- Keyboard shortcuts from the NUI.
local Keys = {
    basic = function() Ed.Adv = false end,
    advanced = function() Ed.Adv = true end,
    axis = function() Ed.Axis = NEXT_AXIS[Ed.Axis] end,
    grid = function() Ed.Grid = not Ed.Grid end,
    link = function() Ed.Link = not Ed.Link end,
    shop = function() Ed.Shop = not Ed.Shop if not Ed.Shop then CancelPlacing() end end,
    cancel = function() if Ed.Placing then CancelPlacing() else ClearSel() end end,
    tint = function()
        local Any = false
        Each(function(It) SetTint(It, ((It.Tint or 0) + 1) % (Cfg.Tints or 16)) Any = true end)
        if Any and not Ed.Placing then Commit() end
    end,
    delete = function()
        if Ed.Placing then return CancelPlacing() end
        if not next(Ed.Multi) then return end
        Each(function(It) Outline(It, false) SetRemoved(It, true) end)
        ClearSel()
        Commit()
    end,
    undo = function()
        if Ed.Index <= 1 then return end
        CancelPlacing()
        Ed.Index = Ed.Index - 1
        ApplySnapshot(Ed.History[Ed.Index])
    end,
    redo = function()
        if Ed.Index >= #Ed.History then return end
        CancelPlacing()
        Ed.Index = Ed.Index + 1
        ApplySnapshot(Ed.History[Ed.Index])
    end,
    save = function()
        local C = Save()
        if #C.Adds + #C.Updates + #C.Removes == 0 then return Warn('Nothing To Save: There are no changes.') end
        Ed.Saving = true
        SetTimeout(3000, function() if Ed then Ed.Saving = false end end)
        Reload()
    end,
}

Cb('key', function(D)
    local Fn = Keys[D.K]
    if not Fn then return end
    Fn()
    if Ed then Push() end
end)

Cb('typing', function(D) Ed.Typing = D.State == true end)
Cb('look', function(D)
    local R = GetCamRot(Ed.Cam, 2)
    SetCamRot(Ed.Cam, math.max(-89.0, math.min(89.0, R.x - (D.dy or 0) * 0.12)), 0.0, R.z - (D.dx or 0) * 0.12, 2)
end)

Cb('spawn', function(D)
    if D.Wall then StartPlacing('fw_wall', { L = 2.0, H = 2.5, Holes = {} })
    elseif GetDecorItem(D.Model) then StartPlacing(D.Model) end
    Push()
end)

Cb('down', function(D)
    if Ed.Placing then return FinishPlacing() end
    local It, H = Sel(), Ed.Hover
    if not D.Ctrl and Valid(It) and H and H[1] then return StartDrag(It, H[1], H[2], H[3]) end

    local Key = Pick()
    if not Key then
        if not D.Ctrl then ClearSel() end
    elseif D.Ctrl then
        ToggleMulti(Key)
    else
        if not (Ed.Link and Ed.Multi[Key]) then SelectOnly(Key) else Ed.Sel = Key end
        StartDrag(Ed.Items[Key], Ed.Adv and 'c' or 's', nil, nil)
    end
    Push()
end)

Cb('up', function()
    local D = Ed.Drag
    Ed.Drag = nil
    if D and D.Moved then Commit() end
end)

-- Right click: select what's under the cursor; the NUI opens the options menu when something is selected.
Cb('options', function()
    if not Ed.Placing then
        local Key = Pick()
        if Key and not Ed.Multi[Key] then SelectOnly(Key) end
    end
    Push()
    return { Open = Sel() ~= nil }
end)

Cb('select', function(D)
    local It = Ed.Items[D.Key]
    if not Valid(It) then return end
    CancelPlacing()
    SelectOnly(D.Key)
    local Dir = GetEntityCoords(It.Ent) - GetCamCoord(Ed.Cam)
    SetCamRot(Ed.Cam, math.deg(math.atan(Dir.z, #vector2(Dir.x, Dir.y))), 0.0, -math.deg(math.atan(Dir.x, Dir.y)), 2)
    Push()
end)

Cb('set', function(D)
    if not Valid(Sel()) or not D.Pos or not D.Rot then return end
    local P = vector3(D.Pos.x + 0.0, D.Pos.y + 0.0, D.Pos.z + 0.0)
    if not InZone(P) then return Warn('Invalid Position: That is outside of the house.') end
    MoveSel(P, vector3(D.Rot.x + 0.0, D.Rot.y + 0.0, D.Rot.z + 0.0))
    if Ed.Placing then Push() else Commit() end
end)

Cb('ground', function()
    local It = Sel()
    if not Valid(It) then return end
    local P = GetEntityCoords(It.Ent)
    for _, E in ipairs(Parts(It)) do SetEntityCollision(E, false, false) end
    local Hit, Coords = Cast(P + vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, -1.0), It.Ent)
    for _, E in ipairs(Parts(It)) do SetEntityCollision(E, true, true) end
    if not Hit then return end
    MoveSel(vector3(P.x, P.y, Coords.z + BottomOffset(It)))
    if Ed.Placing then Push() else Commit() end
end)

Cb('duplicate', function()
    local It = Sel()
    if not Valid(It) or Ed.Placing then return end
    local _, Rot = Transform(It)
    StartPlacing(It.Model, It.Wall and Copy(It.Wall), Rot, It.Tint)
    Push()
end)

-- Colour picked in the options menu (palette row) for everything selected.
Cb('tint', function(D)
    local Tint = math.floor(tonumber(D.Value) or 0)
    if Tint < 0 or Tint >= (Cfg.Tints or 16) then return end
    Each(function(It) SetTint(It, Tint) end)
    if Ed.Placing then Push() else Commit() end
end)

Cb('reset', function()
    local It = Sel()
    if not Valid(It) then return end
    local _, R = Transform(It)
    MoveSel(nil, vector3(0.0, 0.0, R.z))
    if Ed.Placing then Push() else Commit() end
end)

Cb('wall', function(D)
    local It, W = Sel(), SanitizeWall(D)
    if not Valid(It) or not It.Wall or not W then return end
    if It.Own and Ed.Placing then
        DeleteWall(It.WallObj)
        local Pos, Rot = Transform(It)
        It.WallObj = CreateWall(W, Pos, Rot, It.Tint)
        It.Ent, It.Wall = It.WallObj.Anchor, W
        SetAlpha(It, 190)
        return Push()
    end
    RebuildWall(It, W)
    Commit()
end)

-- Scroll: rotate. Ctrl + scroll: rotation step. Alt + scroll: grid step.
Cb('wheel', function(D)
    local Up = (D.d or 0) < 0
    if D.Ctrl then
        Ed.RotInc = math.max(1, math.min(#Cfg.RotSteps, Ed.RotInc + (Up and 1 or -1)))
    elseif D.Alt then
        Ed.GridInc = math.max(1, math.min(#Cfg.GridSteps, Ed.GridInc + (Up and 1 or -1)))
    else
        if not Valid(Sel()) then return end
        Rotate(RotStep() * (Up and 1 or -1))
        if not Ed.Placing then return Commit() end
    end
    Push()
end)

Cb('close', function(D)
    if Ed.Dirty and D.Save then
        Save()
        Cleanup()
    end
    CloseMloEditor()
end)

RegisterNetEvent("fw-housing:Client:SyncHouse", function(HouseId)
    if Ed and HouseId == Ed.HouseId then
        Ed.House = Config.Houses[HouseId] or Ed.House
        Ed.Saving = false
    end
end)

AddEventHandler('onResourceStop', function(Res)
    if Res == GetCurrentResourceName() and Ed then CloseMloEditor() end
end)

RegisterNetEvent("fw-housing:Client:Mlo:OpenDecorate", function() OpenMloDecorateMenu() end)

-- /wallcheck: spawns a kit panel in front of you and tells whether the streamed .ydr has collision.
RegisterCommand('wallcheck', function()
    local Model = 'fw_wall_100x200'
    if not IsModelInCdimage(GetHashKey(Model)) then return FW.Functions.Notify("fw-walls isn't streamed (fw_wall_100x200 missing).", "error") end
    local Ped, Hash = PlayerPedId(), HousingLoadModel(Model)
    local P = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 2.0, -1.0)
    local Wall = CreateObjectNoOffset(Hash, P.x, P.y, P.z, false, false, false)
    SetEntityHeading(Wall, GetEntityHeading(Ped))
    FreezeEntityPosition(Wall, true)
    RequestCollisionForModel(Hash)
    local Timeout = GetGameTimer() + 3000
    while not HasCollisionForModelLoaded(Hash) and GetGameTimer() < Timeout do Wait(50) end
    Wait(250)
    -- 511 = every shape test type: the panels use the vanilla prop flags (map types), not only "object".
    local A, B = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 0.0, 0.3), GetOffsetFromEntityInWorldCoords(Ped, 0.0, 4.0, 0.3)
    local _, Hit, _, _, Entity = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(A.x, A.y, A.z, B.x, B.y, B.z, 511, Ped, 0))
    DeleteEntity(Wall)
    if Hit == 1 and Entity == Wall then
        FW.Functions.Notify("The wall has collision. Still walking through? Restart fw-walls and clear your FiveM cache.", "success", 8000)
    else
        FW.Functions.Notify("The streamed wall has NO collision: run tools/make_wall_collisions.py and replace fw-walls/stream.", "error", 8000)
    end
end, false)
