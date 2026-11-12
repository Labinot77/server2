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

## Same model side by side (Variant)
A replaced texture shows on every prop of that model, so two ATMs next to each other both showed the page.
Give the model a `Variant`: a copy of the prop with its own screen texture name. Only the prop that shows the
page is swapped to the copy, so its neighbours keep the normal screen. **One copy per model is enough**
(200 houses with `house_monitor_01` only need `house_monitor_01_dui`).

Making a copy: duplicate the `.ydr` + `.ytd` as `<model>_dui`, rename the screen texture (e.g. `_dui` suffix)
in the `.ytd` and in the `.ydr`'s shader, stream it, and set `Variant` + `Texture` in `config/sh_config.lua`.

- Map props (ATMs) are swapped with `CreateModelSwap`, fw-admin props are respawned as the copy in the same frame.
- The swap happens when the prop becomes the nearest in range (idle screen), not when it's opened, and the
  page is on the texture before the swap, so nobody sees it change.
- `DUI:Show` returns the entity now showing the page: `local Ok, Entity = DUI:Show(Name, Entity)`.
- `DUI:GetBaseModel(Entity)` / `DUI:GetVariant(Model)` help with interactions and model checks; register your
  interact options for the copy too, the player looks at the copy once it's swapped.
- Each player shows one screen of a type at a time, so one copy per model is all a client ever needs.

## Houses next to each other (SameInterior)
`SameInterior = true` only uses props in the interior the player stands in, and watchers only see a mirrored
screen from inside the same interior. Two houses with the same computer never show each other's screen:
```lua
DUI:RegisterScreen('house_computer', {
    Url = 'nui://my-housing/html/computer.html',
    Models = { 'house_monitor_01' },
    Distance = 8.0,
    Placed = true,
    Mirror = true,
    SameInterior = true,
})
```

## Computers (Desktop)
`Desktop = true` uses the shared desktop (`html/desktop`): menu bar, dock, and apps in windows. Each laptop or
monitor decides its own apps, so every computer looks the same but shows different apps:
```lua
DUI:RegisterScreen('bennys_laptop', { Models = { ... }, Placed = true, Desktop = true, Mirror = true })

AddEventHandler('fw-dui:Client:Shown', function(Name, Entity)
    if Name ~= 'bennys_laptop' then return end
    DUI:SetApps(Name, {
        { id = 'management', label = 'Bennys Management', icon = 'fas fa-car-mechanic', url = 'nui://fw-bennys/html/laptop.html' },
    }, 'management') -- optional: open this app right away
end)

DUI:SendApp('bennys_laptop', 'management', 'orders', List) -- the app gets { action = 'orders', data = List }
DUI:OpenApp(Name, AppId) / DUI:CloseApp(Name, AppId)
```
Apps are normal pages (any resource) running in an iframe; they keep running while their window is closed, so
live data stays up to date. The desktop draws the cursor, so hide your own cursor when `window.parent !== window`.
Preview in a browser: `html/desktop/index.html?mock`.

## Glare / stable screen light
A DUI on a prop is lit like the rest of the prop, so the sun and lamps reflect on it (glare) and it gets darker
at night. Two parts fix it:
1. **Specular** (code): set `Specular` to the screen's specular map name. fw-dui replaces it with flat black
   while the page shows, which removes the reflections.
2. **Emissive screen** (model, in your `_dui` copy): in CodeWalker open the copy's `.ydr`, select the screen
   material and set its shader to `emissive.sps` (or `emissivenight.sps`), with the screen texture as
   DiffuseSampler and no specular map. An emissive screen lights itself, so it looks the same at noon and at
   night. If you do this, the `Specular` line isn't needed.
