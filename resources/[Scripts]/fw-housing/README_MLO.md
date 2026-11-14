# fw-housing: MLO houses

## Install
1. Replace `fw-housing`, `fw-doors` and `fw-menu` with these folders (`client/cl_decorate.lua` is removed).
2. Start order: `PolyZone`, `interact`, `fw-doors`, `fw-housing`. The `mlo` and `mlo_data` columns are created automatically.

## How it works
| Part | Where |
| --- | --- |
| Houses, doors, zone, recolourable textures, colour palette | `config/sh_mlo.lua` |
| Prop catalog (taken from kq_propplacer `settings.lua`) | `config/sh_catalog.lua` |
| Doors / keys / access / colours / decor (server) | `server/sv_mlo.lua` |
| Zone streaming, colours, stash (client) | `client/cl_mlo.lua` |
| Decorate menu, placement, owner menu | `client/cl_mlo_decorate.lua` |

* **Doors:** each `FrontDoor` / `BackDoor` entry is registered in **fw-doors** at runtime (`HOUSE_<key>_<Side>_<n>`, not written to doors.json). The fw-doors HUD / `[E]` locks them. Owner + keyholders with *Doors* access are the door's CitizenIds; the server rejects toggles from anyone else. The phone lock drives the front door.
* **fw-menu (F1) inside the zone:** *Decorate* (owner / keyholders with *Decorate*) and *House* (owner).
* **Decorate:** freecam editor (`html/index.html` + `client/cl_mlo_decorate.lua`), camera locked to the house zone. Furniture List (categories, search, Placed tab), Object Settings (snap movement / rotation, camera speed, exact position / rotation, copy / paste, wall size and holes). 3D gizmo: drag arrows / centre to move, `R` rotate rings, `Q` world / local axes, `G` ground, `Space` place. All changes are local until **Save** (one batch to the server: `fw-housing:Server:Decor:Save`); Undo / Redo / Discard work on the local copy.
* **House menu:** keyholders (per person: Doors / Stash / Decorate access, take keys), give keys to players within 5 m, colours for walls / floor / ceiling (palette, custom hex, original), lock doors.
* **Colours:** solid-colour runtime textures replace the textures listed in `Surfaces` while you are inside. For `house_shell_01` the interior uses `mloqf3_plaster_white`, `mloqf3_brick_cream`, `mloqf3_plaster_grey` and `mloqf3_metal_sheet` from `mloqf3_tex`; move them between Walls / Floor / Ceiling if the guess is wrong.

## fw-doors exports (server)
`SetRuntimeDoor({ Info, Model, Coords, CitizenIds, Connected })`, `SetDoorAccess(Info, Cids)`, `SetDoorLocked(Info, bool)`, `IsDoorLocked(Info)`. Event `fw-doors:Server:DoorChanged(Info, Locked)`.

## Creating houses in game (`/housecreator`, admin)
1. Stand inside the empty MLO, `/housecreator` > **Create new house**.
2. **Details**: name, price, class, max decorations.
3. **Zone > Draw / add points**: walk the corners, `E` on the floor for each corner, `X` undo, arrow up / down for the height, `Enter` done.
   The zone, doors and spawn stay drawn while you work.
4. **Front door > Pick door(s)**: look at the door, `E` (twice for a double door), `Enter` done. Same for the back door (optional).
5. Optional: **Spawn point** (where you stand), **Surfaces** (the shell's .ytd + wall / floor / ceiling texture names), **Stash**.
6. **Save house**: stored in the `mlo_houses` table (created automatically), a `player_houses` row is made, every
   client gets the zone and the doors are registered in fw-doors **locked**. Edit the same way from **Houses**.
Each house in the list also has Teleport, *Test: buy it* (`/buymlo key`), *Test: reset owner* (`/sellmlo key`) and Delete
(in-game houses only, not while owned). Houses in `config/sh_mlo.lua` still work; editing one saves a database copy that wins.

## Commands
`/housecreator` (admin), `/buymlo [key]`, `/sellmlo [key]` (test, admin), `/mlogarage [key]`, `/decorate`, `/mlodoor` (admin: prints a door entry for `Doors`).
