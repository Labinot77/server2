import { VehicleShops } from "../../shared/types";
import { Thread } from "../../shared/classes/thread";
import { Vector3, Vector3Format, Vector4 } from "../../shared/classes/math";
import { Delay, RegisterNUICallback, SendUIMessage, SetUIFocus, exp } from "../../shared/utils";
import { FW } from "../client";

const CatalogThread = new Thread("tick", 4);

const UndergroundShowroom = new Vector3(-41.36324, -1052.294, -42.50);
const UndergroundShowroomCar = new Vector4(-37.26872, -1054.309, -43.37314, 32.1);

let Cam: number = 0;
let Vehicle: number = 0;
let UsingCatalog: boolean = false;

const AddCatalogZone = (ShopId: VehicleShops, ShopAbbvr: string, ShopLabel: string, ZoneData: {
    center: Vector3Format;
    length: number;
    width: number;
    heading: number;
    minZ: number;
    maxZ: number;
}) => {
    exp['PolyZone'].CreateBox({
        center: ZoneData.center,
        length: ZoneData.length,
        width: ZoneData.width,
    }, {
        name: `${ShopId}_catalog`,
        heading: ZoneData.heading,
        minZ: ZoneData.minZ,
        maxZ: ZoneData.maxZ,
    }, (IsInside: boolean) => {
        if (IsInside) {
            CatalogThread.data = {
                ShopId,
                ShopAbbvr,
                ShopLabel
            };
            CatalogThread.start();
        } else {
            CatalogThread.stop();
        }
    });
};

CatalogThread.addHook("preStart", (Data) => {
    exp['fw-ui'].ShowInteraction(`[E] ${Data.ShopAbbvr} Catalogus`)
});

type CatalogData = { ShopId: VehicleShops; ShopAbbvr: string; ShopLabel: string };

const OpenCatalog = async (Data: CatalogData) => {
    if (UsingCatalog) return;
    UsingCatalog = true;

    exp['fw-assets'].AddProp('Tablet')
    await exp['fw-assets'].RequestAnimationDict('amb@code_human_in_bus_passenger_idles@female@tablet@base')
    TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 3.0, 3.0, -1, 49, 0, false, false, false);

    const Vehicles = await FW.SendCallback("fw-businesses:Server:GetCatalog", Data.ShopId)
    if (!Vehicles || Vehicles.length == 0) {
        UsingCatalog = false;
        exp['fw-assets'].RemoveProp();
        StopAnimTask(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 1.0);
        return FW.Functions.Notify("Geen voertuigen in deze catalogus..", "error");
    };

    SetUIFocus(true, true)
    SendUIMessage("VehicleCatalog", "SetVisibility", {
        Visible: true,
        Shop: Data.ShopLabel,
        Vehicles: Vehicles
    })

    exp['fw-ui'].HideInteraction()

    await Delay(1500);
    ToggleCatalogCam(true);
};

CatalogThread.addHook("active", (Data: any) => {
    if (IsControlJustReleased(0, 38)) OpenCatalog(Data);
});

CatalogThread.addHook("afterStop", () => {
    exp['fw-ui'].HideInteraction();
});

const ToggleCatalogCam = (pCreateCam: boolean) => {
    if (pCreateCam) {
        const CamCoords = UndergroundShowroom;

        Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true);
        SetFocusArea(CamCoords.x, CamCoords.y,CamCoords.z, 0.0, 0.0, 0.0);
        SetCamCoord(Cam, CamCoords.x, CamCoords.y, CamCoords.z);
        SetCamRot(Cam, -15.0, 0.0, 252.063, 0);
        SetCamFov(Cam, 50.0);
        SetCamActive(Cam, true);
        RenderScriptCams(true, false, 1, true, true);
    } else {
        if (!Cam) return;
        RenderScriptCams(false, false, 1, true, true);
        SetCamActive(Cam, false);
        DestroyCam(Cam, true);
        SetFocusEntity(PlayerPedId());
        Cam = 0;
    };
}

const ResetCamFov = (ModelName: string) => {
    const IsVehicleBig = CalculateCamPos(ModelName, 15.5)
    SetCamFov(Cam, IsVehicleBig ? 70.0 : 50.0);
};

