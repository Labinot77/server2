import { writable } from "svelte/store";
import { FetchNui } from "../../utils/FetchNui";
import { IsEnvBrowser } from "../../utils/Utils";

// Data sent by fw-clothes (client/_cl_main.lua SendSkinToUI).
export const Visible = writable(false);
export const MenuType = writable("Creation");
export const Values = writable({});      // { Hat: { MaxComps, MaxTxts }, ... }
export const Skin = writable({});        // Config.CurrentSkin.Clothes
export const Blocked = writable({});     // job whitelisted drawables per component
export const Meta = writable({
    Model: "mp_m_freemode_01",
    Gender: "Male",
    PedId: 0,
    IsCustomPed: false,
    CustomPeds: [],
    PedList: [],
    TattooNames: {},
    MaxTattooLayers: 9,
    IsFree: false,
    ItemPrice: 0,
    Images: { UseCdn: true, BaseUrl: false },
    Money: { Cash: 0, Bank: 0 },
});
export const Price = writable(0);

// Calls a NUI callback on fw-clothes, resolves with its result (or null when it failed).
export const Post = async (Event, Data = {}) => {
    if (IsEnvBrowser()) return MockPost(Event, Data);
    try {
        return await FetchNui("fw-clothes", Event, Data);
    } catch (e) {
        return null;
    }
};

export const RefreshPrice = async () => {
    const Result = await Post("Clothing/GetClothesPrice");
    if (typeof Result == "number") Price.set(Result);
};

// Lua arrays arrive as JS arrays, sparse ones as objects with 1-based keys.
export const LuaIndex = (Arr, Index) => {
    if (Arr == undefined) return undefined;
    if (Array.isArray(Arr)) return Arr[Index];
    return Arr[Index + 1] ?? Arr[String(Index + 1)];
};

const ToArray = (V) => Array.isArray(V) ? [...V] : Object.keys(V || {}).sort((a, b) => a - b).map((k) => V[k]);

// Update one value of a skin entry (0-based index) in the local copy.
export const SetSkin = (Id, Index, Value) => {
    Skin.update((S) => {
        const Arr = ToArray(S[Id]);
        Arr[Index] = Value;
        return { ...S, [Id]: Arr };
    });
};

export const TattooSet = (Zone) => {
    const Set = new Set();
    Object.values(Zone || {}).forEach((V) => { if (Number(V) > 0) Set.add(Number(V)) });
    return Set;
};

export const HairPalette = [
    "#0e1214", "#191e1f", "#262221", "#2a190d", "#432813", "#432813", "#6a462c", "#684b31",
    "#765940", "#816648", "#9f8359", "#af9869", "#b8a371", "#c5a763", "#e5c57f", "#ebd094",
    "#a68155", "#854a31", "#652012", "#5d0200", "#610000", "#7b0501", "#a6240d", "#bf451c",
    "#a74b25", "#b04921", "#5f5f5f", "#828282", "#b3b3b3", "#d3d3d3", "#3f304f", "#553769",
    "#763475", "#ff76f3", "#fa4698", "#ff9fc7", "#009aa4", "#005b88", "#003074", "#39a86a",
    "#167d5f", "#0a584f", "#c1cd2d", "#70b100", "#3ca408", "#ecc457", "#f6bb00", "#f79700",
    "#ff8c2a", "#ff8355", "#f38f57", "#dd5534", "#d92715", "#b20000", "#880000", "#120904",
    "#1d120b", "#22150d", "#2c1d11", "#22150b", "#150d05", "#000000", "#6f6b65", "#a27b4b",
];

export const MakeupPalette = [
    "#9d1a28", "#d4305a", "#c84c6b", "#c1627c", "#ae4e6a", "#b83c46", "#802729", "#aa625a",
    "#cd8a7a", "#d8a79c", "#d29794", "#b26f61", "#b95d4c", "#af472a", "#be727a", "#d68297",
    "#ffa4cb", "#f977ab", "#ed3783", "#bb466c", "#6f1b2f", "#47121e", "#b01625", "#ec142a",
    "#da0005", "#f5506f", "#ea38be", "#cc1cb9", "#a40faf", "#6c0a73", "#720560", "#510858",
    "#6a0ca1", "#0d2d6f", "#1048ad", "#1374c4", "#16aada", "#1ccfe1", "#19d9ad", "#1fcc80",
    "#10a22a", "#068800", "#72de3c", "#d3fd2f", "#f3f62a", "#ffef1f", "#ffcc1e", "#ff8e1d",
    "#ff5604", "#c96e0e", "#ffd783", "#fff8ce", "#ffffff", "#bdbfbf", "#969696", "#524948",
    "#090000", "#559ba4", "#486f8f", "#0c1f4f", "#a7806c", "#846150", "#6d4e41", "#35211b",
];

// ---- Browser preview only (npm run dev, open /#clothing) ----
const MockPost = async (Event, Data) => {
    if (Event == "Clothing/GetClothesPrice") return 50;
    if (Event == "Clothing/GetOutfits") return [{ Id: 12, Title: "Casual" }, { Id: 15, Title: "Work" }];
    if (Event == "Clothing/ShareOutfit") return { Code: "AB12CD34EF" };
    if (Event == "Clothing/ToggleTattoo") return { Success: true, Zone: [Data.Index], Price: 75 };
    if (Event == "Clothing/ProcessComponentChange") return { Success: true, Values: { MaxComps: 60, MaxTxts: 5 } };
    return { Success: true };
};
