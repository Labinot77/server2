-- Features ported from illenium-appearance, rebuilt on fw-core / fw-clothes skin format.
-- Loaded after _sv_main.lua (alphabetical), so FW is already defined.
FW = FW or exports['fw-core']:GetCoreObject()

local DB = exports['ghmattimysql']
local FreeEdit = {} -- [Source] = expiry timer -> next PurchaseClothes is free (character creation / admin).

-- // Helpers \\ --

function IsClothesAdmin(Source)
    return FW.Functions.HasPermission(Source, "admin") or FW.Functions.HasPermission(Source, "god")
end

local TattooZones = { TattoosTorso = true, TattoosHead = true, TattoosLArm = true, TattoosRArm = true, TattoosLLeg = true, TattoosRLeg = true }

function DeepEqual(A, B)
    if type(A) ~= type(B) then return false end
    if type(A) ~= "table" then return A == B end
    for k, v in pairs(A) do if not DeepEqual(v, B[k]) then return false end end
    for k, v in pairs(B) do if A[k] == nil then return false end end
    return true
end

function DeepCopy(T)
    if type(T) ~= "table" then return T end
    local R = {}
    for k, v in pairs(T) do R[k] = DeepCopy(v) end
    return R
end

-- Authoritative price, same rules as the client display (GetClothesPrice).
function CalculateClothesPrice(OldSkin, NewSkin)
    local Old = (OldSkin and OldSkin.Clothes) or {}
    local Price = 0

    for k, v in pairs(NewSkin.Clothes or {}) do
        if type(v) == "table" then
            local Prev = type(Old[k]) == "table" and Old[k] or {}
            if TattooZones[k] then
                Price = Price + CountTattooChanges(Prev, v) * Config.ClothesPrice
            elseif Prev[1] ~= v[1] then
                Price = Price + Config.ClothesPrice
            end
        end
    end

    return FW.Shared.CalculateTax("Clothes", Price)
end

local function GetGenderKey(Player)
    return Player.PlayerData.charinfo.gender == 1 and "Female" or "Male"
end

local function ListContains(List, Value)
    for _, v in pairs(List or {}) do
        if v == Value or GetHashKey(v) == GetHashKey(Value) then return true end
    end
    return false
end

-- Port of illenium's blacklist: model must be allowed and job-whitelisted pieces only for that job.
function ValidateSkin(Source, Skin)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player or type(Skin) ~= "table" or type(Skin.Model) ~= "string" or type(Skin.Clothes) ~= "table" then
        return false, "Ongeldige kleding."
    end

    if IsClothesAdmin(Source) then return true end

    local Gender = GetGenderKey(Player)
    local CurrentModel = Player.PlayerData.skin and Player.PlayerData.skin.Model
    local CustomOwner = Config.CustomPeds[Skin.Model]
    if CurrentModel and GetHashKey(CurrentModel) == GetHashKey(Skin.Model) then
        -- Keeping the ped you already have is always fine.
    elseif CustomOwner then
        if CustomOwner ~= Player.PlayerData.citizenid then
            return false, "Je mag deze ped niet gebruiken."
        end
    elseif not ListContains(Gender == "Female" and Config.FemalePeds or Config.MalePeds, Skin.Model) then
        return false, "Je mag deze ped niet gebruiken."
    end

    for Job, Pieces in pairs(Config.WhitelistedClothes[Gender] or {}) do
        if Player.PlayerData.job.name ~= Job then
            for Component, Drawables in pairs(Pieces) do
                local Worn = Skin.Clothes[Component]
                if type(Worn) == "table" and ListContains(Drawables, Worn[1]) then
                    return false, "Je draagt kleding die bij een andere baan hoort."
                end
            end
        end
    end

    return true
end

-- Only free components (props, hair colour) may differ, model must stay the same.
function IsFreeSkinChange(OldSkin, NewSkin)
    if not OldSkin or not OldSkin.Clothes then return true end
    if OldSkin.Model ~= NewSkin.Model then return false end

    local Keys = {}
    for k in pairs(OldSkin.Clothes) do Keys[k] = true end
    for k in pairs(NewSkin.Clothes) do Keys[k] = true end

    for k in pairs(Keys) do
        local A, B = OldSkin.Clothes[k], NewSkin.Clothes[k]
        if not DeepEqual(A, B) and not Config.FreeComponents[k] then
            if k == "Hair" and type(A) == "table" and type(B) == "table" and A[1] == B[1] and A[2] == B[2] then
                -- Only hair colour changed (hair dye).
            else
                return false, k
            end
        end
    end

    return true
