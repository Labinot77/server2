-- House tablet (House app): overview, upgrades, maintenance fee, access, colours / timecycle.
-- House.MloData: Upgrades = { [id] = true }, Timecycle = name, Fee = { Due = unix, Account = id }, FeeHistory = { ... }
local FW = exports['fw-core']:GetCoreObject()
local Cfg = Config.HouseApp

function HasUpgrade(House, Id)
    return House and House.MloData and House.MloData.Upgrades and House.MloData.Upgrades[Id] == true or false
end

function MaxKeyholders(House)
    return Cfg.Keyholders + (HasUpgrade(House, 'keyholder') and 5 or 0)
end

local function Notify(Source, Text, Type) TriggerClientEvent('FW:Notify', Source, Text, Type) end
local function Money(N) return '$' .. exports['fw-businesses']:NumberWithCommas(math.floor(N)) end

-- The MLO house + player, if the player has keys (OwnerOnly: is the owner).
local function GetHouse(Source, HouseId, OwnerOnly)
    local Player, House = FW.Functions.GetPlayer(Source), Config.Houses[HouseId]
    if not Player or not House or not House.Mlo or not House.Owned then return end
    local Cid = Player.PlayerData.citizenid
    if not HasKeyToHouse(HouseId, Cid) or (OwnerOnly and House.Owner ~= Cid) then return end
    House.MloData = House.MloData or {}
    return House, Player, Cid
end

local function UpgradeById(Id)
    for _, U in ipairs(Cfg.Upgrades) do if U.Id == Id then return U end end
end

-- // Maintenance fee \\ --

local function FeeAmount(House) return math.floor((House.Price or 0) * Cfg.Fee.Percent / 100) end

local function Fee(House)
    House.MloData.Fee = House.MloData.Fee or {}
    local F = House.MloData.Fee
    F.Due = F.Due or os.time() + Cfg.Fee.Days * 86400
    return F
end

local function AddHistory(House, Amount, Status)
    House.MloData.FeeHistory = House.MloData.FeeHistory or {}
    table.insert(House.MloData.FeeHistory, 1, { Name = FW.Functions.GetPlayerCharName(House.Owner), Cid = House.Owner, Amount = Amount, Date = os.time(), Status = Status })
    for I = #House.MloData.FeeHistory, 26, -1 do House.MloData.FeeHistory[I] = nil end
end

-- Auto-withdrawal on the due date from the chosen account (default: the owner's personal account).
local function ChargeFees()
    for HouseId, House in pairs(Config.Houses) do
        if House.Mlo and House.Owned and House.MloData then
            local F = Fee(House)
            if F.Due <= os.time() then
                local Amount, Account = FeeAmount(House), F.Account
                if not Account then
                    local Row = exports['ghmattimysql']:executeSync("SELECT `charinfo` FROM `players` WHERE `citizenid` = ?", { House.Owner })[1]
                    Account = Row and json.decode(Row.charinfo or '{}').account
                end
                local Paid = Amount <= 0 or (Account and exports['fw-financials']:RemoveMoneyFromAccount('1001', '1', Account, Amount, 'TRANSFER', 'Maintenance fee: ' .. House.Adress))
                AddHistory(House, Amount, Paid and 'Paid' or 'Failed')
                F.Due = F.Due + Cfg.Fee.Days * 86400
                if F.Due <= os.time() then F.Due = os.time() + Cfg.Fee.Days * 86400 end
                SaveHouse(HouseId)
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        ChargeFees()
    end
end)

-- // Security upgrade \\ --

-- Tells the owner (if online) that the house was broken into. Also callable from other resources (lockpicks).
function NotifyBreakIn(HouseId)
    local House = Config.Houses[HouseId]
    if not House or not HasUpgrade(House, 'security') then return end
    local Owner = FW.Functions.GetPlayerByCitizenId(House.Owner)
    if Owner then
        TriggerClientEvent("fw-phone:Client:Notification", Owner.PlayerData.source, "house-breakin-" .. HouseId, "fas fa-shield-alt", { "white", "rgb(150, 30, 40)" }, "House Security", "Someone broke into " .. House.Adress .. "!", false, false)
    end
