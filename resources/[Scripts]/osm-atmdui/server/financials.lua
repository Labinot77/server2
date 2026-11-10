-- fw-financials access with the same rules as the bank app:
-- the personal account, plus shared/business accounts the character has Withdraw permission on.

local FW = exports['fw-core']:GetCoreObject()
local Financials = exports['fw-financials']

Bank = {}

-- fw-financials saves balances with an async UPDATE, so a read right after a withdrawal
-- can still return the old value. Remember the new balance for a few seconds.
local pending = {}

local function Balance(accountId, dbValue)
    local p = pending[accountId]
    if p and GetGameTimer() < p.expires then return p.balance end
    pending[accountId] = nil
    return tonumber(dbValue) or 0
end

local function Permissions(account, cid)
    if account.citizenid == cid then return { Withdraw = true, Transactions = true } end
    for _, entry in pairs(json.decode(account.authorized or '[]') or {}) do
        if entry.Cid == cid then return entry.Permissions or {} end
    end
    return {}
end

local function FormatDate(ts)
    if type(ts) == 'number' then
        return os.date('%d/%m %H:%M', ts > 1e11 and math.floor(ts / 1000) or ts)
    end
    local _, m, d, H, M = tostring(ts):match('(%d+)-(%d+)-(%d+)[T ](%d+):(%d+)')
    return d and ('%s/%s %s:%s'):format(d, m, H, M) or ''
end

function Bank.GetPlayer(src)
    return FW.Functions.GetPlayer(src)
end

---@return { id: string, label: string, balance: number, canHistory: boolean }[]
function Bank.GetAccounts(src)
    local player = Bank.GetPlayer(src)
    if not player then return {} end
    local cid = player.PlayerData.citizenid
    local list = {}

    local personal = Financials:GetFinancialAccountById(player.PlayerData.charinfo.account)
    if personal and personal.active ~= 0 then
        list[1] = { id = tostring(personal.accountid), label = 'PERSONAL', balance = Balance(personal.accountid, personal.balance), canHistory = true }
    end

    local rows = exports['ghmattimysql']:executeSync(
        "SELECT * FROM `player_financials` WHERE (`citizenid` = @Cid OR `authorized` LIKE @LikeCid) AND NOT `type` = 'Standaard' AND `active` = 1",
        { ['@Cid'] = cid, ['@LikeCid'] = '%' .. cid .. '%' }
    ) or {}

    for _, acc in ipairs(rows) do
        local perms = Permissions(acc, cid)
        if perms.Withdraw then
            list[#list + 1] = {
                id = tostring(acc.accountid),
                label = tostring(acc.name or acc.type):upper(),
                balance = Balance(acc.accountid, acc.balance),
                canHistory = perms.Transactions == true,
            }
        end
    end

    return list
end

local function FindAccount(src, accountId)
    for _, acc in ipairs(Bank.GetAccounts(src)) do
        if acc.id == tostring(accountId) then return acc end
    end
end

function Bank.GetHistory(src, accountId, limit)
    local acc = FindAccount(src, accountId)
    if not acc or not acc.canHistory then return {} end

    local all = Financials:GetAccountTransactions(acc.id) or {}
    local out = {}
    for i = 1, math.min(limit, #all) do
        local t = all[i]
        out[i] = {
            type = tostring(t.TransactionType or 'Transaction'),
            amount = tonumber(t.Amount) or 0,
            negative = t.IsNegative == true,
            date = FormatDate(t.Timestamp),
            note = t.Message and tostring(t.Message):sub(1, 40) or '',
        }
    end
    return out
end

---@return boolean ok, number|nil balance, string|nil errorKey
function Bank.Withdraw(src, accountId, amount)
    local player = Bank.GetPlayer(src)
    local acc = player and FindAccount(src, accountId)
    if not acc then return false, nil, 'no_permission' end
    if acc.balance < amount then return false, acc.balance, 'insufficient_funds' end

    local cid = player.PlayerData.citizenid
    if not Financials:RemoveMoneyFromAccount(cid, acc.id, acc.id, amount, 'Withdraw', 'ATM Withdrawal', false) then
        return false, acc.balance, 'error'
    end

    local balance = acc.balance - amount
    pending[acc.id] = { balance = balance, expires = GetGameTimer() + 5000 }
    player.Functions.AddMoney('cash', amount, 'ATM Withdrawal')

    local c = player.PlayerData.charinfo
    TriggerEvent('fw-logs:Server:Log', 'money', 'ATM Withdraw [osm-atmdui]',
        ('User: [%s] - %s - %s %s\nAmount: %s\nAccount ID: %s'):format(src, cid, c.firstname, c.lastname, amount, acc.id), 'red')
    TriggerClientEvent('fw-financials:Client:RefreshFinancials', src)

    return true, balance
end
