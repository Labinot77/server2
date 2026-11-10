import { Config, NeonLayouts, PlateIndexes, WheelTypes, WindowTints, XenonColors } from "../../shared/config";
import type { BennysCategory, BennysNode, BennysOption, CameraFocus, OptionsNode } from "../../shared/types";
import { GetPrice, VehicleState } from "./vehicle";

type ModDef = { Type: number; Label: string; Description: string; Icon: string; Camera: CameraFocus };

// Visual body mods shown directly in the Customization list (order matches the reference UI).
const BODY_MODS: ModDef[] = [
    { Type: 0, Label: "Spoiler", Description: "Aero Enhancement", Icon: "fas fa-wind", Camera: "rear" },
    { Type: 1, Label: "Front Bumper", Description: "Impact Defense", Icon: "fas fa-car", Camera: "front" },
    { Type: 2, Label: "Rear Bumper", Description: "Stylish Protection", Icon: "fas fa-car-bump", Camera: "rear" },
    { Type: 3, Label: "Skirts", Description: "Sleek", Icon: "fas fa-car-side", Camera: "side" },
    { Type: 4, Label: "Exhaust", Description: "Engine's Roar", Icon: "fas fa-burn", Camera: "rear" },
    { Type: 6, Label: "Grille", Description: "Front Fascia", Icon: "fas fa-grip-lines", Camera: "front" },
    { Type: 7, Label: "Hood", Description: "Bonnet Styling", Icon: "fas fa-car-mechanic", Camera: "front" },
    { Type: 8, Label: "Left Fender", Description: "Wide Body", Icon: "fas fa-arrow-left", Camera: "side" },
    { Type: 9, Label: "Right Fender", Description: "Wide Body", Icon: "fas fa-arrow-right", Camera: "side" },
    { Type: 10, Label: "Roof", Description: "Top Styling", Icon: "fas fa-arrow-to-top", Camera: "top" },
    { Type: 5, Label: "Roll Cage", Description: "Chassis Frame", Icon: "fas fa-border-all", Camera: "interior" },
];

const PERFORMANCE_MODS: ModDef[] = [
    { Type: 11, Label: "Engine", Description: "Raw Power", Icon: "fas fa-cogs", Camera: "front" },
    { Type: 12, Label: "Brakes", Description: "Stopping Power", Icon: "fas fa-compact-disc", Camera: "wheel" },
    { Type: 13, Label: "Transmission", Description: "Faster Shifts", Icon: "fas fa-random", Camera: "default" },
    { Type: 15, Label: "Suspension", Description: "Handling", Icon: "fas fa-sort-amount-down", Camera: "wheel" },
    { Type: 16, Label: "Armor", Description: "Body Protection", Icon: "fas fa-shield-alt", Camera: "default" },
];

const INTERIOR_MODS: ModDef[] = [
    { Type: 27, Label: "Trim", Description: "Interior Trim", Icon: "fas fa-paint-roller", Camera: "interior" },
    { Type: 28, Label: "Ornaments", Description: "Dash Ornaments", Icon: "fas fa-star", Camera: "interior" },
    { Type: 29, Label: "Dashboard", Description: "Dash Design", Icon: "fas fa-tachometer-alt", Camera: "interior" },
    { Type: 30, Label: "Dials", Description: "Gauge Style", Icon: "fas fa-tachometer-alt-fast", Camera: "interior" },
    { Type: 31, Label: "Door Speakers", Description: "Audio", Icon: "fas fa-volume-up", Camera: "interior" },
    { Type: 32, Label: "Seats", Description: "Comfort", Icon: "fas fa-chair", Camera: "interior" },
    { Type: 33, Label: "Steering Wheel", Description: "Grip", Icon: "fas fa-steering-wheel", Camera: "interior" },
    { Type: 34, Label: "Shifter", Description: "Gear Knob", Icon: "fas fa-joystick", Camera: "interior" },
    { Type: 35, Label: "Plaques", Description: "Badges", Icon: "fas fa-award", Camera: "interior" },
    { Type: 36, Label: "Speakers", Description: "Audio", Icon: "fas fa-speaker", Camera: "interior" },
];

const ENGINE_BAY_MODS: ModDef[] = [
    { Type: 39, Label: "Engine Block", Description: "Engine Bay", Icon: "fas fa-cube", Camera: "front" },
    { Type: 40, Label: "Air Filter", Description: "Engine Bay", Icon: "fas fa-filter", Camera: "front" },
    { Type: 41, Label: "Struts", Description: "Engine Bay", Icon: "fas fa-grip-lines-vertical", Camera: "front" },
];

