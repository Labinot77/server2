-- Wall maths shared by the creator, the streamer and the server. Everything snaps to the fw-walls grid.
-- Wall = { Pos = {x,y,z} (bottom centre), Heading, L, H, Holes = { { Type = 'door'|'window', X (centre offset), Z (bottom), W, H, Model?, Flip?, Passage? } } }
local C = Config.Cell
local function Cells(V) return math.floor((tonumber(V) or 0) / C + 0.5) end
local function Clamp(V, Min, Max) return math.max(Min, math.min(Max, V)) end

-- N cells split into kit sizes (8 / 4 / 2 / 1 cells = 200 / 100 / 50 / 25 cm): { { Size, Start } }.
local function Split(N)
    local List, Start = {}, 0
    for _, S in ipairs({ 8, 4, 2, 1 }) do
        while N - Start >= S do List[#List + 1] = { Size = S, Start = Start } Start = Start + S end
    end
    return List
end

local function NewGrid(Cols, Rows)
    local G = {}
    for R = 0, Rows - 1 do G[R] = {} for Col = 0, Cols - 1 do G[R][Col] = true end end
    return G
end

-- Fills the free cells with as few kit panels as possible. Fn(Model, centre column, bottom row).
local function Fill(Grid, Cols, Rows, Fn)
    local function Fit(N) for _, S in ipairs({ 8, 4, 2, 1 }) do if S <= N then return S end end end
    for R = 0, Rows - 1 do
        for Col = 0, Cols - 1 do
            if Grid[R][Col] then
                local Wd, Ht = 0, 1
                while Wd < 8 and Grid[R][Col + Wd] do Wd = Wd + 1 end
                Wd = Fit(Wd)
                local function RowFree(Row)
                    if not Grid[Row] then return false end
                    for I = 0, Wd - 1 do if not Grid[Row][Col + I] then return false end end
                    return true
                end
                while Ht < 8 and RowFree(R + Ht) do Ht = Ht + 1 end
                Ht = Fit(Ht)
                for Y = R, R + Ht - 1 do for X = Col, Col + Wd - 1 do Grid[Y][X] = nil end end
                Fn(('fw_wall_%dx%d'):format(Wd * 25, Ht * 25), Col + Wd / 2, R)
            end
        end
    end
end

-- Snaps a wall to the grid. Holes keep one free cell around them for the frame; overlapping holes are dropped.
function SanitizeWall(W)
    if type(W) ~= 'table' or type(W.Pos) ~= 'table' then return end
    local L, H = Clamp(Cells(W.L), 4, Cells(Config.MaxLength)), Clamp(Cells(W.H), 4, Cells(Config.MaxHeight))
    local Wall = {
        Pos = { x = tonumber(W.Pos.x) or 0.0, y = tonumber(W.Pos.y) or 0.0, z = tonumber(W.Pos.z) or 0.0 },
        Heading = (tonumber(W.Heading) or 0.0) % 360, L = L * C, H = H * C, Holes = {},
    }
    local Boxes = {}
    for _, Hole in ipairs(type(W.Holes) == 'table' and W.Holes or {}) do
        if #Wall.Holes >= Config.MaxHoles then break end
        local Door = Hole.Type == 'door'
        local Hw = Clamp(Cells(Hole.W), 1, L - 2)
        local Hh = Clamp(Cells(Hole.H), 1, H - (Door and 1 or 2))
        local Left = Clamp(Cells((tonumber(Hole.X) or 0) - Hw * C / 2 + Wall.L / 2), 1, L - Hw - 1)
        local Bottom = Door and 0 or Clamp(Cells(Hole.Z), 1, H - Hh - 1)
        local Box, Free = { Left - 1, Left + Hw + 1, Bottom - 1, Bottom + Hh + 1 }, true
        for _, B in ipairs(Boxes) do
            if Box[1] < B[2] and B[1] < Box[2] and Box[3] < B[4] and B[3] < Box[4] then Free = false end
        end
        if Free then
            Boxes[#Boxes + 1] = Box
            Wall.Holes[#Wall.Holes + 1] = {
                Type = Door and 'door' or 'window', Model = Door and tostring(Hole.Model) or nil, Flip = Door and Hole.Flip == true or nil, Passage = Door and Hole.Passage == true or nil,
                X = (Left + Hw / 2) * C - Wall.L / 2, Z = Bottom * C, W = Hw * C, H = Hh * C,
            }
        end
    end
    return Wall
end

-- Every prop of a wall in wall space: { Kind = 'wall'|'frame'|'glass'|'door', Model, X, Y, Z, Pitch, Yaw }.
function BuildShellWall(W)
    local Cols, Rows, Half, Pieces = Cells(W.L), Cells(W.H), W.L / 2, {}
    local Grid = NewGrid(Cols, Rows)
    local function Add(Kind, Model, X, Y, Z, Pitch, Yaw)
        Pieces[#Pieces + 1] = { Kind = Kind, Model = Model, X = X, Y = Y, Z = Z, Pitch = Pitch or 0.0, Yaw = Yaw or 0.0 }
    end

    for _, H in ipairs(W.Holes) do
        local Left, Right, Bottom, Top = H.X - H.W / 2, H.X + H.W / 2, H.Z, H.Z + H.H
        local Lc, Bc = Cells(Left + Half), Cells(Bottom)
        for R = Bc, Bc + Cells(H.H) - 1 do for Col = Lc, Lc + Cells(H.W) - 1 do Grid[R][Col] = nil end end

        -- Frame: 25 cm panels turned 90 degrees stick out 7.5 cm on both sides of the wall.
        -- Jambs beside the hole, a head above it (and a sill under windows). 2 mm overlap hides the hole edges.
        for _, S in ipairs(Split(Cells(H.H))) do
            local Model, Z = ('fw_wall_25x%d'):format(S.Size * 25), Bottom + S.Start * C
            Add('frame', Model, Left - 0.048, 0.0, Z, 0.0, 90.0)
            Add('frame', Model, Right + 0.048, 0.0, Z, 0.0, 90.0)
        end
        local Rails = { Top + 0.048 }
        if H.Type == 'window' then Rails[2] = Bottom - 0.048 end
        for _, Z in ipairs(Rails) do
            for _, S in ipairs(Split(Cells(H.W) + 2)) do
                Add('frame', ('fw_wall_%dx25'):format(S.Size * 25), Left - C + (S.Start + S.Size / 2) * C, 0.125, Z, 90.0, 0.0)
            end
        end

        if H.Type == 'window' then
            -- Invisible panels: you see out through the hole, bullets and players are stopped.
            local Wc, Hc = Cells(H.W), Cells(H.H)
            Fill(NewGrid(Wc, Hc), Wc, Hc, function(Model, X, R) Add('glass', Model, Left + X * C, 0.0, Bottom + R * C) end)
        else
            Add('door', H.Model, H.Flip and Right or Left, 0.0, Bottom, 0.0, H.Flip and 180.0 or 0.0)
        end
    end

    Fill(Grid, Cols, Rows, function(Model, X, R) Add('wall', Model, X * C - Half, 0.0, R * C) end)
    return Pieces
end
