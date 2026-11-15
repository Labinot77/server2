-- Phone hand states (ported from codera-phone): none < open < texting < call.
-- Several states can be active at once; the highest priority one drives the animation and prop.
local ActiveStates, AppliedState = {}, 'none'
local Priority = { none = 0, open = 1, texting = 2, call = 3 }

local TEXT_DICT, TEXT_ANIM = 'amb@world_human_stand_mobile@male@text@base', 'base'
local CAR_DICT, FOOT_DICT = 'anim@cellphone@in_car@ps', 'cellphone@'

local Prop, OpenProp, Unfolded, LiveAttach = nil, nil, false, nil
local Current, LoopRunning, Transitioning = {}, false, false

local function LoadDict(Dict)
    if HasAnimDictLoaded(Dict) then return true end
    if not DoesAnimDictExist(Dict) then return false end
    RequestAnimDict(Dict)
    local Timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(Dict) and GetGameTimer() < Timeout do Citizen.Wait(0) end
    return HasAnimDictLoaded(Dict)
end

local function LoadModel(Hash)
    if not IsModelInCdimage(Hash) then return false end
    RequestModel(Hash)
    local Timeout = GetGameTimer() + 3000
    while not HasModelLoaded(Hash) and GetGameTimer() < Timeout do Citizen.Wait(0) end
    return HasModelLoaded(Hash)
end

local function InVehicle() return IsPedInAnyVehicle(PlayerPedId(), false) end

-- Prop -----------------------------------------------------------------
local function GetAttach(State)
    if LiveAttach then return LiveAttach end
    local A = Config.PhoneAttach[State] or Config.PhoneAttach.default or {}
    return { bone = A.bone or Config.PhonePropBone, offset = A.offset or vector3(0.0, 0.0, 0.0), rot = A.rot or vector3(0.0, 0.0, 0.0) }
end

local function Attach(Obj, State)
    if not Obj or not DoesEntityExist(Obj) then return false end
    local Ped, A = PlayerPedId(), GetAttach(State)
    SetEntityCollision(Obj, false, false)
    AttachEntityToEntity(Obj, Ped, GetPedBoneIndex(Ped, A.bone), A.offset.x, A.offset.y, A.offset.z, A.rot.x, A.rot.y, A.rot.z, true, true, false, true, 1, true)
    return IsEntityAttachedToEntity(Obj, Ped)
end

local function ApplyFold()
    if not OpenProp then return end
    if DoesEntityExist(Prop) then SetEntityVisible(Prop, not Unfolded, false) end
    if DoesEntityExist(OpenProp) then SetEntityVisible(OpenProp, Unfolded, false) end
end

local function Spawn(Model)
    local C = GetEntityCoords(PlayerPedId())
    local Obj = CreateObject(Model, C.x, C.y, C.z + 0.2, true, true, false)
    SetModelAsNoLongerNeeded(Model)
    return DoesEntityExist(Obj) and Obj or nil
end

local function CreateProp(State)
    if not (Prop and DoesEntityExist(Prop)) then
        local Closed, Open = joaat(Config.PhoneProp), joaat(Config.PhonePropOpen)
        local Custom = LoadModel(Closed) and LoadModel(Open)
        if not Custom then LoadModel(`prop_npc_phone_02`) end

        Prop = Spawn(Custom and Closed or `prop_npc_phone_02`)
        OpenProp = Custom and Spawn(Open) or nil
        ApplyFold()
    end

    Attach(Prop, State)
    Attach(OpenProp, State)
end

local function RemoveProp()
    for _, Obj in ipairs({ Prop, OpenProp }) do
        if Obj and DoesEntityExist(Obj) then DeleteEntity(Obj) end
    end
    Prop, OpenProp = nil, nil
end

function SetPhoneFolded(Open)
    Unfolded = Open and true or false
    ApplyFold()
end

-- Animations -------------------------------------------------------------
local function IsDead()
    local Meta = FW.Functions.GetPlayerData().metadata or {}
    return IsEntityDead(PlayerPedId()) or Meta.isdead or Meta.inlaststand
end

