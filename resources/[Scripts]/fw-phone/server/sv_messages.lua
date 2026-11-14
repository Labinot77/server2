local DB = exports['ghmattimysql']

-- Group chats use "g<id>" as their phone key; shared locations are stored as "x,y".
local function GroupId(Key) return tonumber(tostring(Key or ''):match('^g(%d+)$')) end

local function IsMember(GroupId, Phone)
    return DB:executeSync('SELECT 1 FROM `phone_group_members` WHERE `group_id` = ? AND `number` = ?', { GroupId, Phone })[1] ~= nil
end

local function GetMembers(GroupId)
    return DB:executeSync('SELECT `number`, `name` FROM `phone_group_members` WHERE `group_id` = ?', { GroupId })
end

local function ParseLoc(Loc)
    local X, Y = tostring(Loc or ''):match('^(%-?%d+%.?%d*),(%-?%d+%.?%d*)$')
    return X and ('%.2f,%.2f'):format(tonumber(X), tonumber(Y)) or nil
end

Citizen.CreateThread(function()
    DB:executeSync([[CREATE TABLE IF NOT EXISTS `phone_groups` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `name` VARCHAR(40) NOT NULL, `owner` VARCHAR(20) NOT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    DB:executeSync([[CREATE TABLE IF NOT EXISTS `phone_group_members` (
        `group_id` INT NOT NULL, `number` VARCHAR(20) NOT NULL, `name` VARCHAR(80) NOT NULL DEFAULT '',
        PRIMARY KEY (`group_id`, `number`), INDEX (`number`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local HasLoc = DB:executeSync([[SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'phone_messages' AND COLUMN_NAME = 'loc']])[1]
    if not HasLoc then DB:executeSync('ALTER TABLE `phone_messages` ADD COLUMN `loc` VARCHAR(40) NULL') end
end)

FW.Functions.CreateCallback("fw-phone:Server:HasUnreadConversations", function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then Cb(false) return end

    local Result = DB:executeSync('SELECT COUNT(*) as amount FROM `phone_messages` WHERE `to_phone` = @Phone AND `unread` = 1', { ['@Phone'] = Player.PlayerData.charinfo.phone })
    Cb(Result[1].amount > 0)
end)

FW.Functions.CreateCallback("fw-phone:Server:Messages:GetChats", function(Source, Cb, UsingBurner)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then Cb({}) return end

    local MyPhone = UsingBurner and UsingBurner or Player.PlayerData.charinfo.phone

    local Contacts = {}
    for _, C in ipairs(DB:executeSync('SELECT `phone`, `name` FROM `phone_contacts` WHERE `citizenid` = ?', { Player.PlayerData.citizenid })) do
        Contacts[C.phone] = C.name
    end

    local Chats = {}
    for _, G in ipairs(DB:executeSync('SELECT g.`id`, g.`name` FROM `phone_groups` g JOIN `phone_group_members` m ON m.`group_id` = g.`id` WHERE m.`number` = ?', { MyPhone })) do
        local Members = GetMembers(G.id)
        for _, M in ipairs(Members) do M.name = Contacts[M.number] or (M.name ~= '' and M.name) or FormatPhone(M.number) end
        Chats['g' .. G.id] = { from_phone = MyPhone, to_phone = 'g' .. G.id, name = G.name, group = { Id = G.id, Members = Members }, messages = {} }
    end

    local Result = DB:executeSync([[SELECT * FROM `phone_messages` WHERE `from_phone` = @Phone OR `to_phone` = @Phone
        OR `to_phone` IN (SELECT CONCAT('g', `group_id`) FROM `phone_group_members` WHERE `number` = @Phone) ORDER BY `timestamp` DESC]], { ['@Phone'] = MyPhone })

    for _, v in ipairs(Result) do
        local Receiver = GroupId(v.to_phone) and v.to_phone or (MyPhone == v.to_phone and v.from_phone or v.to_phone)
        if Chats[Receiver] == nil then
            Chats[Receiver] = { from_phone = MyPhone, to_phone = Receiver, name = Contacts[Receiver] or FormatPhone(Receiver), messages = {} }
        end

        local Chat = Chats[Receiver]
        Chat.messages[#Chat.messages + 1] = {
            Sender = v.from_phone,
            SenderName = Chat.group and (Contacts[v.from_phone] or FormatPhone(v.from_phone)) or nil,
            Message = v.message,
            Attachments = json.decode(v.attachments) or {},
            Loc = v.loc,
            Timestamp = v.timestamp,
            Unread = v.unread,
        }
    end

    Cb(Chats)
end)

FW.Functions.CreateCallback("fw-phone:Server:Messages:SendMessage", function(Source, Cb, Data, UsingBurner)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then Cb({Success = false, Msg = "Invalid Player"}) return end

    if not IsNetworkEnabled then
        return Cb({Success = false, Msg = "No internet access.."})
    end

    local MyPhone = UsingBurner and UsingBurner or Player.PlayerData.charinfo.phone
    local To, Message, Loc = tostring(Data.Phone or ''), tostring(Data.Message or ''):sub(1, 500), ParseLoc(Data.Loc)
    local Attachments = type(Data.Attachments) == 'table' and Data.Attachments or {}
    local Gid = GroupId(To)

    if To == '' or (Message == '' and #Attachments == 0 and not Loc) then return Cb({Success = false}) end
    if Gid and not IsMember(Gid, MyPhone) then return Cb({Success = false, Msg = "You're not in this group."}) end

    DB:executeSync("INSERT INTO `phone_messages` (`from_phone`, `to_phone`, `message`, `attachments`, `loc`, `unread`) VALUES (@FromPhone, @ToPhone, @Message, @Attachments, @Loc, @Unread)", {
        ['@FromPhone'] = MyPhone,
        ['@ToPhone'] = To,
        ['@Message'] = Message,
        ['@Attachments'] = json.encode(Attachments),
        ['@Loc'] = Loc,
        ['@Unread'] = Gid and 0 or 1,
    })

    TriggerEvent("fw-logs:Server:Log", 'conversations', "Text Sent", ("User: [%s] - %s - %s\nReceiver: %s - %s\nMessage: %s\nAttachments: %s\nLocation: %s"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, To, Gid and "Group" or FW.Functions.GetPlayerCharNameByPhone(To) or "Invalid Player.", Message, json.encode(Attachments), Loc or "-"), "green")

    TriggerClientEvent('fw-phone:Client:Messages:RefreshMessagesChat', Source, {}, false)

    local Preview = Loc and "Shared a location" or (Message ~= '' and Message or "Sent a photo")
    local Targets = {}
    if Gid then
        local Group = DB:executeSync('SELECT `name` FROM `phone_groups` WHERE `id` = ?', { Gid })[1]
        for _, M in ipairs(GetMembers(Gid)) do
            if M.number ~= MyPhone then Targets[#Targets + 1] = { M.number, Group and Group.name or "Group" } end
        end
    else
        Targets[1] = { To }
    end

    for _, T in ipairs(Targets) do
        local ToPlayer = FW.Functions.GetPlayerByPhone(tostring(T[1]))
        if ToPlayer then
            local From = GetContactName(ToPlayer.PlayerData.citizenid, MyPhone)
            TriggerClientEvent('fw-phone:Client:Messages:RefreshMessagesChat', ToPlayer.PlayerData.source, {
                Name = T[2] or From,
                Phone = Gid and To or MyPhone,
                Message = T[2] and (From .. ": " .. Preview) or Preview,
            }, true)
        end
    end

    Cb({Success = true})
end)

FW.Functions.CreateCallback("fw-phone:Server:Messages:CreateGroup", function(Source, Cb, Data, UsingBurner)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb({Success = false}) end

    local MyPhone = UsingBurner and UsingBurner or Player.PlayerData.charinfo.phone
    local Name = tostring(Data.Name or ''):sub(1, 40)
    if Name == '' or type(Data.Numbers) ~= 'table' or #Data.Numbers == 0 then return Cb({Success = false, Msg = "Enter a name and pick a member."}) end

    local Gid = (DB:executeSync('INSERT INTO `phone_groups` (`name`, `owner`) VALUES (?, ?)', { Name, MyPhone }) or {}).insertId
    if not Gid then return Cb({Success = false, Msg = "Could not create the group."}) end

    local Numbers, Seen = { MyPhone }, { [MyPhone] = true }
    for _, N in ipairs(Data.Numbers) do
        N = tostring(N):gsub('%D', '')
        if N ~= '' and not Seen[N] and #Numbers < 32 then Seen[N] = true; Numbers[#Numbers + 1] = N end
    end

    for _, N in ipairs(Numbers) do
        DB:executeSync('INSERT INTO `phone_group_members` (`group_id`, `number`, `name`) VALUES (?, ?, ?)', { Gid, N, FW.Functions.GetPlayerCharNameByPhone(N) or '' })
        local T = FW.Functions.GetPlayerByPhone(N)
        if T and N ~= MyPhone then TriggerClientEvent('fw-phone:Client:Messages:RefreshMessagesChat', T.PlayerData.source, {}, false) end
    end

    Cb({Success = true, Key = 'g' .. Gid})
end)

FW.Functions.CreateCallback("fw-phone:Server:Messages:LeaveGroup", function(Source, Cb, Data, UsingBurner)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb({Success = false}) end

    local MyPhone = UsingBurner and UsingBurner or Player.PlayerData.charinfo.phone
    local Gid = GroupId(Data.Phone)
    if not Gid then return Cb({Success = false}) end

    DB:executeSync('DELETE FROM `phone_group_members` WHERE `group_id` = ? AND `number` = ?', { Gid, MyPhone })
    if not DB:executeSync('SELECT 1 FROM `phone_group_members` WHERE `group_id` = ? LIMIT 1', { Gid })[1] then
        DB:executeSync('DELETE FROM `phone_groups` WHERE `id` = ?', { Gid })
        DB:executeSync('DELETE FROM `phone_messages` WHERE `to_phone` = ?', { 'g' .. Gid })
    end

    Cb({Success = true})
end)

RegisterNetEvent("fw-phone:Server:Messages:SetChatRead")
AddEventHandler("fw-phone:Server:Messages:SetChatRead", function(Data, UsingBurner)
    if GroupId(Data.ToPhone) then return end
    DB:execute("UPDATE `phone_messages` SET `unread` = 0 WHERE `from_phone` = @FromPhone AND `to_phone` = @ToPhone AND `unread` = 1", {
        ["@FromPhone"] = Data.ToPhone,
        ["@ToPhone"] = Data.FromPhone,
    })
end)
