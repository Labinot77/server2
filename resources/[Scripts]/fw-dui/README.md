# fw-dui

Shared DUI screens on props. A **screen** is one named page (`atm`, `bennys_laptop`, ...).

- **Models with `Variants` (location pools)**: a prop someone uses gets a free screen copy for its location from the
  server, and every player around it sees that copy + the user's page. Idle props show one shared idle page on the
  original model's screen (`Idle`). See "Location pools" below. ATMs, laptops and the bank terminal work like this.
- **Models without `Variants` (old way)**: the page is on the nearest prop of the screen's models while the player is
  in range (props that exist once, like the bank keypads / panels).

Props placed from the fw-admin panel are pulled from fw-admin (`Placed = true`).
Start order: `fw-admin` → `fw-dui` → resources that use it (`fw-financials`, `fw-bennys`, `fw-heists`).

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

## Typing
While a screen is focused the keyboard types on it (`client/cl_keys.lua`: every key is a key mapping, so it works with
game controls disabled; held keys repeat, shift gives capitals/symbols). Backspace types now, ESC / right click leave.
- Pages: include `<script src="nui://fw-dui/html/keys.js"></script>`, click an `<input>` / `<textarea>` and type
  (React inputs too). Every key is also a `dui:key` window event (`detail` = key). The desktop forwards keys to the app in front.
- Lua (hit-tested pages like the ATM): `AddEventHandler('fw-dui:Client:Key', function(Name, Key) end)`.
- Keys: one character, or `Backspace` / `Enter` / `Delete` / `ArrowLeft` / `ArrowRight`. `Focus(Name, { Keyboard = false })` turns it off.
- Watchers (Mirror) get `*` for characters unless the screen has `MirrorKeys = true`.
- While focused `LocalPlayer.state.duiFocus` is true: fw-core `FW.AddKeybind` (phone, inventory, ...) and the fw-inventory
  hotbar ignore keys. Other resources with their own key mappings: check that flag too.
- Holding a key repeats at `Config.KeyRepeat` (Delay / Rate in ms).

## Camera per prop (/duicam)
Stand at a screen prop and run `/duicam` (or `/duicam <model>`). W/S A/D Q/E move the camera, arrows move the point it
looks at, scroll = FOV, SHIFT = fine, ENTER = save, BACKSPACE = cancel. The `Camera = { ... }` line is printed in F8:
paste it into that model in `config/sh_config.lua`. It's also applied right away (until fw-dui restarts).

## One prop out of several (Anchor)
`Anchor = vector3(...)` uses only the prop closest to that point, e.g. one of the four monitors on a bank desk.
`/duiprop <model>` prints the coords of the nearest prop of a model.

## Static map props (ymap / MLO)
A prop placed in a ymap or MLO without physics is a *building*, not an object: `GetClosestObjectOfType`, interact and
`/duiprop` can't find it, so the screen never loads and the prop keeps its normal display. Give its positions:
`RegisterScreen(Name, { ..., Static = { vector4(x, y, z, heading) } })`. fw-dui keeps an invisible copy of the model at
each point while you're within 60m (range, camera, interact use it); the texture swap is per model so the real prop shows
the page. Get the position + heading from the ymap (CodeWalker), or look at the prop and run `/duiprop <model>`.
Is the map prop another model (e.g. the interior's own `v_corp_bk_secpanel`, and the `_dui` copy is yours)? Add
`SwapFrom = 'v_corp_bk_secpanel'`: it's swapped to the screen's model at each Static point (exact same spot).

## Mirror (others see your screen)
Register with `Mirror = true` and players within `Config.MirrorDistance` see what the user does on it:
cursor, clicks and every `Send`. `DUI:Send(Name, Action, Data, MirrorData)` lets you send watchers
something else (`MirrorData`, e.g. balances replaced by `**`) or nothing (`false`).
Old way: when the user stops, watchers get `fw-dui:Client:WatchEnded (Name, Entity)` to restore their own page,
and someone who walks up halfway through only sees changes from that moment on.
Location pools: watchers get all page messages sent so far; only things switched with mouse clicks before they
arrived (like a laptop tab) can differ until the next change.

## Location pools (Variants)
`AddReplaceTexture` is global per client: every prop of a model shows the same page. So each model gets **two
copies** with their own screen texture (`prop_fleeca_atm_dui_01`, `prop_fleeca_atm_dui_02`; the same texture name in
both is fine as long as each copy has its own `.ytd` / `textureDictionary` in the `.ytyp`):

```lua
['prop_fleeca_atm'] = { Variants = { 'prop_fleeca_atm_dui_01', 'prop_fleeca_atm_dui_02' }, Texture = 'prop_fleeca_atm_screen_dui', ... },
```

1. `DUI:Show(Name, Entity)` asks the server (`server/sv_pool.lua`) for a copy for that prop. A copy is free when no
   other prop of that model within `Config.PoolRadius` (80m) uses it, so the same two copies work at every location:
   two players at Location A and two at Location B all have their own screen.
2. Every client around the prop (within `Config.PoolRenderDistance`, 35m) swaps it to that copy (map props:
   `CreateModelSwap`, fw-admin props: respawned locally) and puts a page on the copy's texture.
3. The user drives their page. Everyone else gets the user's page messages, cursor and clicks (mirror); the server
   keeps the page messages, so a player who walks up later first gets everything sent so far.
4. `DUI:Release(Name)`: the copy goes back to the original prop for everyone and is free again. Also on disconnect,
   or when the user is over `Config.PoolLeaveDistance` (15m) from the prop for 10 seconds.

- `DUI:Show` returns `true, Entity` (the copy now standing there) or `false, Reason`: `'busy'` (someone uses this
  prop), `'full'` (both copies in use at this location: wait or try another one).
- `DUI:IsInUse(Entity)` = a player uses this prop now (hide your prompt). `DUI:GetVariants(Model)` lists the copies
  (register your interact options for them too, the player looks at the copy while it's in use).
- `fw-dui:Client:Shown` only fires for the user. `SetApps` and `Send` are mirrored while in use (`MirrorData` as
  before), so watchers get the same desktop and data without doing anything.
- `/duidebug` lists the pool (key, variant, owner, distance, shown here or not).
- PoolRadius must be over twice PoolRenderDistance: then no client ever sees the same copy at two props.

### Idle page (props nobody uses)
`Idle = true` on a model: every idle prop of it near you shows one shared idle page on the **original** model's
screen texture (`Idle = { Texture, Dict }`, defaults: the model's `Texture` and the original model name). Desktop
screens show an empty desktop (no apps); other screens get `fw-dui:Client:Idle (Name, Model)` and send their idle
content with `DUI:SendIdle(Name, Model, Action, Data)` (fw-financials: the idle ATM screen). In-use props are copies
with their own texture, so they're not affected. No idle page? The original's texture has another name / .ytd:
`/duiidle <model> <texture> [dict]` tries one live, `/duidebug` lists the idle pages.

Making a copy: duplicate the `.ydr`/`.yft` + `.ytd` as `<model>_dui_01` and `_dui_02`, give each `.ytyp` archetype its
own `textureDictionary` (= its own name), stream them, and list them in `Variants`.

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

## ATM screen on its own texture (Fleeca)
`prop_fleece_emis` is a sheet with the screen *and* the lit sign panels, so a DUI on it also covers the signs
(black bars) and the screen only shows a cut-out of the page. In the copy `prop_fleeca_atm_dui`, give the screen
its own material and texture `prop_fleeca_atm_screen_dui`, mapped edge to edge; the signs keep `prop_fleece_emis`.
fw-dui's config already points at `prop_fleeca_atm_screen_dui`.