const CalculateCamPos = (ModelName: string, LargeCamSize: number = 15.5): boolean => {
    const [[minX, minY, minZ], [maxX, maxY, maxZ]] = GetModelDimensions(ModelName);
    const [midX, midY, midZ] = [maxX - minX, maxY - minY, maxZ - minZ];
    const ModelVolume = midX * midY * midZ;
    return ModelVolume > LargeCamSize
};

const SpawnCatalogVehicle = async (ModelName: string) => {
    if (Vehicle) {
        FW.VSync.DeleteVehicle(Vehicle)
        Vehicle = 0;
    };

    await exp['fw-assets'].RequestModelHash(ModelName);

    Vehicle = CreateVehicle(ModelName, UndergroundShowroomCar.x, UndergroundShowroomCar.y, UndergroundShowroomCar.z, UndergroundShowroomCar.w, false, true);
    SetVehicleOnGroundProperly(Vehicle);
    FreezeEntityPosition(Vehicle, true);
    SetEntityHeading(Vehicle, UndergroundShowroomCar.w);
    SetVehicleEngineOn(Vehicle, true, true, false);
    SetVehicleDirtLevel(Vehicle, 0.0);
    SetVehicleModKit(Vehicle, 0);
    SetEntityInvincible(Vehicle, true);
    SetEntityCollision(Vehicle, false, true);
    SetModelAsNoLongerNeeded(ModelName);

    ResetCamFov(ModelName)
};

const CloseCatalog = () => {
    UsingCatalog = false;
    StopRotation();
    SetUIFocus(false, false);
    SendUIMessage("VehicleCatalog", "SetVisibility", { Visible: false });

    if (Vehicle) {
        FW.VSync.DeleteVehicle(Vehicle);
        Vehicle = 0;
    };

    exp['fw-assets'].RemoveProp();
    StopAnimTask(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 1.0);

    ToggleCatalogCam(false);
};

RegisterNUICallback("VehicleCatalog/Close", (Data: any, Cb: Function) => {
    CloseCatalog();
    Cb("ok");
});

RegisterNUICallback("VehicleCatalog/SetVehicle", async (Data: {
    Model: string;
}, Cb: Function) => {
    SpawnCatalogVehicle(Data.Model)

    const VehicleInfo: {
        Acceleration?: number;
        Speed?: number;
        Handling?: number;
        Braking?: number;
    } = {}
    const IsMotorCycle = IsThisModelABike(Data.Model)

    let Timeout = false
    setTimeout(() => {
        Timeout = true
    }, 13500);

    while (!DoesEntityExist(Vehicle) && !Timeout) await Delay(100);

    if (Timeout) return Cb(false);

    const InitialDriveMaxFlatVel = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
    const InitialDriveForce = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fInitialDriveForce')
    const InitialDragCoeff = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fInitialDragCoeff')
    const TractionCurveMax = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fTractionCurveMax')
    const TractionCurveMin = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fTractionCurveMin')
    const SuspensionReboundDamp = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fSuspensionReboundDamp')
    const BrakeForce = GetVehicleHandlingFloat(Vehicle, 'CHandlingData', 'fBrakeForce')
    let Force = InitialDriveForce;

    if (InitialDriveForce > 0 && InitialDriveForce < 1) Force = Force * 1.1;

    const Accel = (InitialDriveMaxFlatVel * Force) / 10
    VehicleInfo.Acceleration = Accel

    const Speed = ((InitialDriveMaxFlatVel / InitialDragCoeff) * (TractionCurveMax + TractionCurveMin)) / 40
    VehicleInfo.Speed = IsMotorCycle ? Speed * 2 : Speed;

    const Handling = (TractionCurveMax + SuspensionReboundDamp) * TractionCurveMin
    VehicleInfo.Handling = IsMotorCycle ? Handling * 2 : Handling;

    const Braking = ((TractionCurveMin / InitialDragCoeff) * BrakeForce) * 7
    VehicleInfo.Braking = IsMotorCycle ? Braking * 2 : Braking;

    Cb(VehicleInfo)
});

