import { ColorPalette, Config } from "../../shared/config";

// Every customisable thing on the vehicle is a "slot" with a JSON-serialisable value.
//   Mod:<type>           number (-1 = stock)
//   Turbo / Xenon        boolean
//   Wheels               { Type, Index }
//   WindowTint           number
//   PlateIndex           number
//   XenonColor           number (-1 = stock)
//   Neon                 boolean[4] (left, right, front, back)
//   NeonColor/TyreSmoke  hex string
//   Color:Primary|Secondary        hex string (custom RGB)
//   ColorType:Primary|Secondary    number (paint type)
//   Color:Pearlescent|Wheels|Dashboard|Interior   number (GTA colour index)
//   Livery / LegacyLivery number
//   Extra:<id>           boolean (on)
//   Stance:<name>        number
//   Repair               true

export type SlotMap = Record<string, any>;

const PERFORMANCE_MODS = [11, 12, 13, 15, 16];

export const HexToRgb = (Hex: string): [number, number, number] => {
    const Clean = Hex.replace("#", "");
    const Num = parseInt(Clean.length === 3 ? Clean.split("").map(C => C + C).join("") : Clean, 16);
    return [(Num >> 16) & 255, (Num >> 8) & 255, Num & 255];
};

export const RgbToHex = (R: number, G: number, B: number): string =>
    "#" + [R, G, B].map(V => Math.max(0, Math.min(255, Math.round(V))).toString(16).padStart(2, "0")).join("");

export const IndexToHex = (Index: number) => ColorPalette[Index] || "#000000";

export class VehicleState {
    readonly Vehicle: number;
    readonly Original: SlotMap = {};
    Pending: SlotMap = {};
    RepairCosts = 0;

    // Raw paint info needed to restore non-custom colours.
    private RawPaint = { PrimaryIndex: 0, SecondaryIndex: 0, PrimaryCustom: false, SecondaryCustom: false };

    constructor(Vehicle: number) {
        this.Vehicle = Vehicle;
        this.Snapshot();
    }

    // ---------- Reading ----------

    private Snapshot() {
        const V = this.Vehicle;
        const O = this.Original;

        for (let Type = 0; Type <= 48; Type++) {
            if (Type === 18 || Type === 20 || Type === 22 || Type === 23 || Type === 24 || Type === 47) continue;
            O[`Mod:${Type}`] = GetVehicleMod(V, Type);
        }

        O["Turbo"] = !!IsToggleModOn(V, 18);
        O["Xenon"] = !!IsToggleModOn(V, 22);
        O["XenonColor"] = GetVehicleXenonLightsColour(V);
        if (O["XenonColor"] === 255) O["XenonColor"] = -1;

        O["Wheels"] = { Type: GetVehicleWheelType(V), Index: GetVehicleMod(V, 23) };
        O["WindowTint"] = Math.max(0, GetVehicleWindowTint(V));
        O["PlateIndex"] = GetVehicleNumberPlateTextIndex(V);
        O["Neon"] = [0, 1, 2, 3].map(I => !!IsVehicleNeonLightEnabled(V, I));
        O["NeonColor"] = RgbToHex(...GetVehicleNeonLightsColour(V));
        O["TyreSmoke"] = RgbToHex(...GetVehicleTyreSmokeColor(V));
        O["Livery"] = GetVehicleMod(V, 48);
        O["LegacyLivery"] = GetVehicleLivery(V);

        // Paint
        const [PrimaryIndex, SecondaryIndex] = GetVehicleColours(V);
        const [PearlIndex, WheelIndex] = GetVehicleExtraColours(V);
        const [PrimaryType] = GetVehicleModColor_1(V);
        const [SecondaryType] = GetVehicleModColor_2(V);

        this.RawPaint = {
            PrimaryIndex,
            SecondaryIndex,
            PrimaryCustom: !!GetIsVehiclePrimaryColourCustom(V),
            SecondaryCustom: !!GetIsVehicleSecondaryColourCustom(V),
        };

        O["ColorType:Primary"] = PrimaryType >= 0 && PrimaryType <= 5 ? PrimaryType : 0;
        O["ColorType:Secondary"] = SecondaryType >= 0 && SecondaryType <= 5 ? SecondaryType : 0;
        O["Color:Primary"] = this.RawPaint.PrimaryCustom ? RgbToHex(...GetVehicleCustomPrimaryColour(V)) : IndexToHex(PrimaryIndex);
        O["Color:Secondary"] = this.RawPaint.SecondaryCustom ? RgbToHex(...GetVehicleCustomSecondaryColour(V)) : IndexToHex(SecondaryIndex);
        O["Color:Pearlescent"] = PearlIndex;
        O["Color:Wheels"] = WheelIndex;
        O["Color:Dashboard"] = GetVehicleDashboardColour(V);
        O["Color:Interior"] = GetVehicleInteriorColour(V);

        // Extras
        for (let Id = 0; Id <= 20; Id++) {
            if (DoesExtraExist(V, Id)) O[`Extra:${Id}`] = !!IsVehicleExtraTurnedOn(V, Id);
        }

        // Stance
        O["Stance:SpacersFront"] = Round(Math.abs(GetVehicleWheelXOffset(V, 0)));
        O["Stance:SpacersRear"] = Round(Math.abs(GetVehicleWheelXOffset(V, 2)));
        O["Stance:CamberFront"] = Round(Math.abs(GetVehicleWheelYRotation(V, 0)));
        O["Stance:CamberRear"] = Round(Math.abs(GetVehicleWheelYRotation(V, 2)));
        O["Stance:Width"] = Round(GetVehicleWheelWidth(V));
        O["Stance:Suspension"] = Round(GetVehicleSuspensionHeight(V));

        // Damage
        const Body = GetVehicleBodyHealth(V);
        const Engine = GetVehicleEngineHealth(V);
        this.RepairCosts = Math.max(0, Math.ceil(1000 - Body)) + Math.max(0, Math.ceil(1000 - Engine));
        O["Repair"] = false;
    }

