import { IsEnvBrowser, SendEvent } from "../../utils/Utils";
import { MockRequest } from "./bennys.mock";

// Set from the Open payload, so the UI works whatever the resource folder is called.
let Resource = "fw-bennys";
export const SetResource = Name => { if (Name) Resource = Name; };

export const Request = (Event, Data = {}) => {
    if (IsEnvBrowser()) return MockRequest(Event, Data);
    SendEvent(`Bennys/${Event}`, Data, () => {}, Resource);
};

export const PlaySound = (Name = "SELECT", Set = "HUD_FRONTEND_DEFAULT_SOUNDSET") => Request("PlaySoundFrontend", { Name, Set });

export const Same = (A, B) => JSON.stringify(A) === JSON.stringify(B);

export const FormatPrice = Value => Value <= 0 ? "Free" : "$" + Math.round(Value).toLocaleString("en-US");

// Throttle that always delivers the last call.
export const Throttle = (Fn, Ms) => {
    let Last = 0, Timer = null, LastArgs = null;
    return (...Args) => {
        LastArgs = Args;
        const Now = Date.now();
        const Run = () => { Last = Date.now(); Timer = null; Fn(...LastArgs); };
        if (Now - Last >= Ms) Run();
        else if (!Timer) Timer = setTimeout(Run, Ms - (Now - Last));
    };
};

// ---------- Colour helpers ----------

export const HexToRgb = Hex => {
    const Num = parseInt((Hex || "#000000").replace("#", ""), 16);
    return [(Num >> 16) & 255, (Num >> 8) & 255, Num & 255];
};

export const RgbToHex = (R, G, B) => "#" + [R, G, B].map(V => Math.round(V).toString(16).padStart(2, "0")).join("");

export const HsvToHex = (H, S, V) => {
    const F = N => {
        const K = (N + H / 60) % 6;
        return V - V * S * Math.max(0, Math.min(K, 4 - K, 1));
    };
    return RgbToHex(F(5) * 255, F(3) * 255, F(1) * 255);
};

export const HexToHsv = Hex => {
    const [R, G, B] = HexToRgb(Hex).map(V => V / 255);
    const Max = Math.max(R, G, B), Min = Math.min(R, G, B), D = Max - Min;
    let H = 0;
    if (D) {
        if (Max === R) H = ((G - B) / D) % 6;
        else if (Max === G) H = (B - R) / D + 2;
        else H = (R - G) / D + 4;
        H *= 60;
        if (H < 0) H += 360;
    }
    return { H, S: Max ? D / Max : 0, V: Max };
};

export const NearestPaletteIndex = (Hex, Palette) => {
    const [R, G, B] = HexToRgb(Hex);
    let Best = 0, BestDist = Infinity;
    for (let I = 0; I < Palette.length; I++) {
        const [PR, PG, PB] = HexToRgb(Palette[I]);
        // Weighted euclidean (closer to perceived difference than plain RGB).
        const Dist = 2 * (R - PR) ** 2 + 4 * (G - PG) ** 2 + 3 * (B - PB) ** 2;
        if (Dist < BestDist) { BestDist = Dist; Best = I; }
    }
    return Best;
};
