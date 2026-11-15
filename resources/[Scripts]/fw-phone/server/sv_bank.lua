-- Returns the player's permissions on an account, or nil when they have no access.
local function GetAccess(Player, AccountId)
    if AccountId == Player.PlayerData.charinfo.account then
        return { Transfer = true, Transactions = true }
    end

    local Account = exports['ghmattimysql']:executeSync("SELECT `citizenid`, `authorized` FROM `player_financials` WHERE `accountid` = ?", { AccountId })[1]
    if not Account then return nil end
    if Account.citizenid == Player.PlayerData.citizenid then return { Transfer = true, Transactions = true } end

    for _, A in pairs(json.decode(Account.authorized or '[]') or {}) do
        if A.Cid == Player.PlayerData.citizenid then return A.Permissions end
    end
end

FW.Functions.CreateCallback("fw-phone:Server:Bank:GetTransactions", function(Source, Cb, Data)
    local Player = FW.Functions.GetPlayer(Source)
    local Access = Player and GetAccess(Player, Data.AccountId)
    if not Access or not Access.Transactions then return Cb({}) end

    local All, Retval = exports['fw-financials']:GetAccountTransactions(Data.AccountId), {}
    for i = 1, math.min(#All, 50) do Retval[i] = All[i] end
    Cb(Retval)
end)

FW.Functions.CreateCallback("fw-phone:Server:Bank:Transfer", function(Source, Cb, Data)
    local Player = FW.Functions.GetPlayer(Source)
    local Amount = math.floor(tonumber(Data.Amount) or 0)
    if not Player then return Cb({ Success = false, Msg = "Invalid player." }) end
    if Amount <= 0 then return Cb({ Success = false, Msg = "Enter a valid amount." }) end

    local Access = GetAccess(Player, Data.AccountId)
    if not Access or not Access.Transfer then return Cb({ Success = false, Msg = "No transfer access on this account." }) end

    -- Target can be a phone number (online player) or an account id.
    local TargetPlayer = FW.Functions.GetPlayerByPhone(tostring(Data.Target or ''))
    local TargetAccount = TargetPlayer and TargetPlayer.PlayerData.charinfo.account or tostring(Data.Target or '')
    if TargetAccount == Data.AccountId then return Cb({ Success = false, Msg = "You can't send money to the same account." }) end
    if not exports['fw-financials']:GetFinancialAccountById(TargetAccount) then return Cb({ Success = false, Msg = "Recipient not found." }) end

    local Comment = tostring(Data.Comment or ''):sub(1, 100)
    if Comment == '' then Comment = "Phone transfer" end

    if not exports['fw-financials']:RemoveMoneyFromAccount(Player.PlayerData.citizenid, Data.AccountId, Data.AccountId, Amount, 'Transfer', Comment, false) then
        return Cb({ Success = false, Msg = "Not enough balance." })
    end
    exports['fw-financials']:AddMoneyToAccount(Player.PlayerData.citizenid, Data.AccountId, TargetAccount, Amount, 'Transfer', Comment)

    TriggerEvent("fw-logs:Server:Log", 'transfermoney', "Money Transferred [Phone]", ("User: [%s] - %s - %s\nFrom: %s\nTarget: %s\nAmount: %s"):format(Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, Data.AccountId, TargetAccount, Amount), "blue")

    if TargetPlayer then
        TriggerClientEvent("fw-phone:Client:Notification", TargetPlayer.PlayerData.source, 'bank-deposit-' .. math.random(111, 999), 'fas fa-university', { 'white', '#1f6fe0' }, "Bank", ("$%s was deposited into your account."):format(Amount))
    end

    Cb({ Success = true })
end)
