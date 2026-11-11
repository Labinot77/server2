local interactions = require 'client.api'
local utils = require 'client.helpers'
local settings = require 'config.settings'
local CURRENT_SELECTION = 1
local CURRENT_OPTION = 0

-- CACHE
local Wait = Wait
local IsControlJustPressed = IsControlJustPressed
local IsNuiFocused = IsNuiFocused
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedCuffed = IsPedCuffed

local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local DisableControlAction = DisableControlAction

local visibleOptions = {}

-- Arrow keys + mouse wheel. 241/242 are the raw cursor scroll inputs, 14/15/16/17 the weapon-wheel ones.
local scrollUpControls = { 172, 241, 15, 17 }   -- arrow up, scroll up
local scrollDownControls = { 173, 242, 14, 16 } -- arrow down, scroll down
local weaponScrollControls = { 14, 15, 16, 17, 99, 100, 261, 262 }

-- Disabled controls never report through IsControlJustPressed, so check both.
local function controlPressed(controls)
    for i = 1, #controls do
        local control = controls[i]
        if IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control) then
            return true
        end
    end
    return false
end

-- Collects the options whose canInteract passes into visibleOptions and returns how many there are.
local function getVisibleOptions(interaction)
    table.wipe(visibleOptions)
    local amount = 0
    local options = interaction.options
    for i = 1, #options do
        local option = options[i]
        local ok = true
        if option.canInteract then
            ok = false
            pcall(function() ok = option.canInteract(interaction.entity, interaction.coords, option.args) end)
        end
        if ok then
            amount += 1
            visibleOptions[amount] = option
        end
    end
    return amount
end

local function triggerOption(interaction, option)
    if option.action then
        pcall(function() option.action(interaction.entity, interaction.coords, option.args) end)
    elseif option.serverEvent then
        TriggerServerEvent(option.serverEvent, option.args)
    elseif option.event then
        TriggerEvent(option.event, option)
    end
end

local nearby = {}

-- ============================================================================
-- Line of sight
-- A ray is cast from the player's head (or camera) to every nearby point. Points with a wall or
-- object in between are hidden and can't be used.
-- ============================================================================
local los = settings.LineOfSight or { enabled = false }
local visibility = {} -- [key] = true when the point is in line of sight

local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local GetPedBoneCoords = GetPedBoneCoords
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetEntityAttachedTo = GetEntityAttachedTo

-- Stable key per point. Model interactions are re-cloned every refresh, so they are keyed by entity.
local function losKey(interaction)
    if interaction.id then return interaction.id end
    if interaction.bone then return ('b:%s:%s'):format(interaction.entity, interaction.bone) end
    if interaction.entity then return ('e:%s'):format(interaction.entity) end
    local c = interaction.coords
    return ('c:%.2f:%.2f:%.2f'):format(c.x, c.y, c.z)
end

local function isInSight(interaction)
    if not los.enabled then return true end
    return visibility[losKey(interaction)] == true
end

