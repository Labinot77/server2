# fw-housing: MLO houses (test version)

## Install
1. Replace `resources/[Scripts]/fw-housing` with this folder. **Delete `client/cl_decorate.lua`** if it is still there, because it was replaced by `client/cl_mlo_decorate.lua`.
2. Replace `resources/[Scripts]/interact/client/api.lua` with the patched one. Interaction ids were `#interactions + 1`, which overwrote live interactions after anything was removed.
3. Make sure `PolyZone` and `interact` start before `fw-housing`.
4. Start the server. The `mlo` column and the `player_houses` row for every house in `config/sh_mlo.lua` are created automatically.

## How it works
| Part | Where |
| --- | --- |
| Config (zone, front door, optional back door, stash size, catalog) | `config/sh_mlo.lua` |
| DB sync, door lock state, decoration validation, garage validation, commands | `server/sv_mlo.lua` |
| Door system + interact prompts, PolyZone furniture streaming, stash/wardrobe | `client/cl_mlo.lua` |
| Decorate menu + placement tool | `client/cl_mlo_decorate.lua` |

* **Doors:** each MLO door is registered in the GTA door system and gets an interact point. Players with keys see Unlock/Lock. Everyone else sees Knock, which notifies the players inside. Front and back doors lock separately. The phone lock controls the front door.
* **Furniture streaming:** the house PolyZone spawns all furniture when you enter it and deletes it when you leave. Updates only respawn the objects that changed.
* **Decorating** (`/decorate`, or Furniture in the phone): you can place Furniture, Walls and Doors. A placed door can be opened and closed by anyone inside, and that state is synced. The client and the server both check that you are inside the zone and that the object is inside it too.
* **Garage** (`/mlogarage`, or Garage in the phone): this uses the server-side position of your ped or vehicle. It has to be outside the zone, within `Config.MLOGarage.MaxDistanceFromZone` of the zone edge and within `MaxHeightDifference` of the floor.
* **Stash / wardrobe:** these are set from the phone as usual. The server only accepts them inside the zone.

## Commands
| Command | Who | What |
| --- | --- | --- |
| `/buymlo [key]` | `Config.MLOTest.Permission` | [TEST] buy the MLO house you're in / at the door of |
| `/sellmlo [key]` | `Config.MLOTest.Permission` | [TEST] reset it to the market (clears furniture + garage) |
| `/mlogarage [key]` | keyholders | place the garage where you stand / sit |
| `/decorate` | owner / keyholders | open the decorate menu (inside only) |
| `/mlodoor` | admin | print the model + coords of the door you look at (for `FrontDoor` / `BackDoor`) |

## Adding a back door
Stand at the back door, look at it, run `/mlodoor` and paste the two printed lines into `BackDoor = { ... }`.
