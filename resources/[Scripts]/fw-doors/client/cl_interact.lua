-- Doors through the `interact` resource (Config.HUD.Mode = 'interact').
-- Only doors near the player are registered; the point is attached to the door object.
-- The prompt shows the lock state (LOCKED / UNLOCKED); E toggles it if you have keys.

DoorInteract = { Points = {} } -- DoorId -> { Id, Entity }

local Cfg = Config.HUD
if not (DoorHud and DoorHud.Interact) then
    DoorInteract.Refresh = function() end
    return
end

local Points = DoorInteract.Points
local Busy = false

local function InteractRunning()
    return GetResourceState('interact') == 'started'
end

local function Usable(Door)
    if not Door or Door.Disabled or Door.IsHidden or not Door.Coords then return false end
    if Door.IsGate and not Cfg.ShowOnGates then return false end
    return true
end

-- Door entity + offset to the middle of its model (local space).
local function DoorEntity(Door)
    local Model = type(Door.Model) == 'string' and GetHashKey(Door.Model) or Door.Model
    local Entity = GetClosestObjectOfType(Door.Coords.x, Door.Coords.y, Door.Coords.z, 1.0, Model, false, false, false)
    if Entity == 0 then return end

    local Min, Max = GetModelDimensions(Model)
    return Entity, vector3((Min.x + Max.x) / 2, (Min.y + Max.y) / 2, Cfg.ZOffset or 0.0)
end

-- Same behaviour as pressing E in the original ListenForKeypress.
local function ToggleDoor(DoorId)
    if Busy then return end
    Busy = true

    CreateThread(function()
        local Door = Config.Doors[DoorId]
        if Door and HasDoorAcces(DoorId) then
            TriggerServerEvent('fw-doors:Server:ToggleLockState', DoorId)
            for _, C in pairs(Door.Connected or {}) do
                TriggerServerEvent('fw-doors:Server:ToggleLockState', C)
            end

            if Door.IsGate then
                TriggerEvent('fw-sound:client:play', Door.Locked == 0 and 'GarageClose' or 'GarageOpen', 0.15)
            else
                DoorAnimation()
            end
        else
            FW.Functions.Notify("Geen toegang!", "error")
            PlaySoundFromEntity(-1, "Keycard_Fail", PlayerPedId(), "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", 1, 5.0)
        end

        Wait(500)
        Busy = false
    end)
end

-- One option, label = current state. No canInteract: interact would call it
-- cross-resource every frame. The label is swapped via UpdateInteraction on sync.
local function BuildOptions(DoorId)
    local Locked = Config.Doors[DoorId].Locked == 1 and 1 or 0
    return {
        {
            name = 'fw-doors:toggle',
            label = Cfg.Labels[Locked],
            action = function() ToggleDoor(DoorId) end,
        },
    }
end

local function Remove(DoorId)
    local Point = Points[DoorId]
    if not Point then return end
    Points[DoorId] = nil
    if InteractRunning() then exports.interact:RemoveInteraction(Point.Id) end
end

-- interact recalculates entity points every frame, so the prompt swings with the door.
local function Add(DoorId, Door)
    local Entity, Offset = DoorEntity(Door)
    if not Entity then return end -- door object not streamed in yet, try next tick

    local Ok, Id = pcall(function()
        return exports.interact:AddLocalEntityInteraction({
            name = ('fw-doors:%s'):format(Door.Info or DoorId),
            entity = Entity,
            offset = Offset,
            smooth = true, -- interact predicts the swing so the prompt doesn't trail the door
            distance = Cfg.RingDistance,
            interactDst = Door.IsGate and Cfg.GateInteractDistance or Cfg.InteractDistance,
            options = BuildOptions(DoorId),
        })
    end)
    if not Ok then return print(('^1[fw-doors]^7 interact AddLocalEntityInteraction failed: %s'):format(Id)) end
    if Id then Points[DoorId] = { Id = Id, Entity = Entity } end
end

-- Called from the Sync event when a lock state changes.
function DoorInteract.Update(DoorId)
    local Point = Points[DoorId]
    if Point and InteractRunning() then
        exports.interact:UpdateInteraction(Point.Id, BuildOptions(DoorId))
    end
end

-- Called by the creator when a door is added / edited / disabled.
function DoorInteract.Refresh(DoorId)
    Remove(DoorId)
end

CreateThread(function()
    local Warned = false

    while true do
        Wait(1000)

        if not InteractRunning() then
            if not Warned then
                print("^3[fw-doors]^7 Config.HUD.Mode = 'interact' but the interact resource isn't started. Start it before fw-doors.")
                Warned = true
            end
            goto continue
        end
        Warned = false

        if LoggedIn and Config.Doors then
            local Pos = GetEntityCoords(PlayerPedId())
            local Range = Cfg.RegisterDistance

            for DoorId, Door in pairs(Config.Doors) do
                local Near = Usable(Door) and #(Pos - Door.Coords) < Range

                -- Door object streamed out/in: its handle changed, so re-attach.
                if Points[DoorId] and not DoesEntityExist(Points[DoorId].Entity) then Remove(DoorId) end

                if Near and not Points[DoorId] then
                    Add(DoorId, Door)
                elseif not Near and Points[DoorId] then
                    Remove(DoorId)
                end
            end
        end

        ::continue::
    end
end)

-- interact restarted: all its points are gone, re-add ours.
AddEventHandler('onClientResourceStart', function(Resource)
    if Resource == 'interact' then
        for K in pairs(Points) do Points[K] = nil end
    end
end)

AddEventHandler('onClientResourceStop', function(Resource)
    if Resource == 'interact' then
        for K in pairs(Points) do Points[K] = nil end
    end
end)