const MISC_MODS: ModDef[] = [
    { Type: 14, Label: "Horns", Description: "Make Some Noise", Icon: "fas fa-bullhorn", Camera: "default" },
    { Type: 25, Label: "Plate Holder", Description: "Plate Frame", Icon: "fas fa-rectangle-wide", Camera: "rear" },
    { Type: 26, Label: "Vanity Plate", Description: "Front Plate", Icon: "fas fa-id-card", Camera: "front" },
    { Type: 37, Label: "Trunk", Description: "Boot Styling", Icon: "fas fa-box-open", Camera: "rear" },
    { Type: 38, Label: "Hydraulics", Description: "Bounce", Icon: "fas fa-arrows-alt-v", Camera: "side" },
    { Type: 42, Label: "Arch Covers", Description: "Wheel Arches", Icon: "fas fa-circle-notch", Camera: "wheel" },
    { Type: 43, Label: "Aerials", Description: "Antennas", Icon: "fas fa-broadcast-tower", Camera: "rear" },
    { Type: 44, Label: "Trim B", Description: "Exterior Trim", Icon: "fas fa-paint-brush", Camera: "side" },
    { Type: 45, Label: "Fuel Tank", Description: "Tank Styling", Icon: "fas fa-gas-pump", Camera: "side" },
    { Type: 46, Label: "Windows", Description: "Window Mods", Icon: "fas fa-window-maximize", Camera: "side" },
];

const ModLabel = (Vehicle: number, Type: number, Index: number, Fallback: string) => {
    const Label = GetModTextLabel(Vehicle, Type, Index);
    if (Label) {
        const Text = GetLabelText(Label);
        if (Text && Text !== "NULL") return Text;
    }
    return Fallback;
};

const BuildModNode = (State: VehicleState, Def: ModDef): OptionsNode | null => {
    const V = State.Vehicle;
    const Count = GetNumVehicleMods(V, Def.Type);
    if (Count <= 0) return null;

    const Slot = `Mod:${Def.Type}`;
    const IsPerformance = Config.Prices.Performance[Def.Type] !== undefined;
    const Options: BennysOption[] = [{ Label: "Stock", Value: -1, Price: 0 }];

    for (let I = 0; I < Count; I++) {
        const Fallback = IsPerformance ? `Level ${I + 1}` : `Part ${I + 1}`;
        Options.push({
            Label: IsPerformance ? Fallback : ModLabel(V, Def.Type, I, Fallback),
            Value: I,
            Price: GetPrice(State, Slot, I),
        });
    }

    return { Type: "Options", Id: Slot, Slot, Label: Def.Label, Description: Def.Description, Icon: Def.Icon, Camera: Def.Camera, Options };
};

const BuildModMenu = (State: VehicleState, Id: string, Label: string, Description: string, Icon: string, Defs: ModDef[], Camera: CameraFocus = "default"): BennysNode | null => {
    const Children = Defs.map(Def => BuildModNode(State, Def)).filter(Boolean) as BennysNode[];
    if (Children.length === 0) return null;
    return { Type: "Menu", Id, Label, Description, Icon, Camera, Children };
};

const SimpleOptions = (State: VehicleState, Slot: string, Label: string, Description: string, Icon: string, Camera: CameraFocus, List: Array<{ Label: string; Value: any }>): OptionsNode => ({
    Type: "Options", Id: Slot, Slot, Label, Description, Icon, Camera,
    Options: List.map(Item => ({ ...Item, Price: GetPrice(State, Slot, Item.Value) })),
});

const BuildColors = (State: VehicleState): BennysNode => {
    const P = Config.Prices;
    return {
        Type: "Menu", Id: "Colors", Label: "Colors", Description: "Paint your vehicle", Icon: "fas fa-fill-drip", Camera: "default",
        Children: [
            { Type: "Color", Id: "Color:Primary", Slot: "Color:Primary", Mode: "Custom", Label: "Primary", Description: "Select", Icon: "fas fa-paint-brush", Price: P.Color, TypeSlot: "ColorType:Primary", TypePrice: P.ColorType },
            { Type: "Color", Id: "Color:Secondary", Slot: "Color:Secondary", Mode: "Custom", Label: "Secondary", Description: "Select", Icon: "fas fa-paint-brush-alt", Price: P.Color, TypeSlot: "ColorType:Secondary", TypePrice: P.ColorType },
            { Type: "Color", Id: "TyreSmoke", Slot: "TyreSmoke", Mode: "RGB", Label: "Wheel Smoke", Description: "Select", Icon: "fas fa-smog", Price: P.Color, Camera: "wheel" },
            { Type: "Color", Id: "Color:Dashboard", Slot: "Color:Dashboard", Mode: "Index", Label: "Dashboard", Description: "Select", Icon: "fas fa-tachometer-alt", Price: P.Color, Camera: "interior" },
            { Type: "Color", Id: "Color:Interior", Slot: "Color:Interior", Mode: "Index", Label: "Interior", Description: "Select", Icon: "fas fa-chair", Price: P.Color, Camera: "interior" },
            { Type: "Color", Id: "Color:Wheels", Slot: "Color:Wheels", Mode: "Index", Label: "Wheels", Description: "Select", Icon: "fas fa-tire", Price: P.Color, Camera: "wheel" },
            { Type: "Color", Id: "Color:Pearlescent", Slot: "Color:Pearlescent", Mode: "Index", Label: "Pearlescence", Description: "Select", Icon: "fas fa-sparkles", Price: P.Color },
        ],
    };
};

