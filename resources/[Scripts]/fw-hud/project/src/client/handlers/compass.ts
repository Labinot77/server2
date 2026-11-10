import { Thread } from "../../shared/classes/thread";
import { SendUIMessage, exp } from "../../shared/utils";

const CompassThread = new Thread("tick", 30);
const DetailsInterval = 250;
const MetersPerKm = 1000;

let NextDetailsUpdate = 0;
let LastHeading: number | null = null;
let LastStreet: string | null = null;
let LastZone: string | null = null;
let LastWaypointKey: string | null = null;

onNet("fw-inventory:Client:Cock", () => {
    if (GetVehiclePedIsIn(PlayerPedId(), false) != 0) return;

    if (CompassThread.running && !exp['fw-inventory'].HasEnoughOfItem("pdwatch", 1)) {
        StopCompass();
    } else if (!CompassThread.running && exp['fw-inventory'].HasEnoughOfItem("pdwatch", 1)) {
        StartCompass();
    };
});

const GetHeading = (): number => {
    const [, , Z] = GetGameplayCamRot(2);
    return (((-Z) % 360) + 360) % 360;
};

const GetWaypointDirection = (From: number[], To: number[], Heading: number): string => {
    const Bearing = ((Math.atan2(To[0] - From[0], To[1] - From[1]) * 180 / Math.PI) + 360) % 360;
    const Relative = ((Bearing - Heading + 540) % 360) - 180;

    if (Math.abs(Relative) <= 45) return "straight";
    if (Relative > 45 && Relative <= 135) return "right";
    if (Relative < -45 && Relative >= -135) return "left";
    return "back";
};

const UpdateDetails = (Heading: number) => {
    const [X, Y, Z] = GetEntityCoords(PlayerPedId(), true);

    // Street + zone
    const [StreetHash, CrossingHash] = GetStreetNameAtCoord(X, Y, Z);
    const StreetName = GetStreetNameFromHashKey(StreetHash) || "";
    const Crossing = GetStreetNameFromHashKey(CrossingHash) || "";
    let Zone = GetLabelText(GetNameOfZone(X, Y, Z));
    if (Zone == "NULL") Zone = "";

    const Street = (Crossing != "" ? `${StreetName} [${Crossing}]` : StreetName).toUpperCase();
    Zone = Zone.toUpperCase();

    if (Street != LastStreet || Zone != LastZone) {
        LastStreet = Street;
        LastZone = Zone;
        SendUIMessage("Hud", "SetCompassDetails", { Street, Zone });
    };

    // Waypoint
    const Blip = GetFirstBlipInfoId(8);
    if (DoesBlipExist(Blip)) {
        const [WX, WY] = GetBlipInfoIdCoord(Blip);
        const Distance = `${(Math.sqrt((WX - X) ** 2 + (WY - Y) ** 2) / MetersPerKm).toFixed(2)} km`;
        const Direction = GetWaypointDirection([X, Y], [WX, WY], Heading);
        const Key = `${Distance}|${Direction}`;

        if (Key != LastWaypointKey) {
            LastWaypointKey = Key;
            SendUIMessage("Hud", "SetWaypoint", { Visible: true, Distance, Direction });
        };
    } else if (LastWaypointKey != null) {
        LastWaypointKey = null;
        SendUIMessage("Hud", "SetWaypoint", { Visible: false });
    };
};

CompassThread.addHook("preStart", () => {
    // Force a resend of everything when the thread starts.
    NextDetailsUpdate = 0;
    LastHeading = null;
    LastStreet = null;
    LastZone = null;
    LastWaypointKey = null;
});

CompassThread.addHook("active", () => {
    const Heading = GetHeading();

    if (LastHeading == null || Math.abs(Heading - LastHeading) >= 0.05) {
        LastHeading = Heading;
        SendUIMessage("Hud", "SetCompassHeading", { Heading });
    };

    const Now = GetGameTimer();
    if (Now >= NextDetailsUpdate) {
        NextDetailsUpdate = Now + DetailsInterval;
        UpdateDetails(Heading);
    };
});

export const StartCompass = () => {
    CompassThread.start();
};

export const StopCompass = () => {
    if (exp['fw-inventory'].HasEnoughOfItem("pdwatch", 1)) return;
    CompassThread.stop();
};