# fw-doors – HUD + Door Creator

## HUD (ported from ox_doorlock)
- Door you're targeting: `[E]` key sprite + LOCKED / UNLOCKED in the ox bitmap font, plus centre crosshair.
- No keys: label only (dimmed), no `[E]`.
- Other doors within 6m: ring marker.
- Tweak everything in `config_hud.lua` → `Config.HUD`. Set `Enabled = false` to get the old fw-ui prompts back.

## Door Creator — `/doormenu` (admin / god)
- **Add single door** – aim at the door, `E` to select, fill in the form.
- **Add double door** – select both halves; saved as `NAME_1` / `NAME_2`, connected so they lock together.
- **Edit door I aim at** / **Doors nearby** – edit access & flags, toggle lock, disable/enable, delete (in-game doors only).

Saved to `data/doors.json`:
- `doors`: doors made in-game, appended after config.lua doors on every start (config indices never shift).
- `overrides`: edits to config.lua doors, keyed by `Info`.
