-- ============================================================
--  DUI monitor test for v_corp_desksetb
--
--  Commands:
--    /duispawn              spawn v_corp_desksetb in front of you
--    /duitest [txd] [txn]   apply DUI to txd/txn (defaults below)
--    /duinext               try the next TXD candidate in the list
--    /duiurl <url>          change the page shown on the DUI
--    /duiclear              remove replacement + delete spawned prop
-- ============================================================

local MODEL        = 'prop_laptop_jimmy'
local DEFAULT_TXN  = 'prop_jimmy_screen'

-- Add any TXD names you find in CodeWalker/OpenIV here.
-- /duinext cycles through them so you can see which one works.
local TXD_CANDIDATES = {
    'prop_laptop_jimmy',   -- embedded textures => txd = model name
    'prop_jimmy_screen',   -- in case that name is actually the drawable/ytd
}

local DUI_W, DUI_H = 1024, 1024
local RUNTIME_TXD  = 'dui_test_txd'
local RUNTIME_TXN  = 'dui_test_tex'

local resName   = GetCurrentResourceName()
local duiUrl    = ('nui://%s/html/index.html'):format(resName)
local duiObj    = nil
local runtimeTxdHandle = nil
local spawnedProp = nil
local activeTxd, activeTxn = nil, nil
local candidateIndex = 0

local function notify(msg)
    print('[dui_test] ' .. msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function ensureDui()
    if duiObj then return end
    runtimeTxdHandle = CreateRuntimeTxd(RUNTIME_TXD)
    duiObj = CreateDui(duiUrl, DUI_W, DUI_H)
    -- wait until the browser is ready
    local t = GetGameTimer()
    while not IsDuiAvailable(duiObj) and GetGameTimer() - t < 5000 do
        Wait(0)
    end
    CreateRuntimeTextureFromDuiHandle(runtimeTxdHandle, RUNTIME_TXN, GetDuiHandle(duiObj))
    notify('DUI created: ' .. duiUrl)
end

-- Checks whether a standalone .ytd with this name is streamable.
-- NOTE: embedded drawable dictionaries will report false here even if they work.
local function ytdExists(txd)
    RequestStreamedTextureDict(txd, false)
    local t = GetGameTimer()
    while not HasStreamedTextureDictLoaded(txd) and GetGameTimer() - t < 1500 do
        Wait(0)
    end
    local ok = HasStreamedTextureDictLoaded(txd)
    if ok then SetStreamedTextureDictAsNoLongerNeeded(txd) end
    return ok
end

local function clearReplace()
    if activeTxd then
        RemoveReplaceTexture(activeTxd, activeTxn)
        activeTxd, activeTxn = nil, nil
    end
end

local function applyReplace(txd, txn)
    ensureDui()
    clearReplace()
    AddReplaceTexture(txd, txn, RUNTIME_TXD, RUNTIME_TXN)
    activeTxd, activeTxn = txd, txn

    local exists = ytdExists(txd)
    notify(('Applied: %s / %s  (standalone ytd found: %s)'):format(txd, txn, tostring(exists)))
    notify('Look at the monitor. Grid visible = correct TXD.')
end

RegisterCommand('duispawn', function()
    local hash = GetHashKey(MODEL)
    if not IsModelInCdimage(hash) then
        notify('Model not found: ' .. MODEL)
        return
    end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    if spawnedProp and DoesEntityExist(spawnedProp) then DeleteEntity(spawnedProp) end

    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, -1.0)
    spawnedProp = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(spawnedProp, GetEntityHeading(ped) + 180.0) -- face the player
    FreezeEntityPosition(spawnedProp, true)
    SetModelAsNoLongerNeeded(hash)
    notify('Spawned ' .. MODEL)
end, false)

RegisterCommand('duitest', function(_, args)
    local txd = args[1] or TXD_CANDIDATES[1]
    local txn = args[2] or DEFAULT_TXN
    applyReplace(txd, txn)
end, false)

RegisterCommand('duinext', function()
    candidateIndex = candidateIndex % #TXD_CANDIDATES + 1
    applyReplace(TXD_CANDIDATES[candidateIndex], DEFAULT_TXN)
end, false)

RegisterCommand('duiurl', function(_, args)
    if not args[1] then notify('Usage: /duiurl <url>') return end
    ensureDui()
    SetDuiUrl(duiObj, args[1])
    notify('DUI url set: ' .. args[1])
end, false)

RegisterCommand('duiclear', function()
    clearReplace()
    if spawnedProp and DoesEntityExist(spawnedProp) then DeleteEntity(spawnedProp) end
    spawnedProp = nil
    notify('Cleared')
end, false)

-- On-screen status
CreateThread(function()
    while true do
        if activeTxd then
            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(255, 255, 255, 220)
            SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(('DUI test  TXD: ~y~%s~w~  TXN: ~y~%s'):format(activeTxd, activeTxn))
            EndTextCommandDisplayText(0.015, 0.75)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then return end
    clearReplace()
    if duiObj then DestroyDui(duiObj) end
    if spawnedProp and DoesEntityExist(spawnedProp) then DeleteEntity(spawnedProp) end
end)
