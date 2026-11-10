<img width="1439" height="812" alt="1111" src="https://github.com/user-attachments/assets/7700c9de-4ba0-45a5-83a9-36bdaa352fdb" />
# codera-emote

Animation / emote system for FiveM — **codera Developments Animation System V**.

## Features

- **Emote menu** with tabs: All, Favorites, Emotes, Dances, Moods, Walks, Animals, Placed, Synced. Search, favorites, and drag-and-drop into custom slots. Every card shows a silhouette thumbnail.
- **Quick slots** (`Shift + 1…8`) bound to any emote from the menu.
- **Favorites and quick slots are saved per character** in the database.
- **Synced emotes**: offer an emote to a nearby player; they accept or decline.
- **Placed emotes**: choose a spot and rotation, then sit/lean there.
- **Animal emotes** when the player ped is an animal (dogs, cats, big cats, coyotes, deer, bears).



Emote props (cigarettes, cigars, coffee, phone, notepad, glowsticks, ...) are spawned by the resource itself. Item checks for emotes like smoking are **off** by default; set `REQUIRE_ITEMS = true` at the top of `client/main.js` (search for `REQUIRE_ITEMS`) to require the item.


## Installation

1. Put the `codera-emote` folder in your resources directory. Name the folder `codera-emote` (the resource finds its own name, so other names also work, but the examples below assume `codera-emote`).
2. Import `sql/emotes.sql` into your database.
3. Add `ensure codera-emote` to `server.cfg`, after `oxmysql` and your framework.
4. **ESX users:** copy `server/variants/esx.js` over `server/main.js` and rename the `citizenid` column in `player_emotes` to `player_id`. **QBCore users:** the default `server/main.js` is already the QBCore version.

## Usage

| Command / event | Effect |
| --- | --- |
| `/e <id>` or `/emote <id>` | play an emote, placed emote or synced emote by id (also works with walk and mood names) |
| `/e cancel` or `/e c` | stop the current emote |
| `/emotemenu` or **F3** | open the emote menu (rebindable in FiveM Settings → Key Bindings → FiveM) |
| `/e dance <n>` | play dance number `n` (random if omitted) |
| `TriggerEvent("emotes:OpenMenu")` | open the emote menu |
| `TriggerEvent("animation:cancel")` | cancel the current emote |
| `TriggerEvent("doAnim", id)` / `animation:PlayAnimation` | play an emote by id from another script |
| `np:dances:dance` (net event) | play a dance by index |
| `emotes:use:quickEmote` | trigger a quick slot |

Menu controls: arrow keys to move, `Enter` to play, `F` to favorite, `X` to assign to a slot, `E` / `0` to switch tabs, `/` to search, `Esc` to close.

### Radial menu

If you use `codera-radialmenu`, add the following entry to the radial menu config:

```lua
[4] = {
    id = 'emotes',
    title = 'Emotes',
    icon = 'child',
    items = {
        {
            id = 'emotemenu',
            title = 'Emote Menu',
            icon = 'child',
            type = 'client',
            event = 'emotes:OpenMenu',
            shouldClose = true
        }, {
            id = 'emotecancel',
            title = 'Cancel Emote',
            icon = 'ban',
            type = 'client',
            event = 'animation:cancel',
            shouldClose = true
        }
    }
},
```


## Exports

```lua
-- Returns the animal emote list for the local ped's model (nil/empty for humans)
exports["codera-emote"]:GetAnimalEmotes()
```

`IsShortcut` is also exported (true while Left Shift is held and the player is not moving fast).


## Configuration

- **Emote data:** edit the files in `data/` (each defines a global list such as `EMOTES`, `DANCES`, `WALKS`).
- **Card thumbnails:** `web/dist/thumbs.png` (a 10×9 sprite sheet of 90 silhouettes). Each emote gets one by a stable hash of its category and id. To pin one, set `window.THUMB_OVERRIDE = { "emotes:coffee": "07" }` before the UI script loads (ids are the original figure numbers, in sorted order).
- **Log level:** convar `codera-emote_logLevel`.

## Credits

Author: codera.

## Placed emote controls

While choosing a spot for a placed emote: `Enter` confirms, `X` cancels, mouse wheel rotates, `Z` toggles rotate/height. The on-screen hint shows only **Confirm** and **Cancel**.
