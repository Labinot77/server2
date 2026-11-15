-- Cash is one row per stack with the amount in info.Amount (a row per dollar would flood the table).
CashItem = 'cash'

-- Use instead of COUNT(*) when reading stack sizes.
AmountSql = "CAST(SUM(CASE WHEN item_name = 'cash' THEN CAST(JSON_UNQUOTE(JSON_EXTRACT(info, '$.Amount')) AS UNSIGNED) ELSE 1 END) AS UNSIGNED)"

-- Adds cash to a slot, merging into its stack or creating one.
function AddCashToSlot(InvName, Slot, Amount)
    local Updated = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET info = JSON_SET(info, '$.Amount', CAST(JSON_UNQUOTE(JSON_EXTRACT(info, '$.Amount')) AS UNSIGNED) + ?) WHERE inventory = ? AND slot = ? AND item_name = 'cash' LIMIT 1", { Amount, InvName, Slot })
    if Updated.affectedRows > 0 then return true end

    return exports['ghmattimysql']:executeSync("INSERT INTO player_inventories (inventory, item_name, custom_type, slot, info, createdate) VALUES (?, 'cash', '', ?, ?, ?)", {
        InvName, Slot, json.encode({ Amount = Amount }), os.time() * 1000
    }).affectedRows > 0
end

-- Takes up to Amount from a slot's stack (deleting it when empty), returns what was taken.
function TakeCashFromSlot(InvName, Slot, Amount)
    local Row = exports['ghmattimysql']:executeSync("SELECT id, info FROM player_inventories WHERE inventory = ? AND slot = ? AND item_name = 'cash' LIMIT 1", { InvName, Slot })[1]
    if not Row then return 0 end

    local Have = math.floor(tonumber((json.decode(Row.info) or {}).Amount) or 0)
    local Take = math.min(Have, Amount)
    if Take >= Have then
        exports['ghmattimysql']:executeSync("DELETE FROM player_inventories WHERE id = ?", { Row.id })
    else
        exports['ghmattimysql']:executeSync("UPDATE player_inventories SET info = ? WHERE id = ?", { json.encode({ Amount = Have - Take }), Row.id })
    end
    return Take
end

-- Moves Amount of an item between slots/inventories. Result.affectedRows is the amount moved.
function MoveItemRows(FromInv, FromSlot, ToInv, ToSlot, Item, Amount)
    if Item == CashItem then
        local Taken = TakeCashFromSlot(FromInv, FromSlot, Amount)
        if Taken > 0 then AddCashToSlot(ToInv, ToSlot, Taken) end
        return { affectedRows = Taken }
    end

    return exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = ?, `inventory` = ? WHERE `inventory` = ? AND `slot` = ? AND `item_name` = ? LIMIT " .. math.floor(Amount), {
        ToSlot, ToInv, FromInv, FromSlot, Item
    })
end
