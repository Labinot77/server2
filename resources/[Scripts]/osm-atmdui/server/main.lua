-- ATM callbacks: accounts, history, withdraw (with per-transaction and daily limits).

local daily = {} -- [citizenid] = { day, total }  (in memory: resets at midnight / restart)

local function Daily(src)
    local player = Bank.GetPlayer(src)
    if not player then return nil end
    local cid, today = player.PlayerData.citizenid, os.date('%Y-%m-%d')
    local d = daily[cid]
    if not d or d.day ~= today then
        d = { day = today, total = 0 }
        daily[cid] = d
    end
    return d
end

local function DailyLeft(d)
    return math.max(0, Config.Withdraw.dailyLimit - d.total)
end

lib.callback.register('osm-atmdui:getAccounts', function(src)
    local d = Daily(src)
    if not d then return {}, 0 end
    return Bank.GetAccounts(src), DailyLeft(d)
end)

lib.callback.register('osm-atmdui:getHistory', function(src, accountId)
    return Bank.GetHistory(src, accountId, 6)
end)

local busy = {}

lib.callback.register('osm-atmdui:withdraw', function(src, accountId, amount)
    amount = math.floor(tonumber(amount) or 0)
    local d = Daily(src)

    if not d then return false, nil, Config.Text.error end
    if amount <= 0 then return false, nil, Config.Text.invalid_amount end
    if amount > Config.Withdraw.maxPerTransaction then return false, nil, Config.Text.over_limit end
    if d.total + amount > Config.Withdraw.dailyLimit then return false, nil, Config.Text.daily_limit end
    if busy[src] then return false, nil, Config.Text.error end

    busy[src] = true
    local ok, balance, errKey = Bank.Withdraw(src, accountId, amount)
    busy[src] = nil

    if not ok then return false, balance, Config.Text[errKey] or Config.Text.error end

    d.total = d.total + amount
    return true, balance, nil, DailyLeft(d)
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
