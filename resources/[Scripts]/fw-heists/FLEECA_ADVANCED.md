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
3. **Door access** (needs 2 players): the terminal player generates a code for a door: a 6-digit number to memorise
   (`CodeMemorise` s), then instructions (backwards, +1 / -1 every digit, swap first and last; `Rules` per door).
   The other player types the result on that door's security panel (`v_corp_bk_secpanel_dui_01`, screen
   `secpanel_screen_dui`), before `CodeLifetime` runs out. Security office door -> `FLEECA_LEGIONSQUARE_VAULT_DOOR`,
   Vault corridor door -> `FLEECA_LEGIONSQUARE_VAULT_GATE` (also sets `vault-gate`, so the loot behind the gate opens).
   Door 2 needs door 1 first.

Staff door keypad prop (`Config.FleecaKeypad`, every Fleeca): type the code on the keyboard; `1111` for now.
Opens `DoorIds[1]` (service door) and replaces the staff door lockpick for the vault laptop (`door-lockpicked`).

New password + notes every server start and every bank reset. All checks (items, distance, password, codes, doors) are server side.

## Adjust in-game
- `Advanced.Terminal`, `Advanced.Notes`, `Advanced.Doors[x].Panel` (sh_fleeca.lua). Terminal + panel coords are estimates:
  stand at the prop and run `/duiprop prop_monitor_01a` / `/duiprop v_corp_bk_secpanel_dui_01`, paste the vector3.
- `Doors[x].DoorId` = index in the bank's `DoorIds`.
- fw-dui `prop_monitor_01a`: stream the copy `prop_monitor_01a_dui` with screen texture `prop_moniter_dekstop_01_dui`
  (fw-dui README "Variant"). Until it's streamed, every prop_monitor_01a in view shows the page.
  Black / no page? `/duidebug`. Tweak `Camera` there too.
- Items, timings, difficulty: `config/sh_fleeca_advanced.lua`.

Preview pages in a browser: `html/fleeca/terminal.html?mock`, `html/fleeca/gridbreaker.html?mock`.

## Testing: `/fleecatest <action>` (admin)
Works on the advanced bank you're in. Output in a notification + F8.

1. `/fleecatest on` (no cops / cooldown needed), `/fleecatest items` (cutters + laptop), `/fleecatest reset` for a clean bank
2. `/fleecatest tp box` -> [E] Access -> [E] Hack network (skip: `box`, `hack`)
3. `/fleecatest tp terminal` -> Use terminal, `/fleecatest password` shows the password + which note
4. Generate a code on the terminal, `/fleecatest code` shows the answer, `/fleecatest tp panel1` -> type it (skip: `door 1`)
5. Same for the vault corridor door: `tp panel2`, `door 2`
6. Staff door keypad: `tp staff`, code 1111 (skip: `staff`). Vault: `tp vault`, `vault`
7. `/fleecatest status` any time, `/fleecatest reset` to start over, `/fleecatest off` when done
