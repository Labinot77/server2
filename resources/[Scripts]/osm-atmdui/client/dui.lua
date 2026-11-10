-- One DUI browser, drawn onto the ATM screen texture while a session is open.

local WIDTH, HEIGHT = 1326, 1004 -- matches the layout's aspect ratio
local TXD, TEX = 'atm_dui_txd', 'atm_dui_tex'

local DUI = { object = nil, replaced = nil }

function DUI.Send(action, data)
    if not DUI.object then return end
    SendDuiMessage(DUI.object, json.encode({ action = action, data = data }))
end

local function Create()
    if DUI.object then return true end

    DUI.object = CreateDui(('nui://%s/html/index.html'):format(GetCurrentResourceName()), WIDTH, HEIGHT)
    if not DUI.object then return false end

    local txd = CreateRuntimeTxd(TXD)
    CreateRuntimeTextureFromDuiHandle(txd, TEX, GetDuiHandle(DUI.object))

    local deadline = GetGameTimer() + 3000
    while not IsDuiAvailable(DUI.object) and GetGameTimer() < deadline do Wait(50) end
    Wait(300) -- let React mount before the first message
    return true
end

---Shows the DUI on the screen of `model` and sends the static setup.
function DUI.Show(model)
    if not Create() then return false end

    local tex = Config.Models[model].texture
    DUI.Send('INIT', {
        layout = ATM_Layout,
        bankName = Config.BankName,
        quickAmounts = Config.Withdraw.quickAmounts,
        dailyLimit = Config.Withdraw.dailyLimit,
        model = model,
    })
    AddReplaceTexture(tex.dict, tex.name, TXD, TEX)
    DUI.replaced = tex
    return true
end

function DUI.Hide()
    if not DUI.replaced then return end
    RemoveReplaceTexture(DUI.replaced.dict, DUI.replaced.name)
    DUI.replaced = nil
    DUI.Send('STATE', { screen = 'idle' })
end

ATM_DUI = DUI

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    DUI.Hide()
    if DUI.object then DestroyDui(DUI.object) end
end)
