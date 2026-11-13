# Advanced Fleeca

Banks with an `Advanced` block in `config/sh_fleeca.lua` (Legion Square for now) use this flow instead of thermite + lockpick:

All prompts use the `interact` resource (no eye).

1. **Power box** (interact point on the prop_elecbox_09): `[E] Access` needs `heavy-cutters` -> `[E] Hack the network` needs `heist-laptop`.
   A `custom_laptop_01` is put on the ground and the GridBreaker app (`html/fleeca/gridbreaker.html`) opens in its DUI:
   rotate tiles to route power to the relay, 3 rounds. Success = `powerbox` 1, police alert, 90 min reset timer.
2. **Lobby terminal**: one of the bank's own monitors, the one closest to `Advanced.Terminal`, gets "Use terminal"
   (interact). It is swapped to the `_dui` copy (like the ATMs) and shows the Fleeca Branch Terminal app (`html/fleeca/terminal.html`).
   The password is typed on the screen itself (fw-dui typing). Password = one of the sticky notes (`hei_prop_hei_post_note_01`, scaled up `NoteScale`, "Read note" -> notification).
   The others are decoys; "Password hint" (click security check) reveals the first letter + length. 3 wrong = 60s lockout + alert.
   Login only works after the network hack.
3. **Door access**: generate a code (single use, 15s) -> interact on the keypad -> "Enter access code". Door 1 must be open before door 2.
   Door 2 sets `door-lockpicked`, so the normal vault laptop / gate / loot from `cl_fleeca.lua` continues from there.

Staff door keypad prop (`Config.FleecaKeypad`, every Fleeca): type the code on the keyboard; `1111` for now, or the
live code of the security office door. Opens `DoorIds[1]` (service door).

New password + notes every server start and every bank reset. All checks (items, distance, password, codes, doors) are server side.

## Adjust in-game
- `Advanced.Terminal`, `Advanced.Notes`, `Advanced.Doors[x].Keypad` (sh_fleeca.lua). Terminal + keypad coords are estimates:
  stand at the monitor you want and run `/duiprop prop_monitor_01a`, paste the vector3.
- `Doors[x].DoorId` = index in the bank's `DoorIds`.
- fw-dui `prop_monitor_01a`: stream the copy `prop_monitor_01a_dui` with screen texture `prop_moniter_dekstop_01_dui`
  (fw-dui README "Variant"). Until it's streamed, every prop_monitor_01a in view shows the page.
  Black / no page? `/duidebug`. Tweak `Camera` there too.
- Items, timings, difficulty: `config/sh_fleeca_advanced.lua`.

Preview pages in a browser: `html/fleeca/terminal.html?mock`, `html/fleeca/gridbreaker.html?mock`.
