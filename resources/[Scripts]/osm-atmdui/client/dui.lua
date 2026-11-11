-- The ATM page, drawn by fw-dui on the one ATM in use (other ATMs nearby stay untouched).
-- The DUI is created once and kept, so the React page doesn't reload every session.

local WIDTH, HEIGHT = 1326, 1004 -- matches the layout's aspect ratio
local URL = ('nui://%s/html/index.html'):format(GetCurrentResourceName())

local DUI = { Id = nil }

function DUI.Send(action, data)
    if DUI.Id then exports['fw-dui']:Send(DUI.Id, action, data) end
end

---Shows the page on `entity` and sends the static setup.
function DUI.Show(entity, model)
    DUI.Id = DUI.Id or exports['fw-dui']:Create(URL, WIDTH, HEIGHT)
    if not DUI.Id or not exports['fw-dui']:Attach(DUI.Id, entity) then return false end

    DUI.Send('INIT', {
        layout = ATM_Layout,
        bankName = Config.BankName,
        quickAmounts = Config.Withdraw.quickAmounts,
        dailyLimit = Config.Withdraw.dailyLimit,
        model = model,
    })
    return true
end

function DUI.Hide()
    if not DUI.Id then return end
    DUI.Send('STATE', { screen = 'idle' })
    exports['fw-dui']:Detach(DUI.Id)
end

ATM_DUI = DUI
