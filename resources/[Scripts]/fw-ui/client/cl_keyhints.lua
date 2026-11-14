-- Bottom-right key hints (web/public/keyhints.js). Safe to call every frame: only sends when the hints change.
-- Hints = { { 'E', 'Place' }, { { 'PGUP', 'PGDN' }, 'Height' }, { '', 'Info only' } }
local Last

exports('ShowKeyHints', function(Hints)
    local Encoded = json.encode(Hints)
    if Encoded == Last then return end
    Last = Encoded
    SendNUIMessage({ App = 'KeyHints', Action = 'Show', Payload = Hints })
end)

exports('HideKeyHints', function()
    if not Last then return end
    Last = nil
    SendNUIMessage({ App = 'KeyHints', Action = 'Hide' })
end)
