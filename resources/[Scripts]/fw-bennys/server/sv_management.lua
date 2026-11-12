-- Business management for the laptop's Management app: the same data as the phone's Employment app
-- (phone_businesses + the business bank account), but every action is permission-checked here on the server.
FW = FW or exports['fw-core']:GetCoreObject()

local DB = exports['ghmattimysql']

local PERMISSIONS = { 'Hire', 'Fire', 'ChangeRole', 'PayEmployee', 'PayExternal', 'ChargeExternal', 'PropertyKeys', 'StashAccess', 'CraftAccess', 'VehicleSales' }
local BANK_PERMISSIONS = { 'Balance', 'Deposit', 'Withdraw', 'Transfer', 'Transactions' }

-- Any of these lets a role open the app. Roles and bank access are owner-only.
local MANAGE = { Hire = true, Fire = true, ChangeRole = true, PayEmployee = true, PayExternal = true, ChargeExternal = true }

-- ── Data ───────────────────────────────────────────────────────────────────

local function GetBusiness(Name)
    local Row = DB:executeSync("SELECT * FROM `phone_businesses` WHERE `business_name` = ?", { Name })
    Row = Row and Row[1]
    if not Row then return nil end
    Row.Employees = json.decode(Row.business_employees or '[]') or {}
    Row.Roles = json.decode(Row.business_ranks or '[]') or {}
    return Row
end

local function Save(Name, Field, Value)
    DB:executeSync(("UPDATE `phone_businesses` SET `%s` = ? WHERE `business_name` = ?"):format(Field), { json.encode(Value), Name })
    if ClearBusinessCache then ClearBusinessCache(Name) end -- sv_orders.lua member cache
end

-- { Name, Account } of a character, online or not.
local function GetCharacter(Cid)
    local Player = FW.Functions.GetPlayerByCitizenId(Cid)
    local Info = Player and Player.PlayerData.charinfo
    if not Info then
        local Row = DB:executeSync("SELECT `charinfo` FROM `players` WHERE `citizenid` = ?", { Cid })
        Info = Row and Row[1] and json.decode(Row[1].charinfo)
    end
    if not Info then return nil end
    return { Name = ('%s %s'):format(Info.firstname, Info.lastname), Account = Info.account, Online = Player ~= nil }
end

local function FindIndex(List, Fn)
    for I, V in ipairs(List) do
        if Fn(V) then return I end
    end
end

local function FindRole(Biz, Name)
    return FindIndex(Biz.Roles, function(R) return R.Name:lower() == tostring(Name):lower() end)
end

-- ── Access ─────────────────────────────────────────────────────────────────

-- { IsOwner, Perms = { Hire = bool, ... }, Role } for the player, nil when not in the business.
local function GetAccess(Source, Biz)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return nil end
    local Cid = Player.PlayerData.citizenid

    local Access = { IsOwner = Biz.business_owner == Cid, Perms = {}, Cid = Cid }
    if Access.IsOwner then
        for _, Perm in ipairs(PERMISSIONS) do Access.Perms[Perm] = true end
        Access.Role = 'Owner'
        return Access
    end

    local Employee = Biz.Employees[FindIndex(Biz.Employees, function(E) return E.Cid == Cid end) or 0]
    if not Employee then return nil end
    local Role = Biz.Roles[FindRole(Biz, Employee.Role) or 0]
    Access.Role = Employee.Role
    for _, Perm in ipairs(PERMISSIONS) do Access.Perms[Perm] = Role and Role.Perms[Perm] == true or false end
    return Access
end

local function CanOpen(Access)
    if not Access then return false end
    if Access.IsOwner then return true end
    for Perm in pairs(MANAGE) do
        if Access.Perms[Perm] then return true end
    end
    return false
end

