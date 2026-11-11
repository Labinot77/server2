-- ATM callbacks (was osm-atmdui): accounts, history and withdraw with per-transaction and daily limits.
-- Same access rules as the bank app: the personal account, plus shared/business accounts with Withdraw permission.

local Daily = {}   -- [citizenid] = { Day, Total } (in memory: resets at midnight / restart)
local Busy = {}    -- [source] = true while a withdrawal runs
local Pending = {} -- [accountid] = { Balance, Expires }

-- Balances are saved with an async UPDATE, so a read right after a withdrawal can still be old.
local function Balance(AccountId, DbValue)
    local P = Pending[AccountId]
    if P and GetGameTimer() < P.Expires then return P.Balance end
    Pending[AccountId] = nil
    return tonumber(DbValue) or 0
end

local function Permissions(Account, Cid)
    if Account.citizenid == Cid then return { Withdraw = true, Transactions = true } end
    for _, Entry in pairs(json.decode(Account.authorized or '[]') or {}) do
        if Entry.Cid == Cid then return Entry.Permissions or {} end
    end
    return {}
end

local function FormatDate(Ts)
    if type(Ts) == 'number' then return os.date('%d/%m %H:%M', Ts > 1e11 and math.floor(Ts / 1000) or Ts) end
    local _, M, D, H, Min = tostring(Ts):match('(%d+)-(%d+)-(%d+)[T ](%d+):(%d+)')
    return D and ('%s/%s %s:%s'):format(D, M, H, Min) or ''
end

local function GetDaily(Player)
    local Cid, Today = Player.PlayerData.citizenid, os.date('%Y-%m-%d')
    if not Daily[Cid] or Daily[Cid].Day ~= Today then Daily[Cid] = { Day = Today, Total = 0 } end
    return Daily[Cid]
end

local function DailyLeft(D)
    return math.max(0, Config.ATM.Withdraw.DailyLimit - D.Total)
end

---@return { id: string, label: string, balance: number, canHistory: boolean }[]
local function GetATMAccounts(Player)
    local Cid, List = Player.PlayerData.citizenid, {}

    local Personal = GetFinancialAccountById(Player.PlayerData.charinfo.account)
    if Personal and Personal.active ~= 0 then
        List[1] = { id = tostring(Personal.accountid), label = 'PERSONAL', balance = Balance(Personal.accountid, Personal.balance), canHistory = true }
    end

    local Rows = exports['ghmattimysql']:executeSync(
        "SELECT * FROM `player_financials` WHERE (`citizenid` = @Cid OR `authorized` LIKE @LikeCid) AND NOT `type` = 'Standaard' AND `active` = 1",
        { ['@Cid'] = Cid, ['@LikeCid'] = '%' .. Cid .. '%' }
    ) or {}

    for _, Acc in ipairs(Rows) do
        local Perms = Permissions(Acc, Cid)
        if Perms.Withdraw then
            List[#List + 1] = {
                id = tostring(Acc.accountid),
                label = tostring(Acc.name or Acc.type):upper(),
                balance = Balance(Acc.accountid, Acc.balance),
                canHistory = Perms.Transactions == true,
            }
        end
    end
    return List
end

local function FindAccount(Player, AccountId)
    for _, Acc in ipairs(GetATMAccounts(Player)) do
        if Acc.id == tostring(AccountId) then return Acc end
    end
end

FW.Functions.CreateCallback('fw-financials:Server:ATM:GetAccounts', function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return Cb({ Accounts = {}, DailyLeft = 0 }) end
    Cb({ Accounts = GetATMAccounts(Player), DailyLeft = DailyLeft(GetDaily(Player)) })
end)

FW.Functions.CreateCallback('fw-financials:Server:ATM:GetHistory', function(Source, Cb, AccountId)
    local Player = FW.Functions.GetPlayer(Source)
    local Acc = Player and FindAccount(Player, AccountId)
    if not Acc or not Acc.canHistory then return Cb({}) end

    local All, Out = GetAccountTransactions(Acc.id) or {}, {}
    for I = 1, math.min(6, #All) do
        local T = All[I]
        Out[I] = {
            type = tostring(T.TransactionType or 'Transaction'),
            amount = tonumber(T.Amount) or 0,
            negative = T.IsNegative == true,
            date = FormatDate(T.Timestamp),
            note = T.Message and tostring(T.Message):sub(1, 40) or '',
        }
    end
    Cb(Out)
end)

FW.Functions.CreateCallback('fw-financials:Server:ATM:Withdraw', function(Source, Cb, AccountId, Amount)
    local Text = Config.ATM.Text
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return Cb({ Error = Text.error }) end

    Amount = math.floor(tonumber(Amount) or 0)
    local D = GetDaily(Player)
    if Amount <= 0 then return Cb({ Error = Text.invalid_amount }) end
    if Amount > Config.ATM.Withdraw.MaxPerTransaction then return Cb({ Error = Text.over_limit }) end
    if D.Total + Amount > Config.ATM.Withdraw.DailyLimit then return Cb({ Error = Text.daily_limit }) end
    if Busy[Source] then return Cb({ Error = Text.error }) end

    local Acc = FindAccount(Player, AccountId)
    if not Acc then return Cb({ Error = Text.no_permission }) end
    if Acc.balance < Amount then return Cb({ Balance = Acc.balance, Error = Text.insufficient_funds }) end

    Busy[Source] = true
    local Cid = Player.PlayerData.citizenid
    local Ok = RemoveMoneyFromAccount(Cid, Acc.id, Acc.id, Amount, 'Withdraw', 'ATM Withdrawal', false)
    Busy[Source] = nil
    if not Ok then return Cb({ Balance = Acc.balance, Error = Text.error }) end

    local NewBalance = Acc.balance - Amount
    Pending[Acc.id] = { Balance = NewBalance, Expires = GetGameTimer() + 5000 }
    Player.Functions.AddMoney('cash', Amount, 'ATM Withdrawal')
    D.Total = D.Total + Amount

    local C = Player.PlayerData.charinfo
    TriggerEvent('fw-logs:Server:Log', 'money', 'ATM Withdraw',
        ('User: [%s] - %s - %s %s\nAmount: %s\nAccount ID: %s'):format(Source, Cid, C.firstname, C.lastname, Amount, Acc.id), 'red')
    TriggerClientEvent('fw-financials:Client:RefreshFinancials', Source)

    Cb({ Success = true, Balance = NewBalance, DailyLeft = DailyLeft(D) })
end)

AddEventHandler('playerDropped', function() Busy[source] = nil end)
