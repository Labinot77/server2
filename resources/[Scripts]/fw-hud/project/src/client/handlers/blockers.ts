import { exp } from "../../shared/utils";

// Other resources hide the HUD while their UI is open, keyed by the calling resource.
// "all": status HUD + vehicle HUD + minimap, "vehicle": vehicle HUD only, false: clear.
type Scope = "all" | "vehicle";
const Blockers: Record<string, Scope> = {};

export const IsHudBlocked = () => Object.values(Blockers).includes("all");
export const IsVehicleHudBlocked = () => Object.keys(Blockers).length > 0;

const SetBlocker = (Resource: string, Scope: Scope | false) => {
    if (Scope) Blockers[Resource] = Scope;
    else if (Blockers[Resource]) delete Blockers[Resource];
    else return;
    emit("fw-hud:Client:OnBlockersChanged");
};

exp("SetHudBlocked", (Scope: Scope | false) => SetBlocker(GetInvokingResource() || GetCurrentResourceName(), Scope));

// Never stay hidden because a resource restarted with its UI open.
on("onClientResourceStop", (Resource: string) => SetBlocker(Resource, false));