-- Everything the app shows.
local function BuildView(Biz, Access)
    local Employees = {}
    for _, E in ipairs(Biz.Employees) do
        local Char = GetCharacter(E.Cid)
        Employees[#Employees + 1] = { Cid = E.Cid, Role = E.Role, Name = Char and Char.Name or E.Cid, Online = Char and Char.Online or false }
    end
    table.sort(Employees, function(A, B) return A.Name < B.Name end)

    local Owner = GetCharacter(Biz.business_owner)
    local Account = Biz.business_account and Biz.business_account ~= '' and exports['fw-financials']:GetFinancialAccountById(Biz.business_account)

    return {
        Business = Biz.business_name,
        Owner = Owner and Owner.Name or Biz.business_owner,
        IsOwner = Access.IsOwner,
        MyRole = Access.Role,
        Perms = Access.Perms,
        Employees = Employees,
        Roles = Biz.Roles,
        Permissions = PERMISSIONS,
        BankPermissions = BANK_PERMISSIONS,
        Account = Account and Biz.business_account or nil,
        Balance = Account and tonumber(Account.balance) or nil,
    }
end

-- ── Actions ────────────────────────────────────────────────────────────────

local function Fail(Message) return { Success = false, Message = Message } end
local function Ok(Message) return { Success = true, Message = Message } end

local function CleanAmount(Amount)
    Amount = math.floor(tonumber(Amount) or 0)
    if Amount <= 0 or Amount > 10000000 then return nil end
    return Amount
end

local function CleanText(Text, Max)
    Text = tostring(Text or ''):gsub('^%s+', ''):gsub('%s+$', '')
    return Text:sub(1, Max)
end

local function EmployeeIndex(Biz, Cid)
    return FindIndex(Biz.Employees, function(E) return E.Cid == Cid end)
end

local Actions = {}

function Actions.Hire(Source, Biz, Access, Data)
    if not Access.Perms.Hire then return Fail("You don't have permission to hire.") end
    local Cid = CleanText(Data.Cid, 20)
    if not FindRole(Biz, Data.Role) then return Fail('Pick an existing role.') end
    if Cid == Biz.business_owner or EmployeeIndex(Biz, Cid) then return Fail('This person already works here.') end
    local Char = GetCharacter(Cid)
    if not Char then return Fail('No citizen found with that State ID.') end

    Biz.Employees[#Biz.Employees + 1] = { Cid = Cid, Role = Biz.Roles[FindRole(Biz, Data.Role)].Name }
    Save(Biz.business_name, 'business_employees', Biz.Employees)
    return Ok(('%s has been hired.'):format(Char.Name))
end

function Actions.Fire(Source, Biz, Access, Data)
    if not Access.Perms.Fire then return Fail("You don't have permission to fire.") end
    local Index = EmployeeIndex(Biz, Data.Cid)
    if not Index then return Fail('This person is not an employee.') end
    if Data.Cid == Access.Cid then return Fail("You can't fire yourself.") end

    table.remove(Biz.Employees, Index)
    Save(Biz.business_name, 'business_employees', Biz.Employees)
    return Ok('Employee has been fired.')
end

function Actions.SetRole(Source, Biz, Access, Data)
    if not Access.Perms.ChangeRole then return Fail("You don't have permission to change roles.") end
    local Index, Role = EmployeeIndex(Biz, Data.Cid), FindRole(Biz, Data.Role)
    if not Index then return Fail('This person is not an employee.') end
    if not Role then return Fail('That role does not exist.') end
    if Data.Cid == Access.Cid and not Access.IsOwner then return Fail("You can't change your own role.") end

    Biz.Employees[Index].Role = Biz.Roles[Role].Name
    Save(Biz.business_name, 'business_employees', Biz.Employees)
    return Ok(('Role changed to %s.'):format(Biz.Roles[Role].Name))
end

-- Pays from the business account: PayEmployee for employees, PayExternal for anyone else.
function Actions.Pay(Source, Biz, Access, Data)
    local Cid, Amount = CleanText(Data.Cid, 20), CleanAmount(Data.Amount)
    local IsEmployee = EmployeeIndex(Biz, Cid) ~= nil or Cid == Biz.business_owner
    if not Access.Perms[IsEmployee and 'PayEmployee' or 'PayExternal'] then return Fail("You don't have permission to make this payment.") end
    if not Amount then return Fail('Enter a valid amount.') end
    if not Biz.business_account or Biz.business_account == '' then return Fail('This business has no bank account.') end

    local Char = GetCharacter(Cid)
    if not Char or not Char.Account then return Fail('No citizen found with that State ID.') end

    local Comment = ('Payment from %s: %s'):format(Biz.business_name, CleanText(Data.Comment, 80) ~= '' and CleanText(Data.Comment, 80) or 'No comment')
    if not exports['fw-financials']:RemoveMoneyFromAccount(Access.Cid, Char.Account, Biz.business_account, Amount, 'PAY', Comment, false) then
        return Fail('Not enough money in the business account.')
    end
    exports['fw-financials']:AddMoneyToAccount(Access.Cid, Biz.business_account, Char.Account, Amount, 'PAY', Comment)

    TriggerEvent('fw-logs:Server:Log', 'money', 'Business Payment',
        ('%s paid $%s to %s (%s) from %s\n%s'):format(Access.Cid, Amount, Char.Name, Cid, Biz.business_name, Comment), 'green')
    return Ok(('Paid $%s to %s.'):format(Amount, Char.Name))
end

-- Sends a bill to an online citizen's phone; fw-businesses handles accept / reject (same as the phone app).
function Actions.Charge(Source, Biz, Access, Data)
    if not Access.Perms.ChargeExternal then return Fail("You don't have permission to charge customers.") end
    local Cid, Amount = CleanText(Data.Cid, 20), CleanAmount(Data.Amount)
    if not Amount then return Fail('Enter a valid amount.') end
    if not Biz.business_account or Biz.business_account == '' then return Fail('This business has no bank account.') end

    local Target = FW.Functions.GetPlayerByCitizenId(Cid)
    if not Target then return Fail('That citizen is not in the city.') end

    local Comment = CleanText(Data.Comment, 80) ~= '' and CleanText(Data.Comment, 80) or 'No comment'
    local Ok2, Total = pcall(function() return FW.Shared.CalculateTax('Services', Amount) end)
    Total = Ok2 and Total or Amount

    TriggerClientEvent('fw-phone:Client:Notification', Target.PlayerData.source, ('charge-customer-%s'):format(Cid), 'fas fa-donate', { 'white', 'rgb(38, 50, 56)' },
        'Business Invoice', ('$%s - %s - %s'):format(Total, Biz.business_name, Comment), false, true,
        'fw-businesses:Server:AcceptCharge', 'fw-businesses:Server:RejectCharge',
        { Id = ('charge-customer-%s'):format(Cid), Account = Biz.business_account, Cid = Cid, Charger = Source, Business = Biz.business_name, Amount = Amount, Comment = Comment })
    return Ok('Invoice sent.')
end

function Actions.CreateRole(Source, Biz, Access, Data)
    if not Access.IsOwner then return Fail('Only the owner can create roles.') end
    local Name = CleanText(Data.Name, 24)
    if Name == '' then return Fail('Enter a role name.') end
    if FindRole(Biz, Name) then return Fail('A role with that name already exists.') end

    local Perms = {}
    for _, Perm in ipairs(PERMISSIONS) do Perms[Perm] = false end
    Biz.Roles[#Biz.Roles + 1] = { Name = Name, Perms = Perms }
    Save(Biz.business_name, 'business_ranks', Biz.Roles)
    return Ok(('Role %s created.'):format(Name))
end

-- Toggles one permission of a role.
function Actions.SetPermission(Source, Biz, Access, Data)
    if not Access.IsOwner then return Fail('Only the owner can edit roles.') end
    local Index = FindRole(Biz, Data.Role)
    if not Index then return Fail('That role does not exist.') end

    local Valid = false
    for _, Perm in ipairs(PERMISSIONS) do Valid = Valid or Perm == Data.Permission end
    if not Valid then return Fail('Unknown permission.') end

    Biz.Roles[Index].Perms[Data.Permission] = Data.Value == true
    Save(Biz.business_name, 'business_ranks', Biz.Roles)
    return Ok('Role updated.')
end

function Actions.DeleteRole(Source, Biz, Access, Data)
    if not Access.IsOwner then return Fail('Only the owner can delete roles.') end
    local Index = FindRole(Biz, Data.Role)
    if not Index then return Fail('That role does not exist.') end
    if FindIndex(Biz.Employees, function(E) return E.Role:lower() == Biz.Roles[Index].Name:lower() end) then
        return Fail('An employee still has this role.')
    end

    table.remove(Biz.Roles, Index)
    Save(Biz.business_name, 'business_ranks', Biz.Roles)
    return Ok('Role deleted.')
end

-- Bank access of an employee on the business account (owner only).
function Actions.GetBankAccess(Source, Biz, Access, Data)
    if not Access.IsOwner then return Fail('Only the owner can manage bank access.') end
    local Account = Biz.business_account and exports['fw-financials']:GetFinancialAccountById(Biz.business_account)
    if not Account then return Fail('This business has no bank account.') end

    local Perms = {}
    for _, Entry in pairs(json.decode(Account.authorized or '[]') or {}) do
        if Entry.Cid == Data.Cid then Perms = Entry.Permissions or {} end
    end
    return { Success = true, Bank = { Cid = Data.Cid, Perms = Perms } }
end

function Actions.SetBankAccess(Source, Biz, Access, Data)
    if not Access.IsOwner then return Fail('Only the owner can manage bank access.') end
    if not EmployeeIndex(Biz, Data.Cid) then return Fail('This person is not an employee.') end
    local Account = Biz.business_account and exports['fw-financials']:GetFinancialAccountById(Biz.business_account)
    if not Account then return Fail('This business has no bank account.') end

    local Authorized = json.decode(Account.authorized or '[]') or {}
    local Index = FindIndex(Authorized, function(E) return E.Cid == Data.Cid end)
    local Perms = Index and Authorized[Index].Permissions or {}

    local Valid = false
    for _, Perm in ipairs(BANK_PERMISSIONS) do Valid = Valid or Perm == Data.Permission end
    if not Valid then return Fail('Unknown permission.') end
    Perms[Data.Permission] = Data.Value == true

    -- Without Balance there is no access at all (same rule as the phone app).
    if not Perms.Balance then
        if Index then table.remove(Authorized, Index) end
        Perms = {}
    elseif Index then
        Authorized[Index].Permissions = Perms
    else
        Authorized[#Authorized + 1] = { Cid = Data.Cid, Permissions = Perms }
    end

    DB:executeSync("UPDATE `player_financials` SET `authorized` = ? WHERE `accountid` = ?", { json.encode(Authorized), Biz.business_account })
    return { Success = true, Message = 'Bank access updated.', Bank = { Cid = Data.Cid, Perms = Perms } }
end

-- ── Callbacks ──────────────────────────────────────────────────────────────

local function Load(Source, Business)
    if type(Business) ~= 'string' or not Config.Orders.Businesses[Business] then return nil end
    local Biz = GetBusiness(Business)
    local Access = Biz and GetAccess(Source, Biz)
    if not CanOpen(Access) then return nil end
    return Biz, Access
end

FW.Functions.CreateCallback('fw-bennys:Server:Management:Get', function(Source, Cb, Business)
    local Biz, Access = Load(Source, Business)
    if not Biz then return Cb({ Denied = true }) end
    Cb(BuildView(Biz, Access))
end)

FW.Functions.CreateCallback('fw-bennys:Server:Management:Action', function(Source, Cb, Business, Action, Data)
    local Biz, Access = Load(Source, Business)
    if not Biz then return Cb({ Success = false, Message = "You don't have access to this business.", Denied = true }) end
    if type(Data) ~= 'table' or not Actions[Action] then return Cb(Fail('Unknown action.')) end

    local Result = Actions[Action](Source, Biz, Access, Data)
    if Result.Success then
        Biz = GetBusiness(Business) -- fresh after the change
        Result.View = BuildView(Biz, GetAccess(Source, Biz) or Access)
    end
    Cb(Result)
end)