end
exports('NotifyBreakIn', NotifyBreakIn)

-- // Data for the app \\ --

local function Usage(House)
    local Lights, Plants = 0, 0
    for _, D in ipairs(House.Decorations or {}) do
        local Cat = (GetDecorItem(D.Model) or {}).Category
        if Cat == 'Lights' or Cat == 'Electrical' then Lights = Lights + 1 elseif Cat == 'Plants' then Plants = Plants + 1 end
    end
    local Kwh = Lights * 3 * (HasUpgrade(House, 'electricity') and 0.9 or 1)
    return { Electricity = math.min(math.floor(Kwh + 0.5), 200), Humidity = math.min(30 + Plants * 2, 100), Temperature = 21, Heating = false, Gas = 0 }
end

local function Accounts(Player)
    local List = { { Id = Player.PlayerData.charinfo.account, Label = 'Personal' } }
    local Rows = exports['ghmattimysql']:executeSync("SELECT `accountid`, `name` FROM `player_financials` WHERE `citizenid` = ? AND NOT `type` = 'Standaard' AND `active` = 1", { Player.PlayerData.citizenid })
    for _, A in ipairs(Rows or {}) do List[#List + 1] = { Id = A.accountid, Label = A.name } end
    for _, A in ipairs(List) do A.Balance = exports['fw-financials']:GetAccountBalance(A.Id) end
    return List
end

local function Keyholders(House)
    local List = {}
    for _, Cid in ipairs(House.Keyholders or {}) do
        if Cid ~= House.Owner then
            local A = House.MloData.Access and House.MloData.Access[Cid] or {}
            List[#List + 1] = { Cid = Cid, Name = FW.Functions.GetPlayerCharName(Cid), Doors = A.Doors ~= false, Stash = A.Stash ~= false, Decorate = A.Decorate ~= false }
        end
    end
    return List
end

local function AppData(HouseId, House, Player, Cid)
    local F, Mlo = Fee(House), Config.MLOHouses[House.Mlo] or {}
    local Surfaces = {}
    for _, S in ipairs({ 'Walls', 'Floor', 'Ceiling' }) do
        if Mlo.Surfaces and Mlo.Surfaces[S] and #Mlo.Surfaces[S] > 0 then Surfaces[#Surfaces + 1] = S end
    end
    return {
        HouseId = HouseId, IsOwner = House.Owner == Cid,
        Me = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Street = House.Adress, Label = Mlo.Label or House.Category or 'House',
        Usage = Usage(House), Parking = House.Garage and 1 or 0,
        Upgrades = House.MloData.Upgrades or {}, UpgradeList = Cfg.Upgrades,
        Keyholders = Keyholders(House), MaxKeys = MaxKeyholders(House),
        Fee = { Due = F.Due, Amount = FeeAmount(House), Account = F.Account or Player.PlayerData.charinfo.account, Days = Cfg.Fee.Days },
        History = House.MloData.FeeHistory or {},
        Accounts = House.Owner == Cid and Accounts(Player) or {},
        Surfaces = Surfaces, Colors = House.MloData.Surfaces or {}, Palette = Cfg.Colors,
        Timecycle = House.MloData.Timecycle or '', Timecycles = Cfg.Timecycles,
    }
end

FW.Functions.CreateCallback("fw-housing:Server:Tablet:Get", function(Source, Cb, HouseId)
    local House, Player, Cid = GetHouse(Source, HouseId)
    Cb(House and AppData(HouseId, House, Player, Cid) or false)
end)

-- // Actions (owner only), every reply = { Ok, Msg, Data } \\ --

local Actions = {}

function Actions.upgrade(HouseId, House, Player, D)
    local U = UpgradeById(D.Id)
    if not U then return false, 'Unknown upgrade.' end
    if HasUpgrade(House, U.Id) then return false, 'You already own this upgrade.' end
    if not exports['fw-financials']:RemoveMoneyFromAccount(Player.PlayerData.citizenid, '1', Player.PlayerData.charinfo.account, U.Price, 'PURCHASE', ('House upgrade: %s (%s)'):format(U.Label, House.Adress)) then
        return false, 'Not enough money in your bank account.'
    end
    House.MloData.Upgrades = House.MloData.Upgrades or {}
    House.MloData.Upgrades[U.Id] = true
    return true, U.Label .. ' unlocked for ' .. Money(U.Price) .. '.'
end

function Actions.account(HouseId, House, Player, D)
    for _, A in ipairs(Accounts(Player)) do
        if A.Id == D.Account then Fee(House).Account = A.Id return true, 'Auto-withdrawal account changed.' end
    end
    return false, 'Invalid account.'
end

function Actions.addkey(HouseId, House, Player, D)
    local Cid = tostring(D.Cid or ''):upper():gsub('%s', '')
    local Row = Cid ~= '' and exports['ghmattimysql']:executeSync("SELECT `citizenid` FROM `players` WHERE `citizenid` = ?", { Cid })[1]
    if not Row then return false, 'No citizen with that State ID.' end
    if HasKeyToHouse(HouseId, Cid) then return false, 'They already have access.' end
    if #House.Keyholders - 1 >= MaxKeyholders(House) then return false, 'No room for more keyholders.' end
    table.insert(House.Keyholders, Cid)
    local Target = FW.Functions.GetPlayerByCitizenId(Cid)
    if Target then Notify(Target.PlayerData.source, "You received the keys of " .. House.Adress .. ".", "success") end
    return true, FW.Functions.GetPlayerCharName(Cid) .. ' was added.'
end

function Actions.removekey(HouseId, House, Player, D)
    if D.Cid == House.Owner then return false, "You can't remove the owner." end
    for I, Cid in ipairs(House.Keyholders) do
        if Cid == D.Cid then
            table.remove(House.Keyholders, I)
            if House.MloData.Access then House.MloData.Access[Cid] = nil end
            return true, 'Access removed.'
        end
    end
    return false, 'Not a keyholder.'
end

local Perms = { Doors = true, Stash = true, Decorate = true }
function Actions.perm(HouseId, House, Player, D)
    if not Perms[D.Perm] or not HasKeyToHouse(HouseId, D.Cid) or D.Cid == House.Owner then return false, 'Invalid permission.' end
    House.MloData.Access = House.MloData.Access or {}
    House.MloData.Access[D.Cid] = House.MloData.Access[D.Cid] or {}
    House.MloData.Access[D.Cid][D.Perm] = D.Value == true
    return true
end

local Surfaces = { Walls = true, Floor = true, Ceiling = true }
function Actions.color(HouseId, House, Player, D)
    if not Surfaces[D.Surface] or (D.Hex and not tostring(D.Hex):match('^#%x%x%x%x%x%x$')) then return false, 'Invalid colour.' end
    House.MloData.Surfaces = House.MloData.Surfaces or {}
    House.MloData.Surfaces[D.Surface] = D.Hex or nil
    return true
end

function Actions.timecycle(HouseId, House, Player, D)
    if not HasUpgrade(House, 'timecycle') then return false, 'Requires the Timecycle upgrade.' end
    for _, T in ipairs(Cfg.Timecycles) do
        if T.Id == D.Id then House.MloData.Timecycle = T.Id ~= '' and T.Id or nil return true end
    end
    return false, 'Invalid timecycle.'
end

FW.Functions.CreateCallback("fw-housing:Server:Tablet:Action", function(Source, Cb, HouseId, Action, D)
    local House, Player, Cid = GetHouse(Source, HouseId, true)
    if not House then return Cb({ Ok = false, Msg = 'Only the owner can change this.' }) end
    local Fn = Actions[Action]
    if not Fn then return Cb({ Ok = false, Msg = 'Unknown action.' }) end

    local Ok, Msg = Fn(HouseId, House, Player, type(D) == 'table' and D or {})
    if Ok then
        if Action == 'addkey' or Action == 'removekey' then
            exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `keyholders` = ? WHERE `id` = ?", { json.encode(House.Keyholders), House.DbId })
        end
        CommitHouse(HouseId)
    end
    Cb({ Ok = Ok, Msg = Msg, Data = AppData(HouseId, House, Player, Cid) })
end)
