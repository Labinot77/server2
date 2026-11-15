# fw-shells

Builds shells for MLO houses out of the **fw-walls** kit: walls with door holes (door + frame), one-way windows,
removed map collisions and pass-through doors. Visual builder with a freecam.

## Install
`ensure fw-shells` after `fw-walls` and `fw-doors`, before `fw-housing`. Shells are saved in `data/shells.json`.

## Builder (`/shellcreator`, admin)
**New shell** (stand in the house) or **Shells > Edit**. The camera detaches; the ground under you is the floor.

| Tool | Key | Use |
| --- | --- | --- |
| Select | 1 | Click a wall. Drag an end to resize, the middle to move. Panel: length / height / rotation, doors, windows, `Del` |
| Wall | 2 | Click, click, click... draws connected walls. Click the first point to close the room, right click / `Esc` stops |
| Door | 3 | Pick a door in the panel, click on a wall: hole + door + frame. Panel: door model, hinge side, pass-through |
| Window | 4 | Pick a size, click on a wall: framed hole with an invisible bulletproof pane |
| Collision | 5 | Click a map prop (fence, door, window, wall prop...) to remove its collision. Option: hide it too |

`WASD` move, `Q` / `E` down / up, `Shift` faster, right drag look, wheel zoom, `T` top view (best for drawing),
`G` grid (25 cm), `O` angle snap (15 degrees), `F` floor = surface under the cursor, `Page Up / Down` floor height
(upstairs), `Ctrl+Z / Y` undo / redo, `Ctrl+S` save, `Esc` close. Wall ends stick to each other.

## Windows
The shell sits inside the house. GTA buildings only render from the outside, so from inside you look through the
exterior and see out; from outside you still see the house's own window. The hole has invisible kit panels with
collision, so nobody can shoot or climb through.

## Removing collision
* **Props** (anything the Collision tool outlines in red): collision is switched off on every client while the shell is
  loaded. "Hide the prop too" removes the prop entirely (good for an exterior door or a window frame in the way).
* **Static map collision** (`.ybn`, most building walls; the tool says "static map collision"): the game has no way to
  remove it while running. Either tick **Pass-through** on the door (players press `E` at the door and are moved to the
  other side; locked doors stay closed), or edit the house's `.ybn` in CodeWalker / Sollumz and stream it.

## With fw-housing
Shell doors are normal door props at fixed coords. In `/housecreator` > **Front door > Pick door(s)**, look at a shell
door: fw-housing registers it in fw-doors and handles locks and keys.

## Notes
* Everything snaps to 25 cm. Doors / windows need 25 cm of wall around them for the frame.
* Shooting the invisible pane shows a concrete hit effect (the kit's collision material).
* Door / window types, colours, camera speed and spawn distance: `config.lua`.
