# osm-atmdui (crp-framework)

Fleeca-style ATM rendered on the ATM screen itself (DUI). Mouse moves a cursor on the screen;
click to use it. Withdraw from your personal account or any shared/business account you have
Withdraw access to in fw-financials, and view the last 6 transactions.

Based on [osm-atmdui](https://github.com/OsmFX-Mods/osm-atmdui) by OsmFX Mods (CC BY-NC-SA 4.0, see LICENSE.md).

## Requirements
`ox_lib`, `fw-core`, `fw-financials`, `ghmattimysql`. Optional: `interact` (disabled while the ATM is open).

## Opening it
```lua
exports['osm-atmdui']:OpenATM(entity) -- entity optional; nearest ATM within 2m if nil
exports['osm-atmdui']:IsInSession()
exports['osm-atmdui']:CloseATM()
```
`/atmtest` opens the nearest ATM (set `Config.TestCommand = false` to disable).
ESC, Backspace or right click leaves.

## Files
- `config.lua` limits, camera, per-model offsets, texts
- `client/layout.lua` button positions; used for both drawing and clicking
- `client/main.lua` session, cursor, actions, exports
- `client/dui.lua` / `client/camera.lua` screen texture and locked camera
- `server/financials.lua` fw-financials accounts, history, withdraw
- `server/main.lua` callbacks and limits
- `web/` React source; `cd web && npm i && npm run build` writes `html/index.html`