    Effective(Slot: string) {
        return Slot in this.Pending ? this.Pending[Slot] : this.Original[Slot];
    }

    // Installed values merged with pending changes (sent to the UI).
    Current(): SlotMap {
        return { ...this.Original, ...this.Pending };
    }

    // ---------- Writing ----------

    Preview(Slot: string, Value: any) {
        if (JSON.stringify(Value) === JSON.stringify(this.Original[Slot])) {
            delete this.Pending[Slot];
        } else {
            this.Pending[Slot] = Value;
        }
        this.Apply(Slot);
    }

    Revert(Slot: string) {
        delete this.Pending[Slot];
        this.Apply(Slot);
    }

    RevertAll() {
        const Slots = Object.keys(this.Pending);
        this.Pending = {};
        for (const Slot of Slots) this.Apply(Slot);
    }

    HasPendingStance() {
        return Object.keys(this.Pending).some(Slot => Slot.startsWith("Stance:"));
    }

    // Apply the effective value of a slot to the vehicle.
    Apply(Slot: string) {
        const V = this.Vehicle;
        const Value = this.Effective(Slot);
        SetVehicleModKit(V, 0);

        if (Slot.startsWith("Mod:")) {
            SetVehicleMod(V, Number(Slot.split(":")[1]), Value, false);
        } else if (Slot.startsWith("Color") ) {
            this.RefreshPaint();
        } else if (Slot.startsWith("Extra:")) {
            SetVehicleExtra(V, Number(Slot.split(":")[1]), !Value);
        } else if (Slot.startsWith("Stance:")) {
            this.ApplyStance();
        } else {
            switch (Slot) {
                case "Turbo": ToggleVehicleMod(V, 18, Value); break;
                case "Xenon": ToggleVehicleMod(V, 22, Value); break;
                case "XenonColor": SetVehicleXenonLightsColour(V, Value); break;
                case "WindowTint": SetVehicleWindowTint(V, Value); break;
                case "PlateIndex": SetVehicleNumberPlateTextIndex(V, Value); break;
                case "Livery": SetVehicleMod(V, 48, Value, false); break;
                case "LegacyLivery": SetVehicleLivery(V, Value); break;
                case "Wheels": {
                    SetVehicleWheelType(V, Value.Type);
                    SetVehicleMod(V, 23, Value.Index, false);
                    if (IsThisModelABike(GetEntityModel(V))) SetVehicleMod(V, 24, Value.Index, false);
                    break;
                }
                case "Neon": {
                    for (let I = 0; I < 4; I++) SetVehicleNeonLightEnabled(V, I, Value[I]);
                    break;
                }
                case "NeonColor": {
                    SetVehicleNeonLightsColour(V, ...HexToRgb(Value));
                    break;
                }
                case "TyreSmoke": {
                    ToggleVehicleMod(V, 20, true);
                    SetVehicleTyreSmokeColor(V, ...HexToRgb(Value));
                    break;
                }
                case "Repair": break; // Executed after checkout.
            }
        }
    }

