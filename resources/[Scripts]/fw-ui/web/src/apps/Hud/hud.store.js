// Full replacement for apps/Hud/hud.store.js (keeps the stores from the player/vehicle steps).
import { writable } from "svelte/store";

export const HudVisible = writable(true);

export const Player = writable({
    Stamina: 0, ShowStamina: false,
    Oxygen: 100, IsUnderwater: false, IsSwimming: false,
    HasWeapon: false, AmmoClip: 0, AmmoReserve: 0,
});

export const VehicleData = writable({
    Visible: false,
    Speed: 0, MaxSpeed: 240, Unit: "KM/H",
    Fuel: 100, Gear: "N",
    IsAircraft: false, Altitude: 0,
    Lights: false, Belt: false, Locked: false,
    Engine: 1000, EngineOn: true, Electric: false,
});

// /hudsettings: same shape as the Defaults in fw-hud handlers/settings.ts.
export const HudSettings = writable({
    layout: {
        player:  { x: 0, y: 0, scale: 1 },
        status:  { x: 0, y: 0, scale: 1 },
        weapon:  { x: 0, y: 0, scale: 1 },
        vehicle: { x: 0, y: 0, scale: 1 },
        compass: { x: 0, y: 0, scale: 1 },
    },
    map: { showMinimap: true, showHeading: true, showLocation: true, showWaypoint: true },
    player: { showVoice: true, showNeeds: true, showArmor: true, showStamina: true, showAmmo: true },
    vehicle: { unit: "auto", showGear: true, showFuel: true, showIcons: true, showControls: true },
    general: { opacity: 100, snap: true },
});

// True while the layout editor is open: layers render with sample data so every element can be moved.
export const LayoutEditing = writable(false);

// Bumped whenever a layout transform is applied; Minimap.svelte re-measures its ring on change.
export const LayoutRevision = writable(0);

// Chat: Status.svelte pushes the voice/health row aside while the input bar is open.
export const ChatOpen = writable(false);
export const ChatInputWidth = writable(340);

// Safezone warning + developer badge.
export const SafezoneWarning = writable(false);
export const DevMode = writable(false);