const BuildWheels = (State: VehicleState): BennysNode | null => {
    const V = State.Vehicle;
    const IsBike = IsThisModelABike(GetEntityModel(V));
    const Types = IsBike ? [{ Id: 6, Label: "Bike" }] : WheelTypes;

    const OriginalType = GetVehicleWheelType(V);
    const OriginalIndex = GetVehicleMod(V, 23);
    const CustomTyres = GetVehicleModVariation(V, 23);

    const Children: BennysNode[] = [];
    for (const WheelType of Types) {
        SetVehicleWheelType(V, WheelType.Id);
        const Count = GetNumVehicleMods(V, 23);
        if (Count <= 0) continue;

        const Options: BennysOption[] = [{ Label: "Stock", Value: { Type: WheelType.Id, Index: -1 }, Price: 0 }];
        for (let I = 0; I < Count; I++) {
            const Value = { Type: WheelType.Id, Index: I };
            Options.push({ Label: ModLabel(V, 23, I, `Rim ${I + 1}`), Value, Price: GetPrice(State, "Wheels", Value) });
        }

        Children.push({
            Type: "Options", Id: `Wheels:${WheelType.Id}`, Slot: "Wheels", Label: WheelType.Label, Description: `${Count} rims`,
            Icon: "fas fa-tire-rugged", Camera: "wheel", Options,
        });
    }

    // Restore what was installed.
    SetVehicleWheelType(V, OriginalType);
    SetVehicleMod(V, 23, OriginalIndex, CustomTyres);
    if (IsBike) SetVehicleMod(V, 24, OriginalIndex, CustomTyres);

    if (Children.length === 0) return null;
    return { Type: "Menu", Id: "Wheels", Label: "Wheels", Description: "Rims & Tyres", Icon: "fas fa-tire", Camera: "wheel", Children };
};

const BuildLights = (State: VehicleState): BennysNode => {
    const P = Config.Prices;
    return {
        Type: "Menu", Id: "Lights", Label: "Lighting", Description: "Xenons & Neons", Icon: "fas fa-lightbulb-on", Camera: "front",
        Children: [
            SimpleOptions(State, "Xenon", "Xenon Headlights", "Bright Lights", "fas fa-lightbulb", "front", [{ Label: "Stock", Value: false }, { Label: "Xenon", Value: true }]),
            SimpleOptions(State, "XenonColor", "Xenon Color", "Light Tint", "fas fa-adjust", "front", XenonColors),
            SimpleOptions(State, "Neon", "Neon Layout", "Underglow", "fas fa-border-outer", "side", NeonLayouts),
            { Type: "Color", Id: "NeonColor", Slot: "NeonColor", Mode: "RGB", Label: "Neon Color", Description: "Select", Icon: "fas fa-palette", Price: P.NeonColor, Camera: "side" },
        ],
    };
};

const BuildExtras = (State: VehicleState): BennysNode | null => {
    const Children: BennysNode[] = [];
    for (let Id = 0; Id <= 20; Id++) {
        if (!DoesExtraExist(State.Vehicle, Id)) continue;
        Children.push(SimpleOptions(State, `Extra:${Id}`, `Extra ${Id}`, "Toggle", "fas fa-puzzle-piece", "default", [{ Label: "Off", Value: false }, { Label: "On", Value: true }]));
    }
    if (Children.length === 0) return null;
    return { Type: "Menu", Id: "Extras", Label: "Extras", Description: "Vehicle Extras", Icon: "fas fa-puzzle-piece", Camera: "default", Children };
};

