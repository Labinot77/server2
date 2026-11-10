// Thumbnail lookup, ported from illenium-appearance (web-src/src/utils.ts).
// Each function returns candidate URLs; <ItemImage> tries them in order and falls back to an icon.

const CDN = "https://cdn.jsdelivr.net/gh/ShortByte/GTA5-Cloth-Assets/assets";
const CDN_NO_GENDER = { 1: true, 5: true };
const COMPONENT_FOLDERS = { 1: "masks", 2: "hair", 3: "torsos", 4: "legs", 5: "bags", 6: "shoes", 7: "accessories", 8: "undershirts", 9: "bodyarmors", 10: "decals", 11: "tops" };
const PROP_FOLDERS = { 0: "hats", 1: "glasses", 2: "ears", 6: "watches", 7: "bracelets" };
const PROP_ALIASES = { hats: ["hats", "hat"], glasses: ["glasses", "glass"], ears: ["ears", "ear"], watches: ["watches", "watch"], bracelets: ["bracelets", "bracelet"] };

export const LocalImage = (Path) => `./images/clothing/${Path}`;

export const ClothingImages = (Images, Model, Type, Id, Drawable, Texture = 0) => {
    const Gender = Model == "mp_f_freemode_01" ? "female" : Model == "mp_m_freemode_01" ? "male" : false;
    if (!Gender || Drawable < 0) return []; // CDN only has freemode pictures.

    const Urls = [];
    if (Images?.BaseUrl) {
        Urls.push(`${String(Images.BaseUrl).replace(/\/$/, "")}/${Gender}/${Type}_${Id}_${Drawable}_${Texture}.webp`);
    }

    if (Images?.UseCdn) {
        const Folder = Type == "prop" ? PROP_FOLDERS[Id] : COMPONENT_FOLDERS[Id];
        if (Folder) {
            const Folders = (Type == "prop" && PROP_ALIASES[Folder]) || [Folder];
            const Genders = Type == "component" && CDN_NO_GENDER[Id] ? ["", `/${Gender}`] : [`/${Gender}`, ""];
            for (const F of Folders) for (const G of Genders) Urls.push(`${CDN}/${F}${G}/${Drawable}/${Texture}.webp`);
        }
    }

    return Urls;
};

export const PedImages = (Model) => {
    const Name = String(Model || "").toLowerCase().trim();
    return [
        `https://gtahash.com/models/peds/thumbs/${Name}.webp`,
        `https://docs.fivem.net/peds/${Name}.webp`,
        `https://docs.fivem.net/peds/${Name}.png`,
    ];
};

// "MP_Bea_M_Head_000" -> "BEA HEAD 000"
export const TattooLabel = (Name) => String(Name || "")
    .replace(/^(MP_|mp_)/, "")
    .replace(/_(M|F)(_|$)/g, "$2")
    .replace(/_/g, " ")
    .toUpperCase()
    .trim();