    // Paint natives overwrite each other, so all paint slots are re-applied together.
    private RefreshPaint() {
        const V = this.Vehicle;
        const Pearl = this.Effective("Color:Pearlescent");
        const Wheel = this.Effective("Color:Wheels");

        SetVehicleModColor_1(V, this.Effective("ColorType:Primary"), this.RawPaint.PrimaryIndex, Pearl);
        SetVehicleModColor_2(V, this.Effective("ColorType:Secondary"), this.RawPaint.SecondaryIndex);

        if ("Color:Primary" in this.Pending || this.RawPaint.PrimaryCustom) {
            SetVehicleCustomPrimaryColour(V, ...HexToRgb(this.Effective("Color:Primary")));
        } else {
            ClearVehicleCustomPrimaryColour(V);
        }

        if ("Color:Secondary" in this.Pending || this.RawPaint.SecondaryCustom) {
            SetVehicleCustomSecondaryColour(V, ...HexToRgb(this.Effective("Color:Secondary")));
        } else {
            ClearVehicleCustomSecondaryColour(V);
        }

        SetVehicleExtraColours(V, Pearl, Wheel);
        SetVehicleDashboardColour(V, this.Effective("Color:Dashboard"));
        SetVehicleInteriorColour(V, this.Effective("Color:Interior"));
    }

    // Wheel offset/rotation natives are not persistent, so this runs every frame while stance is pending.
    ApplyStance() {
        const V = this.Vehicle;
        const SpacersFront = this.Effective("Stance:SpacersFront");
        const SpacersRear = this.Effective("Stance:SpacersRear");
        const CamberFront = this.Effective("Stance:CamberFront");
        const CamberRear = this.Effective("Stance:CamberRear");

        // 0 = FL, 1 = FR, 2 = RL, 3 = RR
        SetVehicleWheelXOffset(V, 0, -SpacersFront);
        SetVehicleWheelXOffset(V, 1, SpacersFront);
        SetVehicleWheelXOffset(V, 2, -SpacersRear);
        SetVehicleWheelXOffset(V, 3, SpacersRear);

        SetVehicleWheelYRotation(V, 0, -CamberFront);
        SetVehicleWheelYRotation(V, 1, CamberFront);
        SetVehicleWheelYRotation(V, 2, -CamberRear);
        SetVehicleWheelYRotation(V, 3, CamberRear);

        SetVehicleWheelWidth(V, this.Effective("Stance:Width"));
        SetVehicleSuspensionHeight(V, this.Effective("Stance:Suspension"));
    }
}

const Round = (Value: number) => Math.round(Value * 1000) / 1000;

// ---------- Pricing (single source of truth for UI + checkout) ----------

export const GetPrice = (State: VehicleState, Slot: string, Value: any): number => {
    const P = Config.Prices;

    if (Slot.startsWith("Mod:")) {
        const Type = Number(Slot.split(":")[1]);
        if (PERFORMANCE_MODS.includes(Type)) {
            if (Value < 0) return 0;
            const Tiers = P.Performance[Type];
            return Tiers[Value] ?? Tiers[Tiers.length - 1];
        }
        return Value < 0 ? 0 : (P.Mods[Type] ?? 400);
    }

    if (Slot.startsWith("ColorType:")) return P.ColorType;
    if (Slot.startsWith("Color:")) return P.Color;
    if (Slot.startsWith("Extra:")) return P.Extra;
    if (Slot.startsWith("Stance:")) return P.Stance;

    switch (Slot) {
        case "Turbo": return Value ? P.Turbo : 0;
        case "Xenon": return Value ? P.Xenon : 0;
        case "XenonColor": return P.XenonColor;
        case "Wheels": return Value?.Index < 0 ? 0 : P.Wheels;
        case "WindowTint": return P.WindowTint;
        case "PlateIndex": return P.PlateIndex;
        case "Neon": return P.Neon;
        case "NeonColor": return P.NeonColor;
        case "TyreSmoke": return P.Color;
        case "Livery":
        case "LegacyLivery": return P.Livery;
        case "Repair": return State.RepairCosts;
    }

    return 0;
};
