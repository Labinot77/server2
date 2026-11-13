-- Typing on a focused screen. Every key is a key mapping (Settings > Key Bindings > FiveM > fw-dui), so it fires
-- while game controls are disabled, and not while another UI (fw-ui input, chat) has NUI focus.
-- The page gets { action = 'dui:key', data = { key } } (html/keys.js types it into the focused input),
-- the resource that owns the screen gets fw-dui:Client:Key (Name, Key). Focus with Keyboard = false to turn it off.
-- Keys: a single character, or Backspace / Enter / Delete / ArrowLeft / ArrowRight. Held keys repeat.

local Keys = { -- [key mapping] = { normal, shift }
    SPACE = { ' ' }, MINUS = { '-', '_' }, EQUALS = { '=', '+' }, LBRACKET = { '[', '{' }, RBRACKET = { ']', '}' },
    SEMICOLON = { ';', ':' }, APOSTROPHE = { "'", '"' }, BACKSLASH = { '\\', '|' }, COMMA = { ',', '<' }, PERIOD = { '.', '>' },
    SLASH = { '/', '?' }, BACK = { 'Backspace' }, RETURN = { 'Enter' }, DELETE = { 'Delete' }, LEFT = { 'ArrowLeft' }, RIGHT = { 'ArrowRight' },
}
for C in ('abcdefghijklmnopqrstuvwxyz'):gmatch('.') do Keys[C:upper()] = { C, C:upper() } end
for i = 0, 9 do
    Keys[tostring(i)] = { tostring(i), (')!@#$%^&*('):sub(i + 1, i + 1) }
    Keys['NUMPAD' .. i] = { tostring(i) }
end

local function TypeKey(Key)
    local S = Focused.S
    -- Players watching (Mirror) get * for characters, unless the screen was registered with MirrorKeys = true.
    Send(S.Name, 'dui:key', { key = Key }, (S.MirrorKeys or #Key > 1) and nil or { key = '*' })
    TriggerEvent('fw-dui:Client:Key', S.Name, Key)
end

local Held = {}
for Map, Chars in pairs(Keys) do
    local Cmd = 'fwdui_key_' .. Map:lower()
    RegisterCommand('+' .. Cmd, function()
        if not Focused or Focused.Options.Keyboard == false or Held[Map] then return end
        Held[Map] = true
        CreateThread(function()
            local Delay = Config.KeyRepeat.Delay
            repeat
                TypeKey(IsDisabledControlPressed(0, 21) and Chars[2] or Chars[1]) -- 21 = shift
                Wait(Delay)
                Delay = Config.KeyRepeat.Rate
            until not Held[Map] or not Focused
            Held[Map] = nil
        end)
    end, false)
    RegisterCommand('-' .. Cmd, function() Held[Map] = nil end, false)
    RegisterKeyMapping('+' .. Cmd, 'Screen typing: ' .. Map, 'keyboard', Map)
end
