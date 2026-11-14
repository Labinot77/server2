-- MLO decorate editor: freecam locked to the house zone, 3D gizmo, local working copy (save / undo / redo / discard),
-- NUI in html/index.html. Also the owner house menu (bottom of the file).
-- Uses from cl_mlo.lua: GetMloInsideHouseId, GetMloZone, GetMloDecorEntity, GetMloWall, HousingLoadModel, HasMloAccess,
-- IsMloOwner, CreateWall, LayoutWall, DeleteWall, SetMloDecorPaused
local FW = exports['fw-core']:GetCoreObject()

local Ed = nil
local COLORS = { x = { 230, 70, 70 }, y = { 149, 239, 119 }, z = { 70, 140, 240 }, hover = { 242, 163, 101 } }

exports("IsDecorating", function() return Ed ~= nil end)

-- // Math \\ --

local function Cross(A, B) return vector3(A.y * B.z - A.z * B.y, A.z * B.x - A.x * B.z, A.x * B.y - A.y * B.x) end
local function Dot(A, B) return A.x * B.x + A.y * B.y + A.z * B.z end
local function Norm(V) local L = #V return L > 0 and V / L or V end
local function SnapTo(V, Step) return Step > 0 and math.floor(V / Step + 0.5) * Step or V end

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
    local _, Hit, Coords, _, Entity = GetShapeTestResult(Ray)
    return Hit == 1, Coords, Entity
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

local function Copy(T) return T and json.decode(json.encode(T)) or nil end

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

local function Transform(It)
    return GetEntityCoords(It.Ent), GetEntityRotation(It.Ent, 2)
end

local function SetTransform(It, Pos, Rot)
    if not Valid(It) then return end
    if Pos then SetEntityCoordsNoOffset(It.Ent, Pos.x, Pos.y, Pos.z, false, false, false) end
    if Rot then SetEntityRotation(It.Ent, Rot.x, Rot.y, Rot.z, 2, true) end
    if It.WallObj then LayoutWall(It.WallObj) end
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
    if On then SetEntityDrawOutlineColor(149, 239, 119, 255) end
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
    It.WallObj = CreateWall(W, Pos, Rot)
    It.Ent, It.Wall = It.WallObj.Anchor, W
end

local function LoadItems()
    Ed.Items, Ed.Sel, Ed.Placing, Ed.Drag, Ed.N = {}, nil, nil, nil, 0
    for _, D in ipairs(Ed.House.Decorations or {}) do
        local Key = 'd' .. D.Id
        Ed.Items[Key] = {
            Key = Key, Id = D.Id, Model = D.Model, Wall = Copy(D.Wall),
            Ent = GetMloDecorEntity(D.Id), WallObj = GetMloWall(D.Id),
            Orig = { Pos = vector3(D.Coords.x, D.Coords.y, D.Coords.z), Rot = vector3(D.Rot.x, D.Rot.y, D.Rot.z), Wall = json.encode(D.Wall or false) },
        }
    end
end

-- // History \\ --

local function Snapshot()
    local S = {}
    for Key, It in pairs(Ed.Items) do
        if Valid(It) then
            local Pos, Rot = Transform(It)
            S[Key] = { Pos = Pos, Rot = Rot, Wall = Copy(It.Wall), Removed = It.Removed }
        end
    end
    return S
end

local function ApplySnapshot(S)
    for Key, It in pairs(Ed.Items) do
        local St = S[Key]
        if not Valid(It) then goto continue end
        if St and St.Wall and json.encode(St.Wall) ~= json.encode(It.Wall) then RebuildWall(It, St.Wall) end
        SetRemoved(It, not St or St.Removed == true)
        if St then SetTransform(It, St.Pos, St.Rot) end
        ::continue::
    end
    if Ed.Sel and Ed.Items[Ed.Sel].Removed then Outline(Sel(), false) Ed.Sel = nil end
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

-- // NUI state \\ --

local function Count()
    local N = 0
    for _, It in pairs(Ed.Items) do if not It.Removed then N = N + 1 end end
    return N, Config.MLOHouses[Ed.House.Mlo].MaxDecorations or 100
end