local function getLosOrigin()
    if los.origin == 'camera' then
        return GetFinalRenderedCamCoord()
    end
    return GetPedBoneCoords(cache.ped, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
end

local function isClear(probe, hit, endCoords, hitEntity)
    if not hit or hit == 0 then return true end

    -- Hitting the thing the point belongs to (or a part attached to it) means we're looking at it.
    if probe.entity and hitEntity ~= 0 then
        if hitEntity == probe.entity or GetEntityAttachedTo(hitEntity) == probe.entity then
            return true
        end
    end

    -- Props the player is holding shouldn't block.
    if hitEntity ~= 0 and GetEntityAttachedTo(hitEntity) == cache.ped then
        return true
    end

    -- Point sits slightly inside a surface.
    return #(endCoords - probe.coords) <= los.tolerance
end

if los.enabled then
    CreateThread(function()
        local probes = {}
        while true do
            local list = nearby
            if #list > 0 then
                local origin = getLosOrigin()
                local count = 0

                -- Fire every probe in the same frame, then collect the results.
                for i = 1, #list do
                    local interaction = list[i]
                    local coords = interaction.coords or utils.getCoordsFromInteract(interaction)
                    count += 1
                    probes[count] = {
                        key = losKey(interaction),
                        coords = coords,
                        entity = interaction.entity,
                        handle = StartShapeTestLosProbe(origin.x, origin.y, origin.z, coords.x, coords.y, coords.z,
                            los.flags, interaction.entity or cache.ped, los.options),
                    }
                end

                local fresh = {}
                for i = 1, count do
                    local probe = probes[i]
                    local status, hit, endCoords, _, hitEntity = GetShapeTestResult(probe.handle)
                    local tries = 0
                    while status == 1 and tries < 10 do
                        Wait(0)
                        tries += 1
                        status, hit, endCoords, _, hitEntity = GetShapeTestResult(probe.handle)
                    end

                    if status == 2 then
                        fresh[probe.key] = isClear(probe, hit, endCoords, hitEntity)
                    else
                        fresh[probe.key] = visibility[probe.key] -- probe failed, keep the last result
                    end
                    probes[i] = nil
                end

                visibility = fresh
                Wait(los.interval)
            else
                table.wipe(visibility)
                Wait(250)
            end
        end
    end)
end

local screenCoords, screenCount = {}, 0
local hoverRadius = settings.Prompt.hoverRadius
local GetAspectRatio = GetAspectRatio
local math_sqrt = math.sqrt

local function CreateInteractions()
    local aspect = GetAspectRatio(false)
    local active, activeCoords, activeAmount, activeIndex
    local bestDist = hoverRadius
    screenCount = 0

    -- Pass 1: find every on-screen point and pick the in-range one closest to the crosshair.
    for i = 1, #nearby do
        local interaction = nearby[i]
        local coords = interaction.coords or utils.getCoordsFromInteract(interaction)
        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

        if onScreen and isInSight(interaction) then
            local amount = getVisibleOptions(interaction)

            if amount > 0 then
                screenCount += 1
                screenCoords[screenCount] = coords

                if interaction.curDist <= interaction.interactDst then
                    local dx, dy = (sx - 0.5) * aspect, sy - 0.5
                    local dist = math_sqrt(dx * dx + dy * dy)
                    if dist < bestDist then
                        bestDist = dist
                        active, activeCoords, activeAmount, activeIndex = interaction, coords, amount, screenCount
                    end
                end
            end
        end
    end

    if screenCount == 0 then
        CURRENT_OPTION = 0
        return
    end

    -- Pass 2: dots for everything except the hovered point, which gets the prompt instead.
    for i = 1, screenCount do
        if i ~= activeIndex then
            utils.drawDot(screenCoords[i])
        end
    end

    if settings.Prompt.crosshair then
        utils.drawCrosshair()
    end

    if not active then
        CURRENT_OPTION = 0
        return
    end

    -- Rebuild the option list for the hovered point (pass 1 overwrote it while scanning).
    getVisibleOptions(active)

    -- Bone and model interactions have no id, so fall back to the entity.
    local key = active.id or active.entity
    if key ~= CURRENT_OPTION then
        CURRENT_OPTION = key
        CURRENT_SELECTION = 1
    end

    if CURRENT_SELECTION > activeAmount then
        CURRENT_SELECTION = activeAmount
    end

    if activeAmount > 1 then
        -- Stop the mouse wheel from cycling weapons while it scrolls the options.
        for i = 1, #weaponScrollControls do
            DisableControlAction(0, weaponScrollControls[i], true)
        end

        if CURRENT_SELECTION > 1 and controlPressed(scrollUpControls) then
            CURRENT_SELECTION -= 1
        elseif CURRENT_SELECTION < activeAmount and controlPressed(scrollDownControls) then
            CURRENT_SELECTION += 1
        end
    end

    utils.drawPrompt(activeCoords, visibleOptions, CURRENT_SELECTION)

    if IsControlJustPressed(0, 38) then
        triggerOption(active, visibleOptions[CURRENT_SELECTION])
    end
end

local function isDisabled()
    if LocalPlayer.state.interactionsDisabled then
        return true
    end

    if settings.Disable.onDeath and (IsPedDeadOrDying(cache.ped) or LocalPlayer.state.isDead) then
        return true
    end

    if settings.Disable.onNuiFocus and IsNuiFocused() then
        return true
    end

    if settings.Disable.onVehicle and cache.vehicle then
        return true
    end

    if settings.Disable.onHandCuff and IsPedCuffed(cache.ped) then
        return true
    end

    return false
end

-- Fast thread
CreateThread(function ()
    lib.requestStreamedTextureDict('interact_txd')
    while true do
        local wait = 500
        if next(nearby) and not isDisabled() then
            wait = 0
            CreateInteractions()
        end
        Wait(wait)
    end
end)

-- Slow checker thread
CreateThread(function()
    while true do
        nearby = interactions.getNearbyInteractions()
        Wait(500)
    end
end)