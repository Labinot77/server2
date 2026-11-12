-- ============================================================================
--  Shared inventories (stash, trunk, glovebox, ground, ...)
--  Several players can have one open. Every change to an inventory runs under a lock for that
--  inventory, is checked against the database (not the client's screen), and is pushed to the
--  other viewers right after.
-- ============================================================================
OpenInventories = OpenInventories or {}
Viewers = {} -- [InvName] = { [Source] = MaxWeight }
local BusyInventories = {}

function PlayerInvName(Source)
    local Player = FW.Functions.GetPlayer(Source)
    return Player and ('ply-' .. Player.PlayerData.citizenid) or nil
end

function IsExclusiveInventory(InvName)
    return type(InvName) == 'string' and string.startsWith(InvName, 'ply-')
end

function IsSharedInventory(InvName)
    return type(InvName) == 'string' and InvName ~= 'Store' and InvName ~= 'Crafting' and InvName ~= 'None' and not IsExclusiveInventory(InvName)
end

function AddViewer(InvName, Source, MaxWeight)
    Viewers[InvName] = Viewers[InvName] or {}
    Viewers[InvName][Source] = tonumber(MaxWeight) or 0
end

function RemoveViewer(Source, Except)
    for InvName, List in pairs(Viewers) do
        if InvName ~= Except then
            List[Source] = nil
            if next(List) == nil then Viewers[InvName] = nil end
        end
    end
end

-- Max weight this inventory was opened with (the client sends it when opening; the biggest viewer wins).
function GetSharedMaxWeight(InvName)
    local Max = false
    for _, Weight in pairs(Viewers[InvName] or {}) do
        if Weight > 0 and (not Max or Weight > Max) then Max = Weight end
    end
    return Max
end

-- Push the current contents to everyone looking at it (except the player who just did the change).
function BroadcastInventory(InvName, Except)
    if not Viewers[InvName] then return end
    local Items
    for Viewer in pairs(Viewers[InvName]) do
        if Viewer ~= Except then
            Items = Items or GetInventoryItems(InvName)
            TriggerClientEvent("fw-inventory:Client:RefreshOther", Viewer, InvName, Items)
        end
    end
end

-- Runs Fn with every inventory in Names locked; other changes to them wait their turn.
-- (Database calls yield, so without this two players could both take the same item.)
function WithInventoryLock(Names, Fn, ...)
    local Deadline = GetGameTimer() + 5000
    while true do
        local Free = true
        for _, Name in pairs(Names) do
            if Name and BusyInventories[Name] then Free = false break end
        end
        if Free then break end
        if GetGameTimer() > Deadline then return end
        Citizen.Wait(0)
    end

    for _, Name in pairs(Names) do if Name then BusyInventories[Name] = true end end
    local Ok, Err = pcall(Fn, ...)
    for _, Name in pairs(Names) do if Name then BusyInventories[Name] = nil end end
    if not Ok then print("^1[fw-inventory] " .. tostring(Err) .. "^0") end

    for _, Name in pairs(Names) do
        if Name and IsSharedInventory(Name) then BroadcastInventory(Name, (...)) end
    end
end

-- FW.RegisterServer with the lock. NamesFn(Source, ...) returns the inventories the handler touches.
function RegisterLocked(Event, NamesFn, Fn)
    FW.RegisterServer(Event, function(Source, ...)
        local Names = NamesFn(Source, ...) or {}
        table.insert(Names, PlayerInvName(Source))
        WithInventoryLock(Names, Fn, Source, ...)
    end)
end