Push = function()
    local Placed, Max = Count()
    local It, Data = Sel(), { Placed = Placed, Max = Max, Dirty = Ed.Dirty, Undo = Ed.Index > 1, Redo = Ed.Index < #Ed.History,
        Mode = Ed.Mode, Space = Ed.Space, Placing = Ed.Placing ~= nil, List = {} }
    if Valid(It) then
        local Pos, Rot = Transform(It)
        Data.Sel = { Key = It.Key, Model = It.Model, Label = GetItemLabel(It.Model), Hash = It.WallObj and 0 or GetEntityModel(It.Ent),
            Pos = { x = Pos.x, y = Pos.y, z = Pos.z }, Rot = { x = Rot.x, y = Rot.y, z = Rot.z }, Wall = It.Wall, New = It.Id == nil }
        local Same = 0
        for _, O in pairs(Ed.Items) do if not O.Removed and O.Model == It.Model then Same = Same + 1 end end
        Data.Sel.Same = Same
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

local function Select(Key)
    if Ed.Sel == Key then return end
    Outline(Sel(), false)
    Ed.Sel = Key
    Push()
end

-- // Placing new items (follow the cursor until clicked) \\ --

local function CancelPlacing()
    local It = Ed.Placing and Ed.Items[Ed.Placing]
    if not It then return end
    if It.WallObj then DeleteWall(It.WallObj) elseif DoesEntityExist(It.Ent) then DeleteEntity(It.Ent) end
    Ed.Items[Ed.Placing], Ed.Placing = nil, nil
    if Ed.Sel and not Ed.Items[Ed.Sel] then Ed.Sel = nil end
    Push()
end

local function StartPlacing(Model, Wall, Rot)
    CancelPlacing()
    local Placed, Max = Count()
    if Placed >= Max then return FW.Functions.Notify("This house is full.", "error") end

    local Origin, Dir = CursorRay()
    local Hit, Coords = Cast(Origin, Dir)
    local Pos = Hit and Coords or Origin + Dir * 2.0
    Rot = Rot or vector3(0.0, 0.0, GetCamRot(Ed.Cam, 2).z + 180.0)

    Ed.N = Ed.N + 1
    local It = { Key = 'n' .. Ed.N, Model = Model, Own = true }
    if Wall then
        It.Wall = SanitizeWall(Wall)
        It.WallObj = CreateWall(It.Wall, Pos, Rot)
        It.Ent = It.WallObj and It.WallObj.Anchor
    else
        It.Ent = NewProp(Model, Pos, Rot)
    end
    if not It.Ent then return FW.Functions.Notify("This object could not be loaded.", "error") end

    Ed.Items[It.Key] = It
    Outline(Sel(), false)
    Ed.Sel, Ed.Placing = It.Key, It.Key
    Push()
end

local function FinishPlacing()
    local It = Ed.Placing and Ed.Items[Ed.Placing]
    if not It then return end
    if not InZone(GetEntityCoords(It.Ent)) then return FW.Functions.Notify("That's outside of the house.", "error") end
    Ed.Placing = nil
    Commit()
end

-- // Gizmo \\ --

local function GizmoAxes(It)
    if Ed.Space == 'local' then
        local Right, Fwd, Up = GetEntityMatrix(It.Ent)
        return { x = Norm(Right), y = Norm(Fwd), z = Norm(Up) }
    end
    return { x = vector3(1.0, 0.0, 0.0), y = vector3(0.0, 1.0, 0.0), z = vector3(0.0, 0.0, 1.0) }
end

local function RingPoint(P, Axis, R, A)
    local U = Norm(Cross(Axis, math.abs(Axis.z) < 0.9 and vector3(0.0, 0.0, 1.0) or vector3(1.0, 0.0, 0.0)))
    local V = Cross(Axis, U)
    return P + (U * math.cos(A) + V * math.sin(A)) * R
end

local function Thick(A, B, W, C, Alpha)
    local Fwd = CamVectors(GetCamRot(Ed.Cam, 2))
    local N = Norm(Cross(B - A, Fwd)) * W
    local P1, P2, P3, P4 = A + N, B + N, B - N, A - N
    DrawPoly(P1.x, P1.y, P1.z, P2.x, P2.y, P2.z, P3.x, P3.y, P3.z, C[1], C[2], C[3], Alpha)
    DrawPoly(P3.x, P3.y, P3.z, P2.x, P2.y, P2.z, P1.x, P1.y, P1.z, C[1], C[2], C[3], Alpha)
    DrawPoly(P1.x, P1.y, P1.z, P3.x, P3.y, P3.z, P4.x, P4.y, P4.z, C[1], C[2], C[3], Alpha)
    DrawPoly(P4.x, P4.y, P4.z, P3.x, P3.y, P3.z, P1.x, P1.y, P1.z, C[1], C[2], C[3], Alpha)
