-- Screen layout, shared by Lua (cursor hit-testing) and the React DUI (rendering).
-- Every rect is { x, y, w, h } in percent of the screen (0-100 on both axes).
-- The DUI receives this table on INIT and places each button at exactly these rects,
-- so what you see is always what you click. Move a button here and both follow.

local L = {}

-- Account select
L.accounts = {
    { id = 'acc_prev',    rect = { 25.5, 39.0, 6.8, 11.0 } },
    { id = 'acc_next',    rect = { 67.7, 39.0, 6.8, 11.0 } },
    { id = 'acc_confirm', rect = { 25.5, 54.0, 49.0, 9.5 } },
}

-- Main menu (no transfer)
L.menu = {
    { id = 'menu_history',  rect = { 28.0, 28.0, 44.0, 9.2 } },
    { id = 'menu_withdraw', rect = { 28.0, 39.5, 44.0, 9.2 } },
    { id = 'menu_finish',   rect = { 28.0, 51.0, 44.0, 9.2 } },
    { id = 'back',          rect = { 82.0, 89.5, 14.5, 6.5 } },
}

local tabs = {
    { id = 'tab_history',  rect = { 35.4, 4.6, 14.6, 5.6 } },
    { id = 'tab_withdraw', rect = { 50.6, 4.6, 14.6, 5.6 } },
}

-- Withdraw
L.withdraw = {
    tabs[1], tabs[2],
    { id = 'quick_1', rect = { 14.7, 37.7, 16.6, 6.6 } },
    { id = 'quick_2', rect = { 32.6, 37.7, 16.6, 6.6 } },
    { id = 'quick_3', rect = { 50.5, 37.7, 16.6, 6.6 } },
    { id = 'quick_4', rect = { 68.4, 37.7, 16.6, 6.6 } },

    { id = 'key_1', rect = { 14.7, 46.5, 12.1, 8.6 } },
    { id = 'key_2', rect = { 27.8, 46.5, 12.1, 8.6 } },
    { id = 'key_3', rect = { 40.9, 46.5, 12.1, 8.6 } },
    { id = 'key_4', rect = { 14.7, 56.1, 12.1, 8.6 } },
    { id = 'key_5', rect = { 27.8, 56.1, 12.1, 8.6 } },
    { id = 'key_6', rect = { 40.9, 56.1, 12.1, 8.6 } },
    { id = 'key_7', rect = { 14.7, 65.7, 12.1, 8.6 } },
    { id = 'key_8', rect = { 27.8, 65.7, 12.1, 8.6 } },
    { id = 'key_9', rect = { 40.9, 65.7, 12.1, 8.6 } },
    { id = 'key_clear', rect = { 14.7, 75.3, 12.1, 8.6 } },
    { id = 'key_0',     rect = { 27.8, 75.3, 12.1, 8.6 } },
    { id = 'key_del',   rect = { 40.9, 75.3, 12.1, 8.6 } },

    { id = 'submit', rect = { 54.8, 46.5, 30.2, 18.2 } },
    { id = 'back',   rect = { 82.0, 89.5, 14.5, 6.5 } },
}

-- History
L.history = {
    tabs[1], tabs[2],
    { id = 'back', rect = { 82.0, 89.5, 14.5, 6.5 } },
}

-- Withdraw result
L.result = {
    { id = 'result_done', rect = { 35.0, 66.0, 30.0, 9.5 } },
}

ATM_Layout = L