const BuildLivery = (State: VehicleState): BennysNode | null => {
    const V = State.Vehicle;
    const ModCount = GetNumVehicleMods(V, 48);
    if (ModCount > 0) {
        const List = [{ Label: "Stock", Value: -1 }];
        for (let I = 0; I < ModCount; I++) List.push({ Label: ModLabel(V, 48, I, `Livery ${I + 1}`), Value: I });
        return SimpleOptions(State, "Livery", "Livery", "Wrap Designs", "fas fa-spray-can", "side", List);
    }

    const LegacyCount = GetVehicleLiveryCount(V);
    if (LegacyCount > 0) {
        const List = [];
        for (let I = 0; I < LegacyCount; I++) List.push({ Label: `Livery ${I + 1}`, Value: I });
        return SimpleOptions(State, "LegacyLivery", "Livery", "Wrap Designs", "fas fa-spray-can", "side", List);
    }

    return null;
};

const BuildStancer = (): BennysNode[] => {
    const S = Config.Stance;
    const Price = Config.Prices.Stance;
    return [
        {
            Type: "Slider", Id: "Spacers", Label: "Spacers", Description: "Wheel Spacers", Icon: "fas fa-arrows-alt-h", Camera: "wheel", Price,
            Sliders: [
                { Slot: "Stance:SpacersFront", Label: "Front", Description: "Ratio Left | Ratio Right", ...S.Spacers },
                { Slot: "Stance:SpacersRear", Label: "Rear", Description: "Ratio Left | Ratio Right", ...S.Spacers },
            ],
        },
        {
            Type: "Slider", Id: "Camber", Label: "Camber", Description: "Wheel Camber", Icon: "fas fa-slash", Camera: "front", Price,
            Sliders: [
                { Slot: "Stance:CamberFront", Label: "Front", Description: "Wheel Angle", ...S.Camber },
                { Slot: "Stance:CamberRear", Label: "Rear", Description: "Wheel Angle", ...S.Camber },
            ],
        },
        {
            Type: "Slider", Id: "Width", Label: "Width", Description: "Wheel Width", Icon: "fas fa-expand-alt", Camera: "wheel", Price,
            Sliders: [{ Slot: "Stance:Width", Label: "All Wheels", Description: "Requires custom rims", ...S.Width }],
        },
        {
            Type: "Slider", Id: "Suspension", Label: "Suspension", Description: "Height of the vehicle", Icon: "fas fa-sort-amount-down-alt", Camera: "side", Price,
            Sliders: [{ Slot: "Stance:Suspension", Label: "Height", Description: "Raise | Lower", ...S.Suspension }],
        },
    ];
};

export const BuildCatalog = (State: VehicleState): BennysCategory[] => {
    const Customization: Array<BennysNode | null> = [];

    if (State.RepairCosts > 10) {
        Customization.push({
            Type: "Action", Id: "Repair", Slot: "Repair", Value: true, Label: "Repair", Description: "Fix body & engine",
            Icon: "fas fa-wrench", Price: State.RepairCosts,
        });
    }

    Customization.push(
        BuildColors(State),
        ...BODY_MODS.map(Def => BuildModNode(State, Def)),
        BuildWheels(State),
        BuildModMenu(State, "Performance", "Performance", "Engine & Handling", "fas fa-tachometer-alt-fastest", PERFORMANCE_MODS),
    );

    if (GetNumVehicleMods(State.Vehicle, 18) >= 0 && !IsThisModelABicycle(GetEntityModel(State.Vehicle))) {
        Customization.push(SimpleOptions(State, "Turbo", "Turbo", "Forced Induction", "fas fa-fan", "front", [{ Label: "None", Value: false }, { Label: "Turbo Tuning", Value: true }]));
    }

    Customization.push(
        BuildLights(State),
        SimpleOptions(State, "WindowTint", "Window Tint", "Privacy", "fas fa-window-maximize", "side", WindowTints),
        SimpleOptions(State, "PlateIndex", "Plates", "Plate Style", "fas fa-rectangle-landscape", "rear", PlateIndexes),
        BuildLivery(State),
        BuildModMenu(State, "Interior", "Interior", "Cabin Styling", "fas fa-steering-wheel", INTERIOR_MODS, "interior"),
        BuildModMenu(State, "EngineBay", "Engine Bay", "Under The Hood", "fas fa-car-battery", ENGINE_BAY_MODS, "front"),
        BuildModMenu(State, "Misc", "Miscellaneous", "Everything Else", "fas fa-toolbox", MISC_MODS),
        BuildExtras(State),
    );

    return [
        {
            Id: "Customization",
            Label: "Customization",
            Description: "Personalized vehicles, boundless creativity",
            Icon: "fas fa-car-garage",
            Items: Customization.filter(Boolean) as BennysNode[],
        },
        {
            Id: "Stancer",
            Label: "Stancer",
            Description: "Stancer style, daring wheel artistry",
            Icon: "fas fa-tire",
            Items: BuildStancer(),
        },
    ];
};
