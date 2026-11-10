FW = FW or {}
FW.Config = Config
FW.Shared = Shared
FW.ServerCallbacks = {}
FW.UseableItems = {}

Citizen.CreateThread(function()
    local Result = exports['ghmattimysql']:executeSync("SELECT `taxes` FROM server_config")

    FW.Shared.Tax = {}
    for k, v in pairs(json.decode(Result[1].taxes)) do
        FW.Shared.Tax[k] = v
        print("^7Tax [" .. k .. "] set to " .. tostring(v) .. "%")
    end
end)

-- // Functions \\ --

function GetCoreObject()
	return FW
end

-- Finds an identifier by type (e.g. "steam", "license") regardless of its position in the list.
local function GetIdentifierOfType(Source, Type)
    if GetPlayerIdentifierByType then
        local Id = GetPlayerIdentifierByType(Source, Type)
        if Id and Id ~= '' then return Id end
    end

    local Prefix = Type .. ':'
    for _, Id in ipairs(GetPlayerIdentifiers(Source)) do
        if Id:sub(1, #Prefix) == Prefix then
            return Id
        end
    end

    return nil
end

AddEventHandler("playerConnecting", function(Name, KickReason, Deferral)
    local Source = source

    Deferral.defer()
    Citizen.Wait(0) -- required before the first presentCard/update/done

    local Name = GetPlayerName(Source) or Name
    local SteamId = GetIdentifierOfType(Source, 'steam')
    local SpecialMessage = (SteamId and Config.SpecialMessage[SteamId]) or ('👋 Connecting, %s...'):format(Name)

    Config.ConnectCard.body[2].text = 'Connecting..'
    Deferral.presentCard(Config.ConnectCard, function(data, rawData) end)

    Citizen.Wait(1500)

    local IsBanned, Message = FW.Functions.IsPlayerBanned(Source)
    if IsBanned then
        Deferral.done(Message)
        return
    end

    Config.ConnectCard.body[2].text = 'Checking for whitelist..'
    Deferral.presentCard(Config.ConnectCard, function(data, rawData) end)

    Citizen.Wait(1000)

    -- if not exports['fw-queue']:CheckDiscordRole(Source) then
    --     Deferral.done('Het lijkt erop dat je geen whitelist hebt..')
    --     return
    -- end

    Config.ConnectCard.body[2].text = 'Checking for steam..'
    Deferral.presentCard(Config.ConnectCard, function(data, rawData) end)

    Citizen.Wait(1000)

    if not SteamId then
        print(('^1[SteamCheck]^7 No steam identifier for %s. Identifiers: %s'):format(Name, json.encode(GetPlayerIdentifiersWithoutIp(Source))))
        Deferral.done('We cannot find steam.. Open Steam first, then fully restart FiveM and try again.')
        return
    end

    Config.ConnectCard.body[2].text = 'Connecting..'
    Deferral.presentCard(Config.ConnectCard, function(data, rawData) end)

    Citizen.Wait(math.random(1000, 5000))
    local Steam = SteamId
    local License = GetIdentifierOfType(Source, 'license')

    if FW.AreLicensesUsed(Steam, License) then
        TriggerEvent('fw-logs:Server:Log', 'anticheat', 'Player Join Canceled', ('%s (%s / %s) joined the server but has an client already active.'):format(Name, Steam, License), 'orange')
        Deferral.done('You are in the server with another client..')
        return
    end

    if SpecialMessage ~= nil and SpecialMessage ~= false then
        Config.ConnectCard.body[2].text = '\n\n'..SpecialMessage..'\n'
        Deferral.presentCard(Config.ConnectCard, function(data, rawData) end)
        Citizen.Wait(8000)
    end

    Citizen.Wait(1500)

    local PlayerName = GetPlayerName(Source)
    if PlayerName == nil then return end -- player disconnected during the checks

    print(("^7[NEUTRAL]^7 ^5[%s]^7: %s"):format("Player", ("Player Connecting [Player: %s]"):format(Name)))
    TriggerEvent("fw-queue:Server:Player:Connect", Source, KickReason, Deferral)
    TriggerEvent('fw-logs:Server:Log', 'joinleave', 'Connecting', ("User: %s\nIdentifiers: ```json\n%s```"):format(PlayerName, json.encode(GetPlayerIdentifiersWithoutIp(Source), {indent=4})), 'green')
end)
