// Imported first by client.ts so these exports are registered before anything else runs.
// Other resources (fw-menu, fw-ui, fw-vehicles) call them every frame, so a load error
// elsewhere must not leave them missing.
import { exp } from "../shared/utils";
import { CurrentBennyZone, IsInBennysZone } from "./handler/zone";

let MenuOpen = false;
export const SetMenuOpen = (Open: boolean) => { MenuOpen = Open; };

exp("GetIsInBennysZone", () => IsInBennysZone === true);
exp("IsInSecretBennys", () => IsInBennysZone === true && CurrentBennyZone?.data?.Secret === true);
exp("IsBennysOpen", () => MenuOpen);
