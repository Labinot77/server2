# Wall kit (resizable walls with holes)

GTA can't scale a prop together with its collision, so the editor builds every wall from a small kit
of panels: 16 boxes of 25 / 50 / 100 / 200 cm wide x 25 / 50 / 100 / 200 cm high, 10 cm thick.
The player only sees one wall: they set Length / Height and add door or window holes, and
`BuildWallPieces` (config/sh_mlo.lua) picks the fewest panels that fill it (a 6 x 3 m wall with a door is 10 props).
Everything snaps to 25 cm, so a hole always lines up with the panels.

Names are fixed: `fw_wall_<w>x<h>` (e.g. `fw_wall_100x200`), texture dictionary `fw_walls`,
texture `fw_wall_plaster` (that texture takes the owner's wall colour).

## Build the kit (automatic)
1. Blender 4.2 or newer + Sollumz (Edit > Preferences > Get Extensions, search "Sollumz", Install).
2. Sollumz preferences (Edit > Preferences > Add-ons > Sollumz > Dependencies): install **PyMateria**
   (Windows). Without it the script writes CodeWalker XML (`.ydr.xml`) instead of `.ydr`.
3. Put `tools/make_wall_kit.py` and `tools/fw_wall_plaster.dds` in one folder.
4. Blender > File > New > General > File > Save As > save `wallkit.blend` in that folder.
5. Scripting tab > Open > `make_wall_kit.py` > Run Script (wait a few seconds for the popup).
6. The folder now has `fw-walls/` (fxmanifest + stream with 16 `.ydr`, `fw_walls.ytd`, `fw_walls.ytyp`).
   Copy `fw-walls` to your server, `ensure fw-walls` before `fw-housing`, restart, rejoin.

The script makes the 16 panels, gives them the Sollumz `default.sps` shader with `fw_wall_plaster` from
`fw_walls.ytd`, one drawable each with embedded CONCRETE collision, the texture dictionary, the ytyp and
exports everything as GEN8 (FiveM). Run it again any time; it replaces the previous kit.
Your own texture: replace `fw_wall_plaster.dds` (DXT1/DXT5, square, keep the name).

## Using it in game
Decorate > **Build wall** > a 2 x 2.5 m wall appears where you look.
* Length / Height fields resize it (max 8 x 4 m, see `Config.Walls`).
* **+ Door hole** (1 x 2.25 m) / **+ Window hole** (1 x 1 m at 1 m): set the offset from the
  centre, bottom, width and height of each hole. Then put a door prop from the Doors category in the hole.
* Move / rotate / snap / duplicate work like any prop. The wall counts as one object.
* The owner's wall colour (House menu > Colours > Walls) also paints the kit.

## Kit v3: collision + colour per wall
`make_wall_kit.py` now gives every panel a CONCRETE box collision (vanilla prop flags, centred on the panel) and the tint
shader `default_tnt.sps` with a generated 16 colour palette (`fw_wall_palette`, same order as the first 16
`Config.SurfaceColors`). Rebuild the kit once, replace the whole `fw-walls` folder on the server, clear your FiveM cache.
In the editor: right click a wall > Colour. Y cycles the colour. Each wall saves its own colour.
`make_wall_collisions.py` only redoes the collision of an existing `wallkit.blend`.

## Troubleshooting
* Script error: Window > Toggle System Console shows the reason (Sollumz not enabled, file not saved, .dds missing).
* `.ydr.xml` files instead of `.ydr`: PyMateria isn't installed (step 2).
* Invisible or purple walls: `fw_walls.ytd` missing from stream/.
* Panels flicker between each other: the panels are exactly the right size and sit edge to edge; if you
  change the thickness, keep it the same for every panel.
