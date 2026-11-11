# fw-dui

Shared DUI screens on props. A **screen** is one named page (`atm`, `bennys_laptop`, ...) that fw-dui shows on
the nearest prop of its models while the player is in range, and unloads when nobody is near.
Props placed from the fw-admin panel are pulled from fw-admin (`Placed = true`).

Start order: `fw-admin` → `fw-dui` → resources that use it (`fw-financials`, `fw-bennys`).

## Models
`config/sh_config.lua` says how the page gets on each model: `Texture` (+ `Dict`) or `RenderTarget`,
`Resolution`, and an optional `Camera`. A replaced texture changes on every prop of that model, so props that
may show different pages at the same time need their own model + texture name.

## Use it from another resource (client)
```lua
local DUI = exports['fw-dui']

DUI:RegisterScreen('my_screen', {
    Url = ('nui://%s/html/page.html'):format(GetCurrentResourceName()),
    Models = { 'custom_laptop_01' },
    Distance = 15.0,
    Placed = true, -- only props placed from the admin panel
})

AddEventHandler('fw-dui:Client:Shown', function(Name, Entity, PropId)
    if Name == 'my_screen' then DUI:Send('my_screen', 'data', { ... }) end -- page gets { action, data }
end)

DUI:Show('my_screen', Entity)   -- lock on this prop (yields until loaded)
DUI:Focus('my_screen', { Mouse = true })   -- camera + cursor; ESC / Backspace / right click leaves
DUI:StopFocus()
DUI:Release('my_screen')        -- back to the range check, the page stays on screen
```

Other events: `fw-dui:Client:Hidden (Name)`, `fw-dui:Client:Closed (Name)`, and without `Mouse`:
`fw-dui:Client:Cursor (Name, X, Y)` / `fw-dui:Client:Click (Name, X, Y)` (percent, hit-test yourself).
`DUI:SetCloseable(false)` blocks leaving (e.g. while an ATM transaction runs).
Screens are removed automatically when the resource that registered them stops.

## Mirror (others see your screen)
Register with `Mirror = true` and players within `Config.MirrorDistance` see what the user does on it:
cursor, clicks and every `Send`. `DUI:Send(Name, Action, Data, MirrorData)` lets you send watchers
something else (`MirrorData`, e.g. balances replaced by `**`) or nothing (`false`).
When the user stops, watchers get `fw-dui:Client:WatchEnded (Name, Entity)` to restore their own page.
Someone who walks up halfway through only sees changes from that moment on (a page switched with mouse
clicks before they arrived, like a laptop tab, can differ until the next change).
