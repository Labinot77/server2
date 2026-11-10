// Port of codera-hud client/main.lua (the parts that are not framework specific):
// hides the native HUD pieces the new HUD replaces, and fixes the health/armour scaleform
// so the native bars don't show under the radar.

import { Delay } from "../../shared/utils";

const NativeComponents = [
    6,  // VEHICLE_NAME
    7,  // AREA_NAME
    8,  // VEHICLE_CLASS
    9,  // STREET_NAME
];

let MinimapScaleform = 0;

(async () => {
    MinimapScaleform = RequestScaleformMovie("minimap");
    while (!HasScaleformMovieLoaded(MinimapScaleform)) await Delay(0);
})();

setTick(() => {
    for (const Component of NativeComponents) HideHudComponentThisFrame(Component);

    // Codera calls SETUP_HEALTH_ARMOUR with 3 (= "no native bars") every frame.
    if (MinimapScaleform != 0 && HasScaleformMovieLoaded(MinimapScaleform)) {
        BeginScaleformMovieMethod(MinimapScaleform, "SETUP_HEALTH_ARMOUR");
        ScaleformMovieMethodAddParamInt(3);
        EndScaleformMovieMethod();
    };
});