end

function ConsumeFreeEdit(Source)
    local IsFree = FreeEdit[Source] ~= nil and GetGameTimer() < FreeEdit[Source]
    FreeEdit[Source] = nil
    return IsFree
end

local function GrantFreeEdit(Source)
    FreeEdit[tonumber(Source)] = GetGameTimer() + (30 * 60 * 1000) -- Valid for 30 minutes.
end
exports("GrantFreeEdit", GrantFreeEdit)

AddEventHandler("playerDropped", function()
    FreeEdit[source] = nil
end)

-- // Outfit codes \\ --

local CodeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
local function GenerateCode()
    local Code, Exists
    repeat
        local Parts = {}
        for i = 1, Config.OutfitCodeLength do
            local Idx = math.random(1, #CodeChars)
            Parts[i] = CodeChars:sub(Idx, Idx)
        end
        Code = table.concat(Parts)
        Exists = DB:executeSync("SELECT `id` FROM `player_outfit_codes` WHERE `code` = ?", { Code })[1]
    until not Exists
    return Code
end

FW.Functions.CreateCallback("fw-clothes:Server:GenerateOutfitCode", function(Source, Cb, OutfitId)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb(false) end

    local Outfit = DB:executeSync("SELECT `id` FROM `player_outfits` WHERE `id` = ? AND `citizenid` = ?", { OutfitId, Player.PlayerData.citizenid })[1]
    if not Outfit then return Cb(false) end

    local Existing = DB:executeSync("SELECT `code` FROM `player_outfit_codes` WHERE `outfitid` = ?", { OutfitId })[1]
    if Existing then return Cb(Existing.code) end

    local Code = GenerateCode()
    DB:executeSync("INSERT INTO `player_outfit_codes` (`outfitid`, `code`) VALUES (?, ?)", { OutfitId, Code })
    Cb(Code)
end)

FW.Functions.CreateCallback("fw-clothes:Server:ImportOutfitCode", function(Source, Cb, Name, Code)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb({ Success = false }) end
    if type(Name) ~= "string" or #Name == 0 or #Name > 50 or type(Code) ~= "string" then
        return Cb({ Success = false, Msg = "Ongeldige naam of code." })
    end

    local Row = DB:executeSync([[
        SELECT o.* FROM `player_outfit_codes` c
        JOIN `player_outfits` o ON o.id = c.outfitid
        WHERE c.code = ?
    ]], { Code:upper() })[1]

    if not Row then return Cb({ Success = false, Msg = "Deze code bestaat niet." }) end
    if Row.citizenid == Player.PlayerData.citizenid then return Cb({ Success = false, Msg = "Dit is al jouw outfit." }) end

    DB:executeSync("INSERT INTO `player_outfits` (`citizenid`, `name`, `outfit`) VALUES (?, ?, ?)", {
        Player.PlayerData.citizenid, Name, Row.outfit
    })

    Cb({ Success = true })
end)

-- // Wear a saved outfit (server side, so outfits can't be used to sneak in free clothes) \\ --

FW.Functions.CreateCallback("fw-clothes:Server:WearOutfit", function(Source, Cb, OutfitId)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb(false) end

    local Row = DB:executeSync("SELECT `outfit` FROM `player_outfits` WHERE `id` = ? AND `citizenid` = ?", { OutfitId, Player.PlayerData.citizenid })[1]
    if not Row then return Cb(false) end

    local Outfit = json.decode(Row.outfit)
    local NewSkin = { Model = Outfit.Model, Clothes = Outfit.Clothes }

    local Valid, Msg = ValidateSkin(Source, NewSkin)
    if not Valid then
        Player.Functions.Notify(Msg, "error")
        return Cb(false)
    end

    Player.Functions.SetSkin(NewSkin)
    Cb(NewSkin)
end)

-- // Job outfits (illenium "boss managed outfits") \\ --

local function IsJobAllowed(JobName)
    if not Config.JobOutfits.Enabled then return false end
    if not Config.JobOutfits.Jobs then return JobName ~= "unemployed" end
    return ListContains(Config.JobOutfits.Jobs, JobName)
end

function IsJobBoss(Player)
    if IsClothesAdmin(Player.PlayerData.source) then return true end
    if Player.PlayerData.metadata.ishighcommand then return true end

    local Job = FW.Shared.Jobs[Player.PlayerData.job.name]
    if not Job then return false end

    local Highest = 0
    for Grade in pairs(Job.grades) do
        Highest = math.max(Highest, tonumber(Grade) or 0)
    end
    return (tonumber(Player.PlayerData.job.grade.level) or 0) >= Highest
end

local function GetJobOutfits(Player)
    local Job = Player.PlayerData.job
    if not IsJobAllowed(Job.name) then return {} end
    if Config.JobOutfits.OnDutyOnly and not Job.onduty then return {} end

    local Grade = tonumber(Job.grade.level) or 0
    local Rows = DB:executeSync("SELECT * FROM `job_outfits` WHERE `job` = ? AND `gender` = ? AND `minrank` <= ? ORDER BY `minrank`, `name`", {
        Job.name, Player.PlayerData.charinfo.gender, Grade
    })

    local Retval = {}
    for _, v in pairs(Rows) do
        Retval[#Retval + 1] = { Id = v.id, Title = v.name, MinRank = v.minrank, Outfit = json.decode(v.outfit) }
    end
    return Retval
end

FW.Functions.CreateCallback("fw-clothes:Server:GetJobOutfits", function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb({ Outfits = {}, IsBoss = false }) end

    local Allowed = IsJobAllowed(Player.PlayerData.job.name)
    Cb({
        Outfits = GetJobOutfits(Player),
        IsBoss = Allowed and IsJobBoss(Player),
        Allowed = Allowed,
    })
end)

FW.Functions.CreateCallback("fw-clothes:Server:SaveJobOutfit", function(Source, Cb, Name, MinRank)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb(false) end
    if not IsJobAllowed(Player.PlayerData.job.name) or not IsJobBoss(Player) then return Cb(false) end
    if type(Name) ~= "string" or #Name == 0 or #Name > 50 then return Cb(false) end

    -- Uses the skin the server already has, so a boss can only publish clothes he actually bought.
    local Skin = Player.PlayerData.skin
    local Clothes = {}
    for _, Component in pairs(Config.OutfitComponents) do
        Clothes[Component] = DeepCopy(Skin.Clothes[Component])
    end

    DB:executeSync("INSERT INTO `job_outfits` (`job`, `name`, `gender`, `minrank`, `outfit`) VALUES (?, ?, ?, ?, ?)", {
        Player.PlayerData.job.name, Name, Player.PlayerData.charinfo.gender, tonumber(MinRank) or 0,
        json.encode({ Model = Skin.Model, Clothes = Clothes })
    })

    Player.Functions.Notify("Werk outfit opgeslagen.", "success")
    Cb(true)
end)

RegisterNetEvent("fw-clothes:Server:DeleteJobOutfit")
AddEventHandler("fw-clothes:Server:DeleteJobOutfit", function(Data)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil or not IsJobBoss(Player) then return end

    DB:executeSync("DELETE FROM `job_outfits` WHERE `id` = ? AND `job` = ?", { Data.OutfitId, Player.PlayerData.job.name })
    Player.Functions.Notify("Werk outfit verwijderd.")
    TriggerClientEvent("fw-clothes:Client:CloseOutfits", Source, {}, false)
end)

FW.Functions.CreateCallback("fw-clothes:Server:WearJobOutfit", function(Source, Cb, OutfitId)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return Cb(false) end

    local Outfit
    for _, v in pairs(GetJobOutfits(Player)) do
        if v.Id == OutfitId then Outfit = v.Outfit break end
    end
    if not Outfit then return Cb(false) end

    local Skin = DeepCopy(Player.PlayerData.skin)
    if GetHashKey(Skin.Model) ~= GetHashKey(Outfit.Model) then
        Player.Functions.Notify("Dit outfit past niet bij je ped.", "error")
        return Cb(false)
    end

    for _, Component in pairs(Config.OutfitComponents) do
        if Outfit.Clothes[Component] ~= nil then
            Skin.Clothes[Component] = DeepCopy(Outfit.Clothes[Component])
        end
    end

    Player.Functions.SetSkin(Skin)
    Cb(Skin)
end)