RegisterNUICallback("VehicleCatalog/DoRPM", (Data: any, Cb: Function) => {
    if (Vehicle && DoesEntityExist(Vehicle)) SetVehicleCurrentRpm(Vehicle, 1.0);
    Cb("ok")
})

// Showroom rotation (A/D held in the UI). Runs a tick only while a key is held.
const ROTATE_SPEED = 75.0; // degrees per second
let RotateDirection = 0;
let RotateTick = 0;

const StopRotation = () => {
    RotateDirection = 0;
    if (RotateTick) {
        clearTick(RotateTick);
        RotateTick = 0;
    };
};

RegisterNUICallback("VehicleCatalog/Rotate", (Data: { Direction: number }, Cb: Function) => {
    RotateDirection = Math.sign(Number(Data.Direction) || 0);

    if (RotateDirection == 0) {
        StopRotation();
    } else if (!RotateTick) {
        RotateTick = setTick(() => {
            if (!UsingCatalog || RotateDirection == 0 || !Vehicle || !DoesEntityExist(Vehicle)) return StopRotation();
            SetEntityHeading(Vehicle, (GetEntityHeading(Vehicle) + RotateDirection * ROTATE_SPEED * GetFrameTime()) % 360.0);
        });
    };

    Cb("ok");
});

// Mouse-drag rotation, the UI sends small batched deltas in degrees.
RegisterNUICallback("VehicleCatalog/RotateBy", (Data: { Delta: number }, Cb: Function) => {
    const Delta = Math.max(-45, Math.min(45, Number(Data.Delta) || 0));
    if (Vehicle && DoesEntityExist(Vehicle)) SetEntityHeading(Vehicle, (GetEntityHeading(Vehicle) + Delta) % 360.0);
    Cb("ok");
});

// Preview paint (local entity only, purely visual).
RegisterNUICallback("VehicleCatalog/SetColor", (Data: { Slot: "Primary" | "Secondary" | "Reset"; Rgb?: number[] }, Cb: Function) => {
    if (!Vehicle || !DoesEntityExist(Vehicle)) return Cb("ok");

    if (Data.Slot == "Reset") {
        ClearVehicleCustomPrimaryColour(Vehicle);
        ClearVehicleCustomSecondaryColour(Vehicle);
        return Cb("ok");
    };

    if (!Array.isArray(Data.Rgb) || Data.Rgb.length != 3) return Cb("ok");
    const [R, G, B] = Data.Rgb.map(Val => Math.max(0, Math.min(255, Math.floor(Number(Val) || 0))));

    if (Data.Slot == "Primary") SetVehicleCustomPrimaryColour(Vehicle, R, G, B);
    else if (Data.Slot == "Secondary") SetVehicleCustomSecondaryColour(Vehicle, R, G, B);

    Cb("ok");
});

setImmediate(async () => {
    while (!exp['fw-config'].IsConfigReady()) {
        await Delay(100)
    };

    const CatalogZones: {
        shopId: VehicleShops;
        shopAbbvr: string;
        shopLabel: string;
        interact?: Vector3Format; // interact prompt instead of a [E] zone
        catalogZone?: {
            center: Vector3Format;
            length: number;
            width: number;
            heading: number;
            minZ: number;
            maxZ: number;
        }
    }[] = Object.values(await exp['fw-config'].GetModuleConfig("bus-vehicleshop-catalog"));

    for (let i = 0; i < CatalogZones.length; i++) {
        const { shopId, shopAbbvr, shopLabel, catalogZone, interact } = CatalogZones[i];
        if (catalogZone) AddCatalogZone(shopId, shopAbbvr, shopLabel, catalogZone);
        if (interact) exp['interact'].AddInteraction({
            name: `${shopId}_catalog`,
            coords: interact,
            distance: 3.0,
            interactDst: 1.5,
            options: [{ name: `${shopId}_catalog_open`, label: `${shopAbbvr} Catalogus`, action: () => OpenCatalog({ ShopId: shopId, ShopAbbvr: shopAbbvr, ShopLabel: shopLabel }) }],
        });
    }
});

onNet("fw-ui:appRestart", (pApp: string) => {
    if (!UsingCatalog || (pApp != "root" && pApp != "VehicleCatalog")) return;
    CloseCatalog();
});