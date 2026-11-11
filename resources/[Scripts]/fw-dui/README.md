# fw-dui

Shared DUI resource: draws a web page on **one specific prop** (laptop, monitor, ATM, ...).
Used by `osm-atmdui` and `fw-bennys`; props you place with `fw-props` work the same way.

`ensure fw-dui` after `fw-core` / `fw-ui` and before the scripts that use it.

## Why the page is drawn on the entity
`AddReplaceTexture` and render targets are **global**: they change that texture on every copy of the model,
so two laptops next to each other both showed the page. fw-dui instead draws the page as a quad on the screen
corners of the one entity it is attached to. That also means it is **unlit**: no glare or reflections from
the game lights, the brightness stays the same (`Config.Brightness`).

Models without corners still fall back to the old `Texture` / `RenderTarget` modes (global, with lighting).

## Calibrating a screen
1. `Config.DevMode = true`, restart fw-dui, stand next to the prop.
2. `/duicalib [model]` - a test grid appears on the prop.
3. `1/2/3` pick a corner (top-left, top-right, bottom-left), arrows move it, `PgUp/PgDn` depth, `SHIFT` fine.
4. `ENTER` prints the line for `Config.Models` in F8. Paste it in `config/sh_config.lua`.

Laptops are not calibrated yet, so they use the texture fallback until you do this (the ATM corners come from
the old osm-atmdui offsets and may need a nudge).

## Exports (client)
```lua
local Id = exports['fw-dui']:Create(Url, Width, Height)   -- yields; Width/Height: exports['fw-dui']:GetResolution(Model)
exports['fw-dui']:Attach(Id, Entity)                        -- show on that entity only
exports['fw-dui']:Send(Id, 'action', Data)                  -- page receives { action = 'action', data = Data }
exports['fw-dui']:Detach(Id)                                -- off the prop, page stays loaded
exports['fw-dui']:Destroy(Id)                               -- release (DUIs are pooled, nothing leaks)
exports['fw-dui']:SetUrl(Id, Url)
exports['fw-dui']:MouseMove(Id, X, Y) / MouseDown(Id) / MouseUp(Id) / MouseWheel(Id, Delta)

-- Camera on the screen + cursor. Handles freeze, HUD, interact and ESC / Backspace / right click.
exports['fw-dui']:Focus(Id, {
    Mouse = true,                   -- real mouse events to the page (fw-bennys), or use OnCursor / OnClick (osm-atmdui)
    OnCursor = function(X, Y) end,
    OnClick = function(X, Y) end,
    CanClose = function() return true end,
    OnClose = function() end,
})
exports['fw-dui']:StopFocus()
```
DUIs created by a resource are cleaned up automatically when that resource stops.

## Always-on screens
Add entries to `Config.Screens` (by fw-props `PropId`, or `Model` + `Coords`). A script that attaches to the same
prop (e.g. the work-order laptop) takes over the screen and hands it back when it's done.