local function StartLoop()
    if LoopRunning then return end
    LoopRunning = true
    Citizen.CreateThread(function()
        while Current.Dict do
            if IsDead() then
                ResetPhoneAnim()
                if IsPhoneOpen then ClosePhone(true) end
                break
            end
            if not IsEntityPlayingAnim(PlayerPedId(), Current.Dict, Current.Name, 3) then
                TaskPlayAnim(PlayerPedId(), Current.Dict, Current.Name, Current.Speed, -1.0, -1, 50, 0.0, false, false, false)
            end
            Citizen.Wait(1000)
        end
        LoopRunning = false
    end)
end

local function Play(Dict, Name, Speed)
    if not LoadDict(Dict) then return end
    TaskPlayAnim(PlayerPedId(), Dict, Name, Speed, -1.0, -1, 50, 0.0, false, false, false)
    Current = { Dict = Dict, Name = Name, Speed = Speed }
    StartLoop()
end

local function Stop(Dict, Name)
    StopAnimTask(PlayerPedId(), Dict, Name, 1.0)
    Current = {}
end

local function CallAnim() return InVehicle() and CAR_DICT or FOOT_DICT, 'cellphone_call_listen_base' end
local function HoldAnim() return InVehicle() and CAR_DICT or FOOT_DICT, 'cellphone_text_in' end

local function Transition(Prev, Curr)
    if Curr == 'none' then RemoveProp() else CreateProp(Curr) end
    if Current.Dict then Stop(Current.Dict, Current.Name) end
    if Prev ~= 'none' and Curr ~= 'none' then Citizen.Wait(150) end

    if Curr == 'open' then
        local D, N = HoldAnim(); Play(D, N, 7.0)
    elseif Curr == 'texting' then
        Play(TEXT_DICT, TEXT_ANIM, 4.0)
    elseif Curr == 'call' then
        local D, N = CallAnim(); Play(D, N, 3.0)
    end
end

local function Target()
    local Best = 'none'
    for State in pairs(ActiveStates) do
        if Priority[State] > Priority[Best] then Best = State end
    end
    return Best
end

function SetPhoneStates(Changes)
    for State, Active in pairs(Changes) do ActiveStates[State] = Active and true or nil end
    if Transitioning or Target() == AppliedState then return end

    Transitioning = true
    Citizen.CreateThread(function()
        while Target() ~= AppliedState do
            local Prev = AppliedState
            AppliedState = Target()
            Transition(Prev, AppliedState)
        end
        Transitioning = false
    end)
end

function SetPhoneState(State, Active) SetPhoneStates({ [State] = Active }) end

function ResetPhoneAnim()
    if Current.Dict then Stop(Current.Dict, Current.Name) end
    ActiveStates, AppliedState = {}, 'none'
    RemoveProp()
end

-- Kept for the rest of the resource.
function StartPhoneAnim() SetPhoneState('open', true) end
function StopPhoneAnim() SetPhoneStates({ open = false, texting = false }) end
exports('SetPhoneState', SetPhoneState)

RegisterNUICallback("Phone/Fold", function(Data, Cb)
    SetPhoneFolded(Data.Open)
    Cb("Ok")
end)

RegisterNUICallback("Phone/InputFocus", function(Data, Cb)
    if IsPhoneOpen then SetPhoneState('texting', Data.Focused) end
    Cb("Ok")
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then ResetPhoneAnim() end
end)

-- /phoneattach x y z rx ry rz [bone] | /phoneattach reset
RegisterCommand('phoneattach', function(_, Args)
    if Args[1] == 'reset' then
        LiveAttach = nil
    else
        local N = {}
        for i = 1, 7 do N[i] = tonumber(Args[i]) end
        if not (N[1] and N[2] and N[3]) then return print('[fw-phone] usage: /phoneattach x y z rx ry rz [bone]') end
        LiveAttach = { bone = N[7] or Config.PhonePropBone, offset = vector3(N[1], N[2], N[3]), rot = vector3(N[4] or 0.0, N[5] or 0.0, N[6] or 0.0) }
        print(('[fw-phone] Config.PhoneAttach.%s = { bone = %d, offset = vector3(%.3f, %.3f, %.3f), rot = vector3(%.1f, %.1f, %.1f) }')
            :format(AppliedState, LiveAttach.bone, N[1], N[2], N[3], N[4] or 0.0, N[5] or 0.0, N[6] or 0.0))
    end
    Attach(Prop, AppliedState)
    Attach(OpenProp, AppliedState)
end, false)
