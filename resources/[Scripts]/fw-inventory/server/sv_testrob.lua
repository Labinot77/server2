-- // Test robbery \\ --
-- /inventory:testrob [backpack 1/0]  (admin)
-- Fills a fake player inventory with dummy items + cash and opens it exactly like a real
-- search/rob does (fw-police -> OpenInventory('Other Player', 'ply-<cid>')).
-- Items you take out are REAL items in your own inventory. The cash is fake: stealing it
-- only shows what would have happened.

Config.TestRob = {
    CitizenId = 'TESTROB',
    Label = 'Test Robbery (John Doe)',
    Cash = 1250,
}

local TestInv = 'ply-' .. Config.TestRob.CitizenId
local TestCash = 0

local DummyItems = {
    -- Pockets
    { Slot = 1,  Item = 'weapon_glock', Amount = 1, Info = { Serial = 'TEST-1234-001', Ammo = 12 } },
    { Slot = 2,  Item = 'bandage', Amount = 4 },
    { Slot = 3,  Item = 'lockpick', Amount = 2 },
    { Slot = 4,  Item = 'money-roll', Amount = 15 },
    { Slot = 5,  Item = 'radio', Amount = 1 },
    { Slot = 7,  Item = 'joint', Amount = 3 },
    { Slot = 9,  Item = 'sandwich', Amount = 2 },
    -- Backpack (only when the dummy wears one)
    { Slot = 16, Item = 'plastic', Amount = 20, Backpack = true },
    { Slot = 17, Item = 'electronics', Amount = 5, Backpack = true },
    { Slot = 18, Item = 'repairkit', Amount = 1, Backpack = true },
    { Slot = 21, Item = 'metalscrap', Amount = 12, Backpack = true },
    -- Body
    { Slot = 36, Item = 'id_card', Amount = 1, Info = { citizenid = Config.TestRob.CitizenId, firstname = 'John', lastname = 'Doe', birthdate = '1990-01-01', gender = 'Man', nationality = 'Nederlands' } },
    { Slot = 37, Item = 'phone', Amount = 1 },
    { Slot = 38, Item = 'keyring', Amount = 1 },
    { Slot = 39, Item = 'pdwatch', Amount = 1 },
    { Slot = 40, Item = 'backpack', Amount = 1, Backpack = true },
    -- Clothing
    { Slot = 42, Item = 'hat', Amount = 1, Info = { Prop = 12, Texture = 0 } },
    { Slot = 43, Item = 'mask', Amount = 1, Info = { Prop = 52, Texture = 0 } },
    { Slot = 46, Item = 'watch', Amount = 1 },
}

function IsTestRobInventory(InvName)
    return InvName == TestInv
end

function GetTestRobCash()
    return TestCash
end

local function FillTestInventory(WithBackpack)
    ClearInventory(TestInv)

    local Missing = {}
    for _, Data in ipairs(DummyItems) do
        if not Data.Backpack or WithBackpack then
            if Shared.Items[Data.Item] then
                AddItemToInventory(TestInv, Data.Item, Data.Amount, Data.Slot, Data.Info or {}, "")
            else
                Missing[#Missing + 1] = Data.Item
            end
        end
    end

    if #Missing > 0 then
        print(("^3[fw-inventory] testrob: unknown items skipped: %s^7"):format(table.concat(Missing, ', ')))
    end

    TestCash = Config.TestRob.Cash
end

FW.Commands.Add("inventory:testrob", "Bekijk hoe het beroven van een speler eruit ziet (dummy items).", {
    { name = "backpack", help = "1 = met rugzak (standaard), 0 = zonder" },
}, false, function(Source, Args)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    if OpenInventories[TestInv] and OpenInventories[TestInv] ~= Source then
        return Player.Functions.Notify("Iemand anders test dit al.", "error")
    end
    OpenInventories[TestInv] = false

    FillTestInventory(Args[1] ~= '0')
    TriggerClientEvent("fw-inventory:Client:OpenOtherPlayer", Source, TestInv)
end, 'admin')

-- Clean up leftovers from a previous run.
Citizen.CreateThread(function()
    ClearInventory(TestInv)
end)

function TestRobTakeCash()
    TestCash = 0
end