end

-- Draws the gizmo and returns the handle under the cursor: { Axis = 'x'|'y'|'z'|'c' }.
local function Gizmo(It, Mouse)
    local P = GetEntityCoords(It.Ent)
    local Size = #(GetCamCoord(Ed.Cam) - P) * 0.18
    local Axes, Hover, Best = GizmoAxes(It), nil, 0.015
    local Active = Ed.Drag and Ed.Drag.Axis

    if Ed.Mode == 'move' then
        local Ps = ToScreen(P)
        if Ps and #(Mouse - Ps) < 0.012 then Hover, Best = 'c', 0 end
        for Axis, Dir in pairs(Axes) do
            local A, B = ToScreen(P), ToScreen(P + Dir * Size)
            local D = A and B and SegDist(Mouse, A, B) or 1
            if D < Best then Hover, Best = Axis, D end
        end
        for Axis, Dir in pairs(Axes) do
            local C = (Active or Hover) == Axis and COLORS.hover or COLORS[Axis]
            local Tip = P + Dir * Size
            Thick(P, Tip, Size * 0.012, C, 255)
            DrawMarker(28, Tip.x, Tip.y, Tip.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Size * 0.05, Size * 0.05, Size * 0.05, C[1], C[2], C[3], 255, false, false, 2, false, nil, nil, false)
        end
        local C = (Active or Hover) == 'c' and COLORS.hover or { 255, 255, 255 }
        DrawMarker(28, P.x, P.y, P.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Size * 0.04, Size * 0.04, Size * 0.04, C[1], C[2], C[3], 220, false, false, 2, false, nil, nil, false)
    else
        local R, Seg, Rings = Size * 0.8, 40, {}
        for Axis, Dir in pairs(Axes) do
            local Pts = {}
            for I = 0, Seg do
                local Pt = RingPoint(P, Dir, R, I / Seg * math.pi * 2)
                Pts[#Pts + 1] = { Pt, ToScreen(Pt) }
                local Prev = Pts[#Pts - 1]
                if Prev and Prev[2] and Pts[#Pts][2] then
                    local D = SegDist(Mouse, Prev[2], Pts[#Pts][2])
                    if D < Best then Hover, Best = Axis, D end
                end
            end
            Rings[Axis] = Pts
        end
        for Axis, Pts in pairs(Rings) do
            local C = (Active or Hover) == Axis and COLORS.hover or COLORS[Axis]
            for I = 2, #Pts do Thick(Pts[I - 1][1], Pts[I][1], Size * 0.01, C, 255) end
        end
    end
    return Hover, P, Axes
end

local function StartDrag(It, Handle, P, Axes)
    local Origin, Dir, Mouse = CursorRay()
    local Pos, Rot = Transform(It)
    local D = { Axis = Handle, Pos = Pos, Rot = Rot }
    if Ed.Mode == 'rotate' then
        local C = ToScreen(P)
        if not C then return end
        D.Center, D.A0 = C, math.atan(Mouse.y - C.y, Mouse.x - C.x)
        D.Sign = Dot(Axes[Handle], Norm(P - Origin)) < 0 and -1 or 1
    elseif Handle == 'c' then
        D.Normal = vector3(0.0, 0.0, 1.0)
        D.Start = PlaneHit(Origin, Dir, Pos, D.Normal)
    else
        D.Dir = Axes[Handle]
        D.Normal = Norm(Cross(D.Dir, Cross(Norm(Pos - Origin), D.Dir)))
        D.Start = PlaneHit(Origin, Dir, Pos, D.Normal)
    end
    if Ed.Mode == 'move' and not D.Start then return end
    Ed.Drag = D
end

local function UpdateDrag(It)
    local D = Ed.Drag
    local Origin, Dir, Mouse = CursorRay()
    if Ed.Mode == 'rotate' then
        local A = math.atan(Mouse.y - D.Center.y, Mouse.x - D.Center.x)
        local Deg = SnapTo(math.deg(A - D.A0) * D.Sign, Ed.SnapRot)
        local R = D.Rot
        return SetTransform(It, nil, vector3(R.x + (D.Axis == 'x' and Deg or 0.0), R.y + (D.Axis == 'y' and Deg or 0.0), R.z + (D.Axis == 'z' and Deg or 0.0)))
    end

    local Hit = PlaneHit(Origin, Dir, D.Pos, D.Normal)
    if not Hit then return end
    local New
    if D.Axis == 'c' then
        local Delta = Hit - D.Start
        New = D.Pos + vector3(SnapTo(Delta.x, Ed.SnapMove), SnapTo(Delta.y, Ed.SnapMove), 0.0)
    else
        New = D.Pos + D.Dir * SnapTo(Dot(Hit - D.Start, D.Dir), Ed.SnapMove)
    end
    if InZone(New) then SetTransform(It, New) end
end

local function ItemAt(Entity)
    for Key, It in pairs(Ed.Items) do
        if not It.Removed then
            for _, E in ipairs(Parts(It)) do
                if E == Entity then return Key end
            end
        end
    end
end

-- // Open / close \\ --

local Catalog = nil
local function BuildCatalog()
    if Catalog then return Catalog end
    Catalog = {}
    for _, Cat in ipairs(Config.DecorCatalog) do
        local Items = {}
        for _, Item in ipairs(Cat.items) do
            if IsModelInCdimage(GetHashKey(Item.model)) then Items[#Items + 1] = { Model = Item.model, Label = GetItemLabel(Item.model) } end
        end
        if #Items > 0 then Catalog[#Catalog + 1] = { Name = Cat.category, Items = Items } end
    end
    return Catalog
end

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
                elseif #(Pos - It.Orig.Pos) > 0.001 or #(Rot - It.Orig.Rot) > 0.01 or json.encode(It.Wall or false) ~= It.Orig.Wall then
                    Changes.Updates[#Changes.Updates + 1] = { Id = It.Id, Coords = P, Rot = R, Wall = It.Wall }
                end
            elseif not It.Removed then
                Changes.Adds[#Changes.Adds + 1] = { Model = It.Model, Coords = P, Rot = R, Wall = It.Wall }
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
    Ed.Items, Ed.Sel, Ed.Dirty = {}, nil, false
    SetMloDecorPaused(false)
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
        Push()
    end)
end

function CloseMloEditor()
    if not Ed then return end
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

    Ed = { HouseId = HouseId, House = Config.Houses[HouseId], Cam = Cam, Mode = 'move', Space = 'world',
        SnapMove = 0.0, SnapRot = 0.0, CamSpeed = 0.05, Typing = false, MouseDown = false }
    LoadItems()
    ResetHistory()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ Action = 'Open', Data = { Catalog = BuildCatalog(), Thumb = Config.Decorate.Thumbnails, Address = Ed.House.Adress, Walls = IsModelInCdimage(GetHashKey('fw_wall_100x100')) } })
    Push()

    Citizen.CreateThread(function()
        local LastPush = 0
        while Ed do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            if GetMloInsideHouseId() ~= Ed.HouseId or IsEntityDead(PlayerPedId()) then CloseMloEditor() break end

            -- Freecam, can't leave the zone. WASD, E up, CTRL down, SHIFT fast.
            if not Ed.Typing then
                local Fwd, Right = CamVectors(GetCamRot(Ed.Cam, 2))
                local Move = vector3(0.0, 0.0, 0.0)
                if IsDisabledControlPressed(0, 32) then Move = Move + Fwd end
                if IsDisabledControlPressed(0, 33) then Move = Move - Fwd end
                if IsDisabledControlPressed(0, 35) then Move = Move + Right end
                if IsDisabledControlPressed(0, 34) then Move = Move - Right end
                if IsDisabledControlPressed(0, 38) then Move = Move + vector3(0.0, 0.0, 1.0) end
                if IsDisabledControlPressed(0, 36) then Move = Move - vector3(0.0, 0.0, 1.0) end
                if #Move > 0 then
                    local Speed = Ed.CamSpeed * 60.0 * (IsDisabledControlPressed(0, 21) and 3.0 or 1.0) * GetFrameTime()
                    local New = GetCamCoord(Ed.Cam) + Norm(Move) * Speed
                    if InZone(New) then SetCamCoord(Ed.Cam, New.x, New.y, New.z) end
                end
            end
            local C = GetCamCoord(Ed.Cam)
            SetFocusPosAndVel(C.x, C.y, C.z, 0.0, 0.0, 0.0)

            local It = Sel()
            if Ed.Placing and Valid(It) then
                -- New object follows the cursor over surfaces.
                local Origin, Dir = CursorRay()
                local Hit, Coords = Cast(Origin, Dir, It.Ent, It.WallObj and 1 or nil)
                if Hit then
                    local Pos = vector3(SnapTo(Coords.x, Ed.SnapMove), SnapTo(Coords.y, Ed.SnapMove), Coords.z + BottomOffset(It))
                    if InZone(Pos) then SetTransform(It, Pos) end
                end
                Outline(It, true)
            elseif Valid(It) then
                Outline(It, true)
                local _, _, Mouse = CursorRay()
                Ed.Hover = { Gizmo(It, Mouse) }
                if Ed.Drag then
                    UpdateDrag(It)
                    if GetGameTimer() - LastPush > 100 then LastPush = GetGameTimer() Push() end
                end
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
        if Ed then Fn(D or {}) end
        Reply('ok')
    end)
end

Cb('typing', function(D) Ed.Typing = D.State == true end)
Cb('look', function(D)
    local R = GetCamRot(Ed.Cam, 2)
    SetCamRot(Ed.Cam, math.max(-89.0, math.min(89.0, R.x - (D.dy or 0) * 0.12)), 0.0, R.z - (D.dx or 0) * 0.12, 2)
end)
Cb('settings', function(D)
    Ed.SnapMove, Ed.SnapRot = tonumber(D.SnapMove) or 0.0, tonumber(D.SnapRot) or 0.0
    Ed.CamSpeed = math.max(0.01, tonumber(D.CamSpeed) or 0.05)
end)
Cb('mode', function() Ed.Mode = Ed.Mode == 'move' and 'rotate' or 'move' Push() end)
Cb('space', function() Ed.Space = Ed.Space == 'world' and 'local' or 'world' Push() end)

Cb('spawn', function(D)
    if D.Wall then
        if not IsModelInCdimage(GetHashKey('fw_wall_100x100')) then return FW.Functions.Notify("The wall kit (fw-walls) isn't installed.", "error") end
        return StartPlacing('fw_wall', { L = 2.0, H = 2.5, Holes = {} })
    end
    if Config.DecorByModel[D.Model] then StartPlacing(D.Model) end
end)

Cb('down', function()
    if Ed.Placing then return FinishPlacing() end
    local It, Hover = Sel(), Ed.Hover and Ed.Hover[1]
    if Valid(It) and Hover then return StartDrag(It, Hover, Ed.Hover[2], Ed.Hover[3]) end

    local Origin, Dir = CursorRay()
    local Hit, _, Entity = Cast(Origin, Dir)
    local Key = Hit and Entity ~= 0 and ItemAt(Entity)
    if Key then
        Select(Key)
        if Ed.Mode == 'move' then
            local New = Ed.Items[Key]
            StartDrag(New, 'c', GetEntityCoords(New.Ent), GizmoAxes(New))
        end
    else
        Select(nil)
    end
end)

Cb('up', function()
    if not Ed.Drag then return end
    Ed.Drag = nil
    Commit()
end)

Cb('place', function()
    if Ed.Placing then FinishPlacing() else Select(nil) end
end)
Cb('cancel', function() if Ed.Placing then CancelPlacing() else Select(nil) end end)
Cb('select', function(D)
    local It = Ed.Items[D.Key]
    if not Valid(It) then return end
    CancelPlacing()
    Select(D.Key)
    -- Look at it.
    local Dir = GetEntityCoords(It.Ent) - GetCamCoord(Ed.Cam)
    SetCamRot(Ed.Cam, math.deg(math.atan(Dir.z, #vector2(Dir.x, Dir.y))), 0.0, -math.deg(math.atan(Dir.x, Dir.y)), 2)
end)

Cb('set', function(D)
    local It = Sel()
    if not Valid(It) or not D.Pos or not D.Rot then return end
    local P = vector3(D.Pos.x + 0.0, D.Pos.y + 0.0, D.Pos.z + 0.0)
    if not InZone(P) then return FW.Functions.Notify("That's outside of the house.", "error") end
    SetTransform(It, P, vector3(D.Rot.x + 0.0, D.Rot.y + 0.0, D.Rot.z + 0.0))
    if not Ed.Placing then Commit() end
end)

Cb('ground', function()
    local It = Sel()
    if not Valid(It) then return end
    local P = GetEntityCoords(It.Ent)
    for _, E in ipairs(Parts(It)) do SetEntityCollision(E, false, false) end
    local Hit, Coords = Cast(P + vector3(0.0, 0.0, 0.05), vector3(0.0, 0.0, -1.0), It.Ent)
    for _, E in ipairs(Parts(It)) do SetEntityCollision(E, true, true) end
    if Hit then
        SetTransform(It, vector3(P.x, P.y, Coords.z + BottomOffset(It)))
        if not Ed.Placing then Commit() end
    end
end)

Cb('delete', function()
    local It = Sel()
    if not It then return end
    if Ed.Placing then return CancelPlacing() end
    Outline(It, false)
    SetRemoved(It, true)
    Ed.Sel = nil
    Commit()
end)

Cb('duplicate', function()
    local It = Sel()
    if not Valid(It) or Ed.Placing then return end
    local _, Rot = Transform(It)
    StartPlacing(It.Model, It.Wall and Copy(It.Wall), Rot)
end)

Cb('wall', function(D)
    local It, W = Sel(), SanitizeWall(D)
    if not Valid(It) or not It.Wall or not W then return end
    if It.Own and Ed.Placing then
        DeleteWall(It.WallObj)
        local Pos, Rot = Transform(It)
        It.WallObj = CreateWall(W, Pos, Rot)
        It.Ent, It.Wall = It.WallObj.Anchor, W
        return Push()
    end
    RebuildWall(It, W)
    Commit()
end)

Cb('undo', function()
    if Ed.Index <= 1 then return end
    CancelPlacing()
    Ed.Index = Ed.Index - 1
    ApplySnapshot(Ed.History[Ed.Index])
    Push()
end)

Cb('redo', function()
    if Ed.Index >= #Ed.History then return end
    CancelPlacing()
    Ed.Index = Ed.Index + 1
    ApplySnapshot(Ed.History[Ed.Index])
    Push()
end)

Cb('save', function()
    local C = Save()
    if #C.Adds + #C.Updates + #C.Removes == 0 then return FW.Functions.Notify("Nothing to save.", "error") end
    Ed.Saving = true
    SetTimeout(3000, function() if Ed then Ed.Saving = false end end)
    Reload()
end)

Cb('discard', function()
    Discard()
    LoadItems()
    ResetHistory()
    Push()
end)

Cb('close', function(D)
    if Ed.Dirty and D.Save then
        Save()
        Cleanup()
    end
    CloseMloEditor()
end)

Cb('wheel', function(D)
    local It = Sel()
    if not Valid(It) then return end
    local _, Rot = Transform(It)
    local Step = (Ed.SnapRot > 0 and Ed.SnapRot or 15.0) * ((D.d or 0) > 0 and -1 or 1)
    SetTransform(It, nil, vector3(Rot.x, Rot.y, Rot.z + Step))
    if Ed.Placing then Push() else Commit() end
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

local function GetPlayerHouse(Perm)
    local HouseId = GetMloInsideHouseId()
    local House = HouseId and Config.Houses[HouseId]
    if not House or not HasMloAccess(HouseId, Perm) then return end
    return HouseId, House
end

-- // Owner house menu \\ --

local function Ev(Name, Args) Args.Event, Args.Type = 'fw-housing:Client:House:' .. Name, 'Client' return Args end

function OpenMloHouseMenu()
    local HouseId, House = GetPlayerHouse()
    if not HouseId or not IsMloOwner(HouseId) then return FW.Functions.Notify("Only the owner can manage this house.", "error") end

    local Data = FW.SendCallback("fw-housing:Server:Mlo:GetManage", HouseId)
    if not Data then return end

    local Keys, Nearby, Colours = {}, {}, {}
    for _, K in ipairs(Data.Keys) do
        local Access = {}
        for _, Perm in ipairs({ 'Doors', 'Stash', 'Decorate' }) do
            Access[#Access + 1] = { Title = Perm .. ': ' .. (K[Perm] and 'Yes' or 'No'), Icon = K[Perm] and 'check' or 'times', CloseMenu = true, Data = Ev('SetAccess', { HouseId = HouseId, Cid = K.Cid, Perm = Perm, Value = not K[Perm] }) }
        end
        Access[#Access + 1] = { Title = 'Take keys', Icon = 'user-minus', CloseMenu = true, Data = Ev('RemoveKey', { HouseId = HouseId, Cid = K.Cid }) }
        Keys[#Keys + 1] = { Title = K.Name, Desc = K.Cid, SecondMenu = Access }
    end
    for _, P in ipairs(Data.Nearby) do
        Nearby[#Nearby + 1] = { Title = P.Name, Desc = 'ID ' .. P.Id, CloseMenu = true, Data = Ev('AddKey', { HouseId = HouseId, Target = P.Id }) }
    end

    local Cfg = (Config.MLOHouses[House.Mlo] or {}).Surfaces
    for _, Surface in ipairs({ 'Walls', 'Floor', 'Ceiling' }) do
        if Cfg and Cfg[Surface] and #Cfg[Surface] > 0 then
            local List = {
                { Title = 'Custom colour', Icon = 'palette', Desc = 'Enter a hex code', CloseMenu = true, Data = Ev('CustomColour', { HouseId = HouseId, Surface = Surface }) },
                { Title = 'Original', Icon = 'undo', CloseMenu = true, Data = Ev('SetSurface', { HouseId = HouseId, Surface = Surface, Hex = false }) },
            }
            for _, C in ipairs(Config.SurfaceColors) do
                List[#List + 1] = { Title = C[1], Desc = C[2], CloseMenu = true, Data = Ev('SetSurface', { HouseId = HouseId, Surface = Surface, Hex = C[2] }) }
            end
            Colours[#Colours + 1] = { Title = Surface, Desc = Data.Surfaces[Surface] or 'Original', SecondMenu = List }
        end
    end

    FW.Functions.OpenMenu({ MainMenuItems = {
        { Title = House.Adress, Desc = 'House management' },
        { Title = 'Keyholders', Icon = 'key', Desc = #Keys .. ' people', SecondMenu = Keys, Disabled = #Keys == 0 },
        { Title = 'Give keys', Icon = 'user-plus', Desc = 'Players next to you', SecondMenu = Nearby, Disabled = #Nearby == 0 },
        { Title = 'Colours', Icon = 'paint-roller', Desc = 'Walls, floor and ceiling', SecondMenu = Colours, Disabled = #Colours == 0 },
        { Title = 'Lock / unlock doors', Icon = 'lock', CloseMenu = true, Data = { Event = 'fw-housing:Client:LockProperty', Type = 'Client' } },
    } })
end
exports("OpenMloHouseMenu", OpenMloHouseMenu)

local function ReopenHouse() SetTimeout(400, OpenMloHouseMenu) end

RegisterNetEvent("fw-housing:Client:House:AddKey", function(D) TriggerServerEvent("fw-housing:Server:Mlo:AddKey", D.HouseId, D.Target) ReopenHouse() end)
RegisterNetEvent("fw-housing:Client:House:RemoveKey", function(D) TriggerServerEvent("fw-housing:Server:Mlo:RemoveKey", D.HouseId, D.Cid) ReopenHouse() end)
RegisterNetEvent("fw-housing:Client:House:SetAccess", function(D) TriggerServerEvent("fw-housing:Server:Mlo:SetAccess", D.HouseId, D.Cid, D.Perm, D.Value) ReopenHouse() end)
RegisterNetEvent("fw-housing:Client:House:SetSurface", function(D) TriggerServerEvent("fw-housing:Server:Mlo:SetSurface", D.HouseId, D.Surface, D.Hex) end)
RegisterNetEvent("fw-housing:Client:House:CustomColour", function(D)
    Wait(100)
    local R = exports['fw-ui']:CreateInput({ { Label = 'Hex colour (e.g. #A1B2C3)', Icon = 'fas fa-palette', Name = 'Hex' } })
    local Hex = R and R.Hex and ('#' .. R.Hex:gsub('#', '')):upper()
    if not Hex or not Hex:match('^#%x%x%x%x%x%x$') then return R and FW.Functions.Notify("Invalid colour.", "error") end
    TriggerServerEvent("fw-housing:Server:Mlo:SetSurface", D.HouseId, D.Surface, Hex)
end)

RegisterNetEvent("fw-housing:Client:Mlo:OpenDecorate", function() OpenMloDecorateMenu() end)
RegisterNetEvent("fw-housing:Client:Mlo:OpenHouse", function() OpenMloHouseMenu() end)
